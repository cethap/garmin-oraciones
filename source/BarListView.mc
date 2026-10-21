import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Layout of the app's lists, the groups and a group's prayers, shared with the layout tests. The app draws
// its own lists, as the Rosario does, because the system's Menu2 draws its items in a small font that an app
// cannot change. The items use the large font, each centered on its own bar in the full-width rows below the
// subscreen lens (rows 73..135 span the whole screen; below them the bezel narrows the rows). Two bars fill
// those rows, so a list shows two items at a time and scrolls as the selection moves past them, with a
// scroll bar beside the bars. The selected item is drawn inverted, a white bar with black text; any other
// is white text on black. Above the bars sits the header beside the lens (HeaderLayout), and the subscreen
// shows the dove (Subscreen).
module MenuLayout {
    // Items shown at once. A third bar would end at row 187, past the screen's last row (175).
    const VISIBLE_ITEMS = 2;
    // Item bars [BAR_LEFT, top, BAR_RIGHT, top + BAR_HEIGHT], the first from FIRST_BAR_TOP and each next
    // one BAR_PITCH lower. The first starts just below the header (the box of its last line ends at row 74);
    // the second ends where the rounding bezel still leaves it the 2px margin (LayoutTests.mc measures them).
    const BAR_LEFT = 14;
    const BAR_RIGHT = 162;
    const FIRST_BAR_TOP = 77;
    const BAR_HEIGHT = 34;
    const BAR_PITCH = 38;
    const BAR_RADIUS = 4;
    // The scroll bar, right of the bars: a 1px track at TRACK_X from TRACK_TOP to TRACK_BOTTOM, centered on
    // the bars, and on it a THUMB_WIDTH thumb whose length and place show the part of the list on screen. The
    // track ends where the bezel still leaves the thumb the 2px margin, rows below included (row 141). The
    // reading view shows its page on the same track (ReadingLayout.thumb).
    const TRACK_X = 166;
    const TRACK_TOP = 85;
    const TRACK_BOTTOM = 141;
    const THUMB_WIDTH = 3;
    // The lists' background: the views clear the screen with it.
    const BACKGROUND = Graphics.COLOR_BLACK;

    // Screen box [left, top, right, bottom] of the bar in slot 0..VISIBLE_ITEMS - 1.
    function bar(slot as Number) as Array<Number> {
        var top = FIRST_BAR_TOP + slot * BAR_PITCH;
        return [BAR_LEFT, top, BAR_RIGHT, top + BAR_HEIGHT] as Array<Number>;
    }

    // The label shown in a slot, in the large font, centered on its bar. The font box (31px: ascent 24,
    // descent 7) is centered, so the letters sit near the bar's middle.
    function label(slot as Number, text as String) as Layout.TextItem {
        var box = bar(slot);
        return new Layout.TextItem(text, Graphics.FONT_LARGE, (box[0] + box[2]) / 2, (box[1] + box[3]) / 2,
            (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER) as Number);
    }

    // Colours of item index while item selected is selected: [text, bar]. The selected item is inverted,
    // black text on a white bar; any other item is white text straight on the black background, with no
    // bar (Graphics.COLOR_TRANSPARENT).
    function itemColors(index as Number, selected as Number) as Array<Number> {
        if (index == selected) {
            return [Graphics.COLOR_BLACK, Graphics.COLOR_WHITE] as Array<Number>;
        }
        return [Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT] as Array<Number>;
    }

    // The first item shown once item selected is selected, the list having shown items from first: the
    // window moves only as far as it must to show the selected item.
    function windowStart(first as Number, selected as Number) as Number {
        if (selected < first) {
            return selected;
        }
        if (selected >= first + VISIBLE_ITEMS) {
            return selected - VISIBLE_ITEMS + 1;
        }
        return first;
    }

    // Box [left, top, right, bottom] of the scroll bar's thumb for a list of count items shown from first:
    // as long as the track times the share of the items on screen, as far down as the hidden items above.
    function thumb(first as Number, count as Number) as Array<Number> {
        var track = TRACK_BOTTOM - TRACK_TOP;
        var top = TRACK_TOP + track * first / count;
        var bottom = TRACK_TOP + track * (first + VISIBLE_ITEMS) / count;
        var left = TRACK_X - THUMB_WIDTH / 2;
        return [left, top, left + THUMB_WIDTH, bottom] as Array<Number>;
    }

    // Draws the scroll bar: the track and, on it, the thumb at [left, top, right, bottom].
    function drawScrollBar(dc as Dc, thumb as Array<Number>) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(TRACK_X, TRACK_TOP, TRACK_X, TRACK_BOTTOM);
        dc.fillRectangle(thumb[0], thumb[1], thumb[2] - thumb[0], thumb[3] - thumb[1]);
    }
}

// A list in the lists' style (MenuLayout): two items on screen, one of them selected, under the title beside
// the lens, with the dove in the subscreen. moveDown and moveUp stop at either end; the window follows the
// selection.
class BarListView extends WatchUi.View {

    // Index of the selected item, and of the first one shown.
    var selected as Number;
    var first as Number;
    private var _labels as Array<String>;
    private var _titleLines as Array<String>;
    private var _dove as BitmapResource?;

    function initialize(title as String, labels as Array<String>, selected as Number) {
        View.initialize();
        _labels = labels;
        _titleLines = HeaderLayout.wrapTitle(title);
        self.selected = selected;
        first = MenuLayout.windowStart(0, selected);
    }

    // The dove, loaded once when the list first opens and let go with the list.
    function onLayout(dc as Dc) as Void {
        if (_dove == null) {
            _dove = Subscreen.loadDove();
        }
    }

    function labels() as Array<String> {
        return _labels;
    }

    function titleLines() as Array<String> {
        return _titleLines;
    }

    // One item down; false (and nothing changes) on the last one.
    function moveDown() as Boolean {
        return selectItem(selected + 1);
    }

    // One item up; false (and nothing changes) on the first one.
    function moveUp() as Boolean {
        return selectItem(selected - 1);
    }

    private function selectItem(index as Number) as Boolean {
        if (index < 0 || index >= _labels.size() || index == selected) {
            return false;
        }
        selected = index;
        first = MenuLayout.windowStart(first, selected);
        return true;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, MenuLayout.BACKGROUND);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var header = HeaderLayout.headerPlan(_titleLines);
        for (var i = 0; i < header.size(); i++) {
            header[i].draw(dc);
        }
        Subscreen.draw(dc, _dove);
        for (var slot = 0; slot < MenuLayout.VISIBLE_ITEMS && first + slot < _labels.size(); slot++) {
            var index = first + slot;
            var colors = MenuLayout.itemColors(index, selected);
            if (colors[1] != Graphics.COLOR_TRANSPARENT) {
                var bar = MenuLayout.bar(slot);
                dc.setColor(colors[1], Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(bar[0], bar[1], bar[2] - bar[0], bar[3] - bar[1], MenuLayout.BAR_RADIUS);
            }
            dc.setColor(colors[0], Graphics.COLOR_TRANSPARENT);
            MenuLayout.label(slot, _labels[index]).draw(dc);
        }
        if (_labels.size() > MenuLayout.VISIBLE_ITEMS) {
            MenuLayout.drawScrollBar(dc, MenuLayout.thumb(first, _labels.size()));
        }
    }
}
