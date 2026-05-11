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
  Linux bundle Xvfb/scrot screenshot smoke launch,
  and `git diff --check`.

## Phase 5.7: Flutter Electron UI And Functional Parity

Purpose: continue desktop UI and feature alignment by comparing Electron and Flutter with repeatable tests and screenshots before mobile work starts.

Deliverables:

- Add Electron reference screenshot capture for the current desktop app.
- Add Flutter Linux screenshot capture under Xvfb/scrot with deterministic app state.
- Maintain a parity matrix covering:
  first-run home,
  populated browse,
  map,
  timeline,
  detail/editing,
  gallery,
  favorites,
  memories,
  settings,
  notifications/AI,
  Chinese locale,
  and restart persistence.
- Fix Flutter UI and functional gaps in focused slices and rerun both Electron and Flutter verification after each slice.
- Keep screenshots under ignored `test-results/` and record paths/results in `AGENTS.md`.

Status:

- Phase handoff completed on 2026-05-09 and pushed to
  `flutter-refactor-phases`.
- Electron and Flutter screenshot harnesses are available.
- First Flutter shell/home/browse/detail alignment slice is implemented and verified;
- gallery/detail/favorites/editing alignment task is implemented and verified;
- memory list/detail alignment is partially implemented and verified;
- notifications/settings alignment is partially implemented and verified;
- map/timeline first-viewport alignment is partially implemented and verified,
  including an Electron-like pale disabled-map canvas in the Flutter Map surface
  and an Electron-like light timeline card with selected-photo banner in the Flutter Timeline surface;
- Chinese locale first-viewport alignment is partially implemented and verified;
- all 13 Flutter parity screenshots have been recaptured at the Electron reference size of 1440x920;
  no unexamined `Gap` rows remain in the parity matrix.
- Parity matrix:
  [docs/flutter-electron-ui-functional-parity.md](flutter-electron-ui-functional-parity.md).
- Populated-grid, favorites, and restart-persistence Flutter surfaces now show
  an Electron-like selected-photo banner above the grid when a photo is selected.
- Detail capture now uses an immersive Electron-like focused dark viewer with
  a large media canvas, right-side metric-card inspector, AI insights,
  gallery strip, keyboard hint, and real add/close/gallery actions instead of
  a plain inline detail page or normal Flutter shell chrome.
- Gallery capture now uses a bordered dark media frame, metadata below the
  image instead of a large scrim, an Open Inspector action, and a separate
  framed gallery strip closer to Electron's viewer hierarchy.
- Populated browse, favorites, and restart-persistence surfaces now include a
  functional Electron-like discovery lens row where Map, Timeline, and Memory
  chips navigate to real app surfaces instead of acting as visual-only hints.
- Notifications now use an Electron-like outer container with separate AI queue
  and Memory candidates cards while preserving retry and memory-review actions.
- Notifications now also place the page title inside the white content card and
  use Electron-like blue/red/green/yellow semantic chips for AI queue,
  failed,
  ready,
  and memory candidate states.
- Settings now use Electron-like primary library actions, backup action grouping
  with `LOCAL JSON`, and an AI Enrichment readiness card with `PRESENT` pills
  while preserving path-based backup/restore and secret-safe AI editing.
- Settings now also keeps the first viewport focused on the Electron-like
  Library Settings card with Add Folder and Scan Library,
  moves manual path import into a lower panel,
  and uses Electron-like orange/white/blue/green action and status semantics
  for restore,
  language save,
  backup format,
  and AI readiness.
- Shared desktop shell chrome now moves notifications into the sidebar header,
  replaces the previous Notifications nav row with an Electron-like Recent row,
  adds a bottom Create Memory action,
  and hides the idle scan status bar so non-immersive pages start at the same
  top content position as Electron.
- Browse controls now use Electron's `Waterfall` label instead of `Grid`,
  including the Simplified Chinese `瀑布流` label,
  and the selected-photo banner now uses Electron's memory-membership copy.
- Focused detail capture now selects the same first fixture photo as Electron
  and exposes Electron-like add,
  close,
  previous,
  next,
  and Gallery top controls with dark/disabled/highlight states.
- Focused detail inspector status now reports file/index health as `HEALTHY`
  while keeping AI failure information in AI-specific fields,
  matching Electron's inspector semantics.
- Fullscreen gallery now removes the extra back/X controls,
  uses dark Detail View/Open Inspector actions,
  shows date plus time,
  uses Electron's `NOT IN ANY MEMORY` and `2 ITEMS` copy,
  and keeps the dark framed media/filmstrip hierarchy.
- Settings backup JSON path controls now live in a lower file-path panel so the
  first viewport matches Electron's backup card density while preserving
  path-based export/restore workflows.
- Browse media cards now use a lower-density desktop grid, larger cards,
  bottom gradient metadata, and improved missing-media fallback so populated,
  favorites, and restart-persistence evidence more closely matches Electron's
  media-card hierarchy.
- Global Flutter desktop brand chrome now matches Electron's `ChronoPic` /
  `Photo workspace` labels instead of identifying the rewrite as
  `ChronoPic Flutter`.
- Empty first-run now uses `Add Folder` as the primary folder-picker action
  while preserving the explicit path-based `Add Library` control below.
- Empty first-run now also removes lower empty-library path/filter controls
  from the first viewport,
  keeps path-based add/scan functionality in Settings,
  adds a `Create First Memory` CTA to the recent-memory empty state,
  and keeps filters visible when active filters return zero photos.
- Populated grid,
  Favorites,
  and Restart Persistence now use Electron-like compact `Select` / `Filter`
  browse-toolbar affordances by default,
  while the full filter panel remains available behind `Filter` and stays
  visible for active search/tag/GPS/AI/date/sort states.
- Map and Timeline screenshots were recaptured after the compact toolbar pass,
  so both now inherit reduced first-viewport toolbar density while preserving
  the disabled-map and timeline-card behavior already implemented.
- Browse media cards now use a taller card ratio,
  and photo/memory fallback surfaces now share an Electron-like edge treatment
  with top path/name text instead of a centered broken-image icon.
- Memories list now has an Electron-like `SUGGESTED MEMORIES` header,
  a real Generate/refresh affordance,
  title-card candidate treatment,
  `Adjust photos`,
  and candidate accept/reject actions aligned more closely with Electron.
- Memory list/detail/home cards now use framed media-style cover fallback
  treatment instead of centered icon-only gradient blocks.
- Memory detail now uses a read-first hero with compact actions and moves
  editable metadata controls into a lower management panel.
- Memory detail now also uses Electron-like updated timestamp formatting,
  a `STORY OUTLINE` section,
  and chapter-card metadata for month/day,
  mapped count,
  and AI readiness.
- Full Flutter-side verification for this phase has been rerun with
  `dart analyze packages/chronopic_app packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `bash tool/capture_flutter_parity.sh all`,
  and a `file` check confirming all 13 Flutter PNGs are 1440x920.
- Electron-side verification has also been rerun:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:backup`,
  `pnpm run e2e:ai`,
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  `node scripts/capture-electron-parity.mjs`,
  and a `file` check confirming all 13 Electron PNGs are 1440x920.
  The Electron gate exposed and now covers a deterministic edit-history rollback
  fix for rapid same-millisecond edits.
- Acceptance spec:
  [docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md](superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md).
- Implementation plan:
  [docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md](superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md).
- Next execution plan:
  keep Phase 6 mobile productization blocked until the pushed Flutter desktop
  parity branch is reviewed or merged.

## Phase 5.8: Viewer Overlay Activation Parity

Purpose: align Flutter and Electron on the real desktop viewer contract after
Phase 5.7 exposed that screenshot parity did not prove the double-click
activation path or the in-overlay Detail/Gallery mode switch.

Deliverables:

- Double-clicking a photo card opens the focused Detail viewer overlay in
  Electron and Flutter.
- Single-click selection,
  Enter-to-Detail,
  selected-photo `G`-to-Gallery,
  Gallery `D` / `Detail View` back to Detail,
  and `Escape` close remain explicit.
- Gallery overlay remains fullscreen,
  navigable,
  and switchable back to Detail from inside the overlay.
- Electron and Flutter tests cover the activation path, not only the gallery view once opened.
- Focused Electron and Flutter screenshots are recaptured and compared for:
  populated browse,
  Detail,
  gallery,
  and the Detail/Gallery overlay mode relationship.

Status:

- Planned on 2026-05-09.
- Corrected on 2026-05-09 after user review clarified that Electron's
  reference behavior is Detail-first overlay activation, not direct
  double-click-to-Gallery.
- Correction commit:
  `96ba222`.
- Electron accessibility E2E now covers Enter-to-Detail,
  double-click-to-Detail,
  Detail-to-Gallery,
  Gallery `D`-to-Detail,
  selected-card `G`-to-Gallery,
  and Escape close.
- Flutter widget/parity tests now cover card double-tap-to-focused-Detail,
  focused Detail-to-Gallery,
  Gallery `D`-to-focused-Detail,
  selected-photo `G`-to-Gallery,
  Enter-to-focused-Detail,
  and Escape close.
- Focused Electron and Flutter screenshots were recaptured for populated
  browse,
  Detail,
  gallery,
  then compared with side-by-side artifacts under
  `test-results/flutter-electron-parity/compare/`.
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md](superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md).

## Phase 5.9: Full Feature UI Parity Review

Purpose: audit all desktop Flutter surfaces against the Electron reference one
by one, using code comparison, behavioral tests, and refreshed screenshot
comparison.

Deliverables:

- All 13 parity surfaces have refreshed Electron and Flutter screenshots.
- All 13 side-by-side compare artifacts are generated and inspected.
- `docs/flutter-electron-feature-ui-review.md` records per-surface behavior
  notes,
  UI differences,
  test coverage,
  and gap decisions.
- Confirmed gaps are promoted into explicit follow-up phases before
  implementation.

Status:

- Reviewed on 2026-05-09.
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-feature-ui-parity-review.md](superpowers/plans/2026-05-09-feature-ui-parity-review.md).
- Detailed review report:
  [docs/flutter-electron-feature-ui-review.md](flutter-electron-feature-ui-review.md).
- Evidence:
  all 13 Electron screenshots,
  all 13 Flutter screenshots,
  and all 13 side-by-side compare artifacts were refreshed.
- Result:
  no new functional workflow gap was found outside localization,
  but `FUI-001` confirms that Flutter zh mode still contains app-owned English
  UI strings.
- Verification:
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm typecheck`,
  `pnpm build`,
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`,
  and
  `git diff --check`
  all passed.
- Next:
  execute Phase 5.10 before further broad UI polish.

## Phase 5.10: Flutter Visible String Localization Parity

Purpose: close the confirmed Flutter Chinese-locale UI parity gap by removing
app-owned English strings from zh mode while preserving source-authored user
content such as filenames, captions, memory names, and imported descriptions.

Reference:

- Finding:
  `FUI-001` in
  [docs/flutter-electron-feature-ui-review.md](flutter-electron-feature-ui-review.md).
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md](superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md).

Deliverables:

- Failing zh tests for selected-photo banners and active filter labels.
- Failing zh tests for Detail/Gallery controls, memory actions, settings,
  notifications, map controls, timeline actions, and status messages.
- Localized Flutter UI strings using the existing `UiStrings` and
  `_localized(labels, en, zh)` patterns.
- Refreshed affected Flutter screenshots and compare artifacts.
- Updated parity review docs and verification records.

Status:

- Implemented and verified on 2026-05-09.
- Red/green coverage:
  the zh app-owned surface test first failed on the English selected-photo
  banner, then passed after localization.
- Verification:
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts`,
  and
  `git diff --check`
  all pass.

## Phase 6: Android And iOS Productization

Purpose: adapt ChronoPic to mobile permissions, lifecycle, and media-library behavior.

Implementation plan:

- [docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md](superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md)

Deliverables:

- Implement Android media permissions, limited or partial access states, and foreground progress for long scans.
- Implement iOS photo-library permissions, limited access, iCloud download states, and asset identifier persistence.
- Replace desktop folder-first onboarding with mobile-native photo-library and file-import entry points.
- Add pause, resume, and retry UX for scans and AI queue work.
- Confirm backup/restore restores ChronoPic metadata only and does not promise to copy original media files.

Exit gate:

- Android and iOS real-device smoke tests can index authorized assets, persist edits, restart, and restore a backup without relying on desktop paths.

Status:

- Implemented and locally verified on 2026-05-09 through the gates available on
  this Linux workstation.
- Android/iOS runners are scaffolded with photo-library permission
  declarations.
- Android media-library access is implemented through a real
  `MediaSourceAdapter` backed by a testable gateway and `photo_manager`.
- Mobile scan progress, limited access, denied permission, pause, resume, and
  retry behavior are covered by Dart/widget tests.
- Mobile first-run onboarding uses the photo library as the primary entry
  instead of desktop folder import.
- The Android user-state toolchain is configured with Temurin JDK `17.0.19`,
  Android SDK `36.0.0`,
  platform `android-36`,
  build-tools `36.0.0`,
  and NDK `28.2.13676358`.
- `flutter build apk --debug` passes and emits
  `chronopic_flutter/apps/chronopic/build/app/outputs/flutter-apk/app-debug.apk`.
- Android emulator smoke passed on `emulator-5554`
  (`Android SDK built for x86_64`,
  Android 16/API 36):
  denied permission recovery,
  selected-photo limited access,
  full-access import,
  restart persistence,
  and metadata backup restore.
- iOS is scaffolded and statically reviewed here, but its real-device exit gate
  requires macOS/Xcode and must not be marked complete from Linux-only evidence.
- Desktop parity remains green after Phase 6:
  Electron `pnpm` gates,
  Electron Playwright gates,
  Flutter package tests,
  Flutter UI/parity tests,
  Flutter analyzer,
  and Android debug build all pass locally.

Remaining before Phase 7 cutover:

- Complete Phase 6.5 mobile deep E2E verification.
- Run `flutter build ios --debug --no-codesign` and `flutter run` from
  macOS/Xcode against an iOS target.
- Complete release signing, mobile privacy disclosures, and migration packaging.

## Phase 6.5: Flutter Mobile Deep E2E Verification

Purpose: deepen mobile validation after Phase 6 smoke so Phase 7 release and
cutover work starts from repeatable Android evidence and explicit iOS gates.

Implementation plan:

- [docs/superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md](superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md)

Deliverables:

- Create a durable mobile E2E evidence matrix for Android and iOS.
- Add stable mobile test hooks for app-owned workflows without changing product
  behavior.
- Add a repeatable Android emulator runner for clean-state permission,
  media-fixture,
  import,
  restart,
  screenshot,
  XML,
  and backup-restore evidence.
- Add Flutter integration tests for app-owned mobile workflows:
  browse,
  detail/gallery,
  metadata edits,
  favorites,
  memories,
  search/filter/sort,
  locale/settings,
  and persistence.
- Keep iOS verification explicit:
  scaffolded/configured code is not enough;
  macOS/Xcode screenshots and command output are required before iOS is marked
  complete.

Exit gate:

- Android deep E2E can run repeatedly from a clean emulator state and produces
  screenshot/XML/backup evidence for denied,
  limited,
  full-access,
  restart persistence,
  metadata backup restore,
  and app-owned workflow coverage.
- iOS deep E2E is either verified from macOS/Xcode or clearly recorded as a
  pending gate with exact commands and required evidence.
- Existing Electron and Flutter Linux desktop gates still pass after the mobile
  E2E additions.

Status:

- Completed locally on 2026-05-10.
- Completed:
  mobile E2E evidence matrix,
  stable mobile workflow hooks,
  Android permission/import/restart/backup runner,
  and app-owned Android integration test coverage for browse,
  detail/gallery,
  edits,
  favorite,
  memories,
  search/filter/sort,
  locale/settings,
  restored-state persistence,
  iOS macOS/Xcode evidence gate documentation,
  and the full Phase 6.5 closeout verification suite.
- iOS remains `Blocked` for live execution until macOS/Xcode evidence is
  available, but the Phase 6.5 gate is recorded with exact commands and
  required screenshots.

Remaining before Phase 7 cutover:

- Run the iOS macOS/Xcode gate when available before treating iOS as
  release-verified.
- Complete release signing, mobile privacy disclosures, and migration packaging.

## Phase 6.6: Flutter Linux Desktop Parity Hardening

Purpose: re-freeze Flutter Linux desktop against the Electron reference after
Phase 6 and Phase 6.5 mobile work, before Phase 7 release and cutover work
starts.

Implementation plan:

- [docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md](superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md)

Deliverables:

- Refresh all 13 Electron reference screenshots.
- Refresh all 13 Flutter Linux screenshots.
- Regenerate all 13 side-by-side compare artifacts.
- Reinspect `docs/flutter-electron-ui-functional-parity.md` and
  `docs/flutter-electron-feature-ui-review.md` against fresh evidence.
- Fix any confirmed Flutter desktop workflow,
  hierarchy,
  localization,
  or responsive gap with focused tests.
- Record screenshot paths,
  commands,
  decisions,
  skipped scenes,
  and remaining accepted differences in `AGENTS.md`.

Reference surfaces:

- Empty first-run home.
- Populated grid/waterfall browse.
- Map browse / disabled-map state.
- Timeline browse.
- Detail inspector and edits.
- Fullscreen gallery.
- Favorites filter.
- Memories list.
- Memory detail management.
- Settings.
- Notifications / AI queue.
- Chinese locale.
- Restart persistence.

Exit gate:

- Electron and Flutter Linux capture directories each contain the same 13
  1440x920 PNGs.
- Compare directory contains the same 13 side-by-side artifacts.
- No unexamined `Gap` rows remain in
  `docs/flutter-electron-ui-functional-parity.md`.
- Any repaired gap has a focused Flutter widget/parity test or named Electron
  E2E coverage path.
- Electron and Flutter desktop verification commands pass after the evidence
  refresh.

Status:

- Completed locally on 2026-05-10.
- Findings:
  no new product UI/function gap was found beyond existing accepted renderer
  differences.
  Phase 6.6 closed two evidence-harness gaps:
  `P66-001`,
  where normal Flutter parity captures inherited the fixture's persisted zh
  locale while Electron normal captures used English;
  and `P66-002`,
  where Playwright's default `test-results` output cleanup removed parity PNG
  evidence.
- Evidence:
  all 13 Electron screenshots,
  all 13 Flutter Linux screenshots,
  all 13 side-by-side compare artifacts,
  and `contact-sheet-phase-6-6.png` were regenerated under
  `test-results/flutter-electron-parity/`.
  The parity evidence remained present after Electron E2E verification because
  Playwright artifacts now live under `test-results/playwright-artifacts/`.
- Verification:
  `pnpm build`,
  `pnpm run e2e:prepare`,
  `node scripts/capture-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  compare artifact generation with `montage`,
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  final evidence count/dimension checks,
  and `git diff --check` all passed.

## Phase 7: Flutter Release Readiness And Cutover

Purpose: make the Flutter rewrite shippable without producing new Electron
release assets.

Implementation plan:

- [docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md](superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md)

Release target decision:

- Flutter Android is the primary executable mobile release target.
- Flutter Linux is the supported desktop release artifact for this repo's
  current runner.
- Flutter iOS remains blocked until macOS/Xcode build,
  signing,
  and E2E evidence exist.
- Electron is no longer a release target.
  Keep it only as parity reference and migration source until cutover is
  complete.

Deliverables:

- Harden Android deep E2E runner:
  clearer `adb`/`uiautomator` retry logs,
  required screenshot/XML/permission/backup artifact assertions,
  summary JSON,
  and two clean emulator runs before release work proceeds.
  Current status:
  assertion helper,
  runner logging/summary hardening,
  two-run wrapper,
  and live two-run emulator evidence are complete.
  Evidence:
  `.tmp/mobile-e2e/android-repeat/20260510T044545Z/combined-summary.json`
  reports `passed`.
- Prove migration and cutover compatibility:
  generate a sanitized real Electron backup fixture,
  restore it through Flutter app/domain code,
  document the user migration path,
  and decide whether direct old SQLite import is still needed.
  Current status:
  complete.
  Evidence:
  `pnpm run e2e:backup`,
  `node scripts/write-flutter-migration-fixtures.mjs`,
  and
  `cd chronopic_flutter && dart test packages/chronopic_app/test/electron_backup_import_test.dart`
  pass.
  Direct old SQLite import is not required for Phase 7 unless JSON backup
  export/restore fails on a real user backup.
- Add Flutter Android release readiness:
  secret-safe signing config,
  release APK/AAB build,
  sha256 artifacts,
  Play Store photo-permission rationale,
  and Data safety notes.
  Current status:
  complete for technical release verification.
  Phase 10 updates the production `applicationId` to `ai.chronopic.app`.
  Evidence:
  missing signing fails release builds with a clear message,
  local signed release APK/AAB build passes,
  and
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`
  verifies APK/AAB/Linux sha256 files.
- Add Flutter Linux release readiness:
  release bundle build,
  tarball archive,
  sha256 artifact,
  and README release artifact updates.
  Current status:
  complete locally.
  Evidence:
  `chronopic_flutter/tool/release/build_linux_release.sh`
  and
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs linux`
  pass.
- Promote Flutter CI gates:
  Flutter analyze,
  Dart tests,
  Flutter widget/parity tests,
  Android debug build,
  optional manual Android emulator E2E,
  and no required Electron package-release gate.
  Current status:
  complete.
  CI now has a Flutter job,
  `.github/workflows/android-deep-e2e.yml` provides a manually triggered
  Android emulator deep E2E gate,
  Electron package verification is no longer a CI release gate,
  and Android deep E2E remains both a local and manual CI Phase 7 gate.
- Replace tag-triggered Electron release workflow with Flutter release workflow:
  upload Flutter Android and Flutter Linux artifacts,
  do not upload new Electron assets.
  Current status:
  complete.
  Tag release workflow now uploads Flutter Android and Flutter Linux assets
  only.
  iOS remains blocked until macOS/Xcode signing and E2E evidence exist.

Version rule:

- Before adding or changing any dependency,
  GitHub Action,
  Flutter SDK setup,
  Android SDK package,
  Gradle plugin,
  or release tool,
  check the current stable version from official sources and record the selected
  version in `AGENTS.md`.

Exit gate:

- Status:
  complete on 2026-05-10.
- Android hardened runner passes two consecutive clean emulator runs and
  validates all required artifacts.
- Flutter imports the real Electron backup fixture through the versioned JSON
  path.
- Flutter Android release APK/AAB and Flutter Linux archive are generated and
  verified locally.
- CI contains Flutter release-readiness gates.
- Tag-triggered release no longer produces Electron artifacts.
- Migration,
  release,
  privacy,
  signing,
  and iOS blocked-gate docs are updated.
- Final local gate evidence:
  `pnpm test && pnpm typecheck && pnpm build`,
  Flutter analyze/package tests/widget tests,
  `flutter build apk --debug`,
  Android two-run E2E hardening,
  signed Android release build,
  Linux release build,
  combined Android/Linux artifact verification,
  and `git diff --check` passed.

## Explicit Non-Goals For The Refactor

- Do not keep Electron as a permanent backend for the Flutter app.
- Do not start with a UI-only port.
- Do not promise identical desktop and mobile interaction models where platform permissions require different UX.
- Do not add OCR, vector search, face/person recognition, cloud sync, or EXIF writeback during the initial rewrite.
- Do not remove the Electron reference app until the Flutter parity and
  migration gates are met.
- Do not produce new Electron release assets during Phase 7.

## Phase 9: Flutter Desktop Interaction Regression Audit

Status:
completed locally on 2026-05-10.

Purpose:
audit Flutter Linux desktop interactions after the v0.1.6 selected-photo
regression and re-check desktop adaptive layout against the Electron reference.

Plan:

- [docs/superpowers/plans/2026-05-10-flutter-desktop-interaction-regression-audit.md](superpowers/plans/2026-05-10-flutter-desktop-interaction-regression-audit.md)

Inputs:

- GitHub Actions `startup_failure` is no longer a phase blocker because the
  user handled it outside this work.
- Real Electron migration sample validation is no longer in scope.
- Electron remains the interaction reference for desktop.

Audit requirements:

- Single click selects only.
- Double click or Enter opens focused Detail.
- `G` opens or switches to Gallery.
- `D` switches from Gallery to Detail.
- Escape closes focused overlays.
- Arrow keys navigate adjacent media.
- Edit feedback is visible inside the focused Detail overlay.
- Waterfall browse starts at 20 items and loads more incrementally.
- Desktop adaptive layout is rechecked at 1366,
  1600,
  and 2048 pixel widths.

Exit gate:

- `docs/flutter-desktop-interaction-regression-audit.md` is complete with no
  `Pending` rows.
- Electron and Flutter screenshot evidence is refreshed where relevant.
- Adaptive screenshots are recorded for browse/detail at the required widths.
- Any confirmed mismatch is fixed with a focused test or recorded as an
  accepted difference.

Closeout evidence:

- `docs/flutter-desktop-interaction-regression-audit.md` has no `Pending`
  rows.
- Electron screenshots:
  `test-results/flutter-electron-parity/electron/*.png`.
- Flutter screenshots:
  `test-results/flutter-electron-parity/flutter/*.png`.
- Compare artifacts:
  `test-results/flutter-electron-parity/compare/*.png`.
- Adaptive screenshots:
  `test-results/flutter-adaptive-regression/*.png`.
- Verification passed:
  `pnpm build`,
  `node scripts/capture-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  `node scripts/compare-flutter-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_adaptive_regression.sh`,
  and the focused Flutter UI/parity tests.

## Phase 10: Flutter Mobile UI Refine

Status:
completed locally on 2026-05-10.

Purpose:
refine the Flutter mobile UI into a production-quality Android touch experience
without weakening the desktop interaction contract.

Plan:

- [docs/superpowers/plans/2026-05-10-flutter-mobile-ui-refine.md](superpowers/plans/2026-05-10-flutter-mobile-ui-refine.md)

Product identity decision:

- Android production package id:
  `ai.chronopic.app`.
- Android E2E package constants and docs should move to the same id.
- iOS bundle metadata may be prepared,
  but iOS live verification remains blocked until macOS/Xcode evidence exists.

Mobile UI surfaces:

- First-run entry.
- Permission denied recovery.
- Scoped photo import.
- Scan progress.
- Browse waterfall.
- Search/filter/sort.
- Detail overlay.
- Gallery overlay.
- Edit metadata feedback.
- Favorites.
- Memories.
- Settings.
- Backup/restore.
- Restart persistence.

Exit gate:

- Flutter analyze passes.
- Dart package tests pass.
- Flutter desktop/mobile UI tests pass.
- Android debug build passes with `ai.chronopic.app`.
- Android deep E2E runner and artifact assertions pass.
- `docs/flutter-mobile-ui-refine-audit.md`,
  `docs/mobile-e2e-verification.md`,
  and `docs/mobile-productization.md` contain the final evidence.

Closeout evidence:

- Android package id is `ai.chronopic.app`.
- Final Android deep E2E output:
  `.tmp/mobile-e2e/android/phase10-final-browse-state/`.
- Final Android deep E2E summary:
  `status: passed`,
  `packageName: ai.chronopic.app`.
- Artifact assertion helper passed as part of the runner.
- Verification passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `MOBILE_E2E_RUN_ID=phase10-final-browse-state bash chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.

Blocked boundary:

- iOS live verification remains blocked until macOS/Xcode evidence exists.

## Phase 11: Flutter Mobile Native Experience Redesign

Status:
complete locally on 2026-05-11.

Purpose:
expand the mobile UI refine work from touch polish into a mobile-native
ChronoPic experience.
Mobile keeps the same local-first data model and core workflows as desktop,
but it should no longer look or behave like a compressed desktop workspace.

Plan:

- [docs/superpowers/plans/2026-05-11-flutter-mobile-native-experience-redesign.md](superpowers/plans/2026-05-11-flutter-mobile-native-experience-redesign.md)

Source input:

- User-provided mobile UI refine proposal reviewed on 2026-05-11.

Core decision:

- Mobile may diverge from desktop visual layout and interaction structure.
- Desktop remains the Linux functional parity reference.
- Android mobile gets its own information architecture,
  navigation,
  and page compositions.
- iOS remains static-prepared only until macOS/Xcode evidence exists.

Planned surfaces:

- Mobile design contract:
  orange action color,
  neutral cards,
  safe-area-aware spacing,
  48px touch targets,
  mobile type hierarchy,
  and icon-first controls.
- Mobile shell and home:
  brand/notification header,
  prominent search,
  shortcut cards for All Photos,
  Favorites,
  Memories,
  and Settings,
  scan progress card,
  Recent Memories,
  and bottom navigation for Waterfall,
  Map,
  Timeline,
  and Settings.
- Search and filters:
  primary search field,
  mobile filter sheet,
  visible active filter chips,
  and browse-mode state preservation.
- Detail and Gallery:
  media-first full-screen mobile Detail,
  top back/index/more controls,
  floating favorite/add-to-memory actions,
  lower metadata/edit cards or sheets,
  and no desktop keyboard shortcut copy.
- Settings:
  grouped mobile list rows with drill-in sheets or subpages for Library,
  Language,
  AI output language,
  Backup / restore,
  Map,
  and advanced local paths.
- Create Memory:
  guided flow for selecting photos,
  editing title/description/cover,
  confirming,
  and opening the created memory.

Implementation result:

- Mobile shell now uses a phone-specific header and bottom navigation for
  Waterfall,
  Map,
  Timeline,
  and Settings instead of compressed desktop tabs.
- Mobile home now exposes primary search,
  horizontal shortcut cards,
  and a scan/catalog status card.
- Dense filters now open from a mobile bottom sheet,
  with active filter chips visible after apply.
- Focused Detail and Gallery now use mobile chrome and no desktop shortcut copy
  on phone layouts.
- Settings now opens as grouped mobile rows with drill-in sheets for complex
  panels.
- Create Memory now has a guided mobile wizard and opens into the existing
  editable memory detail lifecycle for description,
  cover,
  add/remove,
  rename,
  and persistence.

Exit gate:

- Passed locally:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
- Phone-width overflow risks found by verification were fixed in Gallery chrome
  and mobile Language settings.
- Mobile Detail and Settings no longer expose desktop-specific layout/copy on
  phone layouts.
- iOS live verification remains blocked until macOS/Xcode evidence exists.

## Phase 12: Flutter Mobile Import Count And Lazy Thumbnail Pipeline

Status:
completed on 2026-05-11.

Purpose:
fix the remaining Android large-library import issues surfaced by a real phone
screenshot.
Mobile must distinguish photo-library discovery count,
catalog/indexed count,
filtered result count,
and currently visible page count.
Mobile import should index metadata quickly and defer thumbnail materialization
to visible UI surfaces instead of eagerly converting every asset into a second
JPEG during scan.

Plan:

- [docs/superpowers/plans/2026-05-11-flutter-mobile-import-count-and-lazy-thumbnails.md](superpowers/plans/2026-05-11-flutter-mobile-import-count-and-lazy-thumbnails.md)

Source input:

- Android screenshot reviewed on 2026-05-11:
  the status bar showed `406/5405` processed and imported,
  while mobile dashboard and browse controls still showed `20`.

Root causes:

- Mobile dashboard count uses the paged visible browse list rather than the
  full catalog or filtered result count.
- Scan progress does not count skipped unchanged assets as processed.
- Mobile scan still reads,
  decodes,
  resizes,
  JPEG-encodes,
  and writes thumbnail files for changed image assets during import.
- Progress updates trigger UI state changes once per asset.

Completed work:

- Added a repository/app-service count API using the same filters as photo
  listing while ignoring pagination.
- Passed catalog,
  filtered,
  and visible counts through `ChronoPicHome` into mobile dashboard,
  browse,
  map,
  and timeline copy.
- Updated scan progress semantics so skipped assets count toward processed
  progress while final stats remain separated.
- Added a lazy-thumbnail capability for mobile media sources.
  Mobile import records metadata and asset IDs first;
  visible browse/detail/gallery surfaces request platform thumbnails lazily.
- Throttled progress callbacks so large scans do not rebuild the UI once per
  asset.
- Kept desktop directory import and desktop generated thumbnail cache behavior
  intact.

Exit gate:

- Flutter analyze passed.
- Dart package tests passed,
  including mobile scan progress and lazy-thumbnail coverage.
- Flutter UI tests passed,
  including full-count versus first-page-count regression coverage.
- Android deep E2E rejects first-page count being labeled as catalog total.
- Android debug build passed.
- `git diff --check` passed.
- iOS live verification remains blocked until macOS/Xcode evidence exists.
