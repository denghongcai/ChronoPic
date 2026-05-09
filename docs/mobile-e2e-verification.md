# Mobile E2E Verification

## Purpose

This document records repeatable mobile end-to-end verification for ChronoPic
after Phase 6 mobile productization and before Phase 7 release/cutover.

## Android Target

- AVD/device: `chronopic_api36` / `emulator-5554`
- Android release: `16`
- API level: `36`
- App build: debug APK from `chronopic_flutter/apps/chronopic`
- Test media fixture:
  two launcher PNG files pushed to `/sdcard/Pictures/ChronoPicDeepE2E`

## Android Required Scenarios

| Scenario | Required Evidence | Status | Notes |
| --- | --- | --- | --- |
| Permission denied recovery | Screenshot and UI text showing recoverable denied state | Passed | `.tmp/mobile-e2e/android/02-denied.png`, `.xml` |
| Limited selected-photo access | Permission dump plus import count | Passed | `.tmp/mobile-e2e/android/04-limited-access.png`, `.xml`, `04-permissions.txt` |
| Full photo-library access | Import count and browse UI after scan | Passed | `.tmp/mobile-e2e/android/03-full-access.png`, `.xml` |
| Restart persistence | Relaunch screenshot showing browse state, not first-run state | Passed | `.tmp/mobile-e2e/android/05-restart.png`, `.xml` |
| Metadata backup restore | Backup JSON summary and relaunch screenshot after restore | Passed | `.tmp/mobile-e2e/android/backup.json`, `06-restore.png`, `.xml` |
| Edit metadata | Caption/tags/datetime changed, persisted after relaunch | Passed | `flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554` |
| Favorite toggle | Favorite state visible and persisted after relaunch | Passed | `flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554` |
| Memory lifecycle | Create memory, add photo, cover, rename/description, remove photo | Passed | `flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554` |
| Detail/gallery overlay | Open detail/gallery from mobile browse and close it | Passed | `flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554` |
| Search/filter/sort | Query/filter result changes visible on mobile layout | Passed | `flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554` |
| Locale/settings persistence | Locale or settings update survives relaunch | Passed | `flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554` |

## iOS Required Scenarios

| Scenario | Required Evidence | Status | Notes |
| --- | --- | --- | --- |
| Photo permission denied | Simulator/device screenshot | Blocked | Requires macOS/Xcode |
| Limited library access | Simulator/device screenshot and import count | Blocked | Requires macOS/Xcode selected-library evidence |
| Full library access | Import count and browse UI | Blocked | Requires macOS/Xcode full-library evidence |
| Restart persistence | Relaunch screenshot | Blocked | Requires macOS/Xcode relaunch evidence |
| Metadata backup restore | Backup JSON summary and relaunch screenshot | Blocked | Requires macOS/Xcode restore evidence |

## Commands

Record exact commands and outputs for every completed scenario.

### Android Runner

```bash
ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

Expected skeleton evidence:

- `.tmp/mobile-e2e/android/01-first-run.png`
- `.tmp/mobile-e2e/android/01-first-run.xml`

2026-05-10 skeleton result:

- Command:
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Result:
  exit 0 after APK build/install,
  two PNG media fixtures pushed,
  app launched,
  first-run evidence captured,
  permission/import/restart/restore scenarios verified,
  and backup JSON validated with 2 photos.
- First-run assertion:
  `01-first-run.xml` contains `Choose Photos`.
- Permission denied assertion:
  `02-denied.xml` contains
  `Photo library permission denied. Open settings to grant access.`
- Full access assertion:
  `03-full-access.xml` contains
  `Photo library scan complete: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing`
- Limited access assertion:
  `04-limited-access.xml` contains
  `Limited photo access: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing`
- Permission dump assertions:
  `04-permissions.txt` contains
  `android.permission.READ_MEDIA_VISUAL_USER_SELECTED: granted=true`
  and
  `android.permission.READ_MEDIA_IMAGES: granted=false`.
- Restart assertion:
  `05-restart.xml` contains `Select`.
- Restore assertion:
  `06-restore.xml` contains `Select` and `2 items`.

### Android App-Owned Integration Test

```bash
cd chronopic_flutter/apps/chronopic
flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554
```

2026-05-10 app-owned workflow result:

- Result:
  `02:25 +1: All tests passed!`
- Coverage:
  restored mobile catalog browse,
  detail overlay open/close,
  gallery overlay open/close,
  favorite persistence,
  caption/tag/datetime edit persistence,
  memory create/add/cover/rename/description/remove,
  search/filter/sort controls,
  locale settings persistence after a restored app instance.
- Red/green defects caught by the integration test:
  card double-tap had to use raw pointer timestamps so selection remains
  immediate and double-tap does not depend on slow device wall-clock timing,
  focused detail needed a narrow-layout branch so mobile close controls remain
  tappable,
  and app startup now loads persisted locale settings rather than only AI/map
  settings.

### Phase 6.5 Closeout Verification

2026-05-10 closeout result:

- `pnpm test`:
  passed, 42 Node tests.
- `pnpm typecheck`:
  passed.
- `pnpm build`:
  passed, Electron renderer bundle emitted.
- `pnpm run e2e:accessibility`:
  passed, 1 Playwright test.
- `pnpm run e2e:runtime`:
  passed, 1 Playwright test.
- `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`:
  passed, 1 Playwright test.
- `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`:
  passed with no issues.
- `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`:
  passed, 16 Dart tests.
- `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`:
  passed, 17 Flutter widget/parity tests.
- `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`:
  passed.
- `cd chronopic_flutter/apps/chronopic && flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554`:
  passed, 1 integration test.
- `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`:
  passed, exit 0.
- Post-run evidence assertions:
  `01-first-run.xml` contains `Choose Photos`,
  `02-denied.xml` contains the denied recovery copy,
  `03-full-access.xml` contains the 2-photo full-access import count,
  `04-limited-access.xml` contains the 2-photo limited-access import count,
  `04-permissions.txt` confirms selected-photo permission granted while full
  image permission is false,
  `05-restart.xml` contains `Select`,
  `06-restore.xml` contains `2 items`,
  and `backup.json` contains exactly 2 photos.

### iOS macOS/Xcode Gate

These commands must be run on macOS with Xcode installed and either an iOS
simulator or a signed physical iOS target:

```bash
cd chronopic_flutter/apps/chronopic
flutter build ios --debug --no-codesign
flutter run -d <ios-device-or-simulator-id>
```

Required evidence before iOS can move out of `Blocked`:

- Photo permission denied:
  simulator/device screenshot showing the recoverable denied state.
- Limited library access:
  simulator/device screenshot and import count after selecting a limited set of
  photos.
- Full library access:
  import count and browse UI after granting full photo-library access.
- Restart persistence:
  relaunch screenshot showing browse state rather than first-run state.
- Metadata backup restore:
  backup JSON summary and relaunch screenshot after restoring that metadata
  backup into a clean app state.

Linux-only static review is not sufficient for iOS completion.
