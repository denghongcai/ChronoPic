# Flutter Linux Desktop Parity Phase 5.5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter Linux desktop app exercise real local-first desktop workflows before Android/iOS productization starts.

**Architecture:** Keep Electron as the reference implementation, but add a Linux-first parity gate in the Flutter workspace. The current slices make the Flutter desktop UI drive the Dart service layer for real directory scans, persisted local catalog state, edit history, favorites, memories, and backup/restore smoke coverage.

**Tech Stack:** Flutter 3.41.9 stable, Dart 3.11.5, existing Dart workspace packages, `flutter_test`, `test`, `dart:io` desktop directory fixtures.

**Scope note:** This plan records the first executable Linux desktop parity slice. Full Electron parity still requires the remaining Phase 5.5 gaps listed at the end of this file.

---

## File Structure

- Modify `docs/flutter-refactor-phases.md`: insert Phase 5.5 before mobile Phase 6.
- Modify `PLAN.md`: record Phase 5.5 as the active desktop parity gate.
- Modify `chronopic_flutter/packages/chronopic_database/lib/src/repository.dart`: add incremental upsert, edit history, rollback, memory listing, and source tracking.
- Modify `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`: stop restoring one-asset backups during scans; upsert records instead.
- Modify `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`: expose Linux desktop scan and parity actions.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`: wire desktop controls to real service methods.
- Add `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`: widget-level E2E over a temp Linux fixture directory.
- Modify existing package tests where behavior changes.
- Modify `AGENTS.md`: record implementation and verification.

## Task 1: Document Phase 5.5 Gate

- [x] **Step 1: Add Phase 5.5 to the Flutter refactor plan.**

Define the gate as Linux desktop feature parity before mobile work.

- [x] **Step 2: Add Phase 5.5 to `PLAN.md`.**

Record expected deliverables and verification commands.

## Task 2: Make The Service Layer Incremental

- [x] **Step 1: Add repository methods.**

Add `upsertPhotoRecord`, `listLibrarySources`, `upsertLibrarySource`, `listMemories`, `rollbackLatestEdit`, and memory membership helpers.

- [x] **Step 2: Fix indexing to upsert records.**

`ChronoPicIndexerService.scanLibrary()` must not clear the repository while importing multiple files.

- [x] **Step 3: Add app service desktop scan actions.**

Expose `scanDesktopDirectory`, memory actions, backup actions, edit actions, and rollback through `ChronoPicAppService`.

- [x] **Step 4: Add default desktop persistence.**

Default Flutter desktop startup should load and save local app state through the existing backup JSON contract so library state, edits, favorites, and memory membership survive a fresh service or shell.

## Task 3: Wire Linux Desktop UI To Real Actions

- [x] **Step 1: Add library path entry and scan status.**

The UI should accept a local directory path, add it as a library source, and run the desktop scan.

The UI also exposes a native Linux folder picker entry point while keeping typed paths for deterministic tests.

- [x] **Step 2: Add real photo actions.**

The UI should support selecting a photo, editing caption/tags, rolling back the latest edit, and toggling favorite state.

- [x] **Step 3: Add memory and backup actions.**

The UI should create a memory, add the selected photo to it, filter by memories, and exercise export/preview/restore buttons.

- [x] **Step 4: Add memory lifecycle parity actions.**

The UI should expose selected-memory detail editing, rename, description editing, set-cover, and remove-selected-photo actions, with repository/service tests for the same lifecycle.

## Task 4: Add Linux Desktop Parity Tests

- [x] **Step 1: Add temp-directory scan E2E.**

Create a temp Linux fixture directory with supported and unsupported files, enter the path into the Flutter UI, scan, and assert imported photos appear.

- [x] **Step 2: Cover core parity actions.**

Assert search, favorite filtering, caption/tag edit, rollback, memory add/filter, backup export/preview/restore, and unsupported-file filtering.

- [x] **Step 3: Run verification.**

Run:

```bash
cd chronopic_flutter
dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app
dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit
flutter test packages/chronopic_ui apps/chronopic
flutter analyze packages/chronopic_ui apps/chronopic
cd apps/chronopic && flutter build linux --debug
```

## Phase 5.5 Follow-Up Audit

- Electron-vs-Flutter parity matrix rows are now all `Done` or explicitly documented as accepted headless-test differences.
- Add remaining browse polish only if Electron-specific layout behavior is found; adaptive grid columns and larger-library Linux scan coverage are now implemented and verified.
- Add remaining saved-filter polish only if Electron-specific interactions are found; active-filter summary chips, query, tag, GPS, AI status, date, favorite, memory, and sort controls are now covered.
- Add remaining AI polish only if Electron-specific interactions are found; provider settings, failed-queue retry, and candidate accept/reject are now implemented and covered.
- Add remaining gallery polish only if Electron-specific interactions are found; fullscreen dark chrome, counter, keyboard hint, filmstrip, and keyboard/button navigation are now implemented and covered.
- Add remaining detail metadata polish if Electron-specific fields are discovered; captured local date/time, timezone offset, original date text, camera, GPS, MIME, and size are now visible and covered.
- Add remaining map/timeline polish only if Electron-specific interactions are found; shared-result map and timeline browse modes are now implemented and covered.
- Native folder/backup dialog smoke is an accepted headless-test difference for this phase; Linux folder/save/open picker entry points, explicit JSON file-path export/preview/restore, exported JSON parity comparison, and malformed JSON errors are now covered.
- Add remaining i18n polish only if Electron-specific strings are found; English/Simplified Chinese dictionaries, a locale switcher, and critical shell text coverage are now implemented and verified.
- Final full local verification gate passed on 2026-05-08:
  Dart package tests, database tests, Dart analyzer, Flutter tests, Flutter analyzer, `flutter build linux --debug`, and `git diff --check`.
- Phase 5.5 is complete locally against the documented Linux desktop parity gate.
