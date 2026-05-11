# Mobile Productization

## Toolchain Snapshot

Captured on 2026-05-09 during Phase 6 Task 1.

### Flutter Doctor

- Flutter:
  stable `3.41.9` at `/home/dhc/.local/share/flutter`.
- Dart:
  `3.11.5`.
- Host:
  Ubuntu 22.04.5 LTS under WSL2.
- Linux desktop:
  available and healthy.
- Android toolchain:
  Android SDK detected at `/usr/lib/android-sdk`,
  but `cmdline-tools` is missing.
  Android build/smoke cannot be marked complete until command-line tools,
  licenses,
  and an emulator or device are available.
  This Task 1 snapshot was superseded by the user-state Android SDK setup
  recorded in the Android Build Gate section below.
- iOS:
  enabled in Flutter feature flags,
  but this Linux workstation cannot run Xcode,
  iOS simulators,
  or iOS device signing.
  iOS runner files can be scaffolded and statically reviewed here only.
- Chrome/web:
  Chrome executable is missing.
  Web is not part of Phase 6 mobile exit criteria.

### Devices

- Available:
  `Linux (desktop)`.
- Missing:
  Android emulator or physical Android device.
- Not available on this host:
  iOS simulator or iOS physical-device signing.

## Platform Scaffolding

- Android runner:
  `chronopic_flutter/apps/chronopic/android/`.
- iOS runner:
  `chronopic_flutter/apps/chronopic/ios/`.
- Existing app source preserved:
  `chronopic_flutter/apps/chronopic/lib/main.dart`
  still launches `ChronoPicHome`.

## Permission Declarations

Android permissions configured in
`chronopic_flutter/apps/chronopic/android/app/src/main/AndroidManifest.xml`:

- `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"`.
- `READ_MEDIA_IMAGES`.
- `READ_MEDIA_VIDEO`.
- `READ_MEDIA_VISUAL_USER_SELECTED`.

iOS usage descriptions configured in
`chronopic_flutter/apps/chronopic/ios/Runner/Info.plist`:

- `NSPhotoLibraryUsageDescription`.
- `NSPhotoLibraryAddUsageDescription`.

The iOS add-usage description explicitly does not claim that ChronoPic writes
or copies original media files.

## Android Build Gate

Captured on 2026-05-09 during Phase 6 Task 5.

### User-State Tooling

- Installed Temurin JDK `17.0.19+10` under:
  `/home/dhc/.local/share/jdks/temurin-17`.
- Configured Flutter to use that JDK with:
  `flutter config --jdk-dir=/home/dhc/.local/share/jdks/temurin-17`.
- Installed Android command-line tools from Google's current Linux package:
  `commandlinetools-linux-14742923_latest.zip`.
- Installed user-state Android SDK packages under:
  `/home/dhc/.local/share/android-sdk`.
- Configured Flutter to use that SDK with:
  `flutter config --android-sdk=/home/dhc/.local/share/android-sdk`.
- Installed SDK contents:
  `platform-tools`,
  `platforms;android-36`,
  `build-tools;36.0.0`,
  `build-tools;35.0.0`,
  and `ndk;28.2.13676358`.
- Android SDK licenses are accepted in the user-state SDK.

### Doctor And Device State

- `flutter doctor -v` confirms the Android toolchain is healthy with
  Android SDK version `36.0.0`,
  platform `android-36`,
  build-tools `36.0.0`,
  Java `/home/dhc/.local/share/jdks/temurin-17/bin/java`,
  and accepted Android licenses.
- `flutter devices` now lists:
  `Android SDK built for x86 64 (mobile) • emulator-5554 • android-x64 • Android 16 (API 36) (emulator)`,
  and `Linux (desktop)`.
- Android emulator used for smoke:
  AVD `chronopic_api36`,
  API `36`,
  model `Android SDK built for x86_64`,
  Android release `16`,
  boot property `sys.boot_completed=1`.

### APK Build

Command:

```bash
cd chronopic_flutter/apps/chronopic
flutter build apk --debug
```

Result:

- Passed.
- Output:
  `chronopic_flutter/apps/chronopic/build/app/outputs/flutter-apk/app-debug.apk`.
- Artifact size on this workstation after the emulator-smoke fix:
  `163M`.

### Android Device Smoke

Status:

- Passed on the local Android emulator.

Device:

- `emulator-5554`
- Model:
  `Android SDK built for x86_64`
- Android:
  `16`
- API:
  `36`

Smoke evidence:

- Denied permission:
  tapping `Choose Photos`,
  then `DON'T ALLOW`,
  shows
  `Photo library permission denied. Open settings to grant access.`
- Full access:
  two PNG assets were pushed under
  `/sdcard/Pictures/ChronoPicSmoke`,
  media-scanned,
  then imported after `ALLOW ALL`;
  result:
  `Photo library scan complete: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing`.
- Limited access:
  after clearing app data,
  `ALLOW LIMITED ACCESS` opened Android's selected-photo picker;
  selecting both smoke photos and tapping `Allow (2)` produced:
  `Limited photo access: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing`.
  Permission state confirmed with
  `READ_MEDIA_VISUAL_USER_SELECTED=true`,
  `READ_MEDIA_IMAGES=false`,
  and `READ_MEDIA_VIDEO=false`.
- Restart persistence:
  after `adb shell am force-stop ai.chronopic.app` and relaunch,
  the app returned to the existing browse surface with the `Select` action
  instead of the first-run-only state.
- Backup restore:
  the automatic metadata backup at
  `/data/user/0/ai.chronopic.app/code_cache/.local/share/chronopic_flutter/chronopic-backup.json`
  contained `2` photos and `1` library source.
  After clearing app data,
  injecting that JSON back into the default backup path,
  and relaunching,
  the app again returned to the existing browse surface.

Implementation note:

- The first full-access emulator scan exposed Android thumbnail decode failures
  as `0 imported, 2 errors`.
  The fix keeps Android asset entities cached across list/read calls,
  falls back from empty `originBytes` to file bytes,
  surfaces the last scan error,
  and treats thumbnail decode failures as a missing thumbnail rather than an
  import failure.

## Android Release Readiness

Captured on 2026-05-10 during Phase 7 Task 4.

- Android `applicationId`:
  `ai.chronopic.app`.
- Release signing now reads local ignored
  `chronopic_flutter/apps/chronopic/android/key.properties`
  or CI environment variables:
  `CHRONOPIC_ANDROID_STORE_FILE`,
  `CHRONOPIC_ANDROID_STORE_PASSWORD`,
  `CHRONOPIC_ANDROID_KEY_ALIAS`,
  and
  `CHRONOPIC_ANDROID_KEY_PASSWORD`.
- Release builds no longer use the debug signing config.
- Missing release signing material fails `assembleRelease` / `bundleRelease`
  with a clear message,
  while debug APK builds remain unaffected.
- Technical local release verification used a temporary upload keystore under
  `.tmp/release-signing/`.
  The keystore and signing secrets are not committed.
- Android release command:

  ```bash
  chronopic_flutter/tool/release/build_android_release.sh
  ```

## Phase 11 Mobile-Native UI Contract

Captured on 2026-05-11 during Phase 11.

- Android mobile may diverge from the Linux desktop visual layout and
  interaction structure while preserving the same local-first data,
  backup,
  media scan,
  memory,
  AI readiness,
  and persistence contracts.
- Mobile uses a phone-specific shell:
  compact brand/notification header,
  prominent home search,
  horizontal shortcut cards,
  scan/catalog status,
  and bottom navigation for Waterfall,
  Map,
  Timeline,
  and Settings.
- Dense browse controls use a bottom sheet on mobile rather than a squeezed
  desktop toolbar.
- Mobile Detail and Gallery should avoid desktop keyboard shortcut copy.
- Settings uses grouped rows and drill-in sheets for complex controls.
- Create Memory starts with a guided mobile wizard and then opens the existing
  memory detail lifecycle for description,
  cover,
  add/remove photo,
  rename,
  and persistence.

Local Phase 11 gate:

```bash
cd chronopic_flutter && flutter analyze
cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test
cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart
cd chronopic_flutter/apps/chronopic && flutter build apk --debug
git diff --check
```

Result:
all commands passed locally.
iOS live verification remains blocked until macOS/Xcode evidence exists.

## Phase 10 Mobile UI Refine Evidence

Captured on 2026-05-10 after the Android package id moved to
`ai.chronopic.app`.

- Final Android deep E2E command:

  ```bash
  MOBILE_E2E_RUN_ID=phase10-final-browse-state \
    chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
  ```

- Result:
  passed.
- Evidence directory:
  `.tmp/mobile-e2e/android/phase10-final-browse-state/`.
- Runner summary:
  `summary.json` reports `status: passed` and
  `packageName: ai.chronopic.app`.
- Installed package check:
  `adb shell pm list packages | rg 'ai\.chronopic\.app'`
  returned `package:ai.chronopic.app`.
- Covered scenarios:
  first-run baseline,
  permission denied recovery,
  full photo-library access,
  limited selected-photo access,
  restart persistence,
  and metadata backup restore.
- Mobile UI refine matrix:
  [flutter-mobile-ui-refine-audit.md](flutter-mobile-ui-refine-audit.md).

- Artifact verification command:

  ```bash
  node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs
  ```

- Verified artifacts:
  `dist/flutter-release/android/chronopic-flutter-android-release.apk`,
  `dist/flutter-release/android/chronopic-flutter-android-release.apk.sha256`,
  `dist/flutter-release/android/chronopic-flutter-android-release.aab`,
  and
  `dist/flutter-release/android/chronopic-flutter-android-release.aab.sha256`.
- Photo permission and Play Data safety notes are recorded in
  `docs/flutter-release-checklist.md`.

## Phase 6 Closeout Gate

Captured on 2026-05-09.

Electron reference/runtime gates:

- `pnpm test`: passed.
- `pnpm typecheck`: passed.
- `pnpm build`: passed.
- `pnpm run e2e:accessibility`: passed.
- `pnpm run e2e:runtime`: passed.
- `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`:
  passed.

Flutter package/UI gates:

- `dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`:
  passed.
- `dart test packages/chronopic_media/test packages/chronopic_app/test`:
  passed.
- `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`:
  passed.

Mobile platform gates:

- `flutter build apk --debug`:
  passed.
- `flutter devices`:
  lists `emulator-5554` and `Linux (desktop)`.
- Android emulator smoke:
  denied permission,
  limited selected-photo access,
  full access import,
  restart persistence,
  and metadata backup restore passed on `emulator-5554`.
- iOS run/build:
  not run because this Linux workstation cannot provide Xcode,
  iOS simulators,
  or iOS signing.

## iOS Verification Constraint

Static review on 2026-05-09:

- `chronopic_flutter/apps/chronopic/ios/Runner/Info.plist` contains
  `NSPhotoLibraryUsageDescription`.
- `chronopic_flutter/apps/chronopic/ios/Runner/Info.plist` contains
  `NSPhotoLibraryAddUsageDescription`.
- The add/write usage text says ChronoPic does not write originals.

This Linux workstation cannot run Xcode, iOS simulators, or iOS real-device
signing. Phase 6 may scaffold iOS metadata and shared Dart code here, but the
iOS exit gate requires a macOS/Xcode run that executes:

```bash
cd chronopic_flutter/apps/chronopic
flutter build ios --debug --no-codesign
flutter run -d <ios-device-id>
```

## iOS Deep E2E Gate

Recorded on 2026-05-10 during Phase 6.5.

Status:

- Blocked on this Linux workstation.
- Requires macOS with Xcode and either an iOS simulator or signed physical iOS
  target.
- Must not be marked complete from Android, Linux desktop, or static iOS file
  evidence.

Required commands:

```bash
cd chronopic_flutter/apps/chronopic
flutter build ios --debug --no-codesign
flutter run -d <ios-device-or-simulator-id>
```

Required evidence:

- Photo permission denied screenshot showing the recoverable denied state.
- Limited library access screenshot plus import count after selecting a limited
  set of photos.
- Full library access import count plus browse UI after granting full access.
- Restart persistence relaunch screenshot showing browse state rather than the
  first-run state.
- Metadata backup restore JSON summary plus relaunch screenshot after restoring
  that backup into a clean app state.
