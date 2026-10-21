import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Entry point. Annotated for the glance so the glance process can load it.
(:glance)
class OracionesApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Full-screen widget, opened from the glance with START: the list of groups. BACK there closes the app.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var list = new GroupListView();
        return [list, new GroupListDelegate(list, new Navigator())];
    }

    // Compact view shown in the glance loop.
    function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        return [new OracionesGlanceView()];
    }
}
