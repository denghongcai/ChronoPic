# Flutter Refactor Phases

## Goal

Move ChronoPic from the current Electron + React + TypeScript desktop app to a Flutter + Dart product that can support desktop, Android, and iOS without losing the local-first catalog, AI enrichment, memories, search, and backup/restore behavior already implemented in the desktop app.

This is a staged rewrite. The core product behavior moves first, and Flutter UI comes after the Dart domain, database, media, and application layers are stable.

## Current Reference Implementation

The existing Electron app remains the reference implementation until the Flutter version passes parity gates.

- Domain model: [packages/domain/src/index.ts](../packages/domain/src/index.ts)
- SQLite schema and repositories: [packages/infra-db/src/](../packages/infra-db/src/)
- Application use cases: [packages/application/src/index.ts](../packages/application/src/index.ts)
- Desktop capability bridge: [apps/desktop/preload/bridge.ts](../apps/desktop/preload/bridge.ts)
- Media scanning and metadata extraction: [packages/infra-fs/src/index.ts](../packages/infra-fs/src/index.ts)
- Indexing orchestration: [packages/services-indexer/src/index.ts](../packages/services-indexer/src/index.ts)
- AI enrichment pipeline: [packages/services-ai-pipeline/src/](../packages/services-ai-pipeline/src/)
- Renderer state and UX surface: [apps/desktop/renderer/src/](../apps/desktop/renderer/src/)

## Architecture Target

Use a new Flutter/Dart workspace rather than embedding Flutter inside the current Electron app.

```text
chronopic_flutter/
  apps/chronopic/                 # Flutter app for Android, iOS, macOS, Windows, Linux
  packages/chronopic_domain/       # Entities, value objects, filters, backup DTOs
  packages/chronopic_database/     # Drift schema, migrations, repositories
  packages/chronopic_media/        # MediaSourceAdapter, metadata, thumbnail, hash APIs
  packages/chronopic_ai/           # OpenAI-compatible client and normalization
  packages/chronopic_app/          # Use cases, queues, backup/restore orchestration
  packages/chronopic_ui/           # Shared widgets and design system
  packages/chronopic_testkit/      # Fixtures, mocks, golden and service helpers
```

Key boundary rules:

- Domain and backup DTOs are platform-neutral Dart.
- Database logic is behind repositories, not called directly from widgets.
- Media access is adapter-based because desktop directory scanning and mobile photo-library access have different permission models.
- Long-running work runs through explicit queues or isolates.
- Mobile UX must not assume arbitrary filesystem paths are permanently accessible.

## Phase 0: Freeze Parity Contract

Purpose: define what the Flutter rewrite must preserve before any implementation begins.

Started in [docs/flutter-parity-contract.md](flutter-parity-contract.md).

Deliverables:

- List the current user-visible workflows that must survive the rewrite:
  library setup,
  scan,
  waterfall browse,
  map browse,
  timeline browse,
  search and filters,
  detail view,
  gallery view,
  tags,
  captions,
  datetime edits,
  rollback,
  favorites,
  memories,
  memory candidates,
  AI queue,
  i18n,
  backup export,
  backup preview,
  and backup restore.
- Promote existing unit and E2E fixtures into a cross-implementation parity suite.
- Capture sample backup JSON and expected snapshot outputs from the Electron app.
- Define platform differences that are accepted for the first Flutter release.

Exit gate:

- A developer can run the Electron reference flows and compare Flutter service output against the same fixture expectations.

## Phase 1: Dart Domain And Backup Contract

Purpose: port the stable product vocabulary before rebuilding storage or UI.

Deliverables:

- Create Dart models for photos, metadata, semantic fields, index state, library sources, edits, memories, memory candidates, filters, browse modes, place groups, timeline groups, settings, capabilities, and backups.
- Preserve current enum values and serialized field names where backup compatibility depends on them.
- Define backup versioning and import validation in Dart.
- Add tests for defaults, filter conversion, JSON round trips, locale settings, AI settings safety, and backup compatibility.

Exit gate:

- Dart domain tests can parse and re-emit representative Electron backup data without losing authored metadata or generated AI fields.

Status:

- Completed locally on 2026-05-07 in [chronopic_flutter/packages/chronopic_domain/](../chronopic_flutter/packages/chronopic_domain/) and [chronopic_flutter/packages/chronopic_testkit/](../chronopic_flutter/packages/chronopic_testkit/).
- Verified with `dart test packages/chronopic_domain` and `dart analyze packages/chronopic_domain packages/chronopic_testkit`.

## Phase 2: Drift Database And Repositories

Purpose: rebuild the local-first catalog projection with typed Dart persistence.

Deliverables:

- Map the current SQLite tables to Drift:
  `library_sources`,
  `photos`,
  `metadata`,
  `semantic`,
  `index_state`,
  `edit_history`,
  `memories`,
  `memory_photos`,
  and `memory_candidates`.
- Recreate repository behavior for listing, search, tag edit, caption edit, datetime edit, rollback, favorites, memories, memory candidates, place groups, timeline groups, semantic queue stats, backup export, preview, and restore.
- Keep migrations explicit and versioned from the first Dart schema.
- Add repository tests using temporary databases.

Exit gate:

- The Dart repository layer produces equivalent snapshots for the reference fixtures and can restore an Electron backup into a clean database.

Status:

- Completed locally on 2026-05-07 in [chronopic_flutter/packages/chronopic_database/](../chronopic_flutter/packages/chronopic_database/).
- Verified with `dart run build_runner build`, `dart test test/repository_test.dart test/drift_database_test.dart`, and `dart analyze packages/chronopic_database`.
- Drift runtime tests are run from the database package directory so sqlite native asset hooks are available.

## Phase 3: Media Source Abstraction

Purpose: separate product indexing semantics from platform media access.

Deliverables:

- Define `MediaSourceAdapter` with operations for listing assets, reading bytes, stat data, metadata, thumbnails, stable IDs, and missing-asset detection.
- Implement desktop directory adapter for macOS, Windows, and Linux.
- Implement mobile photo-library adapter for Android and iOS using platform asset identifiers rather than durable absolute paths.
- Implement file-picker import adapter for user-selected documents.
- Define how backup/restore represents desktop file paths versus mobile asset IDs.
- Add fixture adapters for deterministic tests.

Exit gate:

- Desktop fixtures can be scanned from directories, and mobile fixture adapters can simulate limited-library, missing-asset, and permission-denied states.

Status:

- Completed locally on 2026-05-07 in [chronopic_flutter/packages/chronopic_media/](../chronopic_flutter/packages/chronopic_media/).
- Verified with `dart test packages/chronopic_media` and `dart analyze packages/chronopic_media`.

## Phase 4: Indexer And AI Pipeline

Purpose: rebuild the core ChronoPic value loop without depending on Electron or Node APIs.

Deliverables:

- Recreate staged indexing:
  scan,
  metadata,
  hash,
  thumbnail,
  duplicate detection,
  missing detection,
  and database write.
- Run CPU-heavy work in isolates or bounded workers.
- Recreate disabled, pending, processing, completed, and failed AI states.
- Rebuild OpenAI-compatible photo and memory enrichment with strict JSON normalization.
- Prefer thumbnail or downscaled inputs for AI to avoid loading large originals on mobile.
- Add retry and recovery behavior for interrupted AI processing.

Exit gate:

- Indexing and AI service tests cover unchanged files, modified files, missing files, duplicates, failed metadata extraction, disabled AI, failed AI, and successful enrichment.

Status:

- Completed locally on 2026-05-07 in [chronopic_flutter/packages/chronopic_ai/](../chronopic_flutter/packages/chronopic_ai/) and [chronopic_flutter/packages/chronopic_app/](../chronopic_flutter/packages/chronopic_app/).
- Verified with `dart test packages/chronopic_ai packages/chronopic_app` and `dart analyze packages/chronopic_ai packages/chronopic_app`.

## Phase 5: Flutter Desktop MVP

Purpose: prove the Flutter app can replace the Electron desktop app for the core workflow.

Deliverables:

- Build desktop-first screens for first run, library settings, scan progress, photo grid, search/filter, detail view, gallery view, edit controls, favorites, memories, and backup/restore.
- Introduce feature controllers or view models instead of recreating one large renderer hook.
- Keep map and timeline connected to the shared discovery query model.
- Add widget tests, golden tests for core surfaces, and desktop integration tests for critical flows.

Exit gate:

- A desktop Flutter build can run the reference fixture workflow end to end and export an equivalent backup.

Status:

- Completed locally on 2026-05-07 as the first Linux desktop MVP shell in [chronopic_flutter/packages/chronopic_ui/](../chronopic_flutter/packages/chronopic_ui/) and [chronopic_flutter/apps/chronopic/](../chronopic_flutter/apps/chronopic/).
- Verified with `flutter test packages/chronopic_ui apps/chronopic`, `flutter analyze packages/chronopic_ui apps/chronopic`, and `flutter build linux --debug`.
- Dependency constraints were checked with `flutter pub outdated`; direct dependencies are up to date, and newer latest-only versions that are not resolvable under Flutter `3.41.9` stable were not forced.

## Phase 5.5: Linux Desktop Feature Parity And E2E Gate

Purpose: finish the Linux desktop Flutter replacement path before starting Android or iOS productization.

Deliverables:

- Drive the Flutter Linux app from real local desktop actions, not only parity fixtures or inert MVP controls.
- Wire local directory registration and manual scan through the Dart service layer and desktop media adapter.
- Preserve incremental scan behavior by appending/upserting records instead of replacing the whole catalog per asset.
- Support the core desktop workflow in the Flutter UI:
  first-run library setup,
  manual scan,
  browse/search/filter,
  detail/gallery selection,
  caption and tag edits,
  rollback,
  favorites,
  memories,
  backup export,
  backup preview,
  and backup restore smoke coverage.
- Add a Linux desktop parity test that uses a deterministic temporary directory and exercises the UI-driven workflow end to end.
- Keep Android and iOS work blocked until this Linux parity gate is passing.

Exit gate:

- `flutter test packages/chronopic_ui apps/chronopic`, Dart package tests, analyzer, and `flutter build linux --debug` pass after the real desktop workflow is wired.

Status:

- Started locally on 2026-05-08.
- First executable Linux parity slice is implemented:
  local directory scan through the Dart service layer,
  UI-driven empty-to-scanned library flow by entering a real Linux directory path and clicking `Scan Library`,
  native folder-picker entry point for first-run library selection,
  incremental catalog upsert,
  browse/search over real scanned files,
  caption/tag/favorite rollback-capable service actions,
  datetime correction and rollback,
  generated thumbnail cache files for local image previews,
  local image preview rendering,
  video placeholder rendering,
  focused gallery dialog open/close,
  gallery adjacent navigation and Escape close behavior,
  desktop date/time datetime correction controls,
  invalid date/time input coverage,
  visible tag/GPS/AI status/date/sort filter controls,
  memory membership,
  favorite filtering,
  explicit JSON backup file export/preview/restore actions,
  native backup save/open picker entry points,
  malformed backup JSON error coverage,
  visible AI readiness, status-count, and memory-candidate surfaces,
  persistent default desktop state backed by the existing backup JSON contract,
  restart/reload coverage for library state, caption/tag edits, favorites, and memory membership,
  memory detail editing, rename, description edit, set-cover, and remove-photo actions,
  detail metadata grid with captured local date/time, timezone offset, original date text, camera, GPS, MIME, and size,
  adaptive browse grid columns with larger-library Linux scan coverage,
  selected-photo keyboard shortcuts for favorite toggle, rollback, and gallery open,
  map and timeline browse modes driven by the shared visible result set,
  AI provider settings, failed-queue retry, and memory candidate accept/reject actions,
  immersive fullscreen gallery chrome with counter, keyboard hint, and filmstrip,
  English/Simplified Chinese UI dictionaries and a visible locale switcher,
  imported/updated/skipped/error/missing scan counts,
  active-filter summary chips,
  visible caption/tag validation,
  visible rollback assertions for caption, tags, favorite, and datetime,
  exported JSON parity comparison,
  and temp-directory parity tests.
- Electron-vs-Flutter Linux parity gaps are tracked in [docs/flutter-linux-desktop-parity-matrix.md](flutter-linux-desktop-parity-matrix.md).
- Native folder/save/open dialogs are an accepted headless-test difference for Phase 5.5:
  Flutter exposes the `file_selector` entry points, while deterministic widget E2E drives typed Linux paths because native portal dialogs are not operable inside Flutter widget tests.
- Final Phase 5.5 verification passed locally on 2026-05-08 with Dart tests, database tests, Dart analyzer, Flutter tests, Flutter analyzer, `flutter build linux --debug`, and `git diff --check`.
- Phase 5.5 is complete locally against the documented Linux desktop parity gate.

## Phase 5.6: Flutter Desktop UI Refine And Component Parity

Purpose: turn the behavior-complete Flutter Linux desktop shell into a product-quality desktop UI before mobile work starts.

Deliverables:

- Treat the Electron desktop UI as the reference information architecture for Flutter desktop.
- Split the current large Flutter UI file into focused modules for:
  localization,
  theme,
  shell/sidebar/page routing,
  home browse,
  library controls,
  filters,
  browse surfaces,
  detail editing,
  gallery,
  memories,
  settings,
  AI status,
  and backup controls.
- Rebuild Flutter desktop around:
  persistent sidebar,
  home page,
  memories page,
  memory detail page,
  settings page,
  notifications/AI work queue page,
  browse toolbar,
  and focused viewer.
- Preserve the full Phase 5.5 Linux desktop parity gate.
- Add layout/page tests so future work cannot collapse the UI back into a single test-shell surface.

Status:

- Complete locally on 2026-05-08.
- Design spec:
  [docs/superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md](superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md).
- Implementation plan:
  [docs/superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md](superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md).
- Implementation result:
  Flutter desktop now uses an Electron-aligned persistent sidebar,
  home browse page,
  memories page,
  memory detail page,
  settings page,
  notifications/AI work queue page,
  focused detail inspector,
  and fullscreen gallery dialog.
- Verification:
  the full Phase 5.5 local gate still passes after the UI refine,
  including Dart package tests,
  database tests,
  Dart analyzer,
  Flutter widget/parity tests,
  Flutter analyzer,
  Linux debug build,
  dependency audit,
  Linux bundle smoke launch,
  and `git diff --check`.

## Phase 6: Android And iOS Productization

Purpose: adapt ChronoPic to mobile permissions, lifecycle, and media-library behavior.

Deliverables:

- Implement Android media permissions, limited or partial access states, and foreground progress for long scans.
- Implement iOS photo-library permissions, limited access, iCloud download states, and asset identifier persistence.
- Replace desktop folder-first onboarding with mobile-native photo-library and file-import entry points.
- Add pause, resume, and retry UX for scans and AI queue work.
- Confirm backup/restore restores ChronoPic metadata only and does not promise to copy original media files.

Exit gate:

- Android and iOS real-device smoke tests can index authorized assets, persist edits, restart, and restore a backup without relying on desktop paths.

## Phase 7: Release, Migration, And Cutover

Purpose: make the Flutter rewrite shippable without stranding existing Electron users.

Deliverables:

- Add desktop packaging for macOS, Windows, and Linux.
- Add mobile signing, entitlements, permissions descriptions, and privacy disclosures.
- Provide Electron-to-Flutter import through the versioned backup JSON path first.
- Decide whether direct old SQLite import is needed after backup import works.
- Keep Electron release support for at least one transition cycle.
- Add crash/error reporting strategy that does not upload user photos or local catalog contents.

Exit gate:

- Users can move from the Electron app to the Flutter app through an explicit migration path, and each target platform has a release checklist.

## Explicit Non-Goals For The Refactor

- Do not keep Electron as a permanent backend for the Flutter app.
- Do not start with a UI-only port.
- Do not promise identical desktop and mobile interaction models where platform permissions require different UX.
- Do not add OCR, vector search, face/person recognition, cloud sync, or EXIF writeback during the initial rewrite.
- Do not remove the Electron reference app until the Flutter parity gates are met.
