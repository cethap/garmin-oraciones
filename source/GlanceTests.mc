import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Tests of the glance's second line, the last prayer read, which the reading view saves when it opens. Each
// test uses the real Storage and puts back what was there.

(:test)
module GlanceCheck {

    // Every prayer the glance may name last, null first: no prayer read yet.
    function lasts() as Array<Number?> {
        var lasts = [null] as Array<Number?>;
        for (var prayer = 0; prayer < Prayers.COUNT; prayer++) {
            lasts.add(prayer);
        }
        return lasts;
    }

    // Puts back the saved value that was there before a test.
    function restore(before) as Void {
        if (before == null) {
            Application.Storage.deleteValue(Prayers.LAST_READ_KEY);
        } else {
            Application.Storage.setValue(Prayers.LAST_READ_KEY, before as Application.PropertyValueType);
        }
    }
}

// Before any prayer has been read, the glance reads "Oraciones" over "13 oraciones", the first run included
// (nothing saved). Once a prayer's reading view opens, the glance reads "Oraciones" over that prayer's short
// title, for each prayer in turn, the latest one winning; a saved value that is not a prayer reads as none.
(:test)
function glanceShowsTheLastPrayerRead(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var before = Application.Storage.getValue(Prayers.LAST_READ_KEY);
    var dc = ScreenArea.measuringDc();
    var ok = false;
    try {
        Application.Storage.deleteValue(Prayers.LAST_READ_KEY);
        var firstRun = Prayers.glanceTitle() + " / " + Prayers.glanceSummary();
        ok = firstRun.equals("Oraciones / 13 oraciones") && Prayers.lastRead() == null;
        var shown = [] as Array<String>;
        // Every prayer, then the first one again: the latest read wins.
        for (var i = 0; i <= Prayers.COUNT; i++) {
            var prayer = i % Prayers.COUNT;
            var view = new PrayerView(prayer);
            view.onLayout(dc);
            view.onShow();
            var summary = Prayers.glanceSummary();
            shown.add(summary);
            ok = ok && Prayers.lastRead() == prayer && Prayers.glanceTitle().equals("Oraciones")
                && summary.equals(Prayers.title(prayer));
        }
        var stored = [-1, Prayers.COUNT, "3", 2.0, [1], true] as Array<Application.PropertyValueType>;
        var invalid = "";
        for (var i = 0; i < stored.size(); i++) {
            Application.Storage.setValue(Prayers.LAST_READ_KEY, stored[i]);
            var summary = Prayers.glanceSummary();
            invalid += " " + stored[i] + "->" + summary;
            ok = ok && Prayers.lastRead() == null && summary.equals("13 oraciones");
        }
        logger.debug("first run '" + firstRun + "'; after each prayer " + shown + "; invalid:" + invalid);
    } finally {
        GlanceCheck.restore(before);
    }
    return ok;
}

// The glance's second line for each possible last prayer: the count before any, else the prayer's short
// title, the same one its group's list shows.
(:test)
function glanceSummaryNamesThePrayer(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var lasts = GlanceCheck.lasts();
    var summaries = [] as Array<String>;
    var ok = true;
    for (var i = 0; i < lasts.size(); i++) {
        var summary = Prayers.glanceSummaryFor(lasts[i]);
        summaries.add(summary);
        ok = ok && summary.equals(lasts[i] == null ? "13 oraciones" : Prayers.title(lasts[i] as Number));
    }
    logger.debug("summaries " + summaries);
    return ok;
}
