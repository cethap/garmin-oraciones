import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// The language the app reads in, and the lookups that read its texts.
//
// An app can load string resources only in the watch's language, so every text the app shows is a JSON
// table per language instead (i18n/<lang>.json, which scripts/gen-i18n.py turns into resources/i18n and the
// keys in I18nKeys.mc). A lookup loads its table in the current language, takes the one text and lets the
// table go, so no table stays in memory. A text made of parts is a template whose $1$, $2$ Lang.format
// fills in, so each language can order its words. Views look a text up once and keep it, never on every
// frame.
//
// The app reads only Spanish so far. A new language adds its i18n/<lang>.json, its code in
// scripts/gen-i18n.py, and its watches in resolve.
//
// The glance can load only the glance table, the one glance-scoped table: loading any other one there
// crashes it with "Symbol Not Found", and the compiler does not warn. So this part, which the glance loads,
// looks up glance texts only (glanceText), and text, which loads any table, lives outside the glance
// (scripts/check-glance-strings.py checks both).
(:glance)
module I18n {

    // The language every lookup reads in, resolved at the first lookup from the watch's language; null
    // until then.
    var current as Language? = null;

    function language() as Language {
        if (current == null) {
            current = resolve(System.getDeviceSettings().systemLanguage);
        }
        return current as Language;
    }

    // Makes every lookup read the given language (the tests read each language so).
    function setLanguage(language as Language) as Void {
        current = language;
    }

    // The language the app reads in on a watch set to systemLanguage: Spanish, the only one so far, on
    // every watch.
    function resolve(systemLanguage as System.Language) as Language {
        return SPA;
    }

    // A text of the glance table, by its key (I18nKeys.mc), in the current language.
    function glanceText(key as Number) as String {
        var texts = Application.loadResource(glanceTable(language())) as Array<String>;
        return texts[key];
    }
}

// The lookups only the full-screen widget makes.
module I18n {

    // Any text, by its key (I18nKeys.mc), in the current language.
    function text(key as Number) as String {
        var texts = Application.loadResource(tableId(key / TABLE_KEYS, language())) as Array<String>;
        return texts[key % TABLE_KEYS];
    }
}
