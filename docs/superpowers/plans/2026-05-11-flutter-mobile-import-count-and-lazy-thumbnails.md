# Flutter Mobile Import Count And Lazy Thumbnails Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Android mobile import counts truthful and make photo-library import fast by indexing metadata first and loading thumbnails lazily.

**Architecture:** Separate catalog totals from paged browse results, separate scan progress from visible-result pagination, and separate metadata indexing from thumbnail materialization. Mobile should use platform thumbnail APIs at render time or through a bounded lazy cache; desktop directory scans can keep the existing generated thumbnail cache.

**Tech Stack:** Flutter, Dart, `photo_manager`, ChronoPic app-service/indexer packages, in-memory repository tests, Flutter widget tests, Android deep E2E.

---

## Root Cause Summary

The 2026-05-11 Android screenshot showed `406/5405` processed in the scan status while the mobile dashboard showed `20 indexed` and the bottom browse controls showed `20 items`.

Confirmed causes:

- `ChronoPicHome` pages visible photos at `_photoPageSize = 20`.
- `HomePage` mobile dashboard displays `photos.length`, which is the current paged result list, not the full catalog or full filtered result count.
- `ScanProgress.processed` is derived from `imported + updated + errors`, so skipped unchanged assets do not count as processed during rescans.
- Mobile import still reads a platform thumbnail for every changed asset, then decodes, resizes, JPEG-encodes, and writes a second thumbnail file during the scan.
- The scan loop processes assets serially and reports UI progress for every asset.

## File Structure

- Modify `chronopic_flutter/packages/chronopic_domain/lib/src/models.dart`
  - Add a query/count model only if the existing `PhotoFilter` cannot support count APIs without ambiguity.
- Modify `chronopic_flutter/packages/chronopic_database/lib/src/repository.dart`
  - Add `countPhotos(PhotoFilter filter)` using the same filter predicate as `listPhotos`.
- Modify `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`
  - Expose `countPhotos(PhotoFilter filter)` through the service boundary.
- Modify `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`
  - Count skipped assets as processed.
  - Add progress throttling.
  - Move mobile thumbnail generation out of the eager scan path.
- Modify `chronopic_flutter/packages/chronopic_media/lib/src/media_source.dart`
  - Keep `readThumbnailBytes` available for lazy UI/cache usage.
  - Do not require all `MediaSourceAdapter` implementations to generate persistent JPEG cache files during scan.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
  - Compute `visiblePhotos`, `visibleResultCount`, and `catalogPhotoCount` separately.
  - Pass count values into mobile/dashboard/browse surfaces.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
  - Display full catalog and filtered-result counts instead of paged list length where labels imply totals.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  - Keep visible-list count for current viewport copy only.
  - Use full filtered count in map/timeline summaries when copy says current results.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
  - Keep detail navigation based on the currently loaded page unless the implementation adds explicit next-page loading.
- Modify `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
  - Add regression coverage for full catalog count versus first page count.
- Modify `chronopic_flutter/packages/chronopic_app/test/mobile_scan_test.dart`
  - Add regression coverage for skipped progress and metadata-first mobile import.
- Modify `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
  - Assert the real mobile shell does not label the first page as the total catalog.

## Task 1: Separate Catalog Counts From Paged Results

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_database/lib/src/repository.dart`
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add failing widget coverage for total count versus visible page**

Create a mobile fixture with at least 25 photos. Assert that the dashboard says `25 indexed` while the visible browse surface may still render the first page.

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected before implementation:
the new assertion fails because the dashboard reports `20 indexed`.

- [x] **Step 2: Add a repository count API**

Extract the existing filter predicate used by `listPhotos` into a shared private helper and add:

```dart
int countPhotos([PhotoFilter filter = const PhotoFilter()]) {
  return _photos.values.where((record) => _matchesPhotoFilter(record, filter)).length;
}
```

The count API must ignore `limit` and `offset` while preserving query, tag, AI status, favorite, memory, GPS, date range, indexed, error, and MIME filters.

- [x] **Step 3: Expose the count through `ChronoPicAppService`**

Add:

```dart
int countPhotos([PhotoFilter filter = const PhotoFilter()]) =>
    repository.countPhotos(filter);
```

- [x] **Step 4: Compute three count values in `ChronoPicHome`**

Keep `_visiblePhotoPage()` for browse rendering. Add full count helpers:

```dart
PhotoFilter _currentPhotoFilter({int? limit}) => PhotoFilter(
  query: _query.isEmpty ? null : _query,
  tag: _tagFilter,
  aiStatus: _aiStatusFilter,
  favorite: _favoriteOnly ? true : null,
  memoryId: _selectedMemoryId,
  hasGps: _gpsOnly ? true : null,
  fromDatetime: _fromDatetimeFilter,
  toDatetime: _toDatetimeFilter,
  sortBy: _sortBy,
  sortDirection: _sortDirection,
  limit: limit ?? _photoResultLimit + 1,
);
```

Use `countPhotos(const PhotoFilter(limit: 1))` for full catalog count and `countPhotos(_currentPhotoFilter(limit: 1))` for filtered count. The implementation must not call `listPhotos(const PhotoFilter(limit: 1000000))` just to count.

- [x] **Step 5: Pass total counts into `HomePage`**

Add props such as:

```dart
required int catalogPhotoCount,
required int filteredPhotoCount,
required int visiblePhotoCount,
```

Use `catalogPhotoCount` for `All Photos` / `indexed locally` copy. Use `filteredPhotoCount` for search/filter result summaries. Use `visiblePhotoCount` only for copy that explicitly says currently loaded.

- [x] **Step 6: Verify**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected after implementation:
the dashboard count uses the full catalog or full filtered count and no longer reports `20 indexed` for a 25+ photo catalog.

## Task 2: Fix Scan Progress Semantics

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`
- Test: `chronopic_flutter/packages/chronopic_app/test/mobile_scan_test.dart`

- [x] **Step 1: Add failing progress coverage for skipped assets**

Create a two-run mobile scan fixture. The second run should produce skipped assets and progress should still reach `processed == discovered`.

Run:

```bash
cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart
```

Expected before implementation:
the new assertion fails because skipped assets are excluded from `processed`.

- [x] **Step 2: Count skipped assets as processed**

Change `_ScanCounters.processed` to:

```dart
int get processed => imported + updated + skipped + errors;
```

This keeps progress honest for initial scans and rescans.

- [x] **Step 3: Preserve complete scan stats**

Keep `IndexerStats.imported`, `updated`, `skipped`, and `errors` separate. Do not collapse them into one count; final status copy should still show each bucket.

- [x] **Step 4: Verify**

Run:

```bash
cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart
```

Expected after implementation:
second-run progress reaches `processed == discovered` while final stats still show skipped count separately.

## Task 3: Remove Eager Mobile JPEG Thumbnail Generation

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/media_source.dart`
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/mobile_photo_library_media_source.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
- Test: `chronopic_flutter/packages/chronopic_app/test/mobile_scan_test.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add failing scan test for metadata-first mobile import**

Create a mobile source fixture that counts calls to `readThumbnailBytes`. Scan it with disabled AI and assert the scan imports records without reading thumbnails during scan.

Run:

```bash
cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart
```

Expected before implementation:
the fixture observes thumbnail reads during scan.

- [x] **Step 2: Add a media-source capability flag**

Add an explicit capability to `MediaSourceAdapter`:

```dart
bool get supportsLazyThumbnails;
```

Return `true` from `MobilePhotoLibraryMediaSource` and `false` from desktop/file-backed sources.

- [x] **Step 3: Skip eager thumbnail writes for lazy-capable sources**

In `ChronoPicIndexerService.scanLibrary`, only call `_readThumbnailBytes` and `_writeThumbnail` when the source does not support lazy thumbnails or when a non-mobile source needs the persistent cache.

For lazy-capable mobile sources, upsert the record with `thumbnailPath: null` and keep `photo.path` as `asset://<id>`.

- [x] **Step 4: Render mobile thumbnails lazily**

Add a UI thumbnail path for `asset://` records that uses `readThumbnailBytes` only when the tile/detail/gallery image is actually visible. Keep this bounded by Flutter image caching and do not write a second JPEG file during import.

The browse/detail/gallery surfaces must still render desktop `Image.file` previews when `thumbnailPath` or local file paths exist.

- [x] **Step 5: Verify no scan-time thumbnail read**

Run:

```bash
cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart
```

Expected after implementation:
disabled-AI mobile import creates catalog records without thumbnail reads during scan.

- [x] **Step 6: Verify mobile UI still shows media previews**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected:
mobile browse/detail/gallery tests still pass with lazy thumbnail rendering.

## Task 4: Throttle Progress Updates

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Test: `chronopic_flutter/packages/chronopic_app/test/mobile_scan_test.dart`

- [x] **Step 1: Add progress throttling test**

Scan a fixture with at least 100 assets and capture progress callbacks. Assert callbacks are emitted at start, periodically, and completion, not once per asset.

Run:

```bash
cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart
```

Expected before implementation:
callbacks are emitted once per asset.

- [x] **Step 2: Add a deterministic progress-report policy**

Report progress when one of these is true:

- the scan starts;
- the scan completes;
- an error occurs;
- at least 10 more assets have been processed since the last report;
- at least 250 milliseconds have elapsed since the last report.

This keeps the UI responsive without forcing full widget rebuilds for every asset.

- [x] **Step 3: Keep final status exact**

The final `ScanRunState.completed` report must include exact imported, updated, skipped, errors, and missing counts.

- [x] **Step 4: Verify**

Run:

```bash
cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart
```

Expected after implementation:
progress callbacks are bounded while final stats remain exact.

## Task 5: Android Deep E2E Evidence

**Files:**
- Modify: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `docs/mobile-productization.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Extend Android deep E2E assertions**

Add assertions that distinguish:

- discovered scope count;
- imported or indexed catalog count;
- visible first-page count.

The test should reject UI copy that labels the first page as the full library count.

- [x] **Step 2: Record manual large-library evidence**

Run against a real or emulator library with more than 200 assets. Capture:

- scan start status;
- mid-scan progress;
- dashboard count after at least 25 imports;
- final status;
- release/debug APK build evidence.

Implementation evidence:
the local gate uses deterministic automated mobile fixtures rather than a
mutable personal photo library:
`mobile_productization_test.dart` covers a 225-photo mobile catalog,
`mobile_scan_test.dart` covers a 100-asset progress-throttling scan,
and the Android debug APK build passed.

- [x] **Step 3: Verify**

Run:

```bash
cd chronopic_flutter && flutter analyze
cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test
cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart
cd chronopic_flutter/apps/chronopic && flutter build apk --debug
git diff --check
```

Expected:
all commands pass. Android live evidence should show the dashboard total is not capped at the first page and scan progress reaches the discovered count.

## Non-Goals

- Do not change desktop directory import semantics in this phase.
- Do not remove desktop-generated thumbnail cache.
- Do not add OCR, vector search, person recognition, cloud sync, or EXIF writeback.
- Do not implement AI thumbnail analysis in this phase.
- Do not claim iOS live behavior from this Linux workstation.

## Self-Review

- Spec coverage:
  the plan covers count correctness, scan progress semantics, eager JPEG removal, progress throttling, UI copy, tests, and Android evidence.
- Placeholder scan:
  no placeholder task is left in this plan.
- Type consistency:
  new count and lazy thumbnail APIs stay within repository, app-service, media-source, and UI package boundaries already used by the Flutter app.
