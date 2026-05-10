# Flutter Electron UI Functional Parity Matrix

| Surface / Workflow | Electron Reference Evidence | Flutter Evidence | Status | Gap | Fix Commit |
| --- | --- | --- | --- | --- | --- |
| Empty first-run home | `test-results/flutter-electron-parity/electron/01-empty-home.png` | `test-results/flutter-electron-parity/flutter/01-empty-home.png` | Accepted Difference | Flutter matches the Electron first-run information architecture and actions. Accepted difference: exact spacing/card sizing/button rendering differs because the Flutter Linux Material renderer and Electron CSS renderer do not share a pixel-identical component system. | `223d9e8` |
| Populated grid/waterfall browse | `test-results/flutter-electron-parity/electron/02-populated-grid.png` | `test-results/flutter-electron-parity/flutter/02-populated-grid.png` | Accepted Difference | Direct photo-card activation is aligned to the Electron model: single click/tap selects immediately, double-click/double-tap opens focused Detail overlay, Enter opens Detail, and `G` opens Gallery for the selected photo. Accepted difference: card proportions and renderer density still differ between Electron CSS and Flutter Material. | `96ba222` |
| Map browse / disabled-map state | `test-results/flutter-electron-parity/electron/03-map.png` | `test-results/flutter-electron-parity/flutter/03-map.png` | Accepted Difference | Flutter matches the Electron disabled-map workflow, mapped counts, GPS selection, and browse controls. Accepted difference: exact discovery-chip density and map-canvas vertical offset differ slightly between renderers. | `223d9e8` |
| Timeline browse | `test-results/flutter-electron-parity/electron/04-timeline.png` | `test-results/flutter-electron-parity/flutter/04-timeline.png` | Accepted Difference | Flutter matches the Electron timeline workflow, scope chips, selected-photo banner, month grouping, and selectable cards. Accepted difference: exact card header proportions and group density differ slightly between renderers. | `223d9e8` |
| Detail inspector and edits | `test-results/flutter-electron-parity/electron/05-detail.png` | `test-results/flutter-electron-parity/flutter/05-detail.png` | Accepted Difference | Flutter matches the Electron focused detail workflow: double-click/double-tap enters this overlay, media/filmstrip occupy the left viewer area, inspector/edit controls occupy the right area, and the top Gallery action switches modes inside the viewer. Accepted difference: exact top-button sizing, media fallback rendering, and lower edit-field scroll position differ while preserving all controls. | `96ba222` |
| Fullscreen gallery | `test-results/flutter-electron-parity/electron/06-gallery.png` | `test-results/flutter-electron-parity/flutter/06-gallery.png` | Accepted Difference | Fullscreen Gallery is aligned as the second viewer mode, opened by selected-photo `G` or the Detail overlay's Gallery action. `D`, `Detail View`, and `Open Inspector` return to focused Detail instead of dropping back to the page. Accepted difference: exact media-frame height, button chrome, and fallback image rendering differ by renderer. | `96ba222` |
| Favorites filter | `test-results/flutter-electron-parity/electron/07-favorites.png` | `test-results/flutter-electron-parity/flutter/07-favorites.png` | Accepted Difference | Favorites photo cards share the same detail-first double-click/double-tap activation contract as the main browse grid. Accepted difference: exact selected-card dimensions and browse spacing differ between adaptive layouts. | `96ba222` |
| Memories list | `test-results/flutter-electron-parity/electron/08-memories-list.png` | `test-results/flutter-electron-parity/flutter/08-memories-list.png` | Accepted Difference | Flutter matches the Electron memories list workflow, suggested-memory generation/refresh, candidate accept/reject, Adjust photos affordance, and memory collections. Accepted difference: exact candidate/card proportions and fallback cover crop differ slightly between renderers. | `223d9e8` |
| Memory detail management | `test-results/flutter-electron-parity/electron/09-memory-detail.png` | `test-results/flutter-electron-parity/flutter/09-memory-detail.png` | Accepted Difference | Flutter matches the Electron memory detail workflow, cover-led hero, timestamp, custom-cover status, description, story outline, chapter metadata, and lower management actions. Accepted difference: exact chip colors/icon treatment/card spacing differ slightly while preserving function. | `223d9e8` |
| Settings | `test-results/flutter-electron-parity/electron/10-settings.png` | `test-results/flutter-electron-parity/flutter/10-settings.png` | Accepted Difference | Flutter matches the Electron settings workflow and first-viewport density while preserving additional lower-panel path, map, source, and secret-safe AI controls. Accepted difference: exact section heights and lower-panel density differ because Flutter exposes desktop-only file-path controls below the first viewport. | `223d9e8` |
| Notifications / AI queue | `test-results/flutter-electron-parity/electron/11-notifications.png` | `test-results/flutter-electron-parity/flutter/11-notifications.png` | Accepted Difference | Flutter matches the Electron notifications workflow, AI queue and memory candidate cards, semantic chips, retry, and suggestions handoff. Accepted difference: exact button color semantics and card spacing differ slightly between renderers. | `223d9e8` |
| Chinese locale | `test-results/flutter-electron-parity/electron/12-zh-locale.png` | `test-results/flutter-electron-parity/flutter/12-zh-locale.png` | Accepted Difference | Phase 5.10 localizes app-owned Flutter zh UI across selected-photo banners, active filter labels, status messages, Detail/Gallery controls, memory actions, settings actions, notifications, map controls, and timeline actions. Accepted difference: fixture-authored filenames, captions, memory names, imported descriptions, tags, and AI text remain source data rather than translated UI. | `acb6794` |
| Restart persistence | `test-results/flutter-electron-parity/electron/13-restart-persistence.png` | `test-results/flutter-electron-parity/flutter/13-restart-persistence.png` | Accepted Difference | Restored photo cards preserve the same selected-photo and detail-first double-click/double-tap activation contract after restart. Accepted difference: exact card dimensions and browse spacing follow the same adaptive-layout difference as populated browse. | `96ba222` |

## Evidence Rules

- Electron screenshots live under `test-results/flutter-electron-parity/electron/`.
- Flutter screenshots live under `test-results/flutter-electron-parity/flutter/`.
- Screenshot files are ignored by git; this matrix records their paths and findings.
- Electron and Flutter captures use the same 1440x920 evidence size for first-viewport comparison.
- A row can only become `Matched` after both screenshots exist and the related test path passes.
- A row can become `Accepted Difference` only with a written reason in the `Gap` column.
- A row cannot be closed from screenshots alone; tests must cover behavior.

## Current Closure Status

- Matrix audit status:
  Phase 5.9 completed the full feature/UI review pass, and Phase 5.10 closed
  the remaining confirmed Chinese-locale gap.
- Electron evidence: all 13 reference screenshots were refreshed with
  `node scripts/capture-electron-parity.mjs` and confirmed as 1440x920.
- Flutter evidence: all 13 screenshots were refreshed with
  `bash tool/capture_flutter_parity.sh all` and confirmed as 1440x920.
- Filename parity: Electron and Flutter capture directories contain the same
  13 PNG names.
- Dependency note: `flutter pub outdated` reports direct dependencies are all
  up to date; newer dev/transitive packages are outside the current resolvable
  set.
- Implementation commit: `223d9e8`.
- Handoff: branch `flutter-refactor-phases` was pushed through evidence commit
  `50bba7c`.
- Current follow-up plan:
  [docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md](superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md).
- Phase 5.8 screenshot comparison artifacts:
  `test-results/flutter-electron-parity/compare/02-populated-grid-compare.png`,
  `test-results/flutter-electron-parity/compare/05-detail-compare.png`,
  and
  `test-results/flutter-electron-parity/compare/06-gallery-compare.png`.
- Phase 5.8 handoff:
  branch `flutter-refactor-phases` now includes correction commit `96ba222`,
  which restores the Electron detail-first activation contract.
- Phase 5.9 handoff:
  `docs/flutter-electron-feature-ui-review.md` records all 13 reviewed
  surfaces and finding `FUI-001`.
- Phase 5.10 handoff:
  `FUI-001` is closed with Flutter zh app-owned string coverage,
  refreshed focused Flutter screenshots,
  refreshed Electron references,
  and regenerated compare artifacts for affected surfaces.
- Desktop baseline freeze:
  refreshed all 13 Electron screenshots,
  refreshed all 13 Flutter screenshots,
  regenerated all 13 side-by-side compare images plus the contact sheet,
  and reran the desktop verification gate after commit `acb6794`.
  The final Electron E2E order was:
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  and
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`.
- Phase 6.6 desktop hardening refresh:
  refreshed all 13 Electron screenshots after Phase 6.5 with
  `node scripts/capture-electron-parity.mjs`;
  refreshed all 13 Flutter Linux screenshots with
  `bash tool/capture_flutter_parity.sh all`;
  regenerated all 13 side-by-side compare artifacts and
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-6-6.png`.
- Phase 6.6 evidence counts:
  Electron `13`,
  Flutter `13`,
  compare `13`;
  all Electron and Flutter PNGs report 1440x920,
  and all compare PNGs report 2976x920.
- Phase 6.6 finding `P66-001`:
  non-zh Flutter parity captures inherited the fixture backup's persisted
  `zh-CN` locale while Electron reference captures force English for normal
  surfaces.
  The Flutter capture harness now writes a temporary `en-US` / `follow-ui`
  backup copy for normal fixture-backed surfaces,
  while keeping `zh-locale` and `restart-persistence` in the persisted zh
  state.
  Affected Flutter surfaces were recaptured and compare artifacts regenerated.
- Phase 6.6 finding `P66-002`:
  Electron E2E verification commands cleaned the root `test-results/`
  directory through Playwright's default output behavior,
  removing the freshly generated parity PNG evidence.
  Playwright artifacts now write to `test-results/playwright-artifacts`,
  leaving `test-results/flutter-electron-parity/` stable for parity evidence.
- Phase 6.6 review decision:
  after the harness fix and refreshed contact-sheet inspection,
  no new product UI/function gap was found beyond the already documented
  accepted renderer differences.

## Remaining Closure Order

No `Gap` rows remain in this matrix as of the local Phase 6.6 refresh.
Future review passes should continue to compare each feature/UI surface against
the Electron reference before promoting new work into implementation phases.

## Capture Commands

Electron reference capture:

```bash
pnpm run e2e:prepare
node scripts/capture-electron-parity.mjs
```

Flutter capture:

```bash
cd chronopic_flutter
bash tool/capture_flutter_parity.sh all
```

Focused Flutter recapture can pass one or more surfaces:

```bash
cd chronopic_flutter
bash tool/capture_flutter_parity.sh settings notifications
```

Flutter capture requires `xvfb-run`, `scrot`, and `LIBGL_ALWAYS_SOFTWARE=1`.
