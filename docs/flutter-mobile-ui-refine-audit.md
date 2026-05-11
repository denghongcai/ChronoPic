# Flutter Mobile UI Refine Audit

Date: 2026-05-10
Primary target: Android
iOS status: Blocked until macOS/Xcode live evidence exists
Production Android package id decision: ai.chronopic.app

## Evidence Matrix

| Flow | Evidence | Status | Notes |
| --- | --- | --- | --- |
| First run | `.tmp/mobile-e2e/android/phase10-final-browse-state/01-first-run.png`, `.xml` and `mobile_productization_test.dart` | Fixed | Mobile first-run now prioritizes photo selection and hides desktop add-folder entry |
| Permission denied | `.tmp/mobile-e2e/android/phase10-final-browse-state/02-denied.png`, `.xml` | Matched | Recovery message remains visible |
| Scoped import | `.tmp/mobile-e2e/android/phase10-final-browse-state/03-scope.png`, `.xml`, `04-scope.png`, `.xml` | Matched | Android scope picker shows the fixture album |
| Scan progress | `.tmp/mobile-e2e/android/phase10-final-browse-state/03-full-access.png`, `.xml`, `04-limited-access.png`, `.xml` | Matched | Full and limited scans report imported counts |
| Browse waterfall | `mobile_productization_test.dart`, `.tmp/mobile-e2e/android/phase10-final-browse-state/03-full-access.png` | Fixed | Initial query is 20 items and 25-photo widget fixture lazy-loads to 25 |
| Search/filter/sort | `mobile_productization_test.dart`, Flutter UI test suite | Matched | Mobile browse marker and controls remain present at 390x844 |
| Detail overlay | `mobile_productization_test.dart` | Fixed | Mobile tap opens focused Detail directly with inspector present |
| Gallery overlay | `mobile_productization_test.dart` | Fixed | Mobile Detail exposes the gallery action inside the focused surface |
| Edit metadata | Flutter UI/mobile tests | Matched | Caption/tags/datetime surfaces remain covered in focused Detail flows |
| Favorites | Flutter UI/mobile tests | Matched | Favorite state remains covered by productization tests |
| Memories | `mobile_productization_test.dart`, `.tmp/mobile-e2e/android/phase10-final-browse-state/05-restart.png` | Fixed | Mobile nav shows Memories as a visible top-level action |
| Settings/backup | `.tmp/mobile-e2e/android/phase10-final-browse-state/backup.json`, `summary.json` | Matched | Backup artifact is valid and settings entry remains visible |
| Restart persistence | `.tmp/mobile-e2e/android/phase10-final-browse-state/05-restart.png`, `.xml` | Fixed | Runner now asserts restored browse state via `2 items`, not a scroll-dependent `Select` button |
| Restore backup | `.tmp/mobile-e2e/android/phase10-final-browse-state/06-restore.png`, `.xml`, `backup.json` | Fixed | Restore returns to browse with `2 items` and backup contains 2 photos |

## Phase 11 Mobile-Native Closeout

Date: 2026-05-11

Phase 11 expands this audit from Phase 10 touch polish into a mobile-native
information architecture.

Implemented:

- mobile-specific theme tokens for phone card radius,
  accent color,
  background/surface colors,
  and 48px touch target guidance;
- mobile shell without the old top All Photos / Favorites / Memories /
  Settings tab row;
- bottom navigation for Waterfall,
  Map,
  Timeline,
  and Settings;
- mobile home dashboard with primary search,
  shortcut cards,
  and scan/catalog status;
- filter bottom sheet with tag,
  GPS,
  AI status,
  date,
  sort,
  clear,
  and apply controls;
- mobile active filter chips after applying search/filter/sort state;
- mobile Detail keys for topbar,
  media,
  and action surfaces,
  with desktop shortcut copy removed;
- compact mobile Gallery chrome;
- grouped mobile Settings rows with drill-in sheets;
- guided mobile Create Memory wizard.

Local evidence:

- `cd chronopic_flutter && flutter analyze`
- `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`
- `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`
- `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
- `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
- `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`
- `git diff --check`

Result:
all commands passed locally.
The Android deep E2E widget runner caught and the phase fixed phone-width
horizontal overflow in Gallery chrome and the mobile Language settings sheet.

## iOS Boundary

iOS UI refine cannot be called live-verified from this Linux workstation.
Allowed here:

- static Dart/Flutter UI changes shared with mobile,
- iOS plist/bundle identifier preparation,
- documentation of required screenshots.

Blocked here:

- simulator screenshots,
- iOS permission prompts,
- iOS signing,
- App Store archive validation.

## Closeout Evidence

- Android package id evidence:
  `adb shell pm list packages | rg 'ai\.chronopic\.app'`
  returned `package:ai.chronopic.app`;
  `.tmp/mobile-e2e/android/phase10-final-browse-state/summary.json`
  records `packageName: ai.chronopic.app`.
- Android screenshots/XML:
  `.tmp/mobile-e2e/android/phase10-final-browse-state/*.png`
  and
  `.tmp/mobile-e2e/android/phase10-final-browse-state/*.xml`;
  all PNGs are 1080x2400.
- Android integration test:
  app-owned workflow coverage remains documented in
  `docs/mobile-e2e-verification.md`.
- Android deep E2E:
  `MOBILE_E2E_RUN_ID=phase10-final-browse-state bash chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
  passed and ran the artifact assertion helper.
- Local Flutter verification:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  and
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`
  passed.
- Remaining gaps:
  iOS remains blocked until macOS/Xcode live evidence exists.
