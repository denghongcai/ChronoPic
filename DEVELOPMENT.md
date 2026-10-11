# ChronoPic Development

This document describes the active Flutter release line. The Electron
implementation remains in the repository as a migration/reference line and is
no longer built or released as the product.

## Repository Status

- Latest verified release: `v0.1.14`
- Flutter workspace: [`chronopic_flutter/`](chronopic_flutter/)
- Runtime/tooling: Flutter stable, Dart 3.13+
- Planning source: [PLAN.md](PLAN.md)
- Active execution log: [docs/superpowers/plans/agent-step-log-flutter-2026-10-12.md](docs/superpowers/plans/agent-step-log-flutter-2026-10-12.md)
- Product verification guidance: [docs/agent-verification-script.md](docs/agent-verification-script.md)

The root `pnpm` workspace still contains the Electron reference app and its
historical tests. Use the Flutter commands below for current product work.

## Setup

```sh
cd chronopic_flutter
flutter pub get
```

## Run And Build

Run the Flutter app for the current host:

```sh
cd chronopic_flutter/apps/chronopic
flutter run -d linux
```

Build desktop or Android debug artifacts:

```sh
cd chronopic_flutter/apps/chronopic
flutter build linux --debug
flutter build apk --debug
```

Android and iOS photo-library access requires the corresponding native
permissions. iOS builds, signing, and live-device verification require
macOS/Xcode.

## Verification

Run from `chronopic_flutter/`:

```sh
dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_app packages/chronopic_ui apps/chronopic
dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test
flutter test packages/chronopic_ui/test apps/chronopic/test
```

The CI gate additionally builds an Android debug APK. After a product phase or
meaningful implementation slice, follow
[docs/agent-verification-script.md](docs/agent-verification-script.md) and
record relevant scenes, checks, and any platform-blocked verification in the
active Flutter step log.

## Backup And Photo Sidecars

Library Settings offers two local JSON portability options:

- **Backup** contains the ChronoPic catalog projection, Memories, settings,
  generated fields, and history. It references original photos by path and does
  not copy media.
- **Photo sidecars** are separate `*.chronopic.json` files for individual
  photos. They contain captions, tags, favorites, and photo metadata, but omit
  settings, Memories, edit history, and AI-generated content. Each sidecar
  identifies its source with the media file's SHA-256 digest and byte size.

Sidecar export writes JSON files into a chosen folder and never modifies
original photos. Import checks SHA-256 before applying metadata; missing and
ambiguous matches and malformed files are reported and skipped. No EXIF
writeback is performed. Import replaces the corresponding catalog metadata on
matched photos.

## Releases

The tag-triggered workflow in
[.github/workflows/release.yml](.github/workflows/release.yml) creates the
GitHub Release and builds Android signed APK/AAB and a Linux x64 tarball. The
workflow uploads SHA-256 checksum files for all artifacts. macOS/iOS and
Windows product artifacts are not currently released.

Release version values are kept aligned in the root `package.json` (used for
Linux archive naming) and `chronopic_flutter/apps/chronopic/pubspec.yaml`.
Both currently identify `v0.1.14`.
After version updates and verification, publish a `v*` tag to run the release
workflow. Confirm its `flutter-android` and `flutter-linux` jobs and verify the
uploaded assets before describing the release as complete.

## Architecture

The Flutter workspace keeps the following boundaries:

- `chronopic_domain`: shared models and portable JSON contracts
- `chronopic_database`: catalog repositories and persistence
- `chronopic_media`: desktop/mobile media-source adapters
- `chronopic_ai`: optional AI provider and normalization
- `chronopic_app`: indexing and application orchestration
- `chronopic_ui`: Flutter surfaces and interactions
- `apps/chronopic`: platform app entry point and native runners

## Planning And Agent Workflow

- [PLAN.md](PLAN.md) is the stable implementation plan and roadmap.
- [AGENTS.md](AGENTS.md) is the current agent instruction and state surface.
- Completed phase plans and full execution history live under
  `docs/superpowers/plans/`.
- [docs/agent-verification-script.md](docs/agent-verification-script.md)
  directs product-level verification after plan items are completed.

When implementation changes a planned phase, update `PLAN.md`, the active step
log, and the Current State section of `AGENTS.md` before considering the work
complete.
