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
| O3 | `feat`: the 13 prayer texts from O1 and the glance with the last prayer read, plus fit tests over every text | delegated writer | [ ] |
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

## Next step

O3 brings in O1's texts: one `i18n` table per prayer, `Prayers.text` loading it, and fit tests over every text. Then O4.
