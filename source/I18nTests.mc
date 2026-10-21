import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Tests of the language the app reads in (I18n.mc), of its tables and of the texts the app shows. A test
// that reads a text sets the language first with TestLanguage.use, and the tests that do not pin a
// language's own words run once in each language (only Spanish so far).

(:test)
module TestLanguage {

    // The languages' codes, in I18n.Language order, for the logs.
    function code(language as Number) as String {
        return ["spa"][language];
    }

    // Makes every lookup read in the language, and names it in the test's log.
    function use(logger as Logger, language as Number) as Void {
        I18n.setLanguage(language as I18n.Language);
        logger.debug("language=" + code(language));
    }
}

(:test)
module TableCheck {

    // Most memory one loaded table may hold, in bytes. A lookup loads its whole table, so this bounds what a
    // lookup adds to the widget's peak. The Rosario's tables measured 784 to 1200 under the same budget.
    const BUDGET = 1536;
    // The glance's table, which the glance loads inside its 32KB.
    const GLANCE_BUDGET = 512;
    // A prayer's text, each a table of its own, which the reading view loads when it opens.
    const TEXT_BUDGET = 2560;

    // The budget of a table.
    function budget(table as Number) as Number {
        if (table == 0) {
            return GLANCE_BUDGET;
        }
        return table >= I18n.TextComeHolySpirit / I18n.TABLE_KEYS ? TEXT_BUDGET : BUDGET;
    }

    // Memory a table holds once loaded, and whether it is whole: texts, none empty. Returns [bytes held,
    // texts in the table, whole].
    function load(table as Number, language as Number) as Array {
        var before = System.getSystemStats().usedMemory;
        var texts = Application.loadResource(I18n.tableId(table, language as I18n.Language)) as Array;
        var held = System.getSystemStats().usedMemory - before;
        var whole = texts.size() > 0;
        for (var i = 0; whole && i < texts.size(); i++) {
            whole = texts[i] instanceof String && (texts[i] as String).length() > 0;
        }
        return [held, texts.size(), whole];
    }
}

// Names the suite in its log, so scripts/test-all.sh can tell this build's output from another app's.
(:test)
function suiteNamesItsLanguages(logger as Logger) as Boolean {
    logger.debug("suite=oraciones languages=" + I18n.LANGUAGE_COUNT);
    return I18n.LANGUAGE_COUNT == 1 && TestLanguage.code(0).equals("spa") && I18n.SPA == 0;
}

// Every watch reads Spanish, the only language so far, whatever its own language.
(:test)
function everyWatchReadsSpanish(logger as Logger) as Boolean {
    var watches = [System.LANGUAGE_ENG, System.LANGUAGE_SPA, System.LANGUAGE_FRE, System.LANGUAGE_DEU,
        System.LANGUAGE_POR] as Array<System.Language>;
    var read = [];
    var ok = true;
    for (var w = 0; w < watches.size(); w++) {
        var language = I18n.resolve(watches[w]);
        read.add(language);
        ok = ok && language == I18n.SPA;
    }
    logger.debug("watches eng,spa,fre,deu,por read " + read);
    return ok;
}

// Every table of every language is whole (texts, none empty) and small: loading one, as each lookup does,
// holds at most TableCheck.BUDGET, and the glance's table at most GLANCE_BUDGET.
(:test)
function everyTableIsWholeAndSmall(logger as Logger) as Boolean {
    // Warm-up: the first table a run loads also pays a one-time cost, so it is loaded once before the
    // measurements.
    TableCheck.load(0, I18n.SPA);
    var ok = true;
    for (var table = 0; table < I18n.TABLE_COUNT; table++) {
        var budget = TableCheck.budget(table);
        var sizes = [] as Array<Number>;
        var held = [] as Array<Number>;
        for (var language = 0; language < I18n.LANGUAGE_COUNT; language++) {
            var loaded = TableCheck.load(table, language);
            held.add(loaded[0] as Number);
            sizes.add(loaded[1] as Number);
            ok = ok && (loaded[2] as Boolean) && loaded[1] == sizes[0] && loaded[0] > 0 && (loaded[0] as Number) <= budget;
        }
        logger.debug("table " + table + ": " + sizes[0] + " texts; bytes held " + held + " (budget " + budget + ")");
    }
    return ok;
}

// The glance reads "Oraciones" over the number of prayers, "13 oraciones".
(:test)
function glanceNamesTheAppAndCountsThePrayers(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var title = Prayers.glanceTitle();
    var summary = Prayers.glanceSummary();
    logger.debug("glance '" + title + "' / '" + summary + "'");
    return Prayers.COUNT == 13 && title.equals("Oraciones") && summary.equals("13 oraciones");
}

// The four groups, in order, and each group's prayers by their short titles: 13 prayers in all, each in one
// group, the groups one after another.
(:test)
function groupsHoldTheirPrayersInOrder(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var groups = ["Espíritu Santo", "Salmos", "Marianas", "Clásicas"];
    var titles = [
        ["Ven, Espíritu", "Veni Creator", "Secuencia"],
        ["Salmo 23", "Salmo 27", "Salmo 51"],
        ["Magníficat", "Ángelus"],
        ["Alma de Cristo", "San Francisco", "Nada te turbe", "Abandono", "San Miguel"]
    ];
    var ok = Prayers.GROUP_COUNT == 4 && Prayers.groupTitles().toString().equals(groups.toString());
    var next = 0;
    for (var group = 0; group < Prayers.GROUP_COUNT; group++) {
        var listed = Prayers.titles(group);
        logger.debug("group " + group + " '" + Prayers.groupTitle(group) + "' from " + Prayers.groupStart(group) + ": " + listed);
        ok = ok && Prayers.groupTitle(group).equals(groups[group]) && Prayers.groupStart(group) == next
            && Prayers.groupSize(group) == titles[group].size() && listed.toString().equals(titles[group].toString());
        for (var i = 0; i < listed.size(); i++) {
            ok = ok && Prayers.title(next + i).equals(listed[i]);
        }
        next += listed.size();
    }
    return ok && next == Prayers.COUNT;
}
