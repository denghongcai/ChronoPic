# Flutter Release Checklist

## Release Line

- Flutter is the Phase 7 release target.
- Electron is not released as a new artifact.
  Keep Electron only as parity reference and migration/backup source until
  cutover is complete.
- Android is the primary mobile release target from this Linux environment.
- Linux desktop is the Flutter desktop release target from this Linux
  environment.
- iOS remains blocked until macOS/Xcode signing,
  build,
  and E2E evidence exist.

## Version And Source Checks

Checked on 2026-05-10:

- Flutter official Android deployment documentation:
  <https://docs.flutter.dev/deployment/android>
  - App Bundle is the preferred Play Store release format.
  - `flutter build appbundle` emits
    `build/app/outputs/bundle/release/app-release.aab`.
  - Flutter documents `android/key.properties` as the local signing-config
    file pattern.
- Android official app-signing documentation:
  <https://developer.android.com/studio/publish/app-signing>
  - APKs must be digitally signed before install/update.
  - Android App Bundles uploaded to Google Play must be signed with an upload
    key before Play App Signing handles final distribution.
- Google Play Photo and Video Permissions policy:
  <https://support.google.com/googleplay/android-developer/answer/14115180>
  - Broad photo/video access must be tied to core app functionality.
  - One-time or infrequent access should use a system picker instead.
- Google Play Data safety documentation:
  <https://support.google.com/googleplay/android-developer/answer/10787469>
  - Published apps must complete the Data safety form.
  - The app must declare whether it collects or shares user data.

## Android Identity Gate

Production package id:

```text
ai.chronopic.app
```

Before production upload:

- Confirm the `applicationId` is still `ai.chronopic.app`.
- Confirm app name,
  Play Console app ownership,
  and Play App Signing setup.
- Generate or register the real upload key.
- Rebuild and rerun the Android release gate.

## Android Signing

Local signed release builds read:

```text
chronopic_flutter/apps/chronopic/android/key.properties
```

That file is ignored by git.
Use `key.properties.example` as the template.

CI may instead provide:

```text
CHRONOPIC_ANDROID_STORE_FILE
CHRONOPIC_ANDROID_STORE_PASSWORD
CHRONOPIC_ANDROID_KEY_ALIAS
CHRONOPIC_ANDROID_KEY_PASSWORD
```

Missing signing material must fail release APK/AAB builds.
Debug signing is not used for release.

## Android Release Build

```bash
chronopic_flutter/tool/release/build_android_release.sh
node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android
```

Expected artifacts:

- `dist/flutter-release/android/chronopic-flutter-android-release.apk`
- `dist/flutter-release/android/chronopic-flutter-android-release.apk.sha256`
- `dist/flutter-release/android/chronopic-flutter-android-release.aab`
- `dist/flutter-release/android/chronopic-flutter-android-release.aab.sha256`

## Linux Release Build

```bash
chronopic_flutter/tool/release/build_linux_release.sh
node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs linux
```

Expected artifacts for version `0.1.7`:

- `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.7.tar.gz`
- `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.7.tar.gz.sha256`

The verifier checks the archive checksum and confirms that the archive contains
the `chronopic` executable.

To verify both current Flutter release targets together:

```bash
node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux
```

2026-05-10 local release verification passed with:

```bash
CHRONOPIC_ANDROID_STORE_FILE="$PWD/.tmp/release-signing/chronopic-upload.jks" CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh
chronopic_flutter/tool/release/build_linux_release.sh
node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux
```

Verified artifact sizes:

- Android APK:
  `56M`
- Android AAB:
  `47M`
- Linux tarball:
  `20M`

## CI Gates

Phase 7 CI keeps Electron runtime/E2E checks while Electron remains the
reference implementation,
but Electron package creation is no longer a release-readiness gate.

CI now has a separate Flutter job that runs:

```bash
cd chronopic_flutter
dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic
dart test packages/chronopic_media/test packages/chronopic_app/test
flutter test \
  packages/chronopic_ui/test/chronopic_home_test.dart \
  packages/chronopic_ui/test/linux_desktop_parity_test.dart \
  packages/chronopic_ui/test/mobile_productization_test.dart
cd apps/chronopic
flutter build apk --debug
```

The workflow clones Flutter from the official stable branch instead of adding a
third-party Flutter setup action.
It uses `actions/setup-java@v5` with Temurin 17 for Android builds.

Android deep E2E is available as both a local gate and a manually triggered
GitHub Actions gate for Phase 7.

Manual workflow:

- `.github/workflows/android-deep-e2e.yml`
- Trigger:
  `workflow_dispatch`
- Default emulator API:
  `36`
- Runner action:
  `reactivecircus/android-emulator-runner@v2.37.0`
- Artifact upload action:
  `actions/upload-artifact@v7.0.1`

```bash
ANDROID_DEVICE_ID=emulator-5554 \
  chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh
```

This avoids making every CI run pay for a full emulator permission/photo-picker
workflow while still preserving a repeatable manual CI path and the stronger
pre-release local evidence.

## Tag Release Workflow

`.github/workflows/release.yml` now publishes Flutter artifacts only.

Release jobs:

- `prepare-release`:
  creates or updates the GitHub Release for the pushed tag.
- `flutter-android`:
  sets up Java with `actions/setup-java@v5`,
  clones Flutter from the official stable branch,
  runs Flutter validation,
  restores signing material from GitHub Secrets,
  builds signed APK/AAB artifacts,
  verifies sha256 files,
  and uploads Android assets.
- `flutter-linux`:
  installs Linux build dependencies,
  clones Flutter from the official stable branch,
  builds the Linux release tarball,
  verifies the archive and sha256 file,
  and uploads Linux assets.

Required Android release secrets:

- `CHRONOPIC_ANDROID_KEYSTORE_BASE64`
- `CHRONOPIC_ANDROID_STORE_PASSWORD`
- `CHRONOPIC_ANDROID_KEY_ALIAS`
- `CHRONOPIC_ANDROID_KEY_PASSWORD`

`v0.1.4` note:
the tag-triggered Linux release job succeeded,
but the Android release job failed because the four Android signing secrets
above were not configured in GitHub Actions.
The Android APK/AAB assets for `v0.1.4` were uploaded manually from the local
signed release build after local artifact verification.
The secrets above were configured after the `v0.1.4` publication on
2026-05-10,
so the next tag release can use the automated Android release job.
Do not rely on the failed `v0.1.4` Android job itself as automation evidence;
validate the next tag-triggered Android job end to end.

`v0.1.5` note:
the tag-triggered Release workflow started as `startup_failure` with no jobs or
logs,
and the `main` CI run for the same commit also started as `startup_failure`.
The workflow files were unchanged from the last successful CI release-prep
state,
so `v0.1.5` was published manually from locally verified Flutter Android/Linux
artifacts.
Post-publication verification downloaded the GitHub Release assets,
checked all three sha256 files,
and confirmed the Linux tarball contains the `chronopic` executable.

`v0.1.6` note:
the tag-triggered Release workflow again completed as `startup_failure` before
jobs were scheduled.
`v0.1.6` was published manually from locally rebuilt and verified Flutter
Android/Linux artifacts.
Post-publication verification downloaded the GitHub Release assets,
checked all three sha256 files,
and confirmed the Linux tarball contains the `chronopic` executable.

The release workflow does not build or upload Electron Linux,
macOS,
or Windows assets.
It does not upload iOS assets until the macOS/Xcode signing and iOS E2E gate is
closed.

## Photo Permission Rationale

ChronoPic is a local-first photo manager.
The core workflow is repeated browsing,
indexing,
metadata editing,
favorites,
memories,
and restore of a local photo library.
That makes persistent or frequent photo access core functionality.

The app should still preserve the Android selected-photo flow:

- Denied permission must be recoverable.
- Limited selected-photo access must work.
- Full photo-library access must import the expected local media.
- Runtime permission state must be covered by Android E2E evidence.

## Play Data Safety Notes

Current Phase 7 declaration basis:

- Photo and video metadata is processed locally.
- Backup JSON is local and user-controlled.
- No cloud sync is implemented.
- No app server upload is implemented.
- No third-party analytics SDK is present in the Flutter release line.
- User photo library access is used for app functionality:
  browsing,
  indexing,
  metadata,
  favorites,
  memories,
  and local backup/restore.

Before Play submission:

- Complete the Play Data safety form for the final package id.
- Provide a privacy policy URL.
- Re-check all Flutter dependencies and SDKs for any data collection behavior.
- Submit the photo/video permissions declaration if broad media permissions
  remain in the manifest.
