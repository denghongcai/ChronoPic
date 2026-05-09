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

## iOS Verification Constraint

This Linux workstation cannot run Xcode, iOS simulators, or iOS real-device
signing. Phase 6 may scaffold iOS metadata and shared Dart code here, but the
iOS exit gate requires a macOS/Xcode run that executes:

```bash
cd chronopic_flutter/apps/chronopic
flutter build ios --debug --no-codesign
flutter run -d <ios-device-id>
```
