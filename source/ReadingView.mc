import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Layout of the reading view, shared with the layout tests; the Rosario's mystery reading, for texts of any
// length. No text ever goes under the subscreen lens or its ring: the header (the prayer's title) stays fixed
// in the band left of the lens (HeaderLayout), and the body (the prayer's text) scrolls only inside a fixed
// window below the lens. The view clips its drawing to that window. The body is set as verse: each printed
// line of the text ("\n") starts a new line at the window's left edge, and a printed line too long for the
// window wraps onto continuation lines indented INDENT px (a hanging indent), so each verse's start shows.
// The body wraps at spaces only: Graphics.fitTextToArea also breaks after apostrophes and around some
// punctuation. Right of the window, on the lists' track (MenuLayout), a thumb shows which part of the text is
// on screen.
module ReadingLayout {
    // Body window [left, top, right, bottom]. The lens ring covers the right side of rows 0..72, so the
    // window starts 2px below it (row 75); 4 lines of the tiny font fit down to row 158. The window keeps
    // the 2px margin inside the visible area on every row it covers (rows 73..160 limit it to 21..156).
    const WINDOW_LEFT = 22;
    const WINDOW_TOP = 75;
    const WINDOW_RIGHT = 154;
    const WINDOW_BOTTOM = 158;
    const BODY_PITCH = 20;
    // Shortest page indicator, in px: a long text would otherwise get a thumb of a pixel or two.
    const MIN_THUMB = 4;
    // The hanging indent of a wrapped printed line's continuation lines, in px.
    const INDENT = 8;
    // How the body lines mark a continuation line: with a leading space, which no other line has, since
    // lines break at spaces and the space is dropped. bodyPlan draws the line without it, INDENT px in.
    const CONTINUATION = " ";

    function windowWidth() as Number {
        return WINDOW_RIGHT - WINDOW_LEFT;
    }

    // Body lines shown at once: every one whole inside the window.
    function visibleLines() as Number {
        return (WINDOW_BOTTOM - WINDOW_TOP - Graphics.getFontHeight(Graphics.FONT_TINY)) / BODY_PITCH + 1;
    }

    // First line shown at the last scroll position: the last window of lines.
    function maxOffset(count as Number) as Number {
        var last = count - visibleLines();
        return last > 0 ? last : 0;
    }

    // DOWN moves a whole window of lines on, and stops at the last window, so its pages start at 0, 4,
    // 8, ... and then at the last window (with 10 lines: 0, 4, 6). UP goes back through those same pages
    // (6, 4, 0): to the last whole window before the current first line, and stops at the first line.
    function nextOffset(offset as Number, count as Number) as Number {
        var next = offset + visibleLines();
        var last = maxOffset(count);
        return next < last ? next : last;
    }

    function prevOffset(offset as Number) as Number {
        if (offset <= 0) {
            return 0;
        }
        return (offset - 1) / visibleLines() * visibleLines();
    }

    // The text's body lines: each printed line wrapped to the window, its continuation lines marked
    // (CONTINUATION). Empty printed lines (a break at either end, or two in a row) add nothing.
    function bodyLines(dc as Dc, text as String) as Array<String> {
        var lines = [] as Array<String>;
        var rest = text;
        while (rest.length() > 0) {
            var cut = rest.find("\n");
            var printed = (cut == null ? rest : rest.substring(0, cut)) as String;
            rest = (cut == null ? "" : rest.substring(cut + 1, rest.length())) as String;
            if (printed.length() > 0) {
                lines.addAll(wrapWords(dc, printed));
            }
        }
        return lines;
    }

    // Greedy word wrap at spaces in the tiny font: the first line as wide as the window allows, the
    // continuation lines INDENT px narrower, each marked with a leading CONTINUATION. Joined back, the lines
    // give the text again. (A single word wider than a line would overflow it; the layout tests measure every
    // line of every text.)
    function wrapWords(dc as Dc, text as String) as Array<String> {
        var lines = [] as Array<String>;
        var line = null as String?;
        var rest = text;
        while (rest.length() > 0) {
            var cut = rest.find(" ");
            var word = (cut == null ? rest : rest.substring(0, cut)) as String;
            rest = (cut == null ? "" : rest.substring(cut + 1, rest.length())) as String;
            var width = lines.size() == 0 ? windowWidth() : windowWidth() - INDENT;
            if (line == null) {
                line = word;
            } else if (dc.getTextWidthInPixels(line + " " + word, Graphics.FONT_TINY) <= width) {
                line = line + " " + word;
            } else {
                lines.add(lines.size() == 0 ? line : CONTINUATION + line);
                line = word;
            }
        }
        if (line != null) {
            lines.add(lines.size() == 0 ? line : CONTINUATION + line);
        }
        return lines;
    }

    // Whether a body line continues the printed line above it.
    function isContinuation(line as String) as Boolean {
        return line.length() > 0 && line.substring(0, 1).equals(CONTINUATION);
    }

    // The body lines shown from the given first line, one pitch apart: each from the window's left edge, a
    // continuation line INDENT px in and without its mark.
    function bodyPlan(lines as Array<String>, offset as Number) as Array<Layout.TextItem> {
        var items = [] as Array<Layout.TextItem>;
        var end = offset + visibleLines();
        if (end > lines.size()) {
            end = lines.size();
        }
        for (var i = offset; i < end; i++) {
            var line = lines[i];
            var x = WINDOW_LEFT;
            if (isContinuation(line)) {
                line = line.substring(1, line.length()) as String;
                x += INDENT;
            }
            items.add(new Layout.TextItem(line, Graphics.FONT_TINY, x, WINDOW_TOP + (i - offset) * BODY_PITCH,
                Graphics.TEXT_JUSTIFY_LEFT as Number));
        }
        return items;
    }

    // Box [left, top, right, bottom] of the page indicator's thumb on the lists' track for count lines shown
    // from offset, or null when they all fit one window. It is as long as the track times the share of the
    // lines on screen, MIN_THUMB at least, and moves from the track's top on the first line to its bottom on
    // the last window.
    function thumb(offset as Number, count as Number) as Array<Number>? {
        var shown = visibleLines();
        if (count <= shown) {
            return null;
        }
        var track = MenuLayout.TRACK_BOTTOM - MenuLayout.TRACK_TOP;
        var length = track * shown / count;
        if (length < MIN_THUMB) {
            length = MIN_THUMB;
        }
        var top = MenuLayout.TRACK_TOP + (track - length) * offset / maxOffset(count);
        var left = MenuLayout.TRACK_X - MenuLayout.THUMB_WIDTH / 2;
        return [left, top, left + MenuLayout.THUMB_WIDTH, top + length] as Array<Number>;
    }
}

// Reading view of one prayer: its title fixed beside the lens, the dove in the subscreen, its text scrolling
// a window at a time below the lens, and the page indicator beside it (ReadingDelegate: UP/DOWN scroll, BACK
// returns to the group's list). The view loads its prayer's text when it opens and keeps only the wrapped
// lines, which go with the view when it closes. Once on screen, its prayer is saved as the last one read.
class PrayerView extends WatchUi.View {

    // First body line shown (0..ReadingLayout.maxOffset).
    var offset as Number;
    private var _prayer as Number;
    private var _titleLines as Array<String>;
    private var _bodyLines as Array<String>;
    private var _dove as BitmapResource?;

    function initialize(prayer as Number) {
        View.initialize();
        offset = 0;
        _prayer = prayer;
        _titleLines = HeaderLayout.wrapTitle(Prayers.title(prayer));
        _bodyLines = [] as Array<String>;
    }

    // Loads the text and wraps it once, on opening (wrapping is the costliest part of a render, and it
    // measures text, so it waits for a Dc). A later layout keeps the lines and the scroll position.
    function onLayout(dc as Dc) as Void {
        if (_dove == null) {
            _dove = Subscreen.loadDove();
        }
        if (_bodyLines.size() == 0) {
            load(dc, Prayers.text(_prayer));
        }
    }

    // The view is on screen: its prayer becomes the last one read, which the glance names.
    function onShow() as Void {
        Prayers.saveLastRead(_prayer);
    }

    // Lays out the given text from its first line. The text itself is let go: the view keeps its lines.
    function load(dc as Dc, text as String) as Void {
        _bodyLines = ReadingLayout.bodyLines(dc, text);
        offset = 0;
    }

    function prayer() as Number {
        return _prayer;
    }

    function titleLines() as Array<String> {
        return _titleLines;
    }

    function bodyLines() as Array<String> {
        return _bodyLines;
    }

    // One window of lines down; false (and nothing changes) at the last one.
    function scrollDown() as Boolean {
        return scrollTo(ReadingLayout.nextOffset(offset, _bodyLines.size()));
    }

    // One window of lines up; false (and nothing changes) at the first line.
    function scrollUp() as Boolean {
        return scrollTo(ReadingLayout.prevOffset(offset));
    }

    private function scrollTo(target as Number) as Boolean {
        if (target == offset) {
            return false;
        }
        offset = target;
        return true;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawItems(dc, HeaderLayout.headerPlan(_titleLines));
        Subscreen.draw(dc, _dove);
        // Belt and braces: whatever the body draws stays inside its window, clear of the lens.
        dc.setClip(ReadingLayout.WINDOW_LEFT, ReadingLayout.WINDOW_TOP, ReadingLayout.windowWidth(),
            ReadingLayout.WINDOW_BOTTOM - ReadingLayout.WINDOW_TOP);
        drawItems(dc, ReadingLayout.bodyPlan(_bodyLines, offset));
        dc.clearClip();
        var thumb = ReadingLayout.thumb(offset, _bodyLines.size());
        if (thumb != null) {
            MenuLayout.drawScrollBar(dc, thumb);
        }
    }

    private function drawItems(dc as Dc, items as Array<Layout.TextItem>) as Void {
        for (var i = 0; i < items.size(); i++) {
            items[i].draw(dc);
        }
    }
}
