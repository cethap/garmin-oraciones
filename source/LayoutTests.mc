import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;

// Checks that drawn text stays inside the visible area of the Instinct 2: the per-row table the Rosario
// calibrated (VisibleArea.mc), with a 2px margin. The subscreen window, a disk of radius 31 around (144,31)
// inside the lens ring, holds the ring and the dove instead. Text boxes span the full font height (ascent +
// descent), as accented capitals reach the ascent. Every test that measures a text measures it in each
// language in turn (TestLanguage.use).
(:test)
module ScreenArea {

    const SIZE = Layout.SCREEN_SIZE;
    const SUBSCREEN_X = 144;
    const SUBSCREEN_Y = 31;
    const SUBSCREEN_RADIUS = 31;
    const MARGIN = 2;
    // Screen position and width of the glance content area (164x62) in the selected slot of the glance
    // loop, as the Rosario measured it on the watch: the selected glance is the lower band, rows 74..136,
    // its content from screen x 9.
    const GLANCE_X = 9;
    const GLANCE_Y = 74;
    const GLANCE_WIDTH = 164;

    function measuringDc() as Dc {
        return new Graphics.BufferedBitmap({:width => SIZE, :height => SIZE}).getDc();
    }

    // Box [left, top, right, bottom] of the item, measured with the real font.
    function measure(dc as Dc, item as Layout.TextItem) as Array<Float> {
        var size = dc.getTextDimensions(item.text, item.font);
        return Layout.textBox(item, size[0], size[1]);
    }

    function offset(box as Array<Float>, dx as Number, dy as Number) as Array<Float> {
        return [box[0] + dx, box[1] + dy, box[2] + dx, box[3] + dy] as Array<Float>;
    }

    function boxInRect(box as Array<Float>, left as Numeric, top as Numeric, right as Numeric, bottom as Numeric) as Boolean {
        return box[0] >= left && box[1] >= top && box[2] <= right && box[3] <= bottom;
    }

    // True when all 4 corners of the box lie within radius of (cx, cy): the farthest one does.
    function boxInDisk(box as Array<Float>, cx as Numeric, cy as Numeric, radius as Numeric) as Boolean {
        var dx = farther(box[0] - cx, box[2] - cx);
        var dy = farther(box[1] - cy, box[3] - cy);
        return dx * dx + dy * dy <= radius * radius;
    }

    // Screen box inside the visible main display with the margin.
    function visible(box as Array<Float>) as Boolean {
        return VisibleArea.boxFits(box, MARGIN);
    }

    // The box [left, top, right, bottom] in Floats.
    function box(rect as Array<Number>) as Array<Float> {
        return [rect[0].toFloat(), rect[1].toFloat(), rect[2].toFloat(), rect[3].toFloat()] as Array<Float>;
    }

    function describe(text as String, box as Array<Float>) as String {
        return "'" + text + "' [" + box[0].format("%.1f") + "," + box[1].format("%.1f") + " .. "
            + box[2].format("%.1f") + "," + box[3].format("%.1f") + "]";
    }

    // The text, its screen box and the margin it keeps inside the visible area (-1: cut).
    function describeVisible(text as String, box as Array<Float>) as String {
        return describe(text, box) + " margin " + VisibleArea.marginOf(box, 9);
    }

    // The system font's name, for logs.
    function fontName(font as Graphics.FontType) as String {
        var fonts = [Graphics.FONT_XTINY, Graphics.FONT_TINY, Graphics.FONT_SMALL, Graphics.FONT_MEDIUM, Graphics.FONT_LARGE];
        var names = ["xtiny", "tiny", "small", "medium", "large"];
        for (var i = 0; i < fonts.size(); i++) {
            if (fonts[i] == font) {
                return names[i];
            }
        }
        return font.toString();
    }

    function farther(a as Float, b as Float) as Float {
        a = a < 0 ? -a : a;
        b = b < 0 ? -b : b;
        return a > b ? a : b;
    }
}

(:test)
function geometryChecksCornersAndClosestPoints(logger as Logger) as Boolean {
    // A 10x10 box whose far corner (110,110) is 14.1 from (100,100).
    var box = [100.0, 100.0, 110.0, 110.0] as Array<Float>;
    var inDisk = ScreenArea.boxInDisk(box, 100, 100, 15) && !ScreenArea.boxInDisk(box, 100, 100, 14);
    // Rows 73..135 span the full width (0..175): a box fits with the margin on both sides only.
    var fullWidth = VisibleArea.boxFits([2.0, 80.0, 173.0, 100.0] as Array<Float>, 2)
        && !VisibleArea.boxFits([1.0, 80.0, 173.0, 100.0] as Array<Float>, 2)
        && !VisibleArea.boxFits([2.0, 80.0, 174.0, 100.0] as Array<Float>, 2);
    // The margin covers rows too: rows 73..135 span the full width, but row 72 ends at 136 (the lens
    // ring), so a box from row 74 keeps only 1px and one from row 75 keeps 2px.
    var rowMargin = VisibleArea.marginOf([50.0, 75.0, 135.0, 90.0] as Array<Float>, 9) == 2
        && VisibleArea.marginOf([50.0, 74.0, 135.0, 90.0] as Array<Float>, 9) == 1;
    // Off the bottom of the screen is never visible; the top rows narrow toward the corner.
    var edges = VisibleArea.marginOf([50.0, 170.0, 60.0, 180.0] as Array<Float>, 9) == -1
        && VisibleArea.boxFits([38.0, 2.0, 100.0, 10.0] as Array<Float>, 2)
        && !VisibleArea.boxFits([37.0, 2.0, 100.0, 10.0] as Array<Float>, 2);
    var center = Layout.textBox(new Layout.TextItem("x", Graphics.FONT_TINY, 50, 40,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER), 30, 23);
    var right = Layout.textBox(new Layout.TextItem("x", Graphics.FONT_TINY, 50, 40, Graphics.TEXT_JUSTIFY_RIGHT), 30, 23);
    logger.debug("inDisk=" + inDisk + " fullWidth=" + fullWidth + " rowMargin=" + rowMargin + " edges=" + edges
        + " center=" + center + " right=" + right);
    return inDisk && fullWidth && rowMargin && edges
        && center[0] == 35.0 && center[1] == 28.5 && center[2] == 65.0 && center[3] == 51.5
        && right[0] == 20.0 && right[1] == 40.0 && right[2] == 50.0 && right[3] == 63.0;
}

// The glance's two lines lie inside its 164x62 content area and, in the selected slot measured on the watch
// (ScreenArea.GLANCE_Y), inside the visible area with the 2px margin. Both use the medium font.
(:test)
function glanceTextStaysInsideTheVisibleArea(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var items = Layout.glancePlan(Prayers.glanceTitle(), Prayers.glanceSummary(), Layout.GLANCE_HEIGHT);
        ok = ok && items.size() == 2;
        for (var i = 0; i < items.size(); i++) {
            var item = items[i];
            var box = ScreenArea.measure(dc, item);
            var screen = ScreenArea.offset(box, ScreenArea.GLANCE_X, ScreenArea.GLANCE_Y);
            var fits = item.font == Graphics.FONT_MEDIUM
                && ScreenArea.boxInRect(box, 0, 0, ScreenArea.GLANCE_WIDTH, Layout.GLANCE_HEIGHT)
                && ScreenArea.visible(screen);
            logger.debug((fits ? "fits " : "OUT ") + Graphics.getFontHeight(item.font) + "px "
                + ScreenArea.describeVisible(item.text, screen) + ", " + (ScreenArea.GLANCE_WIDTH - box[2]).format("%.0f")
                + "px to the content's right edge");
            ok = ok && fits;
        }
    }
    return ok;
}

// The two glance lines read as one block, vertically centered in the 62px slot: the title over the summary,
// both in the medium font at x 9, the summary's box starting where the title's ends (touching, never
// overlapping), with the same room above the block as below it (1px apart at most): rows 4..31 and 31..58.
(:test)
function glanceLinesReadAsOneBlock(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var font = Graphics.FONT_MEDIUM;
    var line = Graphics.getFontHeight(font);
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var items = Layout.glancePlan(Prayers.glanceTitle(), Prayers.glanceSummary(), Layout.GLANCE_HEIGHT);
        var title = ScreenArea.measure(dc, items[0]);
        var summary = ScreenArea.measure(dc, items[1]);
        var gap = summary[1] - title[3];
        var above = title[1];
        var below = Layout.GLANCE_HEIGHT - summary[3];
        var spread = above - below;
        var block = items.size() == 2 && items[0].font == font && items[1].font == font
            && items[0].x == Layout.GLANCE_LEFT && items[1].x == Layout.GLANCE_LEFT && Layout.GLANCE_LEFT == 9
            && items[1].y - items[0].y == line && gap == 0 && above >= 0 && below >= 0 && spread >= -1 && spread <= 1;
        logger.debug((block ? "block " : "APART ") + ScreenArea.describe(items[0].text, title) + " over "
            + ScreenArea.describe(items[1].text, summary) + " gap " + gap.format("%.0f") + ", " + above.format("%.0f")
            + "px above, " + below.format("%.0f") + "px below; medium " + line + "px");
        ok = ok && block;
    }
    return ok;
}

// The views center the ring and the dove on the subscreen the device reports (Subscreen.ring). On the
// Instinct 2 that is the subscreen window the layout checks use, so the checks, fed the same ring, measure
// what the views draw.
(:test)
function ringSitsOnTheDeviceSubscreen(logger as Logger) as Boolean {
    var subscreen = (WatchUi has :getSubscreen) ? WatchUi.getSubscreen() : null;
    var ring = Subscreen.ring();
    if (subscreen == null) {
        logger.debug("no subscreen reported; ring=" + ring);
        return false;
    }
    logger.debug("subscreen=" + subscreen.x + "," + subscreen.y + " " + subscreen.width + "x" + subscreen.height + " ring=" + ring);
    return subscreen.x + subscreen.width / 2 == ScreenArea.SUBSCREEN_X
        && subscreen.y + subscreen.height / 2 == ScreenArea.SUBSCREEN_Y
        && subscreen.width == subscreen.height && subscreen.width / 2 == ScreenArea.SUBSCREEN_RADIUS
        && ring[0] == ScreenArea.SUBSCREEN_X && ring[1] == ScreenArea.SUBSCREEN_Y && ring[2] < ScreenArea.SUBSCREEN_RADIUS;
}

// The subscreen ring, 1px wide, keeps the 2px margin inside the subscreen window (radius 31), and the dove,
// a 32x32 bitmap centered on it, lies wholly inside the ring with the 2px margin: every corner of its box
// within the ring's inner edge less the margin. So neither runs under the opaque lens ring around the window.
(:test)
function doveSitsInsideTheSubscreenRing(logger as Logger) as Boolean {
    var ring = Subscreen.ring();
    var dove = Subscreen.loadDove();
    var box = ScreenArea.box(Subscreen.doveBox(ring, dove.getWidth(), dove.getHeight()));
    var ringFits = ring[2] + 1 <= ScreenArea.SUBSCREEN_RADIUS - ScreenArea.MARGIN;
    var inner = ring[2] - 1 - ScreenArea.MARGIN;
    var doveFits = ScreenArea.boxInDisk(box, ring[0], ring[1], inner);
    logger.debug("ring " + ring + " fits=" + ringFits + "; dove " + dove.getWidth() + "x" + dove.getHeight() + " at "
        + ScreenArea.describe("dove", box) + " inside radius " + inner + " fits=" + doveFits);
    return ringFits && doveFits && dove.getWidth() == 32 && dove.getHeight() == 32;
}

// The list of groups, the app's first screen: "Oraciones" beside the lens over the four groups in the large
// font, two at a time, each centered on its own bar in the full-width rows below the lens. At every
// selection, every text drawn, the selected item's bar and the scroll bar keep the 2px margin inside the
// visible area, each label lies inside its bar, and the list draws (MenuCheck.listFits). The title, wrapped
// whole in up to 3 lines, fits beside the lens and ends above the first bar.
(:test)
function groupListStaysInsideTheVisibleArea(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var seen = {} as Dictionary<String, Boolean>;
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        var list = new GroupListView();
        list.onLayout(dc);
        ok = list.labels().size() == Prayers.GROUP_COUNT && MenuCheck.headerFits(dc, I18n.text(I18n.GroupsTitle), list, seen, logger)
            && MenuCheck.listFits(dc, list, seen, logger) && ok;
    }
    return ok;
}

// Each group's list of prayers, in the same style: the group's title beside the lens over its prayers' short
// titles. For every group, at every selection, everything it draws fits as the list of groups does, and the
// group's title, wrapped whole, ends above the first bar.
(:test)
function prayerListsStayInsideTheVisibleArea(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var seen = {} as Dictionary<String, Boolean>;
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        for (var group = 0; group < Prayers.GROUP_COUNT; group++) {
            var list = new PrayerListView(group);
            list.onLayout(dc);
            ok = list.labels().size() == Prayers.groupSize(group)
                && MenuCheck.headerFits(dc, Prayers.groupTitle(group), list, seen, logger)
                && MenuCheck.listFits(dc, list, seen, logger) && ok;
        }
    }
    var first = MenuLayout.bar(0);
    var second = MenuLayout.bar(1);
    logger.debug("bars " + first + " " + second + " large font " + Graphics.getFontHeight(Graphics.FONT_LARGE) + "px (ascent "
        + Graphics.getFontAscent(Graphics.FONT_LARGE) + ", descent " + Graphics.getFontDescent(Graphics.FONT_LARGE) + ")");
    return ok && first[3] < second[1] && MenuLayout.VISIBLE_ITEMS == 2;
}

// Only the selected item of a list is inverted, at every selection: the selected one is black text on a
// white bar, any other white text on the black background with no bar. So the items always look different,
// and every label contrasts with what lies under it (MenuLayout.itemColors, which the lists draw with).
(:test)
function listsInvertOnlyTheSelectedItem(logger as Logger) as Boolean {
    var ok = MenuLayout.BACKGROUND == Graphics.COLOR_BLACK;
    var looks = "";
    var count = 5;
    for (var selected = 0; selected < count; selected++) {
        looks += " selected " + selected + ":";
        for (var i = 0; i < count; i++) {
            var colors = MenuLayout.itemColors(i, selected);
            var under = colors[1] == Graphics.COLOR_TRANSPARENT ? MenuLayout.BACKGROUND : colors[1];
            var inverted = colors[0] == Graphics.COLOR_BLACK && colors[1] == Graphics.COLOR_WHITE;
            var plain = colors[0] == Graphics.COLOR_WHITE && colors[1] == Graphics.COLOR_TRANSPARENT;
            ok = ok && colors.size() == 2 && (i == selected ? inverted : plain) && colors[0] != under;
            looks += " " + i + (i == selected ? " inverted" : " plain");
        }
    }
    logger.debug(looks);
    return ok;
}

// Every character the lists and the glance draw has a glyph in the font they draw it with: the glance's
// lines (medium), the groups' and the prayers' titles on the bars (large) and in the header (tiny), and the
// list of groups' title (tiny). Spanish needs á é í ó ú ñ and their capitals (Á in "Ángelus").
(:test)
function listFontsHaveEveryGlyph(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    var texts = [] as Array<String>;
    var fonts = [] as Array<Graphics.FontType>;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        texts.add(Prayers.glanceTitle());
        fonts.add(Graphics.FONT_MEDIUM);
        texts.add(Prayers.glanceSummary());
        fonts.add(Graphics.FONT_MEDIUM);
        texts.add(I18n.text(I18n.GroupsTitle));
        fonts.add(Graphics.FONT_TINY);
        for (var group = 0; group < Prayers.GROUP_COUNT; group++) {
            var titles = Prayers.titles(group);
            titles.add(Prayers.groupTitle(group));
            for (var i = 0; i < titles.size(); i++) {
                texts.add(titles[i]);
                fonts.add(Graphics.FONT_LARGE);
                texts.add(titles[i]);
                fonts.add(Graphics.FONT_TINY);
            }
        }
    }
    var checked = {} as Dictionary<String, Number>;
    var ok = texts.size() > 0;
    for (var t = 0; t < texts.size(); t++) {
        ok = GlyphCheck.allDrawn(dc, texts[t], fonts[t], checked) && ok;
    }
    logger.debug("non-ASCII glyph widths by font " + checked);
    return ok;
}

// The lists stay small: each open list, laid out and drawn, measured on its own after one warm-up list,
// holds less than MenuCheck.MEMORY_BUDGET bytes.
(:test)
function listsStaySmall(logger as Logger) as Boolean {
    var dc = ScreenArea.measuringDc();
    TestLanguage.use(logger, I18n.SPA);
    var warmUp = MenuCheck.memoryHeld(dc, -1);
    var held = [] as Array<Number>;
    var ok = true;
    for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
        TestLanguage.use(logger, language);
        for (var group = -1; group < Prayers.GROUP_COUNT; group++) {
            var bytes = MenuCheck.memoryHeld(dc, group);
            held.add(bytes);
            ok = ok && bytes > 0 && bytes < MenuCheck.MEMORY_BUDGET;
        }
    }
    logger.debug("warm-up list " + warmUp + " bytes; groups, then each group's prayers: " + held + " (budget "
        + MenuCheck.MEMORY_BUDGET + ")");
    return ok;
}

(:test)
module GlyphCheck {

    // Every non-ASCII character of the text has a glyph in the font: it measures neither 0 nor what a
    // character the font lacks measures (a CJK one; the font draws a box for it). Each character and font
    // is checked once and its width kept in checked ("é@large" => 14).
    function allDrawn(dc as Dc, text as String, font as Graphics.FontType, checked as Dictionary<String, Number>) as Boolean {
        var missing = dc.getTextWidthInPixels("中", font);
        var name = ScreenArea.fontName(font);
        var chars = text.toCharArray();
        var ok = true;
        for (var c = 0; c < chars.size(); c++) {
            var glyph = chars[c].toString();
            var key = glyph + "@" + name;
            if (chars[c].toNumber() < 128 || checked.hasKey(key)) {
                continue;
            }
            var width = dc.getTextWidthInPixels(glyph, font);
            checked[key] = width;
            ok = ok && width > 0 && width != missing;
        }
        return ok;
    }
}

(:test)
module MenuCheck {

    // Most memory one open list may hold, in bytes: the Rosario's budget for its menu and picker (656 and
    // 536 bytes measured there), now also covering the dove each list keeps.
    const MEMORY_BUDGET = 3072;

    // Memory an open list holds once laid out and drawn: the list of groups (group -1) or a group's prayers.
    function memoryHeld(dc as Dc, group as Number) as Number {
        var before = System.getSystemStats().usedMemory;
        var list = (group < 0 ? new GroupListView() : new PrayerListView(group)) as BarListView;
        list.onLayout(dc);
        list.onUpdate(dc);
        return System.getSystemStats().usedMemory - before;
    }

    // The list's title, wrapped whole in up to 3 lines, fits the visible area beside the lens and ends above
    // the first bar.
    function headerFits(dc as Dc, title as String, list as BarListView, seen as Dictionary<String, Boolean>, logger as Logger) as Boolean {
        var ok = LayoutCheck.wrapsWhole(title, list.titleLines(), 3, logger);
        var header = HeaderLayout.headerPlan(list.titleLines());
        for (var i = 0; i < header.size(); i++) {
            ok = LayoutCheck.mainItemFits(dc, header[i], seen, logger) && ok;
            ok = endsAbove(dc, header[i], MenuLayout.bar(0)[1], logger) && ok;
        }
        return ok && header.size() > 0;
    }

    // Walks the list's selection from its first item to its last. At each step the window shows the selected
    // item, and every item on screen fits (shownFits); the list draws.
    function listFits(dc as Dc, list as BarListView, seen as Dictionary<String, Boolean>, logger as Logger) as Boolean {
        var count = list.labels().size();
        for (var i = 0; i < count; i++) {
            list.moveUp();
        }
        var ok = count > 0 && list.selected == 0 && list.first == 0;
        var trail = "";
        for (var position = 0; position < count; position++) {
            if (position > 0) {
                ok = list.moveDown() && ok;
            }
            trail += " " + list.selected + "/" + list.first;
            ok = list.selected == position && shownFits(dc, list, seen, logger) && ok;
            list.onUpdate(dc);
        }
        ok = !list.moveDown() && ok;
        if (!ok) {
            logger.debug("OUT list " + list.labels() + " selected/first" + trail);
        }
        return ok;
    }

    // The items on screen: each label, in the large font, fits the visible area and lies on its bar; the
    // selected item's bar fits; and the scroll thumb fits, on the track.
    function shownFits(dc as Dc, list as BarListView, seen as Dictionary<String, Boolean>, logger as Logger) as Boolean {
        var labels = list.labels();
        var ok = list.selected >= list.first && list.selected < list.first + MenuLayout.VISIBLE_ITEMS;
        for (var slot = 0; slot < MenuLayout.VISIBLE_ITEMS && list.first + slot < labels.size(); slot++) {
            var index = list.first + slot;
            var item = MenuLayout.label(slot, labels[index]);
            ok = item.font == Graphics.FONT_LARGE && LayoutCheck.mainItemFits(dc, item, seen, logger) && ok;
            ok = onItsBar(dc, item, MenuLayout.bar(slot), logger) && ok;
            if (index == list.selected) {
                var bar = ScreenArea.box(MenuLayout.bar(slot));
                var barFits = ScreenArea.visible(bar);
                if (!barFits) {
                    logger.debug("OUT " + ScreenArea.describeVisible("bar", bar));
                }
                ok = barFits && ok;
            }
        }
        if (labels.size() > MenuLayout.VISIBLE_ITEMS) {
            var thumb = ScreenArea.box(MenuLayout.thumb(list.first, labels.size()));
            var thumbFits = ScreenArea.visible(thumb) && thumb[1] >= MenuLayout.TRACK_TOP && thumb[3] <= MenuLayout.TRACK_BOTTOM
                && thumb[3] - thumb[1] > 0 && thumb[0] > MenuLayout.BAR_RIGHT;
            if (!thumbFits) {
                logger.debug("OUT " + ScreenArea.describeVisible("scroll thumb", thumb));
            }
            ok = thumbFits && ok;
        }
        return ok;
    }

    // The header text ends above the given row, so the bars never run into it.
    function endsAbove(dc as Dc, item as Layout.TextItem, row as Number, logger as Logger) as Boolean {
        var box = ScreenArea.measure(dc, item);
        var ok = box[3] <= row;
        if (!ok) {
            logger.debug("OVERLAP header " + ScreenArea.describe(item.text, box) + " runs into row " + row);
        }
        return ok;
    }

    // The label lies inside its bar, with the gap it keeps on each side logged.
    function onItsBar(dc as Dc, item as Layout.TextItem, bar as Array<Number>, logger as Logger) as Boolean {
        var box = ScreenArea.measure(dc, item);
        var ok = ScreenArea.boxInRect(box, bar[0], bar[1], bar[2], bar[3]);
        logger.debug((ok ? "on bar " : "OFF bar ") + ScreenArea.describe(item.text, box) + " in " + bar + " gaps left "
            + (box[0] - bar[0]).format("%.1f") + " right " + (bar[2] - box[2]).format("%.1f"));
        return ok;
    }
}

(:test)
module LayoutCheck {

    // Checks one item, each distinct text and position once (logged, then remembered): inside the visible
    // area with the margin.
    function mainItemFits(dc as Dc, item as Layout.TextItem, seen as Dictionary<String, Boolean>, logger as Logger) as Boolean {
        var key = item.text + "@" + item.x + "," + item.y + "@" + ScreenArea.fontName(item.font);
        if (seen.hasKey(key)) {
            return seen[key] as Boolean;
        }
        var box = ScreenArea.measure(dc, item);
        var fits = ScreenArea.visible(box);
        seen[key] = fits;
        logger.debug((fits ? "fits " : "OUT ") + ScreenArea.describeVisible(item.text, box));
        return fits;
    }

    // Wrapping kept every word (no "..." cut) in at most maxLines lines.
    function wrapsWhole(text as String, lines as Array<String>, maxLines as Number, logger as Logger) as Boolean {
        var ok = lines.size() > 0 && lines.size() <= maxLines && HeaderLayout.joined(lines).equals(text);
        if (!ok) {
            logger.debug("CUT '" + text + "' -> " + lines);
        }
        return ok;
    }
}
