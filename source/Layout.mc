import Toybox.Graphics;
import Toybox.Lang;

// Text layout shared by the views and the layout tests: each view asks for a plan (the text items it
// draws) and draws it, so the tests can measure the very same items against the visible area.
(:glance)
module Layout {

    // Instinct 2 screen: 176x176.
    const SCREEN_SIZE = 176;
    // Height of the glance content area (164x62; on the watch the selected glance sits at screen 9,74).
    const GLANCE_HEIGHT = 62;
    // Glance text: two lines in the medium font sharing a left indent, read as one block vertically
    // centered in the slot, the second line's box starting where the first one's ends. The medium font is
    // the system font closest to the other apps' glances on the watch; the tiny font looked much smaller.
    const GLANCE_LEFT = 9;

    // One piece of text a view draws, with the arguments Dc.drawText takes.
    class TextItem {
        var text as String;
        var font as Graphics.FontType;
        var x as Number;
        var y as Number;
        var justify as Number;

        function initialize(text as String, font as Graphics.FontType, x as Number, y as Number, justify as Number) {
            self.text = text;
            self.font = font;
            self.x = x;
            self.y = y;
            self.justify = justify;
        }

        function draw(dc as Dc) as Void {
            dc.drawText(x, y, font, text, justify);
        }
    }

    // Glance: the title over the summary, one block vertically centered in a slot of the given height.
    function glancePlan(title as String, summary as String, height as Number) as Array<TextItem> {
        var font = Graphics.FONT_MEDIUM;
        var justify = Graphics.TEXT_JUSTIFY_LEFT as Number;
        var line = Graphics.getFontHeight(font);
        var top = (height - 2 * line) / 2;
        return [
            new TextItem(title, font, GLANCE_LEFT, top, justify),
            new TextItem(summary, font, GLANCE_LEFT, top + line, justify)
        ] as Array<TextItem>;
    }

    // Box [left, top, right, bottom] that text of the given measured size covers when drawn as the
    // item says. Centered text may fall on half pixels, so the box is in Floats.
    function textBox(item as TextItem, width as Number, height as Number) as Array<Float> {
        var left = item.x.toFloat();
        var horizontal = item.justify & 3;
        if (horizontal == Graphics.TEXT_JUSTIFY_CENTER) {
            left -= width / 2.0;
        } else if (horizontal == Graphics.TEXT_JUSTIFY_RIGHT) {
            left -= width;
        }
        var top = item.y.toFloat();
        if ((item.justify & Graphics.TEXT_JUSTIFY_VCENTER) != 0) {
            top -= height / 2.0;
        }
        return [left, top, left + width, top + height] as Array<Float>;
    }
}
