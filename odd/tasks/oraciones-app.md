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
| O2 | `feat`: app scaffold from the Rosario. Manifest (UUID 10421347-cc46-4b32-9c0c-4faa7adf3579), jungle, the copied layout and i18n code, the group and prayer lists, the reading view, the dove ring, tests | delegated writer | [ ] |
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

## Next step

O1 research and O2 scaffold, run in parallel. O3 brings in O1's texts.
