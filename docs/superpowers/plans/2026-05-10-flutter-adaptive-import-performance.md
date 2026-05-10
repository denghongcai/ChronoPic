# Flutter Adaptive Import And Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter release line usable on real desktop and Android libraries by fixing responsive layout, scoped Android import, lazy browse rendering, and blocking scan work.

**Architecture:** The Flutter shell must stop using a global scroll wrapper for browse pages. The browse page owns its viewport through slivers and incremental query limits, while non-browse pages keep local scroll behavior. Android import gains explicit photo-library scopes through the existing media-source abstraction before considering a separate filesystem SAF path.

**Tech Stack:** Flutter, Dart, `photo_manager` 3.9.0, existing ChronoPic Dart service/repository/media packages, Flutter widget tests, Android adb/uiautomator E2E runner.

---

### Task 1: Document And Lock Root Causes

**Files:**
- Modify: `PLAN.md`
- Modify: `AGENTS.md`

- [x] Record that desktop responsiveness is currently blocked by a centered max-width page wrapper.
- [x] Record that waterfall laziness is broken by `SingleChildScrollView` + shrink-wrapped `GridView`.
- [x] Record that Android import currently scans `onlyAll: true` and fetches up to 100000 assets in one request.
- [x] Record that mobile thumbnail creation currently reads original bytes and performs synchronous decode/write work on the scan path.

### Task 2: Responsive Browse Viewport And Lazy Waterfall

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/shell/desktop_shell.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify tests under `chronopic_flutter/packages/chronopic_ui/test/`

- [x] Add a shell wrapper for pages that own their own scrolling.
- [x] Convert the home browse surface from a shrink-wrapped `GridView` inside a global scroll view to a `CustomScrollView` with `SliverGrid`.
- [x] Add incremental photo query limits and a load-more threshold so waterfall does not request or build the whole library at once.
- [x] Reset the photo page limit when query, filter, sort, favorite, memory, or source scope changes.
- [x] Keep detail and gallery activation behavior unchanged.
- [x] Add widget assertions that the home waterfall uses a sliver grid, remains adaptive across desktop widths, and initially limits large result sets.

### Task 3: Android Scoped Photo Library Selection

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/photo_library_gateway.dart`
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/photo_manager_gateway.dart`
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/mobile_photo_library_media_source.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify mobile media/source tests.

- [x] Add a `PhotoLibraryScope` model that represents All Photos and concrete photo-library paths/albums.
- [x] Add gateway methods to list available scopes and page assets from one selected scope.
- [x] Replace hard-coded `onlyAll: true` scanning with a user-visible selected scope.
- [x] Keep All Photos as an explicit option, not the silent default for every scan.
- [x] Defer Android filesystem-folder SAF support unless album/path selection is insufficient after testing.

### Task 4: Scan Throughput And Responsiveness

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/photo_manager_gateway.dart`
- Modify app/media tests.

- [x] Page asset discovery in batches rather than fetching a 100000-item list.
- [x] Prefer photo-manager thumbnail bytes for mobile thumbnail generation instead of reading full original bytes where possible.
- [x] Move thumbnail decode/write off the most blocking synchronous path.
- [x] Keep scan progress visible and monotonic while batches are processed.
- [x] Add focused tests proving disabled-AI mobile import avoids original reads and scoped gateway calls remain explicit.

### Task 5: Verification

**Files:**
- Modify: `docs/agent-verification-script.md` only if the gate list needs a new scene.
- Record evidence in `AGENTS.md`.

- [x] Run Flutter analyze.
- [x] Run Dart package tests.
- [x] Run focused Flutter UI tests for responsive/lazy waterfall.
- [x] Rebuild Android debug APK.
- [x] Run Android scoped-import/deep E2E where emulator tooling is available.
- [x] Capture desktop screenshots at 1366, 1600, and 2048 widths and compare the browse/detail surfaces against the Electron reference behavior.

### Verification Evidence

- `cd chronopic_flutter && flutter analyze`
- `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`
- `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
- `cd chronopic_flutter/apps/chronopic && flutter build linux --debug`
- `ANDROID_DEVICE_ID=emulator-5554 MOBILE_E2E_RUN_ID=phase8-final-20260510T122821Z chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android/phase8-final-20260510T122821Z`
- Desktop screenshots captured under `test-results/flutter-adaptive-phase8/`:
  `1366-populated-grid.png`,
  `1600-populated-grid.png`,
  `2048-populated-grid.png`,
  `1366-detail.png`,
  `1600-detail.png`,
  and `2048-detail.png`.
