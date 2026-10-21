import Toybox.Lang;
import Toybox.WatchUi;

// Buttons of the reading view: DOWN and UP scroll the text a window at a time and do nothing past either
// end; BACK closes the view, back to the group's list on the same prayer. Holding UP does nothing.
class ReadingDelegate extends WatchUi.BehaviorDelegate {

    private var _view as PrayerView;
    private var _navigator as Navigator;

    function initialize(view as PrayerView, navigator as Navigator) {
        BehaviorDelegate.initialize();
        _view = view;
        _navigator = navigator;
    }

    // DOWN
    function onNextPage() as Boolean {
        if (_view.scrollDown()) {
            WatchUi.requestUpdate();
        }
        return true;
    }

    // UP
    function onPreviousPage() as Boolean {
        if (_view.scrollUp()) {
            WatchUi.requestUpdate();
        }
        return true;
    }

    // BACK: back to the group's list.
    function onBack() as Boolean {
        _navigator.close();
        return true;
    }

    // Hold UP: consumed, so it neither scrolls nor opens anything.
    function onMenu() as Boolean {
        return true;
    }
}
