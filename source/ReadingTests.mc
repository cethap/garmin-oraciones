import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Tests of the reading view (PrayerView, ReadingLayout and ReadingDelegate). They read every prayer's text
// and placeholder texts made here (Placeholder) of 1, 300 and 2,500 characters, longer than any prayer, with
// line breaks and every Spanish letter and mark a prayer may use.

(:test)
module Placeholder {

    // The placeholders' lengths, in characters.
    function lengths() as Array<Number> {
        return [1, 300, 2500] as Array<Number>;
    }

    // A text of exactly length characters: words with accents, ñ, ü, ¡ ¿, « », the ellipsis and the dash,
    // separated by single spaces, with a paragraph break ("\n") instead of the space after every 17th word.
    // It never starts or ends with a space or a break, and has no two breaks in a row.
    function text(length as Number) as String {
        var words = ["Señor,", "ten", "piedad", "de", "nosotros;", "¡Alégrate,", "María!", "llena", "eres", "de", "gracia.",
            "¿Quién", "como", "Dios?", "«Ven»", "—dijo—", "y", "el", "Ángel", "habló…", "Éfeso,", "Íñigo", "Óscar",
            "Úrsula", "pingüino", "corazón", "misericordia", "según", "tu", "bondad;", "lávame", "más", "y", "más"];
        var text = "";
        var count = 0;
        while (text.length() < length) {
            if (count > 0) {
                text += count % 17 == 0 ? "\n" : " ";
            }
            text += words[count % words.size()];
            count++;
        }
        text = text.substring(0, length) as String;
        var last = text.substring(length - 1, length) as String;
        if (last.equals(" ") || last.equals("\n")) {
            text = text.substring(0, length - 1) + "a";
        }
        return text;
    }

    // Paragraph breaks in the text.
    function breaks(text as String) as Number {
        var count = 0;
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            if (chars[i] == '\n') {
                count++;
            }
        }
        return count;
    }
}

(:test)
module ReadingCheck {

    // Most memory one open reading view may hold, in bytes, once laid out and drawn, measured on its own after
    // one warm-up view. A view holds its title and body lines and the dove; the text it wraps is let go.
    // Measured: 688, 1576 and 8376 bytes for 1, 300 and 2,500 characters (190 lines); the first view a test
    // measures pays about 140 bytes more, once, so the test measures a warm-up view first. 12288 leaves about
    // 1.5x the largest and is under 20% of the widget's 64KB.
    const MEMORY_BUDGET = 12288;
    // What a closed view may leave behind, in bytes: nothing it allocated outlives it (0 measured).
    const RELEASE_SLACK = 0;
    // The prayer whose title the placeholders read under: Psalm 51, the longest prayer.
    const PLACEHOLDER_PRAYER = 5;

    // A reading view of the prayer laid out with the given text, as the view lays out its own on opening.
    function open(prayer as Number, text as String?, dc as Dc) as PrayerView {
        var view = new PrayerView(prayer);
        view.onLayout(dc);
        if (text != null) {
            view.load(dc, text);
        }
        return view;
    }

    // [bytes an open view holds once laid out and drawn, bytes left once it is let go], for a view of the
    // placeholder prayer laid out with the given text, or of the given prayer with its own text (text null),
    // which the view loads from its table as it does on opening.
    function memoryHeld(dc as Dc, text as String?, prayer as Number) as Array<Number> {
        var before = System.getSystemStats().usedMemory;
        var view = open(prayer, text, dc) as PrayerView?;
        (view as PrayerView).onUpdate(dc);
        var held = System.getSystemStats().usedMemory - before;
        view = null;
        var left = System.getSystemStats().usedMemory - before;
        return [held, left] as Array<Number>;
    }

    // The body window as a screen box [left, top, right, bottom].
    function window() as Array<Float> {
        return [ReadingLayout.WINDOW_LEFT.toFloat(), ReadingLayout.WINDOW_TOP.toFloat(),
            ReadingLayout.WINDOW_RIGHT.toFloat(), ReadingLayout.WINDOW_BOTTOM.toFloat()] as Array<Float>;
    }

    // The text the lines give back: each paragraph's lines joined with spaces, the paragraphs with "\n" where
    // a blank line separates them.
    function unwrap(lines as Array<String>) as String {
        var text = "";
        for (var i = 0; i < lines.size(); i++) {
            if (lines[i].length() == 0) {
                text += "\n";
            } else {
                text += (i > 0 && lines[i - 1].length() > 0 ? " " : "") + lines[i];
            }
        }
        return text;
    }

    // The lines hold the whole text, wrapped at spaces only: they give the text back, no line is empty but
    // the one blank line between two paragraphs, and no line starts or ends with a space.
    function wrapsWhole(text as String, lines as Array<String>, logger as Logger) as Boolean {
        var blanks = 0;
        var ok = lines.size() > 0 && unwrap(lines).equals(text);
        for (var i = 0; i < lines.size(); i++) {
            var line = lines[i];
            if (line.length() == 0) {
                blanks++;
                ok = ok && i > 0 && i < lines.size() - 1 && lines[i - 1].length() > 0 && lines[i + 1].length() > 0;
                continue;
            }
            ok = ok && line.find("\n") == null && !line.substring(0, 1).equals(" ")
                && !line.substring(line.length() - 1, line.length()).equals(" ");
        }
        ok = ok && blanks == Placeholder.breaks(text);
        logger.debug((ok ? "whole " : "CUT ") + text.length() + " chars, " + Placeholder.breaks(text) + " breaks: "
            + lines.size() + " lines, " + blanks + " blank");
        return ok;
    }

    // Header text ends above the window, so the body never runs into it.
    function aboveTheWindow(dc as Dc, item as Layout.TextItem, logger as Logger) as Boolean {
        var box = ScreenArea.measure(dc, item);
        var ok = box[3] <= ReadingLayout.WINDOW_TOP;
        if (!ok) {
            logger.debug("OVERLAP header " + ScreenArea.describe(item.text, box) + " runs into the window");
        }
        return ok;
    }

    // At this scroll position the window shows as many lines as it holds (fewer only at the end of a short
    // text), each whole inside the window and inside the visible area with the margin.
    function bodyInsideTheWindow(dc as Dc, lines as Array<String>, offset as Number, logger as Logger) as Boolean {
        var items = ReadingLayout.bodyPlan(lines, offset);
        var shown = lines.size() - offset;
        if (shown > ReadingLayout.visibleLines()) {
            shown = ReadingLayout.visibleLines();
        }
        var ok = items.size() == shown;
        for (var i = 0; i < items.size(); i++) {
            var box = ScreenArea.measure(dc, items[i]);
            var fits = items[i].text.equals(lines[offset + i]) && items[i].font == Graphics.FONT_TINY
                && ScreenArea.boxInRect(box, ReadingLayout.WINDOW_LEFT, ReadingLayout.WINDOW_TOP,
                    ReadingLayout.WINDOW_RIGHT, ReadingLayout.WINDOW_BOTTOM)
                && ScreenArea.visible(box);
            if (!fits) {
                logger.debug("OUT at offset " + offset + " " + ScreenArea.describeVisible(items[i].text, box));
            }
            ok = ok && fits;
        }
        return ok;
    }

    // The page indicator at this scroll position: none when the text fits one window; otherwise a thumb at
    // least ReadingLayout.MIN_THUMB long on the lists' track, right of the window, inside the visible area,
    // at the track's top on the first page and at its bottom on the last. Returns the thumb's top, -1 for none,
    // or -2 when it does not fit.
    function thumbTop(offset as Number, count as Number, logger as Logger) as Number {
        var thumb = ReadingLayout.thumb(offset, count);
        if (count <= ReadingLayout.visibleLines()) {
            return thumb == null ? -1 : -2;
        }
        if (thumb == null) {
            logger.debug("NO thumb at offset " + offset + " of " + count + " lines");
            return -2;
        }
        var box = ScreenArea.box(thumb);
        var last = ReadingLayout.maxOffset(count);
        var fits = ScreenArea.visible(box) && thumb[0] > ReadingLayout.WINDOW_RIGHT && thumb[1] >= MenuLayout.TRACK_TOP
            && thumb[3] <= MenuLayout.TRACK_BOTTOM && thumb[3] - thumb[1] >= ReadingLayout.MIN_THUMB
            && (offset != 0 || thumb[1] == MenuLayout.TRACK_TOP) && (offset != last || thumb[3] == MenuLayout.TRACK_BOTTOM);
        if (!fits) {
            logger.debug("OUT thumb at offset " + offset + " of " + count + " lines: " + ScreenArea.describeVisible("thumb", box));
            return -2;
        }
        return thumb[1];
    }

    // The texts the reading tests read: the placeholders, then what each prayer shows today.
    function texts() as Array<String> {
        var texts = [] as Array<String>;
        var lengths = Placeholder.lengths();
        for (var i = 0; i < lengths.size(); i++) {
            texts.add(Placeholder.text(lengths[i]));
        }
        for (var prayer = 0; prayer < Prayers.COUNT; prayer++) {
            texts.add(Prayers.text(prayer));
        }
        return texts;
    }
}

(:test)
module ScrollCheck {

    // First lines shown while pressing DOWN (or UP) from the given one over count lines, until it stops.
    function pages(from as Number, count as Number, down as Boolean) as Array<Number> {
        var shown = [from] as Array<Number>;
        for (var i = 0; i < count; i++) {
            var next = down ? ReadingLayout.nextOffset(from, count) : ReadingLayout.prevOffset(from);
            if (next == from) {
                break;
            }
            shown.add(next);
            from = next;
        }
        return shown;
    }

    // The pages of count lines, top to bottom: each whole window below the last one (0, 4, 8, ...), then
    // the last window.
    function expectedPages(count as Number) as Array<Number> {
        var last = ReadingLayout.maxOffset(count);
        var pages = [] as Array<Number>;
        for (var offset = 0; offset < last; offset += ReadingLayout.visibleLines()) {
            pages.add(offset);
        }
        pages.add(last);
        return pages;
    }

    function reversed(values as Array<Number>) as Array<Number> {
        var result = [] as Array<Number>;
        for (var i = values.size() - 1; i >= 0; i--) {
            result.add(values[i]);
        }
        return result;
    }
}

// The placeholders are what the reading tests say they are: 1, 300 and 2,500 characters, the longer two with
// several paragraph breaks.
(:test)
function placeholdersHaveTheirLengthsAndBreaks(logger as Logger) as Boolean {
    var lengths = Placeholder.lengths();
    var ok = true;
    for (var i = 0; i < lengths.size(); i++) {
        var text = Placeholder.text(lengths[i]);
        var breaks = Placeholder.breaks(text);
        logger.debug(text.length() + " chars, " + breaks + " breaks: '" + (text.length() > 60 ? text.substring(0, 60) + "…" : text) + "'");
        ok = ok && text.length() == lengths[i] && (lengths[i] < 300 || breaks >= 2) && text.find("\n\n") == null;
    }
    return ok;
}

// The body wraps at spaces only and keeps every word: a paragraph break ("\n") starts a new paragraph after
// one blank line, and no line holds a break or starts or ends with a space. So each text reads in full.
(:test)
function readingWrapsParagraphsAtSpacesOnly(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var texts = ReadingCheck.texts();
        for (var t = 0; t < texts.size(); t++) {
            ok = ReadingCheck.wrapsWhole(texts[t], ReadingLayout.bodyLines(dc, texts[t]), logger) && ok;
        }
    }
    // Two paragraphs, the second one word: one line, a blank line, one line.
    var two = ReadingLayout.bodyLines(dc, "Amén.\nAleluya.");
    logger.debug("two paragraphs: " + two);
    return ok && two.toString().equals(["Amén.", "", "Aleluya."].toString());
}

// The reading view never puts text under the subscreen lens or its ring, for every placeholder and every
// prayer at every scroll position. The body window fits the visible area with the 2px margin; the title,
// wrapped whole in up to 3 lines, fits beside the lens and ends above the window; every body line drawn
// lies whole inside the window; and the page indicator fits right of the window, on the lists' track, and
// moves down page by page from the track's top to its bottom.
(:test)
function readingTextStaysClearOfTheLens(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var window = ReadingCheck.window();
    var ok = ScreenArea.visible(window) && ReadingLayout.visibleLines() == 4;
    logger.debug((ok ? "fits " : "OUT ") + ScreenArea.describeVisible("body window", window) + " lines=" + ReadingLayout.visibleLines());
    var seen = {} as Dictionary<String, Boolean>;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var placeholders = Placeholder.lengths().size();
        var texts = ReadingCheck.texts();
        for (var t = 0; t < texts.size(); t++) {
            var prayer = t < placeholders ? ReadingCheck.PLACEHOLDER_PRAYER : t - placeholders;
            var view = ReadingCheck.open(prayer, t < placeholders ? texts[t] : null, dc);
            ok = LayoutCheck.wrapsWhole(Prayers.title(prayer), view.titleLines(), 3, logger) && ok;
            var header = HeaderLayout.headerPlan(view.titleLines());
            for (var i = 0; i < header.size(); i++) {
                ok = LayoutCheck.mainItemFits(dc, header[i], seen, logger) && ok;
                ok = ReadingCheck.aboveTheWindow(dc, header[i], logger) && ok;
            }
            var body = view.bodyLines();
            var last = ReadingLayout.maxOffset(body.size());
            var top = -1;
            for (var offset = 0; offset <= last; offset++) {
                ok = ReadingCheck.bodyInsideTheWindow(dc, body, offset, logger) && ok;
                var thumb = ReadingCheck.thumbTop(offset, body.size(), logger);
                ok = ok && thumb != -2 && thumb >= top;
                top = thumb;
            }
            logger.debug("'" + Prayers.title(prayer) + "' " + texts[t].length() + " chars: " + body.size() + " lines, last offset "
                + last + ", last thumb top " + top);
        }
    }
    return ok;
}

// Every character of the placeholders, of the text every prayer shows today and of the prayers' titles has a
// glyph in the tiny font the reading view draws them in: á é í ó ú ñ ü and their capitals, ¡ ¿ « », the
// ellipsis and the dash.
(:test)
function readingFontHasEveryGlyph(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var checked = {} as Dictionary<String, Number>;
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var texts = ReadingCheck.texts();
        for (var prayer = 0; prayer < Prayers.COUNT; prayer++) {
            texts.add(Prayers.title(prayer));
        }
        for (var t = 0; t < texts.size(); t++) {
            ok = GlyphCheck.allDrawn(dc, texts[t], Graphics.FONT_TINY, checked) && ok;
        }
    }
    logger.debug("non-ASCII glyph widths " + checked);
    return ok && checked.size() >= 18;
}

// In the reading view DOWN and UP scroll a window of lines at a time. UP on the first line and DOWN on the
// last window do nothing; DOWN stops at each whole window (0, 4, 8, ...) and then at the last window, so it
// shows every line, and UP retraces those pages in reverse; hold UP does nothing; and none of them opens or
// closes anything. BACK closes the view, back to the group's list.
(:test)
function readingScrollsPageByPageAndBackCloses(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var down = ScrollCheck.pages(0, 10, true);
    var up = ScrollCheck.pages(down[down.size() - 1], 10, false);
    logger.debug("10 lines: down " + down + " up " + up);
    var ok = down.toString().equals([0, 4, 6].toString()) && up.toString().equals([6, 4, 0].toString());
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var lengths = Placeholder.lengths();
        for (var i = 0; i < lengths.size(); i++) {
            var navigator = new NavigationFake.Recorder();
            var view = ReadingCheck.open(ReadingCheck.PLACEHOLDER_PRAYER, Placeholder.text(lengths[i]), dc);
            var delegate = new ReadingDelegate(view, navigator);
            var count = view.bodyLines().size();
            var handled = delegate.onPreviousPage();
            var stuckAtTop = view.offset == 0;
            var shownDown = [view.offset];
            for (var n = 0; n < count && delegate.onNextPage() && view.offset != shownDown[shownDown.size() - 1]; n++) {
                shownDown.add(view.offset);
            }
            var bottom = view.offset;
            handled = delegate.onNextPage() && handled;
            var stuckAtBottom = view.offset == bottom && bottom == ReadingLayout.maxOffset(count);
            handled = delegate.onMenu() && handled;
            var menuKept = view.offset == bottom;
            var shownUp = [view.offset];
            for (var n = 0; n < count && delegate.onPreviousPage() && view.offset != shownUp[shownUp.size() - 1]; n++) {
                shownUp.add(view.offset);
            }
            var expected = ScrollCheck.expectedPages(count);
            var same = shownDown.toString().equals(expected.toString())
                && shownUp.toString().equals(ScrollCheck.reversed(expected).toString());
            var quiet = navigator.calls.size() == 0;
            var back = delegate.onBack();
            logger.debug(lengths[i] + " chars: " + count + " lines, down " + shownDown + " up " + shownUp + " expected " + expected
                + " stuckAtTop=" + stuckAtTop + " stuckAtBottom=" + stuckAtBottom + " menuKept=" + menuKept + " quiet=" + quiet
                + " BACK handled=" + back + " calls=" + navigator.calls);
            ok = ok && handled && stuckAtTop && stuckAtBottom && menuKept && same && quiet && back
                && navigator.calls.toString().equals(["close"].toString()) && view.offset == 0;
        }
    }
    return ok;
}

// The reading view lays out and draws every placeholder at every scroll position, clip and page indicator
// included, and stays small: each open view, measured on its own after one warm-up view, holds less than
// ReadingCheck.MEMORY_BUDGET bytes, and leaves nothing behind once let go (the text is loaded when the view
// opens and goes with it).
(:test)
function readingViewStaysSmallAndLetsGo(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    TestLanguage.use(logger, I18n.SPA);
    var lengths = Placeholder.lengths();
    // Warm-up: the first view measured also pays a one-time cost, so it is measured and left out.
    var warmUp = ReadingCheck.memoryHeld(dc, Placeholder.text(lengths[1]), ReadingCheck.PLACEHOLDER_PRAYER);
    var held = [] as Array<Number>;
    var left = [] as Array<Number>;
    var drawn = 0;
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        for (var i = 0; i < lengths.size(); i++) {
            var text = Placeholder.text(lengths[i]);
            var bytes = ReadingCheck.memoryHeld(dc, text, ReadingCheck.PLACEHOLDER_PRAYER);
            held.add(bytes[0]);
            left.add(bytes[1]);
            ok = ok && bytes[0] > 0 && bytes[0] < ReadingCheck.MEMORY_BUDGET && bytes[1] <= ReadingCheck.RELEASE_SLACK;
            var view = ReadingCheck.open(ReadingCheck.PLACEHOLDER_PRAYER, text, dc);
            var last = ReadingLayout.maxOffset(view.bodyLines().size());
            for (var offset = 0; offset <= last; offset++) {
                view.offset = offset;
                view.onUpdate(dc);
                drawn++;
            }
        }
    }
    var stats = System.getSystemStats();
    logger.debug("drew " + drawn + " screens; warm-up view " + warmUp + "; held by 1, 300 and 2,500 chars " + held
        + " (budget " + ReadingCheck.MEMORY_BUDGET + "), left after closing " + left + "; test app used " + stats.usedMemory
        + " of " + stats.totalMemory);
    return ok && drawn > 30;
}

// Every prayer opens with its own text, loaded from its table as the view does on opening, and stays small:
// each open view, measured on its own after one warm-up view, holds less than ReadingCheck.MEMORY_BUDGET
// bytes, and leaves nothing behind once let go, so the view keeps only the wrapped lines, not the text. Logs
// each prayer's lines and pages (4 lines a page).
(:test)
function readingViewStaysSmallWithEveryPrayer(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    TestLanguage.use(logger, I18n.SPA);
    ReadingCheck.memoryHeld(dc, null, 0);
    var ok = true;
    var largest = 0;
    var pages = "";
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        for (var prayer = 0; prayer < Prayers.COUNT; prayer++) {
            var bytes = ReadingCheck.memoryHeld(dc, null, prayer);
            largest = bytes[0] > largest ? bytes[0] : largest;
            ok = ok && bytes[0] > 0 && bytes[0] < ReadingCheck.MEMORY_BUDGET && bytes[1] <= ReadingCheck.RELEASE_SLACK;
            var lines = ReadingCheck.open(prayer, null, dc).bodyLines();
            var blanks = 0;
            for (var i = 0; i < lines.size(); i++) {
                blanks += lines[i].length() == 0 ? 1 : 0;
            }
            pages += " '" + Prayers.title(prayer) + "' " + Prayers.text(prayer).length() + " chars " + lines.size() + " lines ("
                + blanks + " blank) " + ScrollCheck.expectedPages(lines.size()).size() + " pages, "
                + ScrollCheck.expectedPages(lines.size() - blanks).size() + " without the blank lines, " + bytes[0] + " bytes held,"
                + " " + bytes[1] + " left;";
        }
    }
    logger.debug("prayers:" + pages + " largest view " + largest + " bytes (budget " + ReadingCheck.MEMORY_BUDGET + ")");
    return ok;
}
