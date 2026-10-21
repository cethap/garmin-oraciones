import Toybox.Lang;

// The prayers the app holds, in four groups, and the glance's texts. A prayer is known by its index,
// 0..COUNT - 1, the groups' prayers one group after another.
(:glance)
module Prayers {
    // Prayers in all the groups.
    const COUNT = 13;

    // The glance: "Oraciones" over the number of prayers ("13 oraciones").
    function glanceTitle() as String {
        return I18n.glanceText(I18n.GlanceTitle);
    }

    function glanceSummary() as String {
        return Lang.format(I18n.glanceText(I18n.GlanceCount), [COUNT]);
    }
}

// The groups and the titles, which only the full-screen widget shows.
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

    // A prayer's short title: its item in its group's list, and the reading view's header.
    function title(prayer as Number) as String {
        var keys = [
            I18n.TitleComeHolySpirit, I18n.TitleVeniCreator, I18n.TitleSequence,
            I18n.TitlePsalm23, I18n.TitlePsalm27, I18n.TitlePsalm51,
            I18n.TitleMagnificat, I18n.TitleAngelus,
            I18n.TitleAnimaChristi, I18n.TitleSaintFrancis, I18n.TitleNadaTeTurbe, I18n.TitleAbandonment, I18n.TitleSaintMichael
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
}
