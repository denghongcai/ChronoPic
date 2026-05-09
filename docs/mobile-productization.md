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
- `flutter devices` still lists only:
  `Linux (desktop)`.
- No Android emulator or physical Android device is currently connected.

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
- Artifact size on this workstation:
  `146M`.

### Android Device Smoke

Status:

- Blocked.

Reason:

- No Android emulator or physical Android device is listed by `flutter devices`.

Unverified until an Android device is available:

- Android device model/API level.
- Denied photo-permission recovery UI on a real device.
- Selected-photo limited-access UI on a real device.
- Full photo-library scan on a real device.
- Restart persistence on Android.
- Backup export/restore on Android.
- Indexed asset count from Android photo-library import.

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
  only `Linux (desktop)` is connected.
- `flutter run -d <android-device-id>`:
  not run because no Android emulator or physical device is connected.
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
