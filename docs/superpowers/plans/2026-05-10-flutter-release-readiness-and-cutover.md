# Flutter Release Readiness And Cutover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare ChronoPic's Flutter app for release and cutover by hardening Android E2E evidence, proving Electron-backup migration into Flutter, adding Flutter Android/Linux release packaging, and promoting Flutter release gates into CI.

**Architecture:** Treat Flutter as the only release target for Phase 7. Electron remains the reference implementation and migration source, but Electron desktop packages must no longer be produced by the release workflow. Android is the primary executable mobile release target from this Linux workstation, Flutter Linux is the desktop release artifact, and iOS remains a documented macOS/Xcode gate until real Apple-toolchain evidence exists.

**Tech Stack:** Flutter/Dart workspace under `chronopic_flutter/`, Android Gradle project, adb/uiautomator, existing Electron Playwright backup fixtures, GitHub Actions, GitHub Releases, shell scripts, Node verification helpers, and repository docs.

---

## Release Target Decision

- Flutter Android release:
  primary Phase 7 release target.
- Flutter Linux release:
  supported desktop artifact for this repo's current Linux runner.
- Flutter iOS release:
  blocked until macOS/Xcode build/run evidence exists.
- Electron release:
  no new release assets.
  Existing Electron code remains only for reference parity,
  migration fixture generation,
  and backup compatibility checks until cutover is complete.

## Dependency And Action Version Rule

- Before adding or changing any dependency,
  GitHub Action,
  Gradle plugin,
  Flutter SDK pin,
  Android SDK package,
  or release tool,
  verify the current stable version from its official source during implementation.
- Record the checked source and chosen version in `AGENTS.md`.
- Prefer existing pinned repo versions when they are already current and supported.
- Do not introduce unverified marketplace actions or third-party release tools.

## File Structure

- Modify `PLAN.md`
  - Replace the Post 6.6 candidate list with active Phase 7 release readiness.
- Modify `docs/flutter-refactor-phases.md`
  - Rewrite Phase 7 around Flutter-only release and cutover.
- Modify `AGENTS.md`
  - Record the plan and every later implementation slice.
- Modify `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
  - Add stronger logs,
    retry accounting,
    artifact assertions,
    summary JSON,
    and deterministic output directories.
- Create `chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs`
  - Validate Android runner PNG/XML/permission/backup artifacts after each run.
- Create `chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`
  - Run the Android deep E2E script twice from clean state and fail if either run is incomplete.
- Modify `docs/mobile-e2e-verification.md`
  - Record hardened runner behavior and two-run evidence.
- Create `tests/fixtures/flutter-migration/electron-backup-v1.json`
  - Sanitized real Electron backup fixture generated from the Electron app.
- Create `tests/fixtures/flutter-migration/electron-backup-v1.expected.json`
  - Expected counts and key fields for Flutter migration assertions.
- Create `scripts/write-flutter-migration-fixtures.mjs`
  - Deterministically generate or refresh the sanitized Electron backup migration fixture.
- Create `chronopic_flutter/packages/chronopic_app/test/electron_backup_import_test.dart`
  - Verify Flutter can preview and restore the Electron backup fixture.
- Create `docs/flutter-migration-cutover.md`
  - Document the user migration path and the direct-SQLite-import decision.
- Modify `chronopic_flutter/apps/chronopic/android/app/build.gradle.kts`
  - Remove debug-key release signing,
    add secret-safe signing config,
    and keep unsigned/dev behavior explicit.
- Create `chronopic_flutter/apps/chronopic/android/key.properties.example`
  - Document required local release signing fields without secrets.
- Create `chronopic_flutter/tool/release/build_android_release.sh`
  - Build release APK/AAB using local ignored signing config or CI-provided secrets.
- Create `chronopic_flutter/tool/release/build_linux_release.sh`
  - Build and archive the Flutter Linux release bundle.
- Create `chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`
  - Check expected release artifacts and sha256 files exist.
- Create `docs/flutter-release-checklist.md`
  - Record release steps,
    signing,
    privacy disclosures,
    artifact names,
    and blocked iOS requirements.
- Modify `.github/workflows/ci.yml`
  - Add Flutter analyze/test/build gates and remove Electron package-release checks from required CI.
- Modify `.github/workflows/release.yml`
  - Replace Electron desktop release assets with Flutter Android and Flutter Linux assets.
- Modify `README.md`
  - Update release artifact names and state that Flutter is the release line.

## Task 1: Promote Phase 7 To Flutter-Only Release Readiness

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Update `PLAN.md`**

  Add Phase 7 with:

  ```markdown
  ### 7. Flutter Release Readiness And Cutover

  - Implementation plan:
    [docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md](docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md)
  - Scope:
    Android deep E2E runner hardening,
    Electron-backup migration compatibility,
    Flutter Android/Linux release artifacts,
    Flutter CI/release workflow promotion,
    and Flutter-only release documentation.
  - Explicit release decision:
    Flutter is the release target.
    Electron is no longer released;
    it remains only as reference and migration source until cutover is complete.
  ```

- [x] **Step 2: Update `docs/flutter-refactor-phases.md`**

  Rewrite Phase 7 so deliverables are Flutter release deliverables:

  ```markdown
  ## Phase 7: Flutter Release Readiness And Cutover

  Purpose: make the Flutter rewrite shippable without producing new Electron release assets.

  Deliverables:

  - Harden Android deep E2E runner and run two clean emulator passes.
  - Prove Flutter can import sanitized real Electron backup JSON.
  - Add Flutter Android release signing and build release APK/AAB.
  - Add Flutter Linux release build/archive.
  - Promote Flutter gates into CI and tag-triggered release workflows.
  - Document migration, release, privacy, and blocked iOS gates.
  ```

- [x] **Step 3: Record plan in `AGENTS.md`**

  Add a step noting the user selected Android E2E hardening,
  migration/cutover,
  release signing,
  CI promotion,
  and Flutter release.

- [x] **Step 4: Verify docs formatting**

  Run:

  ```bash
  git diff --check
  ```

  Expected: no output.

## Task 2: Harden Android Deep E2E Runner

**Files:**
- Modify: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Create: `chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs`
- Create: `chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Add artifact assertion helper**

  Create `assert_android_deep_e2e_artifacts.mjs` that accepts an output directory
  and verifies:

  - `01-first-run.png` and `.xml` exist.
  - `02-denied.png` and `.xml` exist and XML contains denied recovery copy.
  - `03-full-access.png` and `.xml` exist and XML contains the 2-photo import count.
  - `04-limited-access.png`,
    `.xml`,
    and `04-permissions.txt` exist.
  - `04-permissions.txt` confirms selected access granted and full image access false.
  - `05-restart.png` and `.xml` exist and XML contains `Select`.
  - `06-restore.png`,
    `.xml`,
    and `backup.json` exist.
  - `backup.json` parses and contains exactly 2 photos.

- [x] **Step 2: Harden runner logging and retries**

  Update `android_deep_e2e.sh` to:

  - emit timestamped logs,
  - print device id,
  - print scenario start/end markers,
  - retry `uiautomator dump` with named attempts,
  - fail immediately when a required artifact is missing,
  - place each run under a deterministic run directory,
  - write `summary.json` with scenario names and artifact paths,
  - call `assert_android_deep_e2e_artifacts.mjs` before exit.

- [x] **Step 3: Add two-run wrapper**

  Create `run_android_deep_e2e_twice.sh` that:

  - creates `.tmp/mobile-e2e/android-repeat/<timestamp>/run-1`,
  - creates `.tmp/mobile-e2e/android-repeat/<timestamp>/run-2`,
  - runs `android_deep_e2e.sh` once per directory,
  - calls the artifact assertion helper after each run,
  - writes a combined summary,
  - exits non-zero if either run fails.

- [x] **Step 4: Verify with emulator**

  Run:

  ```bash
  ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh
  ```

  Expected:
  two complete run directories,
  each passing artifact assertion,
  and a combined summary file.

## Task 3: Prove Migration And Cutover Compatibility

**Files:**
- Create: `scripts/write-flutter-migration-fixtures.mjs`
- Create: `tests/fixtures/flutter-migration/electron-backup-v1.json`
- Create: `tests/fixtures/flutter-migration/electron-backup-v1.expected.json`
- Create: `chronopic_flutter/packages/chronopic_app/test/electron_backup_import_test.dart`
- Create: `docs/flutter-migration-cutover.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Generate a sanitized Electron backup fixture**

  Use the Electron backup flow as the source of truth.
  Generate a deterministic backup with:

  ```bash
  pnpm run e2e:backup
  node scripts/write-flutter-migration-fixtures.mjs
  ```

  Expected:
  `tests/fixtures/flutter-migration/electron-backup-v1.json`
  contains no real local secrets,
  no user home paths,
  and includes photos,
  settings,
  edits,
  favorites,
  memories,
  memory membership,
  and generated AI status fields.

- [x] **Step 2: Add Flutter restore test**

  Add a Dart test that loads the fixture through Flutter domain/app code and asserts:

  - preview reports expected photo/memory counts,
  - restore with `replace` succeeds,
  - favorites persist,
  - captions/tags/datetime fields persist,
  - memory metadata and membership persist,
  - locale/settings import as expected,
  - generated semantic state is preserved.

  Run:

  ```bash
  cd chronopic_flutter
  dart test packages/chronopic_app/test/electron_backup_import_test.dart
  ```

- [x] **Step 3: Document migration path**

  Create `docs/flutter-migration-cutover.md` with:

  - user-facing flow:
    export JSON backup from Electron,
    install Flutter release,
    restore JSON backup in Flutter,
    verify counts,
    keep originals in place.
  - unsupported flow:
    direct SQLite import is not required for Phase 7 if backup import passes.
  - fallback:
    keep Electron installed until the backup import has been verified by the user.

## Task 4: Add Flutter Android Release Signing And Distribution Readiness

**Files:**
- Modify: `chronopic_flutter/apps/chronopic/android/app/build.gradle.kts`
- Create: `chronopic_flutter/apps/chronopic/android/key.properties.example`
- Create: `chronopic_flutter/tool/release/build_android_release.sh`
- Create: `chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`
- Create: `docs/flutter-release-checklist.md`
- Modify: `docs/mobile-productization.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Record release identity decision gate**

  Current Android package id is `com.example.chronopic`.
  It is not release-safe.
  Before signing a real production release,
  confirm and record the final Android `applicationId`.

  Until the final id is confirmed,
  release builds may be produced for technical verification only.

- [x] **Step 2: Add secret-safe signing config**

  Update Gradle release signing so:

  - debug signing is not used for release,
  - `android/key.properties` is read when present,
  - CI can provide equivalent values through environment variables,
  - missing signing material fails signed release builds with a clear message,
  - `android/key.properties.example` documents required fields.

- [x] **Step 3: Add Android release script**

  `build_android_release.sh` must:

  - print Flutter and Android tool versions,
  - run `flutter clean` only when explicitly requested through an env flag,
  - run `flutter build apk --release`,
  - run `flutter build appbundle --release`,
  - copy artifacts into `dist/flutter-release/android/`,
  - create `.sha256` files.

- [x] **Step 4: Add privacy and release checklist**

  `docs/flutter-release-checklist.md` must include:

  - Android photo permission rationale,
  - Play Store Data safety notes:
    local photo metadata stays on device,
    no cloud sync,
    no original media upload,
    AI provider use only when configured by user,
  - required manual checks before public release,
  - iOS blocked status.

- [x] **Step 5: Verify release build locally**

  Run:

  ```bash
  cd chronopic_flutter/apps/chronopic
  flutter build apk --release
  flutter build appbundle --release
  ```

  Expected:
  release APK and AAB are created.
  If signing secrets are not available,
  record that the build is unsigned or technically verified only.

## Task 5: Add Flutter Linux Release Artifact

**Files:**
- Create: `chronopic_flutter/tool/release/build_linux_release.sh`
- Modify: `chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`
- Modify: `docs/flutter-release-checklist.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Add Linux release build script**

  The script must:

  - run `flutter build linux --release`,
  - stage `chronopic_flutter/apps/chronopic/build/linux/x64/release/bundle`,
  - archive it as `chronopic-flutter-linux-x64-<version>.tar.gz`,
  - create `.sha256`,
  - write artifacts under `dist/flutter-release/linux/`.

- [x] **Step 2: Verify Linux artifact**

  Run:

  ```bash
  chronopic_flutter/tool/release/build_linux_release.sh
  node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs linux
  ```

  Expected:
  archive exists,
  sha256 exists,
  and executable exists inside the archive.

## Task 6: Promote Flutter Gates Into CI

**Files:**
- Modify: `.github/workflows/ci.yml`
- Add: `.github/workflows/android-deep-e2e.yml`
- Modify: `tests/packaging.test.ts`
- Modify: `docs/flutter-release-checklist.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Verify current stable action versions**

  Before editing workflow versions,
  verify current stable versions from official GitHub release/tag pages for
  each action used or added.
  Record the result in `AGENTS.md`.

- [x] **Step 2: Add Flutter CI job**

  CI must run:

  ```bash
  cd chronopic_flutter
  dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic
  dart test packages/chronopic_media/test packages/chronopic_app/test
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart
  cd apps/chronopic
  flutter build apk --debug
  ```

- [x] **Step 3: Remove Electron package release requirement from CI**

  CI can keep Electron tests while it remains the reference,
  but Electron package verification must not be treated as the release gate.
  Remove or demote:

  - `pnpm run package:linux`
  - `pnpm run package:verify`
  - `pnpm run e2e:packaged`

  from required release readiness.

- [x] **Step 4: Optional manual Android E2E workflow**

  Added:
  `.github/workflows/android-deep-e2e.yml`.
  It is manually triggered with `workflow_dispatch`,
  uses `reactivecircus/android-emulator-runner@v2.37.0`,
  runs `chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`,
  and uploads `.tmp/mobile-e2e/android-repeat/` artifacts with
  `actions/upload-artifact@v7.0.1`.

## Task 7: Replace Tag Release Workflow With Flutter Release

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `docs/flutter-release-checklist.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Remove Electron desktop matrix**

  Delete the Electron `desktop` matrix that builds:

  - Linux Electron artifact,
  - macOS Electron artifact,
  - Windows Electron artifact.

- [x] **Step 2: Add Flutter Android release job**

  The job must:

  - set up Flutter and Java,
  - restore signing material from GitHub Secrets,
  - run Flutter validation,
  - build release APK and AAB,
  - upload APK,
    AAB,
    and sha256 files to the GitHub Release.

- [x] **Step 3: Add Flutter Linux release job**

  The job must:

  - set up Flutter Linux dependencies,
  - run Flutter Linux build,
  - archive the release bundle,
  - upload tarball and sha256 files to the GitHub Release.

- [x] **Step 4: Keep iOS blocked**

  Do not add iOS release upload until macOS/Xcode signing and iOS E2E evidence exist.

## Task 8: Final Release Readiness Gate

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `docs/flutter-migration-cutover.md`
- Modify: `docs/flutter-release-checklist.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Run local final verification**

  Ran:

  ```bash
  pnpm test && pnpm typecheck && pnpm build
  cd chronopic_flutter
  dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic
  dart test packages/chronopic_media/test packages/chronopic_app/test
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart
  cd apps/chronopic
  flutter build apk --debug
  ```

  Result:
  all commands passed.

- [x] **Step 2: Run Android hardening gate**

  Ran:

  ```bash
  ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh
  ```

  Result:
  passed.
  Evidence:
  `.tmp/mobile-e2e/android-repeat/20260510T044545Z/combined-summary.json`
  reports `passed` with both `run-1` and `run-2` passed.
  Independent artifact assertions passed for both run directories.

- [x] **Step 3: Run migration gate**

  Ran:

  ```bash
  cd chronopic_flutter
  dart test packages/chronopic_app/test/electron_backup_import_test.dart
  ```

  Result:
  passed.

- [x] **Step 4: Run release artifact verification**

  Ran:

  ```bash
  CHRONOPIC_ANDROID_STORE_FILE="$PWD/.tmp/release-signing/chronopic-upload.jks" CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh
  chronopic_flutter/tool/release/build_linux_release.sh
  node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux
  git diff --check
  ```

  Result:
  passed.
  Generated artifacts:
  `dist/flutter-release/android/chronopic-flutter-android-release.apk`,
  `dist/flutter-release/android/chronopic-flutter-android-release.aab`,
  `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.4.tar.gz`,
  and matching `.sha256` files.

- [x] **Step 5: Close docs**

  Mark Phase 7 complete only when:

  - Android E2E two-run evidence is recorded,
  - migration fixture and Flutter restore test pass,
  - Android APK/AAB release artifacts exist,
  - Flutter Linux release archive exists,
  - CI/release workflows no longer publish Electron assets,
  - release docs state Flutter-only release clearly,
  - iOS remains accurately blocked until macOS/Xcode evidence exists.

  Result:
  all closeout conditions above are met locally.
