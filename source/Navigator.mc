import Toybox.Lang;
import Toybox.WatchUi;

// Opens and closes the app's screens for the delegates: the list of groups, a group's prayers, a prayer's
// reading view, each over the one before. The tests hand the delegates a recording navigator instead
// (NavigationTests.mc), so they check what a button opens without pushing views.
class Navigator {

    function initialize() {
    }

    // Opens a screen over the current one; BACK there returns here.
    function open(view as WatchUi.View, delegate as WatchUi.InputDelegate) as Void {
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
    }

    // Closes the current screen, back to the one it was opened from.
    function close() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
