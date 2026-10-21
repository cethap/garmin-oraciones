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
| O1 | Research: the verbatim Spanish text and source URL of each of the 13 prayers. Report the copyright status, length and any variant | delegated research worker (more than 5 lookups) | [x] Research only, no commit. 13 texts found and checked verbatim by script against 23 downloaded pages; sources and decisions in Progress and NOTICE |
| O2 | `feat`: app scaffold from the Rosario. Manifest (UUID 10421347-cc46-4b32-9c0c-4faa7adf3579), jungle, the copied layout and i18n code, the group and prayer lists, the reading view, the dove ring, tests | delegated writer (2+ non-trivial files) | [x] b353e4d lists (+2435: 102 generated, about 590 copied scripts, 764 tests, this document) RED 10 passed, 8 failed -> GREEN 18/18; 8f5adc9 reading (+751/-3) RED 21 passed, 4 failed -> GREEN 25/25. Debug and release `-w`: 0 warnings, release 15,900 bytes |
| O3 | `feat`: the 13 prayer texts from O1 and the glance with the last prayer read, plus fit tests over every text | delegated writer (2+ non-trivial files) | [x] 459a2e6 texts (+527/-23) RED 25 passed, 2 failed -> GREEN 28/28; 1faca9b glance (+255/-122) RED 28 passed, 2 failed -> GREEN 30/30; 76ff5db verse layout (+124/-62) RED 30 passed, 1 failed -> GREEN 32/32. `check-texts.py` ALL VERBATIM (13 texts, the Magníficat's 2 corrections). Debug and release `-w`: 0 warnings, release 26,556 bytes. Glance 8,552 bytes with no prayer read, 8,616 after one (of 28,488); widget 26,128 with Psalm 27 open |
| O4 | `docs`: README, LICENSE (MIT), NOTICE with the text sources | delegated writer (3 new files) | [x] 64e12f9 (+399): README (English, Spanish summary), LICENSE (MIT, Cesar Tapasco, 2026), NOTICE (each text's source, publisher, notice and the Magníficat's corrections). Structural readback: every README anchor resolves, every table has even columns |
| O5 | `feat`: remove the Veni Creator, at the user's request after testing on the watch ("quita el veni creator, solo deja dos"): the Espíritu Santo group keeps "Ven, Espíritu" and "Secuencia", 12 prayers in all | delegated writer (2+ non-trivial files) | [x] c055e4a (+112/-106) RED 26 passed, 6 failed -> GREEN 33/33. `check-texts.py` ALL VERBATIM: 12 texts. Debug and release `-w`: 0 warnings, release 26,028 bytes |
| O6 | `feat`: the "Básicas" group, first in the list: Padre Nuestro, Pater Noster, Our Father, Ave María, Ave Maria, Hail Mary (the user's choice of six texts; 12 -> 18 prayers) | delegated writer (2+ non-trivial files) | [x] 888b28e (+250/-74) RED 28 passed, 5 failed -> GREEN 33/33. `check-texts.py` ALL VERBATIM: 18 texts. Debug and release `-w`: 0 warnings, release 28,604 bytes |
| O7 | `feat`: seven prayers and the groups "Eucarísticas" and "Del día" (the user's choice; 18 -> 25 prayers, seven groups) | delegated writer (2+ non-trivial files) | [x] a93bca1 (+301/-50) RED 28 passed, 5 failed -> GREEN 34/34. `check-texts.py` ALL VERBATIM: 25 texts. Debug and release `-w`: 0 warnings, release 33,180 bytes |

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
  - **Pages per prayer, first layout** (O2's blank line after each "\n"): Psalm 27 39 pages, Psalm 51 38, Veni Creator 23, Secuencia 22.
  - **76ff5db `feat(reading)`: the texts set as verse** (the parent's decision on that finding).
    - The texts' "\n" mark printed lines, not paragraphs. Each one now starts a new line with no blank line between.
    - A printed line too long for the window wraps at spaces onto continuation lines indented 8px (`ReadingLayout.INDENT`).
    - Lines align to the window's left edge (x 22, continuations x 30) instead of centered.
    - A body line keeps its continuation as a leading space, which no other line has, so the view holds no extra array.
    - The space-only wrap, the page indicator and the 4-line pages are unchanged.
    - Tests: the fit tests check every placeholder and every real text at every offset, with each line's x and left justification. A new test pins each prayer's page count.
    - RED: FAILED (passed=30, failed=1), only the new indent test (blank lines, every line centered at x 88). GREEN: 31/31, then 32/32 with the page pins.
  - **Pages per prayer, verse layout,** at 4 lines a page:

    | Prayer | Characters | Lines (continued) | Pages |
    |---|---|---|---|
    | Ven, Espíritu | 381 | 29 (23) | 8 |
    | Veni Creator | 819 | 67 (39) | 17 |
    | Secuencia | 822 | 61 (31) | 16 |
    | Salmo 23 | 529 | 42 (23) | 11 |
    | Salmo 27 | 1,472 | 113 (66) | 29 |
    | Salmo 51 | 1,466 | 110 (69) | 28 |
    | Magníficat | 733 | 53 (43) | 14 |
    | Ángelus | 667 | 51 (28) | 13 |
    | Alma de Cristo | 396 | 30 (17) | 8 |
    | San Francisco | 588 | 46 (30) | 12 |
    | Nada te turbe | 143 | 10 (1) | 3 |
    | Abandono | 407 | 30 (14) | 8 |
    | San Miguel | 384 | 28 (22) | 7 |

  - **Final checks at 76ff5db:**
    - `scripts/test-all.sh` with `TEXT_SOURCES`: Texts ALL VERBATIM: 13 texts; Translations OK; Glance texts OK; Tests PASSED (passed=32, failed=0, errors=0).
    - Debug `-w` and release `-r -w`: 0 warnings. Release `.prg`: 26,556 bytes.
  - **Memory.**
    - In the test suite, a reading view holds 1,104 (Nada te turbe) to 5,064 bytes (Psalm 27) of a 12,288-byte budget, and leaves 0 bytes once closed.
    - Measured with uncommitted instrumented copies, release builds, in the simulator:

    | | Bytes |
    |---|---|
    | Glance, no prayer read (1faca9b) | 8,552 of 28,488 ("Oraciones" / "13 oraciones") |
    | Glance after one, Psalm 27 saved (1faca9b and 76ff5db) | 8,616 ("Oraciones" / "Salmo 27") |
    | Widget (as a watch-app), list of groups open | 18,632 |
    | Plus the Salmos list | 19,472 |
    | Plus Psalm 27's reading view laid out and drawn, its text still held by the probe | 26,128 (113 lines) |
    | Same, the probe's copy of the text let go | 24,624 |
    | After the view and the list close | 18,712 |

    - Before the verse layout, the same widget probe read 27,088 with the text held, at 155 lines.
    - The first probe laid out and drew all 13 views in one update and tripped the watchdog ("Code Executed Too Long"). One view per update ran clean, as the app does when it opens a prayer.
    - The simulator stopped answering once during O3 and was relaunched by the user; nothing was committed while it was down.

- O4, route: delegated writer, after loading the `cognitive-doc-design` skill.
  - **64e12f9 `docs`:**
    - `README.md` leads with a quick start, then the features, the 13 prayers with their page counts, the controls, development (build, tests, texts and languages, the text check, simulator, sideload), the project layout and the text sources, and closes with a Spanish summary.
    - `LICENSE`: MIT, Cesar Tapasco, 2026, the Rosario's text.
    - `NOTICE`, in the Rosario's style: each text's source URL, publisher and copyright notice as researched, and the changes made to it (the psalms' superscriptions, the Magníficat's two corrections, the Sequence's missing "Amén"). Where a source states no terms, none is claimed.
  - **Checks:** structural readback (every anchor resolves, every table has even columns). Final `scripts/test-all.sh` with `TEXT_SOURCES`: Texts ALL VERBATIM: 13 texts; Translations OK; Glance texts OK; Tests PASSED (passed=32, failed=0, errors=0). Debug and release `-w`: 0 warnings, release 26,556 bytes.

- **Review slices.** The scaffold commit (+2,435) was too large for one native review, so the parent rebuilt the branch as smaller commits with the same final tree (`git diff a3e5f44 HEAD` is empty):
  - c69207a scripts;
  - 73522b3 the app scaffold;
  - e4f0eab the list tests;
  - the later commits replayed as c52b6f5 through a65f664.

  Both new intermediate commits build with 0 warnings (debug and test builds). The pre-split branch is kept locally as `feat/oraciones-mvp-presplit`. The parent's spot check of `scripts/test-all.sh` with `TEXT_SOURCES`: 13 texts ALL VERBATIM, 32 passed, 0 failed.
- **Reviews.** Each slice ran in its own detached worktree; all were approved and acknowledged:

  | Range | Tier | Lineage | Advisory findings |
  |---|---|---|---|
  | edeaea3..c69207a | high | review-fb4fb5de1502ccb1 | 7 |
  | c69207a..73522b3 | medium | review-b933a71553842540 | 4 |
  | 73522b3..0e53016 | medium | review-0744b0dbd2b753d6 | 1 |
  | 0e53016..af35de3 | high | review-4fc23eb4518cff88 | 4 |
  | af35de3..a65f664 | medium | review-a1d8c290459897b6 | 1 |
- **Follow-ups**, non-blocking advisories for later:
  - Scripts:
    - `check-glance-strings.py` counts bare identifiers and checks calls by name only (R2-text-key-scope, R3-text-key-bare-identifier, R3-call-check-name-only);
    - the checkers have no tests of their own (R3-checkers-untested);
    - smaller items: R2-duplicated-model-constants, R3-gen-no-cross-table-id-check, R3-unterminated-literal-line-drift, R2-invisible-literal, R3-002.
  - App:
    - continuation lines are marked by a leading space, with no guard against a source line that starts with one (R3-001, ReadingView);
    - the table-size test measures `usedMemory` deltas (R3-memory-delta-flaky);
    - smaller items: R3-wrap-fallback-unbounded, R3-wrap-whitespace, R2-magnificat-magic-index.
  - Slice artifacts, no action:
    - R3-list-navigation-untested and R3-visiblearea-unused: the tests are in e4f0eab;
    - the glance-memory R3-001 in 0e53016..af35de3: measured afterwards, 8,616 of 28,488 bytes.

- O5, route: delegated writer. The user tested the app on the watch and asked: "quita el veni creator, solo deja dos".
  - **c055e4a `feat`: the Veni Creator removed.**
    - Gone: its text table and short title in `i18n/spa.json` (and the generated files), its entries in `source/Prayers.mc`, its source in `scripts/check-texts.py`, and its entries in NOTICE and the README.
    - The Espíritu Santo group holds "Ven, Espíritu" and "Secuencia"; the groups now start at prayers 0, 2, 5 and 7. `Prayers.COUNT` is 12, and the glance's count reads "12 oraciones". The glance table holds 14 texts, 544 bytes loaded.
    - **Saved glance choice:** the last prayer read is now saved as a stable id, the research id (`Prayers.ids()`, for example "salmo_27"), instead of an index. Removing a prayer shifts the indices, so an index saved by the 13-prayer build would name the wrong prayer.
    - Any stored value that is not a known id reads as none, so the glance shows "12 oraciones" until the next prayer is read. That covers an old build's index, the removed "veni_creator" id and values of other types.
    - Migrating the old indices was left out: it would only help the one watch that ran the dev build, and that watch's value is replaced at the next read.
    - The tests no longer use hard-coded prayer indices: they find Psalm 51 and the Magníficat by id.
  - **Evidence:**
    - RED, after the count, glance, pin and page tests were changed to expect 12 prayers: FAILED (passed=26, failed=6). The 6 were `glanceShowsTheLastPrayerRead`, `glanceSummaryNamesThePrayer`, `glanceNamesTheAppAndCountsThePrayers`, `groupsHoldTheirPrayersInOrder`, `everyTextKeepsItsOpeningItsCloseAndItsLength` and `everyPrayerReadsInItsPages`.
    - GREEN: `scripts/test-all.sh` with `TEXT_SOURCES`: Texts ALL VERBATIM: 12 texts; Translations OK (14 tables, 31 texts); Glance texts OK (14 texts looked up); Tests PASSED (passed=33, failed=0, errors=0), the new id test included.
    - Debug and release `-w`: 0 warnings. Release `.prg`: 26,028 bytes.
  - **Pages per prayer** are unchanged for the 12 that remain: 8, 16, 11, 29, 28, 14, 13, 8, 12, 3, 8, 7.

- **O5 review:** approved (review-8d5270910f2b376e), with three advisory suggestions about the parallel id list in `Prayers.mc:15-19`, kept as follow-ups. The id list is a third array that must stay aligned with the title and text key arrays.
- O6, route: delegated writer. The user's request: a "Básicas" group, first in the list, with six texts.
  - **888b28e `feat`: the Básicas group.**
    - The group holds the Padre Nuestro (Compendium, Spanish edition, with Vatican News), Ave María (same), Ave Maria in Latin (Compendium, English edition, with the Spanish edition) and Hail Mary (Compendium, English edition).
    - **Parent decision:** all six end with "Amen" or "Amén". The English edition's Pater Noster and Our Father have none, so they were replaced by verbatim alternatives that do:
      - the Spanish edition's appendix Pater Noster (unaccented, "quotidianum", ending "Amen");
      - the USCCB's Our Father (https://www.usccb.org/prayers/our-father, ending "Amen.").
    - Ids: `padre_nuestro`, `pater_noster`, `our_father`, `ave_maria_es`, `ave_maria_la`, `hail_mary`. The research notes and the decision are in each table's `//` note and in NOTICE.
    - Groups, in order: Básicas, Espíritu Santo, Salmos, Marianas, Clásicas, starting at prayers 0, 6, 8, 11 and 13. The glance's count reads "18 oraciones".
    - Every label fits FONT_LARGE as given. The widest new one, "Padre Nuestro", is 130px, 9px inside its bar.
    - New glyph: "æ" (Latin "nostræ"), 13px in FONT_TINY.
    - `scripts/check-texts.py` now rejoins the words a PDF hyphenates at a line end, reads ePubs chapter by chapter and ignores stanza numbers ("2. "), as the scratch checker does. Every earlier text still passes.
    - Glance table: 20 texts, 768 bytes loaded (budget 1,024).
    - The text-table budget now covers every table after the ui table, instead of counting from the first text's key.
  - **Pages:** Padre Nuestro 7, Pater Noster 6, Our Father 6, Ave María 5, Ave Maria 4, Hail Mary 5.
  - **Evidence:**
    - RED, after the counts, groups, glance and pins were changed to expect 18 prayers: FAILED (passed=28, failed=5). The 5 were the three glance tests, `groupsHoldTheirPrayersInOrder` and `everyTextKeepsItsOpeningItsCloseAndItsLength`.
    - GREEN: `scripts/test-all.sh` with `TEXT_SOURCES`: Texts ALL VERBATIM: 18 texts; Translations OK (20 tables, 44 texts); Glance texts OK (20 texts looked up); Tests PASSED (passed=33, failed=0, errors=0).
    - The page-count pins were updated from the measured pages.
    - Debug and release `-w`: 0 warnings. Release `.prg`: 28,604 bytes.
    - Memory: measured once all three tasks were in (O8).

- O7, route: delegated writer. The user's request: seven prayers, two of them in Marianas and five in two new groups.
  - **a93bca1 `feat`:** every text from O1's `texts_o7.json`, unchanged, with its research notes in the `//` note and in NOTICE.
    - **Marianas**, after Magníficat and Ángelus:
      - `bendita_pureza`, "Bendita pureza";
      - `consagracion_maria`, "Consagración", the Gran Poder vos form.
    - **Eucarísticas:**
      - `comunion_espiritual`, "Comunión", from Vatican News, vos and tú as printed;
      - `adoro_te`, from ACI Prensa.
    - **Del día:**
      - `ofrecimiento`, the current official Red Mundial text "Padre bueno, sé que estás conmigo…" (the user's choice);
      - `contricion`, "Contrición", from the Compendium;
      - `noche`, "Oración noche", the Liturgy of the Hours form "Visita, Señor, esta habitación…", from Almudí's ePub. Its copyright is recorded as presumably the CEE's, not verified.
    - Group order: Básicas, Espíritu Santo, Salmos, Marianas, Eucarísticas, Del día, Clásicas, starting at prayers 0, 6, 8, 11, 15, 17 and 20. The glance's count reads "25 oraciones".
  - **Fit findings and decisions:**
    - "Adoro te devote" is 150px in FONT_LARGE, 2px wider than its 148px bar (gaps -1 on each side). It is listed as **"Adoro te"** (80px), the hymn's incipit. To confirm with the user.
    - Every other label fits FONT_LARGE. The tightest are "Bendita pureza" at 137px and "Oración noche" at 133px.
    - The header beside the lens could not hold three one-word titles in the tiny font: "Eucarísticas" (88px), "Consagración" (98px) and "Ofrecimiento" (96px). The middle of the band fits only about 78px.
    - New header rule (`HeaderLayout.isWideLine`): a one-line title wider than 78px takes a 3-line title's last line, rows 51..74, centered on x 52, where the band is widest (about 100px). They now fit with margins of 7, 3 and 4px.
    - Every other header keeps its place. A test pins the rule.
  - **Glance table:** 27 texts, 1,024 bytes loaded. The budget rose from 1,024 to 1,536, because the 25 titles live there for the glance.
  - **Pages:** Bendita pureza 5, Consagración 6, Comunión 8, Adoro te 21, Ofrecimiento 11, Contrición 8, Oración noche 4.
  - **Evidence:**
    - RED, after the counts, groups, glance and pins were changed to expect 25 prayers: FAILED (passed=28, failed=5). The 5 were the three glance tests, the groups and the text pins.
    - GREEN: `scripts/test-all.sh` with `TEXT_SOURCES`: Texts ALL VERBATIM: 25 texts; Translations OK (27 tables, 60 texts); Glance texts OK (27 texts looked up); Tests PASSED (passed=34, failed=0, errors=0).
    - Debug and release `-w`: 0 warnings. Release `.prg`: 33,180 bytes.
    - Memory: measured once O8 was in.

## Next step

O8: three psalms and the "Biblia" group. Then the user decides on the pull request and the GitHub repository; creating the repository is a remote operation that needs the user's go-ahead.
