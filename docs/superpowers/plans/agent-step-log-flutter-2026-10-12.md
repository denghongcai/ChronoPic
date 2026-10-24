# ChronoPic Flutter Agent Step Log — 2026-10-12 onward

This dated log continues the Flutter execution history after
`agent-step-log-flutter-line.md` exceeded the ~3,000-line rollover threshold.

### 2026-10-12 Step 280 — Photo Metadata Sidecars

- Fixed the contributor-doc drift: `DEVELOPMENT.md` now describes the active
  Flutter workspace, Flutter-specific checks/builds, and the Android/Linux tag
  release workflow instead of stale Electron package versions and commands.
- Added the versioned `chronopic-photo-metadata` JSON contract. Sidecars include
  SHA-256 and byte size for media identity, plus a one-way path fingerprint for
  disambiguating identical files at an unchanged path. They do not store
  absolute paths, generated AI content, settings, Memories, edit history, or
  original photo bytes.
- Added batch export and recursive import in the Flutter app service, with
  temporary-file replacement on export, strict schema/range validation,
  content-hash matching, ambiguity/duplicate refusal, per-file diagnostics,
  existing edit-history updates, and persistence after successful imports.
- Added localized Library Settings actions, operation-in-flight protection,
  and explicit copy that matching imports replace the corresponding catalog
  values. Original media is not modified and EXIF writeback is not included.
- Added domain contract and app-service tests for cross-path round trip,
  invalid-file reporting, SHA mismatch refusal, authored field restoration,
  AI-generated field preservation, persistence across restart, and unchanged
  original bytes.
- Updated `README.md`, `PLAN.md`, and `docs/flutter-refactor-phases.md`; the
  phase plan is
  [2026-10-12-flutter-photo-metadata-sidecars.md](2026-10-12-flutter-photo-metadata-sidecars.md).

Verification:

- From `chronopic_flutter/`, `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_app packages/chronopic_ui apps/chronopic` — clean.
- From `chronopic_flutter/`, `dart test packages/chronopic_ai/test packages/chronopic_app/test packages/chronopic_media/test packages/chronopic_domain/test` — 92 passed.
- From `chronopic_flutter/`, `dart test packages/chronopic_database/test` — 12 passed.
- From `chronopic_flutter/`, `flutter test packages/chronopic_ui/test apps/chronopic/test` — 33 passed.
- From `chronopic_flutter/apps/chronopic/`, `flutter build linux --debug` and `flutter build apk --debug` — built. Android debug build emitted upcoming Gradle/AGP/Kotlin support warnings; it completed successfully.
- Launched the Flutter Linux debug app under `xvfb-run` with an isolated `XDG_DATA_HOME`; it remained running and responsive for 15 seconds. Startup logged the Impeller backend and no application error.
- Scene 7 persistence was covered by app-service restart tests, including imported sidecar data. Electron-specific Playwright scenes were skipped because Electron is reference-only and unchanged; the active Flutter UI, service, build, and launch paths were exercised.
- `git diff --check` — clean.

Next: assess the remaining candidates in `PLAN.md` Active Direction.

### 2026-10-12 Step 281 — Publish v0.1.14

- Confirmed root package version `0.1.14` and Flutter app version
  `0.1.14+14`; created commit `e87e4b0` and annotated tag `v0.1.14`.
- Pushed `main`; CI run `38156987087` passed both `verify` and `flutter` jobs,
  including the Electron reference E2E suites, Dart/Flutter checks, and Android
  debug build.
- Pushed `v0.1.14`; release workflow run `38157340230` passed
  `prepare-release`, `flutter-android`, and `flutter-linux`. Android signed
  APK/AAB artifacts were built and uploaded by CI; Linux release archive and
  checksum were also built and uploaded.
- Verified the public release at
  https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.14:
  it is published (not draft or prerelease) and has all six expected assets.
- Downloaded all six public assets and ran
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`
  with the downloaded artifacts; SHA-256 checksums and Linux archive contents
  passed.
- Updated `README.md`, `DEVELOPMENT.md`, `PLAN.md`, `AGENTS.md`, and Phase 16
  records to identify `v0.1.14` as the current release and sidecar metadata
  portability as complete.

### 2026-10-22 Step 282 — Implement Phase 17 AI Connection Check

- Added a bounded, 8-second authenticated `GET /models` connection check for
  unsaved OpenAI-compatible AI settings. It compares the configured model id,
  limits the response body to 1 MiB, disables redirects, and returns typed
  secret-safe results without photo upload or inference.
- Wired draft settings through the app service without persistence. Settings
  now provides localized success/failure feedback, disables controls in flight,
  clears stale results on edits, and keeps Save independent from Test.
- Added local HTTP transport tests, app-service no-persist and restart tests,
  and Settings widget coverage for success, unauthorized failure, in-flight
  state, stale-result clearing, and separate Save behavior.
- Corrected Flutter Map documentation: the Map surface remains a placeholder;
  saved AMap credentials are not consumed by Flutter.

Verification:

- From `chronopic_flutter/`, `dart test packages/chronopic_ai/test
  packages/chronopic_app/test packages/chronopic_media/test
  packages/chronopic_domain/test packages/chronopic_database/test` — 114 passed.
- From `chronopic_flutter/`, `flutter test packages/chronopic_ui/test
  apps/chronopic/test` — 35 passed.
- From `chronopic_flutter/`, `dart analyze packages/chronopic_ai
  packages/chronopic_app packages/chronopic_ui apps/chronopic` — no issues.
- From `chronopic_flutter/apps/chronopic/`, `flutter build linux --debug` and
  `flutter build apk --debug` — built. Android emitted upcoming Gradle 8.14,
  AGP 8.11.1, and Kotlin 2.2.20 support warnings.
- Scene 7: app-service tests confirm draft checks do not persist and saved AI
  settings survive restart. Scene 8: Settings tests cover success, safe
  unauthorized feedback, in-flight disablement, stale-result clearing, and
  save/test separation.
- Scene 1 was attempted under Xvfb with isolated `XDG_DATA_HOME`. The process
  started and exposed a Dart VM service, but the window remained 10x10 and
  unmapped; the screenshot was black, also with software rendering. The Linux
  first-frame visual check remains open for a desktop-capable session.
- Electron Playwright scenes were skipped because Electron is reference-only.
  Real-provider smoke was skipped because no reachable user endpoint was
  configured; iOS live verification remains blocked on macOS/Xcode.
- `git diff --check` — clean after the documentation update.

Next: verify the Flutter Linux first frame in a desktop-capable session, then
close Phase 17; afterward prioritize Flutter Map browse completion or iOS live
verification.

### 2026-10-25 Step 283 — Publish v0.1.15

- Updated aligned release versions to root `0.1.15` and Flutter app
  `0.1.15+15`; committed Phase 17 as `725b44779a2882358c4c49626112526d0b961cbc`
  and created annotated tag `v0.1.15`.
- Pushed `main` and the release tag. GitHub Release workflow `40124271584`
  completed successfully: `prepare-release`, `flutter-android`, and
  `flutter-linux` passed.
- Verified the public Release is published with all six expected Android/Linux
  assets. Downloaded all assets and ran
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`;
  SHA-256 files and Linux archive contents passed.
- Main CI workflow `40124271598`: Flutter job passed. Electron reference
  `verify` job failed at `Install Playwright browsers`; GitHub's public job
  summary did not expose the underlying download error. The release workflow
  and its Flutter validation/builds passed independently.
- Updated `PLAN.md`, `DEVELOPMENT.md`, and `AGENTS.md` to identify `v0.1.15` as
  the latest verified release. Phase 17 remains active only for the unresolved
  Scene 1 desktop first-frame check; the Xvfb window was unmapped.
- `git diff --check` — clean after this post-release record update.

Next: verify the Linux first frame in a desktop-capable session, close Phase 17,
and then consider Flutter Map browse completion or iOS live verification.
