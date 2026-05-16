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

Mobile UI refine evidence is tracked in
[flutter-mobile-ui-refine-audit.md](flutter-mobile-ui-refine-audit.md).

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

Default output now goes under a timestamped deterministic run directory:

```text
.tmp/mobile-e2e/android/<YYYYMMDDTHHMMSSZ>/
```

Set `MOBILE_E2E_OUT_DIR` to pin an exact output directory for CI or release
evidence collection.

Required evidence per run:

- `01-first-run.png`
- `01-first-run.xml`
- `02-denied.png`
- `02-denied.xml`
- `03-full-access.png`
- `03-full-access.xml`
- `04-limited-access.png`
- `04-limited-access.xml`
- `04-permissions.txt`
- `05-restart.png`
- `05-restart.xml`
- `06-restore.png`
- `06-restore.xml`
- `backup.json`
- `summary.json`

The runner writes timestamped logs with the target device id, prints scenario
start/end markers, retries `uiautomator dump` with named attempts, fails on
missing screenshots/XML/permission/backup artifacts, and runs the artifact
assertion helper before exiting.

The assertion helper can also be run directly:

```bash
node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs \
  .tmp/mobile-e2e/android/<run-dir>
```

For release-readiness hardening, run two clean emulator passes:

```bash
ANDROID_DEVICE_ID=emulator-5554 \
  chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh
```

The wrapper writes:

```text
.tmp/mobile-e2e/android-repeat/<YYYYMMDDTHHMMSSZ>/run-1/
.tmp/mobile-e2e/android-repeat/<YYYYMMDDTHHMMSSZ>/run-2/
.tmp/mobile-e2e/android-repeat/<YYYYMMDDTHHMMSSZ>/combined-summary.json
```

Each run clears ChronoPic app/media state before execution, re-runs the single
runner, calls the artifact assertion helper after the run, and fails if either
run is incomplete.

The same hardened two-run gate is also available as a manually triggered GitHub
Actions workflow:

- `.github/workflows/android-deep-e2e.yml`
- Trigger:
  `workflow_dispatch`
- Default API level:
  `36`
- Output:
  uploaded `.tmp/mobile-e2e/android-repeat/` artifacts.

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

2026-05-10 Phase 7 runner hardening result:

- Added:
  `chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs`.
- Added:
  `chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`.
- Hardened:
  `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.
- Static verification passed:
  `bash -n chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`,
  `bash -n chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`,
  and
  `node --check chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs`.
- Artifact helper contract verification passed against a generated temporary
  complete artifact directory.
- Fixed two hardening issues exposed by live emulator execution:
  the runner now waits for `/sdcard/Pictures` to become available before media
  cleanup because software-emulated boot can briefly return
  `Transport endpoint is not connected`,
  and the limited-access transition now retries the
  `ALLOW LIMITED ACCESS` tap until the system Photo Picker is confirmed.
- Live two-run emulator verification passed:
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`.
- Evidence directory:
  `.tmp/mobile-e2e/android-repeat/20260510T044545Z/`.
- Result:
  `combined-summary.json` status is `passed`;
  both `run-1` and `run-2` status values are `passed`.
- Post-run artifact assertions passed for both runs:
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android-repeat/20260510T044545Z/run-1`
  and
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android-repeat/20260510T044545Z/run-2`.
- Evidence count:
  `63` files under `.tmp/mobile-e2e/android-repeat/20260510T044545Z`.

2026-05-10 Phase 10 mobile UI refine result:

- Command:
  `MOBILE_E2E_RUN_ID=phase10-final-browse-state bash chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.
- Result:
  passed.
- Evidence directory:
  `.tmp/mobile-e2e/android/phase10-final-browse-state/`.
- Package id:
  `ai.chronopic.app`.
- Scenarios passed:
  first-run baseline,
  permission-denied recovery,
  full photo-library access,
  limited selected-photo access,
  restart persistence,
  and metadata backup restore.
- Artifact assertion:
  passed as part of the runner and checked the required screenshots,
  XML files,
  permissions dump,
  `backup.json`,
  and `summary.json`.
- Mobile-layout assertion update:
  restart and restore now assert browse-state recovery with `2 items`
  instead of relying on the scroll-dependent `Select` button being visible in
  the first UI dump.
- Screenshot size check:
  all PNG evidence in the run is 1080x2400.

2026-05-11 Phase 11 mobile-native UI result:

- Command:
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`.
- Result:
  passed locally.
- Covered workflow:
  restored mobile browse,
  photo open into focused Detail,
  Gallery open/close,
  favorite toggle,
  caption/tags/datetime edit,
  guided Create Memory wizard,
  add photo to memory,
  set cover,
  rename/description edit,
  remove photo,
  mobile search/filter/sort sheet,
  grouped Settings language drill-in,
  locale persistence,
  backup restore,
  and restart-state persistence.
- Regression fixed during this gate:
  mobile Gallery chrome no longer overflows at phone width,
  and the mobile Language settings drill-in sheet uses stacked controls instead
  of a desktop row.

2026-05-11 Phase 12 large-library count and lazy-thumbnail result:

- Command:
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`.
- Result:
  passed locally.
- Added regression coverage:
  Android deep E2E seeds a 25-photo mobile fixture and asserts the mobile shell
  reports `25 indexed`,
  `25 indexed locally`,
  and `20 loaded / 25 total`,
  while rejecting `20 indexed`.
- Large-library fixture evidence:
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
  includes a 225-photo mobile fixture and asserts `225 indexed`,
  `225 indexed locally`,
  and `20 loaded / 225 total`.
- Scan performance evidence:
  `cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart`
  verifies skipped assets count as processed,
  lazy-capable mobile imports do not read thumbnails during scan,
  and 100-asset progress callbacks are throttled.
- Runtime artifact evidence:
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`
  built `build/app/outputs/flutter-apk/app-debug.apk`.
- Skipped:
  no iOS live evidence is claimed from this Linux workstation.

2026-05-14 Phase 13 mobile real-screenshot UX refinement result:

- Command:
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`.
- Result:
  passed locally with the known `integration_test` plugin warning.
- Updated regression coverage:
  the app-owned mobile integration test still seeds a 25-photo fixture and
  asserts `25 indexed`,
  `20 loaded / 25 total`,
  and rejection of `20 indexed`,
  but now also rejects the repeated `25 indexed locally` scan-card copy.
- Focused widget coverage:
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
  verifies the primary catalog count key,
  mobile bottom navigation and bottom spacer,
  lighter focused Detail mobile actions,
  mobile Gallery action row,
  25-photo fixture count semantics,
  and 225-photo fixture total count semantics.
- Runtime artifact evidence:
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`
  built `build/app/outputs/flutter-apk/app-debug.apk`.
- Skipped:
  no iOS live evidence is claimed from this Linux workstation.

2026-05-15 Phase 14 mobile memory creation completion evidence:

- App-owned mobile integration verifies that the Memories shortcut exposes the
  creation flow after import,
  creates a memory through the sheet,
  edits title/description,
  removes the linked photo,
  and survives the backup/restart path.
- Focused widget coverage verifies:
  photo selection,
  selected count,
  disabled progression with no selected photos,
  title editing,
  optional description editing,
  cover choice,
  confirmation,
  and navigation to the created memory detail page.
- Regression coverage preserves Phase 12/13 scroll/tap behavior:
  dragging inside the mobile creation selector does not open focused Detail.
- Runtime artifact evidence remains:
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`.
- Commands passed:
  `cd chronopic_flutter && flutter analyze`;
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`;
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`;
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`;
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`;
  and `git diff --check`.
- Skipped:
  no iOS live evidence is claimed from this Linux workstation.

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
