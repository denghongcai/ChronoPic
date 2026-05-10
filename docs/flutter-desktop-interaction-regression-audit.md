# Flutter Desktop Interaction Regression Audit

Date: 2026-05-10
Reference: Electron desktop
Candidate: Flutter Linux desktop

## Decisions

- Single click selects only.
- Double click opens focused Detail.
- Enter opens focused Detail for the selected photo.
- `G` opens or switches to Gallery.
- `D` switches to Detail from Gallery.
- Escape closes focused overlays.
- Waterfall browse uses incremental 20-item loading.
- Desktop adaptive layout must be rechecked at 1366, 1600, and 2048 widths.
- GitHub Actions startup failure is not part of this phase because the user
  handled it separately.
- Real Electron migration sample validation is not part of this phase.

## Audit Matrix

| Surface | Interaction | Evidence | Status | Notes |
| --- | --- | --- | --- | --- |
| Waterfall | Single click selects without inline detail | `chronopic_home_test.dart`, `test-results/flutter-electron-parity/flutter/02-populated-grid.png` | Matched | Selection shows browse state only; no bottom inline detail |
| Waterfall | Double click opens focused Detail | `chronopic_home_test.dart`, `test-results/flutter-electron-parity/flutter/05-detail.png` | Matched | Focused overlay model preserved |
| Waterfall | Enter opens focused Detail | `chronopic_home_test.dart` | Matched | Selection is sufficient; no inline editor |
| Waterfall | `G` opens Gallery from selection | `linux_desktop_parity_test.dart`, `test-results/flutter-electron-parity/flutter/06-gallery.png` | Matched | Gallery is an overlay |
| Waterfall | Incremental load starts at 20 and loads 20 more | `mobile_productization_test.dart` and `linux_desktop_parity_test.dart` | Fixed | Default query remains 20; 25-photo fixture lazy-loads to 25 |
| Detail | Escape closes overlay | `chronopic_home_test.dart` | Matched | Returns to browse with selection intact |
| Detail | Save/validation feedback visible inside overlay | `linux_desktop_parity_test.dart`, `test-results/flutter-electron-parity/flutter/05-detail.png` | Matched | Edit surface remains in focused Detail |
| Gallery | Arrow navigation and filmstrip update | `linux_desktop_parity_test.dart`, `test-results/flutter-electron-parity/flutter/06-gallery.png` | Matched | Left/right and filmstrip remain connected |
| Gallery | `D` switches to Detail | `linux_desktop_parity_test.dart` | Matched | Switches with the same selected photo |
| Map | Selection does not open inline detail | `test-results/flutter-electron-parity/flutter/03-map.png`, UI parity tests | Matched | Browse mode remains selection-first |
| Timeline | Selection does not open inline detail | `test-results/flutter-electron-parity/flutter/04-timeline.png`, UI parity tests | Matched | Browse mode remains selection-first |
| Settings | Resize does not clip controls | `test-results/flutter-adaptive-regression/1366-populated-grid.png`, `1600-populated-grid.png`, `2048-populated-grid.png` | Matched | Section headers now wrap trailing controls below 520px |
| Memories list | Resize preserves card readability | `test-results/flutter-electron-parity/flutter/08-memories-list.png` | Matched | Cards remain readable in the refreshed capture |
| Memory detail | Resize preserves editor/actions | `test-results/flutter-electron-parity/flutter/09-memory-detail.png` | Matched | Detail actions remain reachable |
| Notifications | Resize preserves queue/action layout | `test-results/flutter-electron-parity/flutter/11-notifications.png` | Matched | Notification queue remains readable |

## Accepted Differences

No new accepted differences recorded yet.

## Closeout Evidence

- Electron screenshots:
  `test-results/flutter-electron-parity/electron/*.png`.
- Flutter screenshots:
  `test-results/flutter-electron-parity/flutter/*.png`.
- Compare artifacts:
  `test-results/flutter-electron-parity/compare/*-compare.png`,
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-9.png`.
- Adaptive screenshots:
  `test-results/flutter-adaptive-regression/1366-populated-grid.png`,
  `test-results/flutter-adaptive-regression/1600-populated-grid.png`,
  `test-results/flutter-adaptive-regression/2048-populated-grid.png`,
  `test-results/flutter-adaptive-regression/1366-detail.png`,
  `test-results/flutter-adaptive-regression/1600-detail.png`,
  and
  `test-results/flutter-adaptive-regression/2048-detail.png`.
- Commands:
  `pnpm build`,
  `node scripts/capture-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  `node scripts/compare-flutter-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_adaptive_regression.sh`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`.
- Remaining gaps:
  none for the Phase 9 desktop audit.
