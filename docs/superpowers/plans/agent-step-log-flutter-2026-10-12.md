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

Next: finalize the `v0.1.14` version metadata, publish the tag, and record the
tag-release workflow result before updating `AGENTS.md` Current State.
