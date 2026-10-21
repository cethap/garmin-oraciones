import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// What every screen draws in the subscreen, the round window inside the lens at the top right: a 1px ring
// and, inside it, a dove (Rez.Drawables.Dove, 32x32, 1-bit), the counterpart of the Rosario's rosary ring.
// The dove is the Holy Spirit's symbol, and the app opens on the prayers to the Holy Spirit.
module Subscreen {
    // The Instinct 2's subscreen (x=113 y=0 62x62), until the device reports its own: the ring is centered
    // on the window, 5px in, as the Rosario's.
    const RING_X = 144;
    const RING_Y = 31;
    const RING_INSET = 5;
    const RING_RADIUS = 31 - RING_INSET;

    // Center and radius [x, y, radius] of the ring: on the subscreen the device reports, or the Instinct 2's
    // when it reports none. The views and the layout tests both use it.
    function ring() as Array<Number> {
        if (WatchUi has :getSubscreen) {
            var subscreen = WatchUi.getSubscreen();
            if (subscreen != null) {
                return [subscreen.x + subscreen.width / 2, subscreen.y + subscreen.height / 2,
                    subscreen.width / 2 - RING_INSET] as Array<Number>;
            }
        }
        return [RING_X, RING_Y, RING_RADIUS] as Array<Number>;
    }

    // Box [left, top, right, bottom] of a width x height dove centered on the ring.
    function doveBox(ring as Array<Number>, width as Number, height as Number) as Array<Number> {
        var left = ring[0] - width / 2;
        var top = ring[1] - height / 2;
        return [left, top, left + width, top + height] as Array<Number>;
    }

    // The dove for a view to keep while it is open.
    function loadDove() as BitmapResource {
        return WatchUi.loadResource(Rez.Drawables.Dove) as BitmapResource;
    }

    // Draws the ring and, when the view has loaded it, the dove in white on the black screen.
    function draw(dc as Dc, dove as BitmapResource?) as Void {
        var ring = ring();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(ring[0], ring[1], ring[2]);
        if (dove != null) {
            var box = doveBox(ring, dove.getWidth(), dove.getHeight());
            dc.drawBitmap(box[0], box[1], dove);
        }
    }
}
