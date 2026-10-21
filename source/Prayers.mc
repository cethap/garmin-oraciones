import Toybox.Application;
import Toybox.Lang;

// The prayers the app holds, in four groups, the last one read and the glance's texts. A prayer is known by
// its index, 0..COUNT - 1, the groups' prayers one group after another.
(:glance)
module Prayers {
    // Prayers in all the groups.
    const COUNT = 13;
    // Application.Storage key of the last prayer read, which the reading view saves when it opens and the
    // glance shows.
    const LAST_READ_KEY = "lastPrayer";

    // A prayer's short title: its item in its group's list, the reading view's header and the glance's
    // second line once it is the last prayer read. The titles are in the glance table, so the glance can
    // name any of them.
    function title(prayer as Number) as String {
        var keys = [
            I18n.TitleComeHolySpirit, I18n.TitleVeniCreator, I18n.TitleSequence,
            I18n.TitlePsalm23, I18n.TitlePsalm27, I18n.TitlePsalm51,
            I18n.TitleMagnificat, I18n.TitleAngelus,
            I18n.TitleAnimaChristi, I18n.TitleSaintFrancis, I18n.TitleNadaTeTurbe, I18n.TitleAbandonment, I18n.TitleSaintMichael
        ] as Array<Number>;
        return I18n.glanceText(keys[prayer]);
    }

    // The last prayer read, or null before any has been read.
    function lastRead() as Number? {
        return decodeLastRead(Storage.getValue(LAST_READ_KEY));
    }

    // A stored value as a prayer: null when it is missing or is not one.
    function decodeLastRead(stored) as Number? {
        if (stored instanceof Number && stored >= 0 && stored < COUNT) {
            return stored as Number;
        }
        return null;
    }

    // The glance: "Oraciones" over the last prayer read, or over the number of prayers ("13 oraciones")
    // before any has been read.
    function glanceTitle() as String {
        return I18n.glanceText(I18n.GlanceTitle);
    }

    function glanceSummary() as String {
        return glanceSummaryFor(lastRead());
    }

    // The glance's second line once the given prayer was read last (null: none yet).
    function glanceSummaryFor(last as Number?) as String {
        if (last == null) {
            return Lang.format(I18n.glanceText(I18n.GlanceCount), [COUNT]);
        }
        return title(last);
    }
}

// The groups and the texts, which only the full-screen widget shows, and the saving of the last prayer read.
module Prayers {
    // The groups, in the order the first list shows them.
    enum Group {
        HOLY_SPIRIT,
        PSALMS,
        MARIAN,
        CLASSIC
    }

    const GROUP_COUNT = 4;

    // Index of a group's first prayer; one past the last group's last prayer for GROUP_COUNT.
    function groupStart(group as Number) as Number {
        return [0, 3, 6, 8, COUNT][group];
    }

    function groupSize(group as Number) as Number {
        return groupStart(group + 1) - groupStart(group);
    }

    function groupTitle(group as Number) as String {
        var keys = [I18n.GroupHolySpirit, I18n.GroupPsalms, I18n.GroupMarian, I18n.GroupClassic] as Array<Number>;
        return I18n.text(keys[group]);
    }

    // Every group's title, in order: the first list's items.
    function groupTitles() as Array<String> {
        var titles = [] as Array<String>;
        for (var group = 0; group < GROUP_COUNT; group++) {
            titles.add(groupTitle(group));
        }
        return titles;
    }

    // A prayer's text, which the reading view loads when it opens, its lines separated by "\n". Each text is
    // a table of its own (i18n/<lang>.json, where its note names its source), so opening a prayer loads only
    // that prayer's text.
    function text(prayer as Number) as String {
        var keys = [
            I18n.TextComeHolySpirit, I18n.TextVeniCreator, I18n.TextSequence,
            I18n.TextPsalm23, I18n.TextPsalm27, I18n.TextPsalm51,
            I18n.TextMagnificat, I18n.TextAngelus,
            I18n.TextAnimaChristi, I18n.TextSaintFrancis, I18n.TextNadaTeTurbe, I18n.TextAbandonment, I18n.TextSaintMichael
        ] as Array<Number>;
        return I18n.text(keys[prayer]);
    }

    // The titles of a group's prayers, in order: its list's items.
    function titles(group as Number) as Array<String> {
        var titles = [] as Array<String>;
        for (var prayer = groupStart(group); prayer < groupStart(group + 1); prayer++) {
            titles.add(title(prayer));
        }
        return titles;
    }

    // Saves the prayer as the last one read: the glance names it from its next refresh.
    function saveLastRead(prayer as Number) as Void {
        Storage.setValue(LAST_READ_KEY, prayer);
    }
}
