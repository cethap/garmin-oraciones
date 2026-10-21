import Toybox.Graphics;
import Toybox.Lang;

// The header every screen shows in the band left of the subscreen lens: the title of what the screen lists
// or reads ("Oraciones", a group, a prayer), wrapped in up to 3 lines of the tiny font and centered on a
// column beside the lens, as the Rosario's menu and reading view show theirs. The band is about 74px wide
// at the top and widens below, so the longer words fall on the lower lines. The system tiny font is 23px
// tall (18 ascent). LayoutTests.mc measures every header against the visible area.
module HeaderLayout {
    // Column the title lines are centered on, and the width they wrap to.
    const TITLE_X = 59;
    const TITLE_WIDTH = 76;
    // Middle of the title block and the distance between its lines: high enough that 3 lines end above
    // the lists' first bar (row 77) and the reading window (row 75).
    const HEADER_CENTER_Y = 43;
    const HEADER_PITCH = 19;
    // fitTextToArea heights that allow 1 and 3 lines of the tiny font (it spaces them 26px apart).
    const ONE_LINE_HEIGHT = 26;
    const THREE_LINES_HEIGHT = 78;

    // Word-wraps a title with a system font (titles have accents).
    function wrapTitle(text as String) as Array<String> {
        return wrap(text, TITLE_WIDTH, THREE_LINES_HEIGHT);
    }

    // A one-line title wider than MIDDLE_WIDTH ("Consagración", 98px) does not fit the middle of the band,
    // where the lens ring leaves about 78px around TITLE_X. It takes the place of a 3-line title's last line
    // instead (rows 51..74), where the band is widest, centered on WIDE_X: about 100px fit there.
    const MIDDLE_WIDTH = 78;
    const WIDE_X = 52;
    const WIDE_CENTER_Y = 62;

    // The wrapped title's lines centered beside the lens.
    function headerPlan(titleLines as Array<String>) as Array<Layout.TextItem> {
        var items = [] as Array<Layout.TextItem>;
        if (isWideLine(titleLines)) {
            addLines(items, titleLines, WIDE_X, WIDE_CENTER_Y, HEADER_PITCH);
        } else {
            addLines(items, titleLines, TITLE_X, HEADER_CENTER_Y, HEADER_PITCH);
        }
        return items;
    }

    // Whether the title is one line wider than MIDDLE_WIDTH.
    function isWideLine(titleLines as Array<String>) as Boolean {
        return titleLines.size() == 1
            && Graphics.fitTextToArea(titleLines[0], Graphics.FONT_TINY, MIDDLE_WIDTH, ONE_LINE_HEIGHT, false) == null;
    }

    // The text in the tiny font, wrapped to the width in the lines the height allows. fitTextToArea's own
    // wrap is kept when it breaks lines only at spaces and cuts no word. Otherwise the text wraps at spaces
    // only, each line as wide as the width allows: fitTextToArea also breaks after an apostrophe, and it
    // cuts a word wider than the width, which here takes a line of its own. LayoutTests.mc measures every
    // line in its place and checks that no text is cut or needs more lines than it has.
    function wrap(text as String, width as Number, height as Number) as Array<String> {
        var fitted = Graphics.fitTextToArea(text, Graphics.FONT_TINY, width, height, false);
        if (fitted != null) {
            var lines = splitLines(fitted);
            if (joined(lines).equals(text)) {
                return lines;
            }
        }
        var lines = [] as Array<String>;
        var line = null as String?;
        var rest = text;
        while (rest.length() > 0) {
            var cut = rest.find(" ");
            var word = (cut == null ? rest : rest.substring(0, cut)) as String;
            rest = (cut == null ? "" : rest.substring(cut + 1, rest.length())) as String;
            if (line == null) {
                line = word;
            } else if (Graphics.fitTextToArea(line + " " + word, Graphics.FONT_TINY, width, ONE_LINE_HEIGHT, false) != null) {
                line = line + " " + word;
            } else {
                lines.add(line);
                line = word;
            }
        }
        if (line != null) {
            lines.add(line);
        }
        return lines;
    }

    // The lines joined back with spaces.
    function joined(lines as Array<String>) as String {
        var text = "";
        for (var i = 0; i < lines.size(); i++) {
            text += (i > 0 ? " " : "") + lines[i];
        }
        return text;
    }

    // The text's lines, split at each "\n".
    function splitLines(text as String) as Array<String> {
        var lines = [] as Array<String>;
        var rest = text;
        var cut = rest.find("\n");
        while (cut != null) {
            lines.add(rest.substring(0, cut) as String);
            rest = rest.substring(cut + 1, rest.length()) as String;
            cut = rest.find("\n");
        }
        lines.add(rest);
        return lines;
    }

    // Wrapped lines centered on (centerX, centerY), pitch px apart: tighter than the font's own line
    // spacing, which is too loose for this screen.
    function addLines(items as Array<Layout.TextItem>, lines as Array<String>, centerX as Number, centerY as Number,
        pitch as Number) as Void {
        var top = centerY - ((lines.size() - 1) * pitch + Graphics.getFontHeight(Graphics.FONT_TINY)) / 2;
        for (var i = 0; i < lines.size(); i++) {
            items.add(new Layout.TextItem(lines[i], Graphics.FONT_TINY, centerX, top + i * pitch, Graphics.TEXT_JUSTIFY_CENTER as Number));
        }
    }
}
