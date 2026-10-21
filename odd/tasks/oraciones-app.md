# Oraciones app

## Objective

A Connect IQ widget for the Garmin Instinct 2 that holds a set of well-known Catholic prayers to read on the watch. It shares the look of the Rosario widget (`~/Documents/garmin-rosario`). Spanish only for now.

## Problem

The Rosario widget guides only the rosary. The user wants the other prayers they pray on the watch too: to the Holy Spirit, psalms, Marian prayers and classic prayers.

## Why

The user asked for it: "Ahora quiero otra app basada en la estética de esta, que estén varias oraciones como las del Espíritu Santo, salmos y otros muy hermosos y conocidos … por ahora en español". They then chose these 13 from a proposed list:

| Group | Prayers |
|-------|---------|
| Al Espíritu Santo | Ven, Espíritu Santo; Ven, Espíritu Creador (Veni Creator); Secuencia de Pentecostés |
| Salmos | Salmo 23; Salmo 27; Salmo 51 (Miserere) |
| Marianas | Magníficat; Ángelus |
| Clásicas | Alma de Cristo; Oración de San Francisco; Nada te turbe (Santa Teresa); Oración de abandono (Charles de Foucauld); San Miguel Arcángel |

## Scope

Authorized by the user in the messages above.

- **Navigation:**
  - The app opens on a list of the four groups, then the group's prayers, in the Rosario's large-bar list style (`BarListView`: FONT_LARGE, two items visible, a thin scroll bar).
  - START selects, UP and DOWN move, BACK goes up one level.
- **Reading view:**
  - It works like the Rosario's mystery reading: UP and DOWN scroll a page, BACK returns, and no text runs under the subscreen lens.
  - Every text fits the visible area.
- **Subscreen ring:** a 1-bit dove, the counterpart of the Rosario's rosary symbol.
- **Glance:** the app name and the last prayer read. Before any prayer has been read, it shows "Oraciones" and the number of prayers.
- **Texts:**
  - Every text is verbatim from a named source, recorded with its URL.
  - Biblical texts (the three psalms and the Magníficat) use the same Spanish Bible as the Rosario's Spanish quotes, *El Libro del Pueblo de Dios* (vatican.va), with attribution. That follows the user's earlier choice for the Rosario.
  - Traditional prayers come from public-domain or Church sources.
- **Strings:** loaded through the Rosario's i18n system (`i18n/<lang>.json`, `scripts/gen-i18n.py`, per-table `jsonData`). Only `spa` for now, so other languages can be added later without a refactor.
- **Repo files:** tests (layout fit, glyphs, delegates, memory), README, MIT LICENSE, NOTICE.

Out of scope for now: other languages, the Connect IQ Store, and the GitHub repository. Creating that repository is a remote operation that needs the user's go-ahead.

## Constraints

- Instinct 2 only (176x176 MIP, subscreen at x=113 y=0 62x62), minApiLevel 3.4.0.
- Glance memory limit 32KB (28,488 bytes usable in the simulator), widget limit 64KB.
- Long texts (Psalm 51, the Sequence, the Veni Creator) load one prayer at a time and are freed when the view closes.
- Reuse the Rosario's tested layout code: the visible-area table, the fit helpers, `BarListView`, the reading layout and the wrap at spaces. Copy what is needed; don't share code across repositories.
- Code, comments and docs in English; the prayer texts in Spanish. Conventional commits with no AI attribution.

## Delivery

- Strategy: `single-pr`, branch `feat/oraciones-mvp` from `main` at edeaea3. No remote yet.
- Forecast: about 1,500 authored changed lines (O1 0, O2 ~700, O3 ~500, O4 ~200), plus the prayer texts.

## Tasks

| ID | Task | Route | Status |
|----|------|-------|--------|
| O1 | Research: the verbatim Spanish text and source URL of each of the 13 prayers. Report the copyright status, length and any variant | delegated research worker (more than 5 lookups) | [ ] |
| O2 | `feat`: app scaffold from the Rosario. Manifest (UUID 10421347-cc46-4b32-9c0c-4faa7adf3579), jungle, the copied layout and i18n code, the group and prayer lists, the reading view, the dove ring, tests | delegated writer (2+ non-trivial files) | [x] b353e4d lists (+2435: 102 generated, about 590 copied scripts, 764 tests, this document) RED 10 passed, 8 failed -> GREEN 18/18; 8f5adc9 reading (+751/-3) RED 21 passed, 4 failed -> GREEN 25/25. Debug and release `-w`: 0 warnings, release 15,900 bytes |
| O3 | `feat`: the 13 prayer texts from O1 and the glance with the last prayer read, plus fit tests over every text | delegated writer (2+ non-trivial files) | [ ] code done, memory pending: 459a2e6 texts (+527/-23) RED 25 passed, 2 failed -> GREEN 28/28; 1faca9b glance (+255/-122) RED 28 passed, 2 failed -> GREEN 30/30. `check-texts.py` ALL VERBATIM (13 texts, the Magníficat's 2 corrections). Debug and release `-w`: 0 warnings, release 26,348 bytes. The glance and widget memory runs are pending: the simulator stopped answering |
| O4 | `docs`: README, LICENSE (MIT), NOTICE with the text sources | delegated writer | [ ] |

## Acceptance criteria

- Builds with 0 warnings, and every test passes.
- Every prayer reads in full, and every text fits the visible area.
- Memory stays within the glance and widget budgets.
- The user checks it on the watch.

## Checks

- TDD for the delegates and the layout plans.
- Fit tests over every text at every scroll offset.
- On-device check by the user.

## Progress

- Feature document created. Repository initialized at edeaea3.
- O2 done in two commits on `feat/oraciones-mvp`, route: delegated writer.
  - **b353e4d `feat`: the scaffold and the lists.**
    - Copied from the Rosario at 5929b7b and adapted: the visible-area table, `Layout` (glance plan, text boxes), the header wrap (`HeaderLayout`, from `MainLayout`), `MenuLayout` and `BarListView`, the i18n system reduced to `spa`, `gen-i18n.py --check`, `check-glance-strings.py` and `test-all.sh` (suite `suite=oraciones`).
    - The i18n model is `i18n/spa.json`, the first entry of `LANGUAGES` in `gen-i18n.py`; a new language adds its file, its code there and its watches in `I18n.resolve`. The language picker was left out.
    - Tables: `glance` (2 texts, 104 bytes loaded), `ui` (6, 256 bytes) and `titles` (13, 504 bytes).
    - Navigation: a `Navigator` pushes and pops the screens, so the tests swap in a recorder. START on a group opens its prayers; BACK there closes the list. BACK on the list of groups returns false, so the system closes the app.
    - Every label fits the large font as given, so none was shortened. The tightest is "Alma de Cristo", 136px, 6px inside its bar.
    - The subscreen shows a 1px ring (radius 26, as the Rosario's ring track) and a 32x32 1-bit dove bitmap (`resources/drawables/dove.svg`, the launcher icon's dove). The test checks the dove's corners stay within radius 23 of (144,31).
    - Lists hold 816 to 920 bytes each (budget 3,072).
  - **8f5adc9 `feat(reading)`: the reading view.**
    - It reuses the Rosario's window (22..154 x 75..158, 4 lines of FONT_TINY), its pages (DOWN 0, 4, 8, ... then the last window; UP back through the same pages) and the wrap at spaces only.
    - A "\n" starts a new paragraph after one blank line; empty paragraphs add nothing.
    - Page indicator: a thumb on the lists' track (x 166, rows 85..141), at least 4px long, from the track's top on page one to its bottom on the last.
    - The view loads `Prayers.text(prayer)` in `onLayout` and keeps only the wrapped lines. Until O3, every prayer reads the UI string "Texto en preparación."; O3 gives each text a table of its own and changes `Prayers.text` to load it.
    - The tests read placeholders made in test code: 1 character, 300 characters (2 breaks) and 2,500 characters (23 breaks). The 2,500-character one gives 190 lines, 23 of them blank, in 48 pages.
    - A view holds 688, 1,576 and 8,376 bytes (budget 12,288) and leaves 0 bytes once let go.
    - FONT_TINY has every glyph tested: á é í ó ú ñ ü, Á É Í Ó Ú, ¡ ¿ « », the ellipsis and the em dash.
  - **Evidence:**
    - RED for the lists: FAILED (passed=10, failed=8) on stubs; the failures were the glance texts, the groups, the glance block, both list fits and the three list-delegate tests.
    - RED for the reading view: FAILED (passed=21, failed=4) on the Rosario's reading code copied as it was. It has no paragraphs (the 300- and 2,500-character texts were cut) and no page indicator, BACK did not close, and START did not open.
    - `scripts/test-all.sh`: Translations OK (1 language x 3 tables, 21 texts), Glance texts OK, Tests PASSED (passed=25, failed=0, errors=0).
    - Debug `-w` and release `-r -w`: 0 warnings. Release `.prg`: 15,900 bytes.
  - **Memory**, measured with uncommitted instrumented copies (release builds, in the simulator, nothing committed):

    | | Bytes |
    |---|---|
    | Glance, `usedMemory` in `onUpdate` | 8,112 of 28,488 ("Oraciones" / "13 oraciones") |
    | Widget (run as a watch-app): list of groups open | 18,392 |
    | Plus the Salmos list | 19,232 |
    | Plus the 2,500-character text and its laid-out reading view | 30,672 while the text is held, 27,832 once it is let go (190 lines) |
    | After the reading view and the list close | 18,672 |

  - **Open for the user:** a 2,500-character text takes 48 DOWN presses at 4 lines a page. To decide after reading the real Psalm 51 on the watch.

- O3, route: delegated writer. Two commits on `feat/oraciones-mvp`.
  - **459a2e6 `feat(texts)`: the 13 texts.**
    - The texts are copied from O1's research (`texts.json`, with the parent's decisions): Ven, Espíritu Santo in the Toledo text; the psalms without their superscriptions; the Sequence ending at "gozo eterno." with no "Amén"; every other text as researched.
    - The Magníficat corrects two transcription typos of its page (https://www.vatican.va/archive/ESL0506/__PVJ.HTM), Lc 1, 48 "porque el miró" -> "porque él miró" and Lc 1, 49 "el Todopoderoso he hecho" -> "el Todopoderoso ha hecho". Both are recorded in the text's `//` note and in `scripts/check-texts.py`.
    - Each text is a table of its own (`text<Name>` in `i18n/spa.json`, one text each), whose `//` note names its source URL and publisher. Loaded, they hold 200 to 1,576 bytes (text budget 2,560).
    - `scripts/check-texts.py <sources-dir> [i18n/spa.json]` compares every text with its downloaded pages, word for word. Corrections count only when the page prints the wrong words exactly once and the text holds the right ones. It also fails when a table's note does not name its source. `scripts/test-all.sh` runs it when `TEXT_SOURCES` names the downloads, which stay out of the repository.
    - A one-word change ("mi copa" -> "mi vaso") and the Magníficat's uncorrected "el miró" both made it fail.
    - Pins hold each text's opening, close and length; a second pin holds the Magníficat's corrected words.
  - **1faca9b `feat(glance)`: the last prayer read.**
    - The reading view saves its prayer under `Application.Storage` key `lastPrayer` in `onShow`.
    - The glance reads "Oraciones" over that prayer's short title, or over "13 oraciones" before any prayer has been read. A stored value that is not a prayer index reads as none.
    - The 13 short titles moved into the glance table, the only one the glance can load. It now holds 15 texts, 584 bytes loaded (budget 1,024).
    - Every second line fits the glance; the widest, "Alma de Cristo", leaves 34px to the content's edge.
  - **Evidence:**
    - RED for the pins: FAILED (passed=25, failed=2), the two pin tests, while every prayer still read the pending notice.
    - RED for the glance: FAILED (passed=28, failed=2), the two glance tests, on stubs.
    - `scripts/test-all.sh` with `TEXT_SOURCES`: Texts ALL VERBATIM: 13 texts; Translations OK (15 tables, 33 texts); Glance texts OK (15 texts looked up); Tests PASSED (passed=30, failed=0, errors=0).
    - Debug `-w` and release `-r -w`: 0 warnings. Release `.prg`: 26,348 bytes.
    - FONT_TINY has every glyph the texts use, the en dash "–" of Psalm 51 included. The texts hold no curly quotes.
  - **Pages per prayer,** at 4 lines a page, with a blank line after each "\n" as O2 built it (in brackets: without the blank lines):

    | Prayer | Characters | Lines | Pages |
    |---|---|---|---|
    | Ven, Espíritu | 381 | 33 | 9 (7) |
    | Veni Creator | 819 | 91 | 23 (16) |
    | Secuencia | 822 | 88 | 22 (15) |
    | Salmo 23 | 529 | 60 | 15 (11) |
    | Salmo 27 | 1,472 | 155 | 39 (28) |
    | Salmo 51 | 1,466 | 149 | 38 (28) |
    | Magníficat | 733 | 60 | 15 (13) |
    | Ángelus | 667 | 72 | 18 (13) |
    | Alma de Cristo | 396 | 40 | 10 (7) |
    | San Francisco | 588 | 58 | 15 (11) |
    | Nada te turbe | 143 | 18 | 5 (3) |
    | Abandono | 407 | 45 | 12 (8) |
    | San Miguel | 384 | 33 | 9 (7) |

  - **Reading view memory, in the test suite:** a view holds 1,336 to 6,224 bytes (Psalm 27) of a 12,288-byte budget, and leaves 0 bytes once closed.
  - **Pending:** the glance memory, with no prayer read and after one, and the widget peak with Psalm 27, measured with instrumented copies. The simulator stopped answering every run, tests included, after the last test run at 15:49; it was not restarted.
  - **Open for the user:** the texts' "\n" are printed lines, not paragraphs, so the blank lines add a third to the psalms' pages (Psalm 27: 39 pages, or 28 without them). Dropping the blank lines would make a wrapped line look like a new one in the centered text. To decide on the watch.

## Next step

Restart the simulator, then measure the glance (no prayer read, then one) and the widget peak with Psalm 27, and check O3 off. Then O4.
