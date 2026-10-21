import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Glance loop entry (164x62 on the Instinct 2): "Oraciones" over the number of prayers, as one block in the
// medium font. Layout.glancePlan places them.
(:glance)
class OracionesGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var items = Layout.glancePlan(Prayers.glanceTitle(), Prayers.glanceSummary(), dc.getHeight());
        for (var i = 0; i < items.size(); i++) {
            items[i].draw(dc);
        }
    }
}
