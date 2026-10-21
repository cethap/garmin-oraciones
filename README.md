# Oraciones for Garmin Instinct 2

Oraciones is a Connect IQ widget that holds 18 well-known Catholic prayers to read on the Garmin Instinct 2: the basic prayers in Spanish, Latin and English, prayers to the Holy Spirit, psalms, Marian prayers and classic prayers. Each text comes word for word from a named source, with the few changes listed in [Text sources](#text-sources). The widget shares the look of the Rosario widget: large-type lists, a reading window that never runs under the subscreen lens, and a dove in the subscreen. It reads in Spanish.

[Resumen en español](#resumen-en-español)

## Quick start

1. Set `DEVELOPER_KEY` to your developer key's path and build the app (see [Build](#build)): `monkeyc -f monkey.jungle -d instinct2 -o bin/Oraciones.prg -y "$DEVELOPER_KEY" -r -w`.
2. Copy `bin/Oraciones.prg` to the `GARMIN/APPS/` folder on the watch (see [Sideload to the watch](#sideload-to-the-watch)).
3. On the watch face, press DOWN until the Oraciones glance shows, then press START to open it.

## Features

- **Groups**: the app opens on its five groups, "Básicas", "Espíritu Santo", "Salmos", "Marianas" and "Clásicas".
  - The lists use the large font, two items at a time, with a thin scroll bar on the right.
  - The selected item is a white bar with black text.
  - The title of what the screen lists ("Oraciones", or the group's name) sits beside the subscreen.
- **Reading view**:
  - The prayer's short title stays beside the subscreen, and its text scrolls four lines at a time in a window below it.
  - The text is set as verse: each printed line of the source starts a new line at the left edge. A line too long for the window wraps at a space onto indented continuation lines, so the start of each verse shows.
  - A thumb on the right shows which part of the text is on screen.
- **Subscreen**: a dove inside a thin ring, the counterpart of the Rosario's Hail Mary ring.
- **Glance**: "Oraciones" over the last prayer read ("Salmo 27"), or over "18 oraciones" before any prayer has been read.
- **Memory**: the app loads one prayer's text when its reading view opens, and lets it go when the view closes.

## The prayers

| Group | Prayer (short title) | Text | Pages |
|-------|----------------------|------|-------|
| Básicas | Padre Nuestro | Padre nuestro | 7 |
| Básicas | Pater Noster | The Our Father in Latin | 6 |
| Básicas | Our Father | The Our Father in English | 6 |
| Básicas | Ave María | Dios te salve, María | 5 |
| Básicas | Ave Maria | The Hail Mary in Latin | 4 |
| Básicas | Hail Mary | The Hail Mary in English | 5 |
| Espíritu Santo | Ven, Espíritu | Ven, Espíritu Santo | 8 |
| Espíritu Santo | Secuencia | Secuencia de Pentecostés | 16 |
| Salmos | Salmo 23 | El Señor es mi pastor | 11 |
| Salmos | Salmo 27 | El Señor es mi luz | 29 |
| Salmos | Salmo 51 | Miserere | 28 |
| Marianas | Magníficat | Lc 1, 46-55 | 14 |
| Marianas | Ángelus | Ángelus | 13 |
| Clásicas | Alma de Cristo | Alma de Cristo | 8 |
| Clásicas | San Francisco | Oración de San Francisco | 12 |
| Clásicas | Nada te turbe | Santa Teresa de Jesús | 3 |
| Clásicas | Abandono | Oración de abandono, Charles de Foucauld | 8 |
| Clásicas | San Miguel | San Miguel Arcángel | 7 |

A page is one screen of four lines. Where each text comes from is in [Text sources](#text-sources).

## Controls

The buttons are named as Connect IQ names them, with their place on the watch.

On the list of groups and on a group's list of prayers:

| Button | Action |
|--------|--------|
| DOWN (lower left) | Select the item below (does nothing on the last one) |
| UP (middle left) | Select the item above (does nothing on the first one) |
| START (upper right) | Open the selected group, or read the selected prayer |
| BACK (lower right) | On a group's list: back to the groups, on the same group. On the groups: close the app |

In the reading view:

| Button | Action |
|--------|--------|
| DOWN | Scroll down one screen (does nothing on the last one) |
| UP | Scroll up one screen (does nothing on the first one) |
| BACK | Back to the group's list, on the same prayer |

Holding UP does nothing anywhere in the app.

## Device support

- Garmin Instinct 2, Connect IQ product `instinct2`.
- The app needs Connect IQ API level 3.4.0 (`minApiLevel` in `manifest.xml`).
- The app declares no permissions. It needs no phone, no internet connection and no sensors.

## Development

### Requirements

| Need | Notes |
|------|-------|
| Connect IQ SDK | API level 3.4.0 or later, with the Instinct 2 device installed from the SDK Manager |
| Java 17 or later | On the `PATH`; the SDK tools need it |
| A developer key | An RSA 4096 key in DER format. Any key works for builds and tests |
| `perl` and `python3` | For `scripts/test-all.sh` |
| `pdftotext` | Only for `scripts/check-texts.py`, which reads two of the sources as PDF |

The commands below read the key's path from the `DEVELOPER_KEY` environment variable:

```sh
export DEVELOPER_KEY=/path/to/developer_key.der
```

### Build

```sh
monkeyc -f monkey.jungle -d instinct2 -o bin/Oraciones.prg -y "$DEVELOPER_KEY" -r -w
```

`-r` strips the debug information and `-w` shows compiler warnings. The build should report none.

### Unit tests

```sh
connectiq &
DEVELOPER_KEY=/path/to/developer_key.der scripts/test-all.sh
```

The script prints one line per step. It stops at the first step that fails, and exits with 0 only when every step passes:

| Step | Passes when |
|------|-------------|
| `python3 -I scripts/check-texts.py "$TEXT_SOURCES"`, only when `TEXT_SOURCES` is set | Every prayer's text is word for word in its source (see [Check the texts](#check-the-texts)) |
| `python3 scripts/gen-i18n.py --check` | Every text is there, and the generated files are up to date (see [Texts and languages](#texts-and-languages)) |
| `python3 scripts/check-glance-strings.py` | The glance uses only the texts and the code it can load |
| The tests, built with `-t -w` and run in the simulator | The build has no warnings, and the simulator reports `PASSED` (otherwise the line gives the log's path) |

| Variable | Meaning | Default |
|----------|---------|---------|
| `DEVELOPER_KEY` | Key that signs the test build (required) | None |
| `CIQ_SDK` | SDK folder | The SDK chosen in the SDK Manager |
| `TEST_OUT` | Folder for the build and its logs | `bin/test` |
| `TEST_TIMEOUT` | Seconds before a run counts as hung | `300` |
| `TEXT_SOURCES` | Folder of the prayers' downloaded source pages | None: the text check is skipped |

What the tests cover:

- **Layout**: every text the app draws is measured with the real fonts against the visible area of the Instinct 2 (`source/VisibleArea.mc`). That covers every list at every selection, every header, the glance's lines and every prayer at every scroll position, so no text runs under the subscreen lens.
- **Glyphs**: every character has a glyph in the font that draws it.
- **Buttons**: the lists' and the reading view's buttons, at both ends, with BACK at each level.
- **Glance**: the last prayer read, including the first run, when nothing is saved yet.
- **Pins**: each text's opening, close and length, and each prayer's page count.
- **Memory**: the budgets of the lists, the reading view and the text tables.

Tests are left out of regular builds.

The glance can load only the resources marked `scope="glance"` and the code annotated `(:glance)`. Anything else crashes it on the watch, yet neither the compiler nor the tests notice. `scripts/check-glance-strings.py` catches it.

### Texts and languages

Every text lives in `i18n/spa.json`, keyed by table and id. Keys that start with `//` are notes. Each prayer's text is a table of its own, so opening a prayer loads only that text. The first table, `glance`, holds the glance's texts and the short titles, which the glance names.

1. Change the texts in `i18n/spa.json`.
2. Run `python3 scripts/gen-i18n.py`. It writes `resources/i18n/spa.xml` and `source/I18nKeys.mc`; don't edit those by hand.
3. Run `scripts/test-all.sh`.

The app reads only Spanish so far. Adding a language takes three changes and no refactor:

1. Add its `i18n/<lang>.json`.
2. Add its code to `LANGUAGES` in `scripts/gen-i18n.py`.
3. Add its watches to `I18n.resolve` in `source/I18n.mc`.

### Check the texts

`scripts/check-texts.py` compares every prayer's text, word for word, with its source page. It ignores line breaks and verse numbers.

The script lists each text's pages in `SOURCES`, together with the two corrections made to the Magníficat's source (see [Text sources](#text-sources)). The downloaded pages are not in the repository:

1. Make a folder for the pages.
2. Download each URL of `SOURCES` into it, under the file name `python3 -I scripts/check-texts.py --name <url>` prints.
3. Run `python3 -I scripts/check-texts.py <folder>`. It prints `ALL VERBATIM: 18 texts` when every text matches.

### Run in the simulator

```sh
connectiq &
monkeydo bin/Oraciones.prg instinct2
```

The simulator shows the glance first. Press START in the simulator to open the full screen.

### Sideload to the watch

1. Build `bin/Oraciones.prg` as shown in [Build](#build).
2. Connect the watch to the computer with its USB cable.
3. Copy `Oraciones.prg` into the `GARMIN/APPS/` folder on the watch.
4. Unplug the watch. Oraciones appears in the glance loop.

## Project layout

App code:

| Path | Purpose |
|------|---------|
| `source/OracionesApp.mc` | App entry point: the list of groups, and the glance; annotated for the glance |
| `source/OracionesGlanceView.mc` | Glance |
| `source/Prayers.mc` | The prayers, their groups, titles and texts, the last one read, and the glance's texts |
| `source/I18n.mc` | The language the app reads in and the text lookups |
| `source/I18nKeys.mc` | Generated by `scripts/gen-i18n.py`: the languages, every text's key and every table |
| `source/Layout.mc` | Text items and the glance's layout, shared with the tests |
| `source/HeaderLayout.mc` | The title beside the lens, wrapped in up to 3 lines |
| `source/Subscreen.mc` | The ring and the dove in the subscreen |
| `source/BarListView.mc` | Layout of the lists and the list view both lists share |
| `source/GroupList.mc` | The list of groups and its buttons |
| `source/PrayerList.mc` | A group's list of prayers and its buttons |
| `source/ReadingView.mc` | The reading view and its layout: verse lines, the hanging indent and the page indicator |
| `source/ReadingDelegate.mc` | Buttons of the reading view: scroll and back |
| `source/Navigator.mc` | Opens and closes the screens, so the tests can record it instead |

Tests:

| Path | Purpose |
|------|---------|
| `source/LayoutTests.mc` | Layout tests for the glance, the subscreen and the lists, and the shared checks |
| `source/ReadingTests.mc` | Reading view: fit at every offset, wrap, indent, scroll, memory, and the placeholder texts |
| `source/NavigationTests.mc` | Buttons of the lists, with a recording navigator |
| `source/GlanceTests.mc` | The glance's last prayer read |
| `source/TextTests.mc` | Pins of each text and of each prayer's page count |
| `source/I18nTests.mc` | The language, its tables and their budgets, and the groups and titles |
| `source/VisibleArea.mc` | Test-only visible area of the Instinct 2, per screen row |

Texts, resources and scripts:

| Path | Purpose |
|------|---------|
| `i18n/spa.json` | Every text: the glance, the groups, the short titles and the 18 prayers, each with its source in a note |
| `resources/i18n/` | Generated: the tables as JSON data, the glance's marked `scope="glance"` |
| `resources/strings/strings.xml` | The app's name |
| `resources/drawables/` | The launcher icon and the subscreen dove, the same dove drawn at 62 and 32 px |
| `scripts/gen-i18n.py` | Generates the tables and their keys from `i18n/`, and checks them (`--check`) |
| `scripts/check-glance-strings.py` | Checks that the glance loads only glance-scoped texts and glance code |
| `scripts/check-texts.py` | Checks every prayer's text against its downloaded source |
| `scripts/test-all.sh` | Runs the checks, then builds and runs the tests |
| `manifest.xml` | App id, type (widget), device, minimum API level, language, permissions (none) |
| `monkey.jungle` | Build file of the app and of its test build (`-t`) |
| `odd/tasks/oraciones-app.md` | The feature's record: tasks, decisions and evidence |
| `LICENSE` | MIT license for the code |
| `NOTICE` | Sources and terms of the prayer texts, which the MIT license does not cover |

## Text sources

Every text is copied word for word from the source below, with the changes listed after the table.

| Prayer | Source | Terms |
|--------|--------|-------|
| Ven, Espíritu Santo | Archidiócesis de Toledo, "Cadena de oración por la asamblea del Sínodo", 2026: https://www.architoledo.org/wp-content/uploads/2026/05/Cadena-de-oracion.pdf | No notice in the PDF; traditional prayer |
| Padre Nuestro; Pater Noster; Ave María; Secuencia de Pentecostés; Ángelus; Alma de Cristo | *Compendio del Catecismo de la Iglesia Católica* (2005), Apéndice A: https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html | © Copyright 2005 - Libreria Editrice Vaticana |
| Ave Maria (Latin); Hail Mary | *Compendium of the Catechism of the Catholic Church* (2005), Appendix: https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_en.html | © Copyright 2005 - Libreria Editrice Vaticana |
| Our Father (English) | United States Conference of Catholic Bishops, "Our Father": https://www.usccb.org/prayers/our-father | Traditional wording; site notice ©2026 USCCB |
| Salmos 23, 27 y 51; Magníficat | *La Biblia. El Libro del Pueblo de Dios* (traducción argentina) on vatican.va, one page per psalm and Lucas 1: `__PGS.HTM`, `__PGW.HTM`, `__PHK.HTM` and `__PVJ.HTM` under https://www.vatican.va/archive/ESL0506/ | Copyright © Libreria Editrice Vaticana |
| Oración de San Francisco | ACI Prensa, "Oración por la Paz": https://www.aciprensa.com/recurso/1707/oracion-por-la-paz | Anonymous prayer; site notice © 2026 EWTN Inc. |
| Nada te turbe | St Teresa of Jesus, as Pope Francis quotes it (video message, 15 April 2021): https://www.vatican.va/content/francesco/es/messages/pont-messages/2021/documents/papa-francesco_20210415_videomessaggio-mujer-excepcional.html | Public domain by age |
| Oración de abandono | ACI Prensa, "Oración de entrega a Dios", Charles de Foucauld: https://www.aciprensa.com/Oracion/entrega.htm | Anonymous Spanish translation; site notice © 2026 ACI Prensa |
| San Miguel Arcángel | Vatican News, "Oraciones: San Miguel Arcángel": https://www.vaticannews.va/es/oraciones/san-miguel-arcangel.html | Copyright © 2017-2026 Dicasterium pro Communicatione |

Changes to the sources:

- **Psalms**: the superscriptions and the verse numbers are left out. The psalms use the Hebrew numbering, as the source does.
- **Magníficat**: it starts at «Mi alma canta», without the narrative "María dijo entonces:", and keeps the source's guillemets. Two transcription typos of the vatican.va page are corrected, as the Bible reads:
  - Lc 1, 48: "porque el miró" becomes "porque él miró";
  - Lc 1, 49: "el Todopoderoso he hecho" becomes "el Todopoderoso ha hecho".
- **Básicas**: all six end with "Amen" or "Amén". The Compendium's English edition prints the Pater Noster and the Our Father without one, so the app takes the Pater Noster of the Spanish edition's appendix (unaccented, "quotidianum") and the USCCB's Our Father instead.
- **Secuencia**: it ends at "y danos tu gozo eterno." with no "Amén", as in the Spanish Lectionary.
- **Every other text**: as printed, its quirks included (for example "El me hace" in Psalm 23, and the missing full stops in Alma de Cristo).

The prayer texts are not covered by the MIT license of the code. They keep the terms of their sources ([NOTICE](NOTICE) has each one's notice).

## License

The code is under the MIT license ([LICENSE](LICENSE)). The prayer texts keep their own terms ([NOTICE](NOTICE)).

## Resumen en español

Oraciones es un widget de Connect IQ para el Garmin Instinct 2 con 18 oraciones católicas conocidas, copiadas palabra por palabra de fuentes identificadas, en cinco grupos:

- **Básicas**: Padre Nuestro, Ave María, y ambas en latín (Pater Noster, Ave Maria) y en inglés (Our Father, Hail Mary).
- **Espíritu Santo**: Ven, Espíritu Santo; Secuencia de Pentecostés.
- **Salmos**: 23, 27 y 51.
- **Marianas**: Magníficat; Ángelus.
- **Clásicas**: Alma de Cristo; Oración de San Francisco; Nada te turbe; Oración de abandono; San Miguel Arcángel.

Al abrirla se ven los cinco grupos. START abre un grupo y luego una oración, UP y DOWN mueven la selección o pasan de página, y BACK vuelve un nivel. En la lista de grupos, BACK cierra la aplicación. El texto se lee en una ventana bajo el lente, cuatro líneas por pantalla, con cada verso en su propia línea. Desde la esfera del reloj, la vista resumida muestra "Oraciones" y la última oración leída, o "18 oraciones" si aún no se ha leído ninguna.

Los salmos y el Magníficat provienen de "El Libro del Pueblo de Dios", publicado en el sitio de la Santa Sede (Copyright © Libreria Editrice Vaticana). En el Magníficat se corrigieron dos erratas de esa página (Lc 1, 48-49: "él miró" y "ha hecho"). Las fuentes y los derechos de cada texto están en [NOTICE](NOTICE).
