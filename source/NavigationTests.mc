import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// Tests of the buttons on the lists and the reading view. A recording navigator (NavigationFake.Recorder)
// stands in for the real one, so opening and closing a screen is recorded instead of pushing and popping a
// view; the views and delegates are real.

(:test)
module NavigationFake {

    // A navigator that records what the delegates ask of it instead of pushing and popping views.
    class Recorder extends Navigator {
        var calls as Array<String>;
        var views as Array<WatchUi.View>;
        var delegates as Array<WatchUi.InputDelegate>;

        function initialize() {
            Navigator.initialize();
            calls = [] as Array<String>;
            views = [] as Array<WatchUi.View>;
            delegates = [] as Array<WatchUi.InputDelegate>;
        }

        function open(view as WatchUi.View, delegate as WatchUi.InputDelegate) as Void {
            calls.add("open");
            views.add(view);
            delegates.add(delegate);
        }

        function close() as Void {
            calls.add("close");
        }
    }

    // Presses UP 5 times, then DOWN and UP past either end of a list of count items, then holds UP: the
    // selection and first item shown after each press ("selected/first"), and whether every press was
    // handled.
    function walk(list as BarListView, delegate as WatchUi.BehaviorDelegate, count as Number) as Array {
        var trail = [] as Array<String>;
        var handled = true;
        for (var i = 0; i < 5; i++) {
            handled = delegate.onPreviousPage() && handled;
        }
        trail.add(list.selected + "/" + list.first);
        for (var i = 0; i < count; i++) {
            handled = delegate.onNextPage() && handled;
            trail.add(list.selected + "/" + list.first);
        }
        handled = delegate.onMenu() && handled;
        for (var i = 0; i < count; i++) {
            handled = delegate.onPreviousPage() && handled;
            trail.add(list.selected + "/" + list.first);
        }
        return [trail, handled];
    }

    // The trail walk gives on a list of count items: down to the last one and one press more (it stays),
    // then back up to the first and one more, the two-item window following the selection.
    function expectedTrail(count as Number) as Array<String> {
        var trail = ["0/0"] as Array<String>;
        var first = 0;
        for (var i = 1; i <= count; i++) {
            var selected = i < count ? i : count - 1;
            first = MenuLayout.windowStart(first, selected);
            trail.add(selected + "/" + first);
        }
        for (var i = 1; i <= count; i++) {
            var selected = count - 1 - i >= 0 ? count - 1 - i : 0;
            first = MenuLayout.windowStart(first, selected);
            trail.add(selected + "/" + first);
        }
        return trail;
    }
}

// On the list of groups DOWN and UP move the selection and stop at either end (no wrap-around), the
// two-item window following it, and hold UP does nothing; none of them opens or closes anything. The list
// opens on the first group.
(:test)
function groupListStopsAtBothEnds(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var navigator = new NavigationFake.Recorder();
    var list = new GroupListView();
    var delegate = new GroupListDelegate(list, navigator);
    var start = list.selected;
    var walked = NavigationFake.walk(list, delegate, Prayers.GROUP_COUNT);
    var expected = NavigationFake.expectedTrail(Prayers.GROUP_COUNT);
    logger.debug("opened on " + start + " trail=" + walked[0] + " expected=" + expected + " handled=" + walked[1]
        + " calls=" + navigator.calls);
    return start == 0 && (walked[1] as Boolean) && walked[0].toString().equals(expected.toString())
        && expected.toString().equals(["0/0", "1/0", "2/1", "3/2", "3/2", "2/2", "1/1", "0/0", "0/0"].toString())
        && navigator.calls.size() == 0;
}

// START on a group opens that group's list of prayers, on its first prayer, with the group's title beside
// the lens; BACK on the list of groups is left to the system, which closes the app (onBack returns false and
// nothing is opened or closed).
(:test)
function groupListOpensTheGroupAndBackLeaves(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var ok = true;
    for (var group = 0; group < Prayers.GROUP_COUNT; group++) {
        var navigator = new NavigationFake.Recorder();
        var list = new GroupListView();
        var delegate = new GroupListDelegate(list, navigator);
        for (var i = 0; i < group; i++) {
            delegate.onNextPage();
        }
        var handled = delegate.onSelect();
        var opened = navigator.views.size() == 1 ? navigator.views[0] : null;
        var prayers = opened instanceof PrayerListView ? opened as PrayerListView : null;
        var labels = prayers != null ? prayers.labels() : [];
        var title = prayers != null ? prayers.titleLines() : [];
        var openedOk = prayers != null && prayers.group() == group && prayers.selected == 0
            && labels.toString().equals(Prayers.titles(group).toString())
            && title.toString().equals(HeaderLayout.wrapTitle(Prayers.groupTitle(group)).toString())
            && navigator.delegates[0] instanceof PrayerListDelegate;
        var back = delegate.onBack();
        logger.debug("group " + group + ": START handled=" + handled + " calls=" + navigator.calls + " labels=" + labels
            + " title=" + title + " BACK handled=" + back);
        ok = ok && handled && openedOk && !back && navigator.calls.toString().equals(["open"].toString())
            && list.selected == group;
    }
    return ok;
}

// On a group's list of prayers DOWN and UP stop at either end, as on the list of groups, and hold UP does
// nothing; BACK closes the list, which leaves the list of groups on the group it opened.
(:test)
function prayerListStopsAtBothEndsAndBackCloses(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var ok = true;
    for (var group = 0; group < Prayers.GROUP_COUNT; group++) {
        var navigator = new NavigationFake.Recorder();
        var list = new PrayerListView(group);
        var delegate = new PrayerListDelegate(list, navigator);
        var count = Prayers.groupSize(group);
        var walked = NavigationFake.walk(list, delegate, count);
        var expected = NavigationFake.expectedTrail(count);
        var quiet = navigator.calls.size() == 0;
        var back = delegate.onBack();
        logger.debug("group " + group + ": trail=" + walked[0] + " expected=" + expected + " handled=" + walked[1]
            + " quiet=" + quiet + " BACK handled=" + back + " calls=" + navigator.calls);
        ok = ok && count > 0 && (walked[1] as Boolean) && walked[0].toString().equals(expected.toString()) && quiet && back
            && navigator.calls.toString().equals(["close"].toString());
    }
    return ok;
}
