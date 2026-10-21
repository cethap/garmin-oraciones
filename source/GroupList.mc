import Toybox.Lang;
import Toybox.WatchUi;

// The app's first screen: "Oraciones" beside the lens over the four groups, the first one selected
// (GroupListDelegate: UP/DOWN move the selection, START opens the group, BACK closes the app).
class GroupListView extends BarListView {

    function initialize() {
        BarListView.initialize(I18n.text(I18n.GroupsTitle), Prayers.groupTitles(), 0);
    }

    function selectedGroup() as Number {
        return selected;
    }
}

// Buttons of the list of groups: DOWN and UP move the selection and stop at either end. START opens the
// selected group's prayers over this list, so BACK there returns here, on the same group. BACK here is left
// to the system, which closes the app. Holding UP does nothing.
class GroupListDelegate extends WatchUi.BehaviorDelegate {

    private var _list as GroupListView;
    private var _navigator as Navigator;

    function initialize(list as GroupListView, navigator as Navigator) {
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

    // START: the group's list of prayers.
    function onSelect() as Boolean {
        var prayers = new PrayerListView(_list.selectedGroup());
        _navigator.open(prayers, new PrayerListDelegate(prayers, _navigator));
        return true;
    }

    // BACK: not handled, so the system closes the app.
    function onBack() as Boolean {
        return false;
    }

    // Hold UP: consumed, so it does nothing.
    function onMenu() as Boolean {
        return true;
    }
}
