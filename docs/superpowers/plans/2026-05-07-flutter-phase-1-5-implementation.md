# Flutter Phase 1-5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first Flutter/Dart rewrite line through Phase 5: domain/backup compatibility, Drift persistence, media adapters, indexer/AI services, and a desktop Flutter MVP shell.

**Architecture:** Add a new `chronopic_flutter/` workspace inside the repository while leaving the Electron app as the parity reference. Keep domain, database, media, AI/app services, UI widgets, app shell, and testkit in separate Dart/Flutter packages, with path dependencies and explicit tests for each phase.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Drift, sqlite3, path/path_provider, Flutter widget tests, Dart package tests, committed parity fixtures under `tests/fixtures/flutter-parity/`.

---

## File Structure

- Create `chronopic_flutter/pubspec.yaml`: Flutter/Dart workspace metadata and repo-local path dependency root.
- Create `chronopic_flutter/analysis_options.yaml`: shared Dart analyzer rules.
- Create `chronopic_flutter/packages/chronopic_domain/`: platform-neutral Dart models, backup parsing, backup validation, JSON round trips.
- Create `chronopic_flutter/packages/chronopic_database/`: Drift schema and repository facade.
- Create `chronopic_flutter/packages/chronopic_media/`: media source adapters and fixture/desktop abstractions.
- Create `chronopic_flutter/packages/chronopic_ai/`: disabled and fixture OpenAI-compatible AI pipeline contracts.
- Create `chronopic_flutter/packages/chronopic_app/`: orchestration services for backup restore, scan/indexing, query snapshots, and AI queue state.
- Create `chronopic_flutter/packages/chronopic_ui/`: shared Flutter widgets for MVP desktop surfaces.
- Create `chronopic_flutter/packages/chronopic_testkit/`: fixture paths, synthetic media records, and parity helpers.
- Create `chronopic_flutter/apps/chronopic/`: Flutter desktop app that composes the service layer and UI package.
- Modify `PLAN.md`: mark phases 1-5 complete only after each phase's artifacts and verification land.
- Modify `AGENTS.md`: append a step after each meaningful phase slice with commands run and remaining next work.

## Task 1: Workspace And Phase 1 Domain/Backup Contract

**Files:**
- Create: `chronopic_flutter/pubspec.yaml`
- Create: `chronopic_flutter/analysis_options.yaml`
- Create: `chronopic_flutter/packages/chronopic_domain/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_domain/lib/chronopic_domain.dart`
- Create: `chronopic_flutter/packages/chronopic_domain/lib/src/models.dart`
- Create: `chronopic_flutter/packages/chronopic_domain/lib/src/backup.dart`
- Create: `chronopic_flutter/packages/chronopic_domain/test/backup_contract_test.dart`
- Create: `chronopic_flutter/packages/chronopic_testkit/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_testkit/lib/chronopic_testkit.dart`
- Create: `chronopic_flutter/packages/chronopic_testkit/lib/src/parity_fixtures.dart`

- [x] **Step 1: Scaffold workspace and domain/testkit package manifests.**

Run:

```bash
mkdir -p chronopic_flutter/packages/chronopic_domain/lib/src chronopic_flutter/packages/chronopic_domain/test chronopic_flutter/packages/chronopic_testkit/lib/src
```

Expected: directories exist.

- [x] **Step 2: Write the domain models and backup parser.**

Implement `ChronoPicBackup.fromJson`, `toJson`, `validateChronoPicBackup`, `BackupRestorePreview.fromBackup`, and model types that preserve the Electron fixture field names.

- [x] **Step 3: Write the Phase 1 parity tests.**

Tests must load `../../../tests/fixtures/flutter-parity/chronopic-backup-v1.json` through testkit helpers and assert:

- schema version is `1`
- counts match `chronopic-backup-v1.expected.json`
- authored caption, authored labels, favorite, generated semantic fields, failed AI state, GPS metadata, memory, membership, and memory candidate survive parse and re-emit
- AI settings safety reports present/missing fields without exposing secrets
- filter defaults and JSON round trips are stable

- [x] **Step 4: Run Phase 1 verification.**

Run:

```bash
cd chronopic_flutter
dart test packages/chronopic_domain
dart analyze packages/chronopic_domain packages/chronopic_testkit
```

Expected: all tests pass and analyzer reports no issues.

## Task 2: Phase 2 Drift Database And Repositories

**Files:**
- Create: `chronopic_flutter/packages/chronopic_database/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_database/lib/chronopic_database.dart`
- Create: `chronopic_flutter/packages/chronopic_database/lib/src/database.dart`
- Create: `chronopic_flutter/packages/chronopic_database/lib/src/repository.dart`
- Create: `chronopic_flutter/packages/chronopic_database/test/repository_test.dart`

- [x] **Step 1: Add Drift dependencies and database schema.**

Use Drift tables for `library_sources`, `photos`, `metadata`, `semantic`, `index_state`, `edit_history`, `memories`, `memory_photos`, and `memory_candidates`. Use schema version `1` for the Flutter rewrite.

- [x] **Step 2: Implement repository facade.**

Provide `restoreBackup`, `createBackup`, `previewBackupRestore`, `listPhotos`, `getPhoto`, `updatePhotoCaption`, `updatePhotoTags`, `updatePhotoFavorite`, `createMemory`, `addPhotoToMemory`, `listPhotosByMemory`, and `listMemoryCandidates`.

- [x] **Step 3: Write repository parity tests.**

Tests restore the Phase 0 fixture into an in-memory Drift database, export it again, and compare expected counts plus authored/generated critical fields.

- [x] **Step 4: Generate Drift code and verify.**

Run:

```bash
cd chronopic_flutter/packages/chronopic_database
dart run build_runner build --delete-conflicting-outputs
dart test
dart analyze
```

Expected: generated code is up to date, tests pass, analyzer reports no issues.

## Task 3: Phase 3 Media Source Abstraction

**Files:**
- Create: `chronopic_flutter/packages/chronopic_media/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_media/lib/chronopic_media.dart`
- Create: `chronopic_flutter/packages/chronopic_media/lib/src/media_source.dart`
- Create: `chronopic_flutter/packages/chronopic_media/lib/src/fixture_media_source.dart`
- Create: `chronopic_flutter/packages/chronopic_media/lib/src/desktop_directory_media_source.dart`
- Create: `chronopic_flutter/packages/chronopic_media/test/media_source_test.dart`

- [x] **Step 1: Define media source contracts.**

Create `MediaSourceAdapter`, `MediaAsset`, `MediaAssetMetadata`, `MediaReadResult`, `MediaSourceException`, and `MediaSourcePermissionState`.

- [x] **Step 2: Implement fixture and desktop directory adapters.**

The fixture adapter returns deterministic assets for tests. The desktop adapter recursively lists supported files and reports missing assets by path.

- [x] **Step 3: Write adapter tests.**

Tests cover listing assets, reading bytes, stat metadata, unsupported file filtering, missing file state, and permission-denied simulation.

- [x] **Step 4: Run Phase 3 verification.**

Run:

```bash
cd chronopic_flutter
dart test packages/chronopic_media
dart analyze packages/chronopic_media
```

Expected: all tests pass and analyzer reports no issues.

## Task 4: Phase 4 Indexer And AI Pipeline

**Files:**
- Create: `chronopic_flutter/packages/chronopic_ai/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_ai/lib/chronopic_ai.dart`
- Create: `chronopic_flutter/packages/chronopic_ai/lib/src/ai_client.dart`
- Create: `chronopic_flutter/packages/chronopic_app/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_app/lib/chronopic_app.dart`
- Create: `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`
- Create: `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`
- Create: `chronopic_flutter/packages/chronopic_app/test/indexer_service_test.dart`
- Create: `chronopic_flutter/packages/chronopic_app/test/app_service_test.dart`

- [x] **Step 1: Define AI client contracts.**

Provide disabled, fixture-success, and fixture-failure clients with statuses matching the Electron domain: `disabled`, `pending`, `processing`, `completed`, and `failed`.

- [x] **Step 2: Implement app/indexer service.**

The first service implementation consumes a `MediaSourceAdapter`, writes records into the Drift repository, skips unchanged assets by source timestamp/hash-like stable key, marks missing assets, and exposes backup/restore orchestration.

- [x] **Step 3: Write service tests.**

Tests cover unchanged files, modified files, missing files, duplicate stable IDs, failed metadata extraction, disabled AI, failed AI, and successful enrichment.

- [x] **Step 4: Run Phase 4 verification.**

Run:

```bash
cd chronopic_flutter
dart test packages/chronopic_ai packages/chronopic_app
dart analyze packages/chronopic_ai packages/chronopic_app
```

Expected: all tests pass and analyzer reports no issues.

## Task 5: Phase 5 Flutter Desktop MVP

**Files:**
- Create: `chronopic_flutter/packages/chronopic_ui/pubspec.yaml`
- Create: `chronopic_flutter/packages/chronopic_ui/lib/chronopic_ui.dart`
- Create: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Create: `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
- Create: `chronopic_flutter/apps/chronopic/pubspec.yaml`
- Create: `chronopic_flutter/apps/chronopic/lib/main.dart`
- Create: `chronopic_flutter/apps/chronopic/test/widget_test.dart`

- [x] **Step 1: Scaffold Flutter app and UI package.**

Use `flutter create --platforms=linux` for the app, then keep UI widgets in `packages/chronopic_ui`.

- [x] **Step 2: Implement desktop MVP shell.**

The shell must render first-run/library settings, scan progress, gallery grid, search/filter controls, detail/gallery placeholder surfaces, edit controls, favorites, memories, and backup/restore actions backed by the Dart app service.

- [x] **Step 3: Write widget tests.**

Widget tests verify app title, library setup CTA, scan action, visible grid, search/filter controls, detail surface, favorites/memories controls, and backup/restore controls.

- [x] **Step 4: Run Phase 5 verification.**

Run:

```bash
cd chronopic_flutter
flutter test packages/chronopic_ui apps/chronopic
flutter analyze packages/chronopic_ui apps/chronopic
flutter build linux --debug -v
```

Expected: widget tests and analyzer pass, Linux debug desktop build completes.

## Task 6: Final Phase 1-5 Audit And Repo Records

**Files:**
- Modify: `PLAN.md`
- Modify: `AGENTS.md`
- Modify: `docs/flutter-refactor-phases.md`

- [x] **Step 1: Update `PLAN.md`.**

Mark Phase 1 through Phase 5 complete only if their exact verification commands pass.

- [x] **Step 2: Update `AGENTS.md`.**

Record one step per completed phase, with what changed, why, verification commands, and remaining next work.

- [x] **Step 3: Run final verification.**

Run:

```bash
git diff --check
cd chronopic_flutter
dart test packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app
flutter test packages/chronopic_ui apps/chronopic
dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit
flutter analyze packages/chronopic_ui apps/chronopic
flutter build linux --debug
```

Expected: all commands pass.
