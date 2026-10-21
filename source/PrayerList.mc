import Toybox.Lang;
import Toybox.WatchUi;

// A group's prayers: the group's title beside the lens over its prayers' short titles, the first one
// selected (PrayerListDelegate: UP/DOWN move the selection, BACK returns to the list of groups).
class PrayerListView extends BarListView {

    private var _group as Number;

    function initialize(group as Number) {
        BarListView.initialize(Prayers.groupTitle(group), Prayers.titles(group), 0);
        _group = group;
    }

    function group() as Number {
        return _group;
    }

    // The selected prayer's index among all the prayers.
    function selectedPrayer() as Number {
        return Prayers.groupStart(_group) + selected;
    }
}

// Buttons of a group's list of prayers: DOWN and UP move the selection and stop at either end. BACK closes
// the list, back to the list of groups on the same group. Holding UP does nothing.
class PrayerListDelegate extends WatchUi.BehaviorDelegate {

    private var _list as PrayerListView;
    private var _navigator as Navigator;

    function initialize(list as PrayerListView, navigator as Navigator) {
        BehaviorDelegate.initialize();
        _list = list;
        _navigator = navigator;
    }

    // DOWN
    function onNextPage() as Boolean {
        if (_list.moveDown()) {
            WatchUi.requestUpdate();
        }
        return true;
    }

    // UP
    function onPreviousPage() as Boolean {
        if (_list.moveUp()) {
            WatchUi.requestUpdate();
        }
        return true;
    }

    // BACK: back to the list of groups.
    function onBack() as Boolean {
        _navigator.close();
        return true;
    }

    // Hold UP: consumed, so it does nothing.
    function onMenu() as Boolean {
        return true;
    }
}
