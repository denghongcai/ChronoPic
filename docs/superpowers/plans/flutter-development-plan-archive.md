# ChronoPic Development Plan — Flutter Line Archive (Completed)

Archived completed plan phases for the Flutter rewrite line
(Phases 4.27-4.38 and Phases 6-14).

### 4.27 Flutter Rewrite Phase 0: Freeze Parity Contract ✅

- Start the Flutter rewrite line without scaffolding Flutter or Dart packages yet.
- Treat the current Electron app as the reference implementation until Flutter passes explicit parity gates.
- Keep this phase focused on migration safety, fixture definition, and acceptance boundaries.
- Do not change product runtime behavior in this phase.

Implementation breakdown:

1. Parity contract
- Define the user-visible workflows the Flutter rewrite must preserve:
  library setup,
  manual scan,
  browse/discovery,
  detail/gallery viewing,
  editing/rollback,
  favorites,
  memories,
  AI setup and queue,
  memory candidates,
  locale/settings,
  backup/preview/restore,
  accessibility,
  and desktop launch.
- Ground the contract in existing Electron tests and docs rather than inventing new semantics.

2. Reference fixture baseline
- Create a sanitized Electron backup fixture suitable for Dart parsing tests.
- Include expected derived counts and key authored/generated fields in a separate expected fixture.
- Keep fixture data deterministic and free of real user paths, real API keys, or real personal photos.

3. Refresh path
- Add a documented command or script that can refresh the Electron reference fixture from the current app behavior.
- Ensure the refresh path uses deterministic fixture media.

4. Handoff to Dart Phase 1
- Make the Phase 1 Dart domain/backup work point at the parity contract and fixtures.
- Do not start Dart model implementation until Phase 0 artifacts exist.

Current status:

- Completed locally on 2026-05-07.
- Added [docs/flutter-parity-contract.md](docs/flutter-parity-contract.md) as the Phase 0 parity contract.
- Linked Phase 0 from [docs/flutter-refactor-phases.md](docs/flutter-refactor-phases.md).
- Added sanitized Flutter parity fixtures under [tests/fixtures/flutter-parity/](tests/fixtures/flutter-parity/):
  [chronopic-backup-v1.json](tests/fixtures/flutter-parity/chronopic-backup-v1.json)
  and [chronopic-backup-v1.expected.json](tests/fixtures/flutter-parity/chronopic-backup-v1.expected.json).
- Added [scripts/write-flutter-parity-fixtures.mjs](scripts/write-flutter-parity-fixtures.mjs)
  and root script `pnpm run fixtures:flutter-parity` to refresh the fixture baseline.
- Added [tests/flutter-parity-fixtures.test.ts](tests/flutter-parity-fixtures.test.ts)
  to validate counts and migration-critical authored/generated fields.
- Verified with:
  `node --check scripts/write-flutter-parity-fixtures.mjs`,
  `node --experimental-strip-types --test tests/flutter-parity-fixtures.test.ts`,
  and `git diff --check`.

### 4.28 Flutter Rewrite Phase 1: Dart Domain And Backup Contract ✅

- Added the Flutter/Dart workspace under [chronopic_flutter/](chronopic_flutter/).
- Added [chronopic_domain](chronopic_flutter/packages/chronopic_domain/) with platform-neutral models for photos, metadata, semantic state, index state, library sources, edit history, memories, memory candidates, settings, filters, backups, and AI readiness.
- Added [chronopic_testkit](chronopic_flutter/packages/chronopic_testkit/) to load the committed parity fixtures from [tests/fixtures/flutter-parity/](tests/fixtures/flutter-parity/).
- Implemented Dart backup parsing, validation, preview counts, JSON re-emission, and fixture-backed compatibility tests.
- Verified with:
  `dart test packages/chronopic_domain`
  and `dart analyze packages/chronopic_domain packages/chronopic_testkit`.

### 4.29 Flutter Rewrite Phase 2: Drift Database And Repositories ✅

- Added [chronopic_database](chronopic_flutter/packages/chronopic_database/) with a repository facade for backup preview/restore/export, photo listing, caption/tag/favorite edits, memory CRUD, memory membership, and memory candidates.
- Added a Drift schema for `library_sources`, `photos`, `memories`, `memory_photos`, `edit_history`, and `memory_candidates`, plus generated Drift code.
- Kept the public app-facing database export focused on the repository facade; Drift internals are exposed only through [chronopic_database_testing.dart](chronopic_flutter/packages/chronopic_database/lib/chronopic_database_testing.dart) for package tests.
- Verified with:
  `dart run build_runner build`,
  `dart test test/repository_test.dart test/drift_database_test.dart`,
  and `dart analyze packages/chronopic_database`.
- Note: the Drift runtime test is run from `chronopic_flutter/packages/chronopic_database` so sqlite native asset hooks are available.

### 4.30 Flutter Rewrite Phase 3: Media Source Abstraction ✅

- Added [chronopic_media](chronopic_flutter/packages/chronopic_media/) with `MediaSourceAdapter`, media asset metadata, read results, permission state, stable IDs, supported-media filtering, and missing-asset handling.
- Implemented deterministic fixture media and a desktop directory adapter for recursive local media discovery.
- Verified with:
  `dart test packages/chronopic_media`
  and `dart analyze packages/chronopic_media`.

### 4.31 Flutter Rewrite Phase 4: Indexer And AI Pipeline ✅

- Added [chronopic_ai](chronopic_flutter/packages/chronopic_ai/) with disabled, fixture-success, and fixture-failure AI client implementations.
- Added [chronopic_app](chronopic_flutter/packages/chronopic_app/) with backup orchestration and an indexer service that consumes media adapters, skips unchanged assets, records missing assets, and writes AI state through the repository boundary.
- Verified with:
  `dart test packages/chronopic_ai packages/chronopic_app`
  and `dart analyze packages/chronopic_ai packages/chronopic_app`.

### 4.32 Flutter Rewrite Phase 5: Flutter Desktop MVP ✅

- Added [chronopic_ui](chronopic_flutter/packages/chronopic_ui/) with the first Flutter Material desktop MVP surface:
  first-run/library actions,
  scan action,
  search/filter controls,
  photo grid,
  favorites,
  memories,
  detail/edit surface,
  gallery surface,
  and backup/restore actions.
- Added the Linux Flutter app shell under [chronopic_flutter/apps/chronopic/](chronopic_flutter/apps/chronopic/).
- Queried the current Flutter stable toolchain and package resolver before finalizing dependencies:
  `flutter upgrade --verify-only` reports Flutter `3.41.9` stable is already current,
  and `flutter pub outdated` reports direct dependencies are up to date with the newest resolvable stable versions.
- Kept `test` at `1.30.0` because `1.31.1` is listed as latest but not resolvable under the current Flutter stable dependency graph.
- Verified with:
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  and `flutter build linux --debug`.

### 4.33 Flutter Rewrite Phase 5.5: Linux Desktop Feature Parity And E2E Gate

- Insert this phase before Android/iOS productization.
- Treat the current Electron desktop app as the reference behavior, but finish Linux Flutter desktop parity first.
- Keep this phase focused on real local-first desktop behavior rather than mobile permissions or packaging.

Implementation breakdown:

1. Real desktop library loop
- Add a Flutter Linux path-entry flow for registering a local library directory.
- Run manual scan through the Dart service layer and desktop media adapter.
- Preserve incremental scan semantics:
  imported assets are upserted,
  unchanged assets are skipped,
  unsupported files are ignored,
  and scan results remain visible in the catalog after multiple files are discovered.

2. Core parity actions
- Wire browse/search/favorite filtering to real service state.
- Wire detail selection to caption edit, tag edit, rollback, favorite toggle, and add-to-memory actions.
- Wire backup export, backup preview, and backup restore smoke actions to the Dart backup contract.

3. Linux parity E2E
- Add a deterministic Flutter test that creates a temporary local directory with supported and unsupported files.
- Drive the UI through add-library, scan, browse, search, favorite, edit, rollback, memory, and backup controls.
- Verify the exported backup preserves the same authored/generated fields that matter for Electron-to-Flutter migration.

4. Completion gate
- Do not start Phase 6 until this phase passes:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  and `flutter build linux --debug`.

Current status:

- Started locally on 2026-05-08.
- Implementation plan is tracked in [docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md](docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md).
- Electron-vs-Flutter Linux parity gaps are tracked in [docs/flutter-linux-desktop-parity-matrix.md](docs/flutter-linux-desktop-parity-matrix.md).
- First executable Linux parity slice completed locally on 2026-05-08:
  repository upsert/edit-history/memory actions,
  app-service desktop directory scan,
  real Flutter path-entry/scan controls,
  caption/tag/favorite/rollback controls,
  memory actions,
  backup smoke actions,
  and temp-directory parity tests.
- Additional Linux parity work completed locally on 2026-05-08:
  UI-driven empty-to-scanned library flow by entering a real Linux directory path and clicking `Scan Library`,
  native folder-picker entry point for first-run library selection,
  generated thumbnail cache files for scanned local images,
  local image preview rendering in grid/detail,
  focused gallery dialog open/close,
  gallery adjacent navigation through toolbar buttons and keyboard arrows,
  gallery Escape close behavior,
  video placeholders in the browse grid,
  desktop date/time fields for datetime correction,
  invalid date/time input handling,
  rollback coverage for caption, tags, favorite, and datetime edits,
  UI-level caption/tag/favorite/memory/backup smoke coverage,
  visible tag/GPS/date/sort filter controls,
  repository coverage for AI status/date/sort filter semantics,
  Favorites navigation filtering coverage,
  and explicit JSON backup export/preview/restore through a Linux file path.
- Backup error coverage now includes malformed JSON handling in both service and Flutter UI tests.
- Flutter backup UI now includes native `file_selector` save/open picker entry points through `choose-backup-export-path` and `choose-backup-restore-path`.
- Flutter AI status panel now exposes secret-safe readiness, per-status AI queue counts, and memory candidate count.
- Flutter Linux desktop now creates a persistent default app service backed by the existing backup JSON contract under the local data directory, and service/UI tests verify that library state, caption/tag edits, favorite state, and memory membership reload in a fresh service or Flutter shell.
- Flutter memory lifecycle now covers detail editing, rename, description edit, set cover, remove selected photo from memory, and persistence through repository/service/UI parity tests.
- Flutter detail metadata now shows captured local date/time, local UTC offset, original date text, camera, GPS, MIME, and size; the Linux parity test verifies the visible metadata grid after datetime correction.
- Flutter browse grid now uses adaptive desktop column counts and has larger-library coverage from an 18-photo scanned Linux fixture directory plus widget-level wide/narrow layout assertions.
- Flutter detail keyboard parity now covers selected-photo shortcuts for favorite toggle, rollback, and gallery open.
- Flutter map and timeline browse modes now run from the same visible result set:
  map mode lists GPS-backed photos and coordinates,
  while timeline mode groups photos by local capture date.
- Flutter AI provider settings, failed-queue retry, and memory candidate accept/reject actions are now wired through repository/service/UI tests.
- Flutter gallery now has a dark fullscreen shell with counter, keyboard hint, filmstrip, button navigation, keyboard navigation, and Escape close coverage.
- Flutter desktop i18n now includes English/Simplified Chinese UI dictionaries, a visible locale switcher, and Chinese coverage for critical shell/import/backup/memory/browse text.
- Flutter manual scan status now distinguishes imported, updated, skipped, error, and missing counts.
- Flutter search/filter UX now exposes an active-filter summary for applied query, tag, GPS, AI status, date, favorite, memory, and sort state.
- Flutter caption/tag editing now includes visible validation for caption length, tag length, tag count, and duplicate-tag normalization.
- Flutter Linux parity E2E now asserts visible rollback state for caption, tags, favorite, and datetime edits.
- Flutter backup export E2E now compares exported JSON photos, memories, memoryPhotos, and settings against the live backup snapshot.
- Native folder/save/open picker behavior is treated as an accepted headless-test difference for Phase 5.5:
  the Flutter UI exposes `file_selector` entry points, while deterministic widget E2E drives typed Linux paths because native portal dialogs are not operable inside Flutter widget tests.
- Final Phase 5.5 verification passed locally on 2026-05-08 with:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  `dart test test/repository_test.dart test/drift_database_test.dart` from [chronopic_flutter/packages/chronopic_database/](chronopic_flutter/packages/chronopic_database/),
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  `flutter build linux --debug`,
  and `git diff --check`.
- Phase 5.5 is complete locally against the documented Linux desktop parity gate.
- Phase 6 Android/iOS productization may start only from this completed Linux desktop baseline.

### 4.34 Flutter Desktop UI Refine And Component Parity Phase

- Treat the current Electron desktop UI as the product-quality reference for the Flutter Linux desktop shell.
- Refine the Flutter UI before mobile work:
  the current Phase 5.5 surface is behavior-complete but still reads like a dense Material test harness.
- Split `chronopic_home.dart` into focused UI modules for:
  localization,
  theme,
  shell/sidebar/page routing,
  home browse,
  library controls,
  filters,
  grid/map/timeline browse,
  detail editing,
  gallery,
  memories,
  settings,
  AI status,
  and backup controls.
- Rebuild Flutter desktop information architecture around the Electron structure:
  persistent left sidebar,
  home page,
  memories page,
  memory detail page,
  settings page,
  notifications/AI work queue page,
  browse toolbar,
  and focused viewer.
- Preserve every Phase 5.5 behavior and stable test key unless the matching test is intentionally updated in the same slice.
- Keep this phase desktop-focused:
  no Android/iOS UI or media permission work until the Flutter desktop UI is product-quality.
- Design spec:
  [docs/superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md](docs/superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md)
- Implementation plan:
  [docs/superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md](docs/superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md)
- Current status:
  complete locally on 2026-05-08.
- Implementation result:
  `chronopic_home.dart` is now the service/state orchestration shell,
  and Flutter UI rendering is split across focused modules for shell,
  home,
  filters,
  browse,
  detail,
  gallery,
  memories,
  settings,
  localization,
  and theme.
- The default home surface now follows the Electron information architecture:
  persistent desktop sidebar,
  dedicated Memories,
  Memory Detail,
  Settings,
  and Notifications pages,
  compact library/search/filter controls,
  focused detail inspector,
  and fullscreen gallery dialog.
- Verification:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  `dart test test/repository_test.dart test/drift_database_test.dart` from [chronopic_flutter/packages/chronopic_database/](chronopic_flutter/packages/chronopic_database/),
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  `flutter build linux --debug`,
  `flutter pub outdated`,
  Linux bundle screenshot smoke launch with
  `xvfb-run -a -s "-screen 0 1600x1200x24"` and `LIBGL_ALWAYS_SOFTWARE=1`,
  and `git diff --check`.
- Dependency audit:
  `flutter pub outdated` reports all direct dependencies are already at the newest resolvable versions;
  newer transitive/dev versions are not mutually compatible with the current resolved toolchain.
- Runtime screenshot evidence:
  `test-results/flutter-ui-refine-xvfb-window.png` captured the Linux debug bundle first-run desktop window at 1280x720.
  The screenshot is intentionally kept under the ignored `test-results/` directory.

### 4.35 Flutter Electron UI And Functional Parity Phase

- Continue desktop-first work before Phase 6 mobile productization.
- Treat Electron as the reference product surface and Flutter Linux desktop as the candidate implementation.
- Align UI and functionality through a repeated loop:
  capture Electron screenshots,
  capture Flutter screenshots,
  compare them in a parity matrix,
  fix concrete gaps,
  then rerun both sides' tests and screenshots.
- Required reference surfaces:
  empty first-run home,
  populated grid/waterfall browse,
  map or disabled-map state,
  timeline,
  detail inspector and editing,
  fullscreen gallery,
  favorites,
  memories list,
  memory detail,
  settings,
  notifications/AI queue,
  Chinese locale,
  and restart persistence.
- Add durable parity matrix:
  [docs/flutter-electron-ui-functional-parity.md](docs/flutter-electron-ui-functional-parity.md)
- Add acceptance spec:
  [docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md](docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md)
- Add implementation plan:
  [docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md](docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md)
- Current status:
  phase handoff completed on 2026-05-09 and pushed to
  `flutter-refactor-phases`.
  Capture harnesses are landed for Electron and Flutter.
  First shell/home/browse/detail alignment slice is implemented and screenshot-backed;
  gallery/detail/favorites/editing alignment task is implemented and screenshot-backed;
  memory list/detail alignment is partially implemented and screenshot-backed;
  notifications/settings alignment is partially implemented and screenshot-backed;
  map/timeline first-viewport alignment is partially implemented and screenshot-backed,
  including an Electron-like pale disabled-map canvas in the Flutter Map surface
  and an Electron-like light timeline card with selected-photo banner in the Flutter Timeline surface;
  Chinese locale first-viewport alignment is partially implemented and screenshot-backed;
  all 13 Flutter parity screenshots have been recaptured at the Electron reference size of 1440x920;
  no unexamined `Gap` rows remain in the parity matrix;
  all rows are either matched by behavior or closed as documented accepted
  renderer/fixture differences.
  The populated-grid, favorites, and restart-persistence Flutter surfaces now
  show an Electron-like selected-photo banner above the grid when a photo is selected.
  Detail capture now uses an immersive Electron-like focused dark viewer with
  a large media canvas, right-side metric-card inspector, AI insights,
  gallery strip, keyboard hint, and real add/close/gallery actions instead of
  a plain inline detail page or normal Flutter shell chrome.
  Gallery capture now uses a bordered dark media frame, metadata below the
  image instead of a large scrim, an Open Inspector action, and a separate
  framed gallery strip closer to Electron's viewer hierarchy.
  Populated browse, favorites, and restart-persistence surfaces now include a
  functional Electron-like discovery lens row where Map, Timeline, and Memory
  chips navigate to real app surfaces instead of acting as visual-only hints.
  Notifications now use an Electron-like outer container with separate AI queue
  and Memory candidates cards while preserving retry and memory-review actions.
  Notifications now also place the page title inside the white content card and
  use Electron-like blue/red/green/yellow semantic chips for AI queue,
  failed,
  ready,
  and memory candidate states.
  Settings now use Electron-like primary library actions, backup action grouping
  with `LOCAL JSON`, and an AI Enrichment readiness card with `PRESENT` pills
  while preserving path-based backup/restore and secret-safe AI editing.
  Settings now also keeps the first viewport focused on the Electron-like
  Library Settings card with Add Folder and Scan Library,
  moves manual path import into a lower panel,
  and uses Electron-like orange/white/blue/green action and status semantics
  for restore,
  language save,
  backup format,
  and AI readiness.
  Shared desktop shell chrome now moves notifications into the sidebar header,
  replaces the previous Notifications nav row with an Electron-like Recent row,
  adds a bottom Create Memory action,
  and hides the idle scan status bar so non-immersive pages start at the same
  top content position as Electron.
  Browse controls now use Electron's `Waterfall` label instead of `Grid`,
  including the Simplified Chinese `瀑布流` label,
  and the selected-photo banner now uses Electron's memory-membership copy.
  Focused detail capture now selects the same first fixture photo as Electron
  and exposes Electron-like add,
  close,
  previous,
  next,
  and Gallery top controls with dark/disabled/highlight states.
  Focused detail inspector status now reports file/index health as `HEALTHY`
  while keeping AI failure information in AI-specific fields,
  matching Electron's inspector semantics.
  Fullscreen gallery now removes the extra back/X controls,
  uses dark Detail View/Open Inspector actions,
  shows date plus time,
  uses Electron's `NOT IN ANY MEMORY` and `2 ITEMS` copy,
  and keeps the dark framed media/filmstrip hierarchy.
  Settings backup JSON path controls now live in a lower file-path panel so the
  first viewport matches Electron's backup card density while preserving
  path-based export/restore workflows.
  Browse media cards now use a lower-density desktop grid, larger cards,
  bottom gradient metadata, and improved missing-media fallback so populated,
  favorites, and restart-persistence evidence more closely matches Electron's
  media-card hierarchy.
  Global Flutter desktop brand chrome now matches Electron's `ChronoPic` /
  `Photo workspace` labels instead of identifying the rewrite as
  `ChronoPic Flutter`.
  Empty first-run now uses `Add Folder` as the primary folder-picker action
  while preserving the explicit path-based `Add Library` control below.
  Empty first-run now also removes the lower path-based library toolbar and
  full filter panel from the first viewport,
  keeps those operational controls available in Settings,
  and adds a `Create First Memory` CTA to the recent-memory empty state.
  Filter controls remain visible when an active filter/search returns zero
  photos,
  so filtered-empty states do not regress into onboarding.
  Populated grid,
  Favorites,
  and Restart Persistence now use Electron-like compact `Select` / `Filter`
  browse-toolbar affordances by default instead of rendering the full filter
  panel in the first viewport;
  the full filter panel remains available behind `Filter` and stays visible for
  active search/tag/GPS/AI/date/sort states.
  Map and Timeline screenshots were recaptured after the compact toolbar pass,
  so both now inherit reduced first-viewport toolbar density while preserving
  the disabled-map and timeline-card behavior already implemented.
  Browse media cards now use a taller card ratio,
  and photo/memory fallback surfaces now share an Electron-like edge treatment
  with top path/name text instead of a centered broken-image icon.
  Memories list now has an Electron-like `SUGGESTED MEMORIES` header,
  a real Generate/refresh affordance,
  title-card candidate treatment,
  `Adjust photos`,
  and candidate accept/reject actions aligned more closely with Electron.
  Memory list/detail/home cards now use framed media-style cover fallback
  treatment instead of centered icon-only gradient blocks.
  Memory detail now uses a read-first hero with compact actions and moves
  editable metadata controls into a lower management panel.
  Memory detail now also uses Electron-like updated timestamp formatting,
  a `STORY OUTLINE` section,
  and chapter-card metadata for month/day,
  mapped count,
  and AI readiness.
  Full Flutter-side verification for this phase has been rerun with
  `dart analyze packages/chronopic_app packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `bash tool/capture_flutter_parity.sh all`,
  and a `file` check confirming all 13 Flutter PNGs are 1440x920.
  Electron-side verification has also been rerun:
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
- Next execution plan:
  keep Phase 6 mobile productization blocked until the pushed Flutter desktop
  parity branch is reviewed or merged.

### 4.36 Viewer Overlay Activation Parity Phase

- Continue desktop-first parity after code comparison found a missed interaction
  contract in Phase 5.7:
  primary photo-card activation and in-overlay Detail/Gallery switching were
  not consistently aligned to the Electron reference.
- Treat the expected desktop behavior as:
  single click selects,
  double-click or double-tap opens the focused Detail viewer overlay,
  Enter opens the same focused Detail/inspector overlay,
  `G` opens gallery for the selected photo,
  Gallery overlay `D` / `Detail View` returns to the focused Detail overlay,
  and `Escape` closes the active overlay while preserving selection.
- Electron comparison finding:
  `packages/ui-components/src/photo-card.tsx`
  correctly wires `onDoubleClick` to detail mode,
  while `packages/ui-components/src/photo-viewer-overlay.tsx`
  supports Detail and Gallery as two modes inside the same fullscreen Radix
  viewer overlay.
- Flutter comparison finding:
  `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  previously wired photo cards only to selection,
  while `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
  provides the fullscreen Gallery mode and now returns explicitly to focused
  Detail mode for `D` / `Detail View`.
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md](docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md)
- Required verification:
  Electron E2E must prove double-click opens Detail,
  the in-overlay Gallery button switches to Gallery,
  and `D` switches Gallery back to Detail;
  Flutter widget/parity tests must prove double-tap opens focused Detail,
  Gallery can be opened from that overlay,
  and `D` / `Detail View` returns to focused Detail;
  both sides must recapture and compare populated browse,
  Detail,
  and Gallery screenshots before closing the corrected matrix rows.
- Current status:
  corrected locally on 2026-05-09 after user review clarified the Electron
  reference interaction;
  correction commit `96ba222` restores Detail-first card activation and
  fixes Flutter Gallery-to-Detail switching.
- Local verification:
  Electron accessibility E2E now covers Enter-to-Detail,
  double-click-to-Detail,
  Detail-to-Gallery,
  Gallery `D`-to-Detail,
  selected-card `G`-to-Gallery,
  and Escape close;
  Flutter parity tests now cover card double-tap-to-focused-Detail,
  focused Detail-to-Gallery,
  Gallery `D`-to-focused-Detail,
  selected-photo `G`-to-Gallery,
  Enter-to-focused-Detail,
  and Escape close.
- Screenshot comparison:
  refreshed Electron and Flutter populated browse,
  Detail,
  and Gallery screenshots are 1440x920;
  side-by-side comparison artifacts are under
  `test-results/flutter-electron-parity/compare/`.

### 4.37 Full Feature UI Parity Review Phase

- Purpose:
  review every Electron-vs-Flutter desktop feature surface and UI state with
  code,
  tests,
  and refreshed screenshot evidence before further broad UI work.
- Method:
  review Electron reference code/runtime first,
  compare Flutter implementation,
  run or add focused tests for behavior,
  refresh screenshots,
  inspect side-by-side compare artifacts,
  and classify each finding as `Matched`,
  `Accepted Difference`,
  or `Gap`.
- Surfaces:
  empty home,
  populated grid,
  map,
  timeline,
  detail,
  gallery,
  favorites,
  memories list,
  memory detail,
  settings,
  notifications,
  Chinese locale,
  and restart persistence.
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-feature-ui-parity-review.md](docs/superpowers/plans/2026-05-09-feature-ui-parity-review.md)
- Detailed review report:
  [docs/flutter-electron-feature-ui-review.md](docs/flutter-electron-feature-ui-review.md)
- Current status:
  reviewed on 2026-05-09.
  Full Electron and Flutter screenshot evidence was refreshed,
  all 13 side-by-side compare artifacts were generated,
  and the detailed review found one confirmed parity gap:
  Flutter zh mode still contains app-owned English UI strings.
  Verification passed after the review:
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm typecheck`,
  `pnpm build`,
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`,
  and
  `git diff --check`.
- Follow-up:
  visible-string localization parity has been promoted to Phase 4.38.

### 4.38 Flutter Visible String Localization Parity Phase

- Purpose:
  close the confirmed Flutter Chinese-locale UI parity gap by removing
  app-owned English strings from zh mode while preserving source-authored user
  content.
- Reference finding:
  `FUI-001` in
  [docs/flutter-electron-feature-ui-review.md](docs/flutter-electron-feature-ui-review.md).
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md](docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md)
- Scope:
  selected-photo banners,
  active filter labels,
  status messages,
  Detail/Gallery controls,
  memory list/detail actions,
  settings actions,
  notifications,
  map controls,
  and timeline actions.
- Test requirement:
  add failing zh assertions before changing strings,
  then refresh the affected Flutter screenshots and compare artifacts.
- Current status:
  implemented and verified on 2026-05-09.
- Result:
  Flutter app-owned zh UI is localized across selected-photo banners,
  active filter labels,
  status messages,
  Detail/Gallery controls,
  memory actions,
  settings,
  notifications,
  map,
  and timeline surfaces.
  Source-authored filenames,
  captions,
  memory names,
  imported descriptions,
  and AI/fixture content remain untranslated.
- Verification:
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts`,
  and
  `git diff --check`
  all pass.


### 6. Flutter Mobile Productization

- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md](docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md)
- Scope:
  Android/iOS runner scaffolding,
  Android-first photo-library permissions,
  mobile-native onboarding,
  resumable scan UX,
  metadata-only backup/restore semantics,
  Android smoke verification,
  and iOS verification constraints.
- Current status:
  implemented and locally verified on 2026-05-09 through the Linux workstation
  gates that are available here.
  Android runners,
  photo/media permissions,
  photo-library media source,
  mobile scan orchestration,
  mobile onboarding,
  Android user-state toolchain,
  Android debug APK build,
  and Android emulator smoke are complete.
  Android smoke passed on `emulator-5554`
  (`Android SDK built for x86_64`,
  Android 16/API 36) for denied permission recovery,
  selected-photo limited access,
  full-access import,
  restart persistence,
  and metadata backup restore.
  iOS runner metadata and photo-library usage descriptions are scaffolded and
  statically reviewed,
  but iOS real-device verification requires macOS/Xcode.
- Execution order:
  start with Android tooling/readiness and platform scaffolding,
  then implement the mobile `MediaSourceAdapter`,
  then wire app-service scan progress,
  then adapt the UI,
  then run Android smoke.
- Constraint:
  iOS code/config can be prepared on this Linux workstation,
  but iOS real-device verification must be done from macOS/Xcode before the
  iOS exit gate can be closed.
- Verification evidence:
  Electron regression gates pass with `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  and
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`.
  Flutter regression gates pass with Dart analyze,
  Dart package tests,
  Flutter UI/parity tests,
  `flutter build apk --debug`,
  and Android emulator smoke on `emulator-5554`.
- Remaining before Phase 7 cutover:
  complete Phase 6.5 mobile deep E2E verification;
  run the iOS build/run gate from macOS/Xcode;
  then handle release signing,
  mobile privacy disclosures,
  and migration/cutover packaging.

### 6.5 Flutter Mobile Deep E2E Verification

- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md](docs/superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md)
- Scope:
  deepen mobile validation after Phase 6 by adding a repeatable Android
  emulator E2E runner,
  Flutter integration coverage for app-owned mobile workflows,
  stable mobile test hooks,
  durable screenshot/XML/backup evidence,
  and an explicit iOS macOS/Xcode verification gate.
- Current status:
  completed locally on 2026-05-10.
  The evidence matrix,
  stable mobile hooks,
  Android permission/import/restart/backup runner,
  app-owned Android integration workflow test,
  iOS macOS/Xcode evidence gate,
  and full closeout verification have landed locally.
- Execution order:
  first create the mobile E2E evidence matrix,
  then add stable mobile test hooks,
  then automate Android permission/import/restart/backup checks,
  then add app-owned integration tests for edit/favorite/memory/detail/gallery/search/settings flows,
  then record iOS requirements and close out the phase.
- Constraint:
  Android permission dialogs and selected-photo picker flows must be driven by
  `adb`/`uiautomator` because they are outside Flutter's widget tree.
  iOS remains pending until macOS/Xcode evidence exists.
- Exit gate:
  Android deep E2E is repeatable from a clean emulator state and covers denied,
  limited,
  full-access,
  restart persistence,
  metadata backup restore,
  and key app-owned workflows.
  iOS evidence is either completed from macOS/Xcode or explicitly recorded as
  pending with exact commands and required screenshots.
- Remaining before Phase 7 cutover:
  run iOS verification from macOS/Xcode when available before treating iOS as
  release-verified,
  then proceed to release signing,
  mobile privacy disclosures,
  and migration/cutover packaging.

### 6.6 Flutter Linux Desktop Parity Hardening

- Status:
  completed locally on 2026-05-10 after Phase 6.5.
- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md](docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md)
- Scope:
  refresh Electron and Flutter Linux parity evidence after Phase 6/6.5,
  inspect all 13 side-by-side compare artifacts,
  preserve or repair desktop parity before Phase 7 release work starts.
- Method:
  run Electron and Flutter Linux against the same parity fixtures,
  capture screenshot evidence for home/library,
  gallery/detail overlay,
  memory list/detail,
  search/filter/sort,
  settings,
  notifications,
  Chinese locale,
  and restart persistence,
  then fix only confirmed mismatches until the Flutter desktop app remains
  functionally and visually aligned with the Electron reference.
- Exit gate:
  all 13 Electron screenshots,
  all 13 Flutter Linux screenshots,
  and all 13 compare artifacts are refreshed;
  `docs/flutter-electron-ui-functional-parity.md` and
  `docs/flutter-electron-feature-ui-review.md` are updated with Phase 6.6
  findings;
  any confirmed gap has a focused test or documented coverage path;
  Electron and Flutter desktop parity verification commands pass.
- Result:
  no new product UI/function gap was found beyond existing accepted renderer
  differences.
  Two parity-harness gaps were closed:
  `P66-001` normalized Flutter capture locale for normal English surfaces,
  and `P66-002` isolated Playwright artifacts so E2E runs no longer delete
  parity screenshot evidence.

### 7. Flutter Release Readiness And Cutover

- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md](docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md)
- Status:
  complete on 2026-05-10.
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
- Planned execution order:
  1. Android deep E2E runner hardening:
     improve `adb`/`uiautomator` retry logging,
     assert required screenshot/XML/backup artifacts after every run,
     write summary JSON,
     and repeat the clean-emulator runner twice to catch flake before release
     work starts.
     Implementation status:
     helper,
     runner logging/summary hardening,
     two-run wrapper,
     and live two-run emulator evidence are complete.
     Evidence:
     `.tmp/mobile-e2e/android-repeat/20260510T044545Z/combined-summary.json`
     reports `passed`.
  2. Migration and cutover compatibility:
     verify Flutter backup import against a sanitized real Electron backup
     fixture,
     document the Electron-to-Flutter migration path,
     and decide whether direct old SQLite import is still needed after backup
     import coverage is proven.
     Implementation status:
     complete.
     Evidence:
     `pnpm run e2e:backup`,
     `node scripts/write-flutter-migration-fixtures.mjs`,
     and
     `cd chronopic_flutter && dart test packages/chronopic_app/test/electron_backup_import_test.dart`
     pass.
     Direct old SQLite import is not required for Phase 7 unless JSON backup
     export/restore fails on a real user backup.
  3. Release signing and Android distribution readiness:
     add secret-safe signing configuration,
     build release APK/AAB artifacts,
     record Play Store photo-permission/privacy disclosure text,
     and document the Android release checklist.
     Implementation status:
     complete for technical release verification.
     Phase 10 updates the production `applicationId` to `ai.chronopic.app`.
     Evidence:
     unsigned/missing-signing release build fails with a clear message,
     local signed release APK/AAB build passes,
     and
     `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`
     verifies APK/AAB/Linux sha256 files.
  4. Flutter Linux release artifact:
     build `chronopic-flutter-linux-x64-0.1.7.tar.gz`,
     create `.sha256`,
     and verify the archive contains the Flutter `chronopic` executable.
     Implementation status:
     complete locally.
     Evidence:
     `chronopic_flutter/tool/release/build_linux_release.sh`
     and
     `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs linux`
     pass.
  5. CI gate promotion:
     add or extend CI/manual workflows for Flutter analyze,
     Dart package tests,
     Flutter UI/parity tests,
     Android debug build,
     and optionally a manually triggered Android emulator E2E workflow.
     Implementation status:
     complete.
     CI now has a Flutter job,
     `.github/workflows/android-deep-e2e.yml` provides a manually triggered
     Android emulator deep E2E gate,
     Electron package verification is no longer a CI release gate,
     and Android deep E2E remains both a local and manual CI Phase 7 gate.
  6. Flutter release workflow:
     replace Electron tag-release assets with Flutter Android and Flutter Linux
     artifacts.
     Do not publish new Electron release assets.
     Implementation status:
     complete.
     Tag release workflow now uploads Flutter Android and Flutter Linux assets
     only.
     iOS remains blocked until macOS/Xcode signing and E2E evidence exist.
- Final Phase 7 gate:
  passed on 2026-05-10.
  Evidence:
  `pnpm test && pnpm typecheck && pnpm build`,
  Flutter analyze/package tests/widget tests,
  `flutter build apk --debug`,
  Android two-run E2E hardening,
  signed Android release build,
  Linux release build,
  combined Android/Linux artifact verification,
  and `git diff --check` all passed locally.
- Version rule:
  before adding or changing dependencies,
  GitHub Actions,
  Android SDK/Gradle/Flutter setup,
  or release tooling,
  check the latest stable version from official sources and record the selected
  version in `AGENTS.md`.
- iOS:
  keep the existing macOS/Xcode live verification gate blocked until real
  Apple-toolchain evidence exists.

### 8. Flutter Adaptive Import And Performance Hardening

- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-adaptive-import-performance.md](docs/superpowers/plans/2026-05-10-flutter-adaptive-import-performance.md)
- Status:
  completed locally on 2026-05-10.
- Scope:
  repair Flutter desktop adaptive layout,
  make the waterfall browse surface genuinely lazy,
  add Android photo-library scope selection before scanning,
  and reduce blocking mobile scan work.
- Root causes confirmed on 2026-05-10:
  1. Desktop/mobile browse pages are wrapped by shell-level
     `SingleChildScrollView` containers and centered max-width frames.
     On wide desktop this creates large dead space and prevents the browse page
     from owning its own viewport.
  2. The waterfall grid uses `GridView.builder`, but it is configured with
     `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside the
     shell-level scroll view.
     That means large result sets participate in one page layout instead of
     being virtualized by the viewport.
  3. Android scanning is currently hard-coded to the synthetic full-library
     path:
     `PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: true)`
     followed by `paths.first.getAssetListPaged(page: 0, size: 100000)`.
     The user cannot choose a specific album/folder-like scope.
  4. Mobile import reads original asset bytes for changed items and thumbnail
     generation decodes/resizes/writes synchronously on the scan path, which can
     make Android import slow and visibly stuck on larger libraries.
- Dependency/version note:
  `photo_manager` was checked against the pub.dev package API on 2026-05-10;
  latest stable is `3.9.0`, matching the current workspace dependency.
- Planned execution order:
  1. Responsive browse viewport:
     let the home/browse page own its scroll viewport,
     align desktop content to the available content area instead of centering
     a narrow column,
     and keep non-browse settings/memory pages scroll-safe.
  2. Lazy waterfall:
     replace the shrink-wrapped browse grid with a sliver grid,
     add incremental query limits and scroll-threshold loading,
     and reset pagination whenever filters, sort, favorites, memory scope, or
     library scope changes.
  3. Android scoped import:
     expose photo-library scopes from `photo_manager`,
     let the user select a concrete scope before scanning,
     and keep All Photos as an explicit choice instead of an invisible default.
  4. Scan responsiveness:
     page mobile asset discovery,
     avoid original-byte reads when thumbnail bytes are enough,
     move CPU-heavy thumbnail work away from synchronous UI-visible scan steps,
     and preserve progress reporting.
  5. Verification:
     run focused Flutter widget tests,
     Dart package tests,
     Flutter analyze,
     Android debug build,
     Android scoped-import E2E where emulator tooling is available,
     and desktop screenshot comparisons at 1366/1600/2048 widths.
- Completion criteria:
  completed on 2026-05-10 with passing code/tests and recorded screenshot/E2E
  evidence.
- Implementation completed on 2026-05-10:
  1. Browse pages now own their viewport instead of being wrapped by the global
     shell scroll frame.
     The home page uses a `CustomScrollView` and sliver grid,
     while non-browse pages keep local scroll behavior.
  2. Waterfall query/render volume is incremental:
     initial result limit is 20 photos,
     scroll-near-end and the fallback load-more control increase the limit by
     20,
     and search/filter/sort/favorites/memory changes reset pagination.
  3. Android import now exposes `PhotoLibraryScope` choices from
     `photo_manager`.
     The user selects `All Photos` or a concrete album/path-like scope before
     scanning,
     and the selected scope is persisted in the source path for that scan.
  4. Mobile asset discovery is paged in `PhotoManagerGateway` instead of
     requesting 100000 assets in one call.
     Disabled-AI scans prefer thumbnail bytes and avoid reading original bytes,
     while thumbnail decode/resize/write runs through `Isolate.run`.
  5. The Android deep E2E runner now validates the scoped-import sheet in both
     full-access and limited-access flows,
     including `03-scope.xml`,
     `04-scope.xml`,
     and artifact assertions for the selected `ChronoPicDeepE2E` scope.
- Verification evidence:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build linux --debug`,
  `ANDROID_DEVICE_ID=emulator-5554 MOBILE_E2E_RUN_ID=phase8-final-20260510T122821Z chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`,
  and
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android/phase8-final-20260510T122821Z`
  all passed.
- Screenshot evidence:
  `test-results/flutter-adaptive-phase8/1366-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/1600-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/2048-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/1366-detail.png`,
  `test-results/flutter-adaptive-phase8/1600-detail.png`,
  and
  `test-results/flutter-adaptive-phase8/2048-detail.png`.
- Post-release interaction correction on 2026-05-10:
  fixed a Flutter desktop regression where single-click selection appended an
  inline `DetailSurface` below the waterfall page.
  The Electron parity contract remains:
  single click selects only,
  double click or Enter opens focused Detail,
  and Gallery remains a focused overlay mode.
  Focused Detail now shows save/validation status inside the inspector overlay
  so edit feedback is visible without relying on the hidden shell status bar.
- Post-release correction verification:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  and
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh populated-grid detail`
  all passed.
  Screenshot evidence:
  `test-results/flutter-electron-parity/flutter/02-populated-grid.png`
  confirms selected browse state has no bottom inline detail,
  and
  `test-results/flutter-electron-parity/flutter/05-detail.png`
  confirms focused Detail remains available.

### 9. Flutter Desktop Interaction Regression Audit

- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-desktop-interaction-regression-audit.md](docs/superpowers/plans/2026-05-10-flutter-desktop-interaction-regression-audit.md)
- Status:
  completed locally on 2026-05-10.
- Scope:
  run an evidence-first desktop interaction audit after the v0.1.6
  selected-photo regression,
  compare Flutter Linux against the Electron reference,
  and re-check desktop adaptive layout at multiple widths.
- Explicit decisions:
  GitHub Actions `startup_failure` is no longer tracked as a current blocker
  because the user handled it outside this phase.
  Real Electron migration samples are no longer in scope;
  do not spend this phase on Electron-to-Flutter data migration validation.
- Audit surfaces:
  Waterfall,
  Map,
  Timeline,
  Detail overlay,
  Gallery overlay,
  Favorites,
  Memories list/detail,
  Settings,
  Notifications,
  Chinese locale,
  and restart persistence.
- Interaction checks:
  single click selects only,
  double click opens focused Detail,
  Enter opens focused Detail from selection,
  `G` opens or switches to Gallery,
  `D` switches back to Detail,
  Escape closes overlays,
  arrow keys navigate adjacent media,
  edit feedback remains visible inside focused Detail,
  and browse pagination still starts at 20 items with incremental loading.
- Adaptive checks:
  capture and inspect desktop browse/detail evidence at 1366,
  1600,
  and 2048 pixel widths;
  check for sidebar overlap,
  toolbar wrapping,
  selected banner clipping,
  card density problems,
  overlay inspector clipping,
  and edit-field scroll reachability.
- Exit gate:
  all audit rows in `docs/flutter-desktop-interaction-regression-audit.md`
  are marked `Matched`,
  `Fixed`,
  or `Accepted Difference`;
  Electron and Flutter screenshots are refreshed where relevant;
  focused Flutter widget/parity tests pass;
  and any confirmed mismatch has a regression test or documented accepted
  difference.
- Closeout evidence:
  refreshed Electron screenshots are under
  `test-results/flutter-electron-parity/electron/*.png`;
  refreshed Flutter screenshots are under
  `test-results/flutter-electron-parity/flutter/*.png`;
  compare artifacts are under
  `test-results/flutter-electron-parity/compare/*.png`;
  desktop adaptive browse/detail captures are under
  `test-results/flutter-adaptive-regression/*.png`.
- Verification:
  `pnpm build`,
  `node scripts/capture-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  `node scripts/compare-flutter-electron-parity.mjs`,
  `cd chronopic_flutter && bash tool/capture_flutter_adaptive_regression.sh`,
  and the focused Flutter UI/parity test suite passed.

### 10. Flutter Mobile UI Refine

- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-mobile-ui-refine.md](docs/superpowers/plans/2026-05-10-flutter-mobile-ui-refine.md)
- Status:
  completed locally on 2026-05-10.
- Scope:
  refine the Flutter mobile UI into a production-quality Android touch
  experience while preserving the existing desktop contract.
- Product identity decision:
  the Android production package id is `ai.chronopic.app`.
  The mobile UI refine phase should update Android package identity,
  Android E2E package constants,
  and related docs.
  iOS bundle metadata can be prepared with the same id,
  but live iOS verification remains blocked until macOS/Xcode evidence exists.
- Explicit non-goals:
  do not re-open real Electron migration sample validation;
  do not mix desktop redesign into the mobile UI refine phase;
  do not claim iOS live verification from this Linux workstation.
- Mobile refine surfaces:
  first-run entry,
  permission denied recovery,
  scoped photo import,
  scan progress,
  browse waterfall,
  search/filter/sort,
  Detail overlay,
  Gallery overlay,
  metadata editing,
  favorites,
  memories,
  settings,
  backup/restore,
  restart persistence,
  and restore verification.
- Design checks:
  mobile first-run should prioritize photo-library selection,
  touch targets should be at least 48px,
  dense desktop toolbar patterns should become mobile-appropriate sheets or
  stacked controls,
  overlay controls should respect safe areas,
  edit feedback should be visible inside the active surface,
  and no horizontal overflow should appear at phone widths.
- Exit gate:
  Flutter analyze,
  Dart package tests,
  Flutter UI/mobile tests,
  Android debug build,
  Android deep E2E artifact assertions,
  and updated mobile UI evidence docs all pass locally.
- Closeout evidence:
  Android package id is now `ai.chronopic.app` across the Android app,
  Android E2E scripts,
  iOS bundle metadata,
  Linux application id,
  and docs.
  Final Android deep E2E artifacts are under
  `.tmp/mobile-e2e/android/phase10-final-browse-state/`;
  `summary.json` reports `status: passed` and
  `packageName: ai.chronopic.app`.
- Verification:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `MOBILE_E2E_RUN_ID=phase10-final-browse-state bash chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
  passed locally.
- Release:
  `v0.1.7` was published on 2026-05-11 from tag
  `cfd5d9f1f0197852886b83acb76543b3fcd2d160`.
  Main CI run `25646589595` passed before tagging.
  Release workflow run `25646732907` passed and uploaded Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and all matching checksum assets.
  Post-publication verification downloaded the public release assets into
  `.tmp/release-verify/v0.1.7`,
  checked the three sha256 files,
  and confirmed the Linux tarball contains the `chronopic` executable.

### 11. Flutter Mobile Native Experience Redesign

- Implementation plan:
  [docs/superpowers/plans/2026-05-11-flutter-mobile-native-experience-redesign.md](docs/superpowers/plans/2026-05-11-flutter-mobile-native-experience-redesign.md)
- Status:
  complete locally on 2026-05-11.
- Source input:
  user-provided mobile UI refine proposal reviewed on 2026-05-11.
- Goal:
  expand Phase 10 from touch usability into a mobile-native ChronoPic product
  shape.
  Mobile should keep the same local-first data model and core workflows as
  desktop,
  but it should no longer look like a compressed desktop workspace.
- Core decision:
  mobile is allowed to diverge from desktop visual layout and interaction
  structure.
  Desktop remains the Linux reference for functional parity,
  while Android mobile gets its own information architecture,
  navigation,
  and page compositions.
- Planned surfaces:
  1. Mobile design contract:
     primary orange action color,
     neutral cards,
     48px touch targets,
     safe-area-aware bottom spacing,
     icon-first controls,
     and a smaller mobile type scale.
  2. Mobile shell and home:
     brand/notification header,
     prominent search,
     shortcut cards for All Photos / Favorites / Memories / Settings,
     scan progress card,
     Recent Memories section,
     and bottom navigation for Waterfall / Map / Timeline / Settings.
  3. Search and filters:
     keep search visible near the top,
     move dense sort/filter controls into a mobile sheet or stacked mobile
     surface,
     and preserve filter state across browse modes.
  4. Detail and Gallery:
     rebuild mobile Detail as a full-screen media-first route,
     use top back/index/more controls,
     move metadata and editing into lower cards or sheets,
     and remove desktop keyboard shortcut copy from mobile.
  5. Settings:
     replace long panel stacks with grouped list rows and drill-in sheets or
     subpages for AI,
     map,
     backup,
     language,
     and advanced local paths.
  6. Create Memory:
     add a guided mobile flow:
     select photos,
     edit title/description/cover,
     then confirm and open the created memory.
- Implementation result:
  mobile now has a dedicated phone shell with header/search/dashboard shortcuts
  and bottom navigation for Waterfall,
  Map,
  Timeline,
  and Settings.
  Dense filters open in a mobile bottom sheet,
  active filter chips remain visible on phone layouts,
  focused Detail and Gallery use mobile-specific chrome without desktop
  keyboard shortcut copy,
  Settings is grouped into mobile rows with drill-in sheets,
  and Create Memory uses a guided mobile wizard before opening the editable
  memory detail lifecycle.
- Explicit non-goals:
  do not redesign Flutter Linux desktop in this phase;
  do not change the release artifact model;
  do not add OCR,
  vector search,
  person recognition,
  cloud sync,
  or EXIF writeback;
  do not claim iOS live verification from this Linux workstation.
- Exit gate:
  passed locally with
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
  The deep E2E run caught and the phase fixed phone-width overflow in Gallery
  chrome and the mobile Language settings drill-in sheet.
  iOS live verification remains blocked on this Linux workstation.
- Release:
  `v0.1.8` was published on 2026-05-11 from tag
  `f4aa0be4394640249de3d7870648d8c08bcdcb36`.
  Main CI run `25655887335` passed before tagging.
  Release workflow run `25656116153` passed and uploaded Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and all matching checksum assets.
  Post-publication verification downloaded the public release assets into
  `.tmp/release-verify/v0.1.8`,
  checked the three sha256 files,
  and confirmed the Linux tarball contains the `chronopic` executable.

### 12. Flutter Mobile Import Count And Lazy Thumbnail Pipeline

- Implementation plan:
  [docs/superpowers/plans/2026-05-11-flutter-mobile-import-count-and-lazy-thumbnails.md](docs/superpowers/plans/2026-05-11-flutter-mobile-import-count-and-lazy-thumbnails.md)
- Status:
  completed on 2026-05-11.
- Source input:
  real Android screenshot reviewed on 2026-05-11 showing
  `扫描进度：已处理 406/5405，已导入 406 个`
  while mobile dashboard and browse chips still displayed `20`.
- Goal:
  make Android mobile import counts truthful and make photo-library import fast
  by separating catalog totals,
  filtered result totals,
  visible page counts,
  scan progress,
  and thumbnail materialization.
- Root causes confirmed:
  1. Mobile dashboard and scan/catalog cards use `photos.length`,
     but `photos` is the current paged browse list capped by
     `_photoPageSize = 20`.
     That makes UI copy like `20 个已索引` read as a catalog total even while
     the scan has already imported hundreds of assets.
  2. `ScanProgress.processed` currently counts imported,
     updated,
     and errored assets,
     but not skipped unchanged assets.
     Rescans can therefore look stuck or under-counted.
  3. Mobile import still reads a platform thumbnail for every changed asset,
     decodes/resizes it,
     encodes a second JPEG,
     and writes it to ChronoPic's thumbnail cache during the scan.
     On large phone libraries this spends CPU,
     I/O,
     storage,
     and progress time before the user sees value.
  4. Scan progress is reported through UI `setState` for every asset,
     which adds avoidable rebuild pressure during large imports.
- Implementation completed:
  1. Count model:
     added a repository/app-service count API that uses the same filters as
     `listPhotos` but ignores pagination.
     `ChronoPicHome` now passes `catalogPhotoCount`,
     `filteredPhotoCount`,
     and visible page length separately into mobile surfaces.
  2. UI copy:
     mobile dashboard cards use full catalog totals where labels imply totals.
     Browse copy uses visible page counts only where it explicitly says
     loaded or visible.
  3. Progress semantics:
     skipped assets now count as processed while imported,
     updated,
     skipped,
     errors,
     and missing remain separate final buckets.
  4. Lazy mobile thumbnails:
     lazy-capable mobile sources no longer eagerly convert every platform
     thumbnail into a ChronoPic
     JPEG during import.
     Mobile scans index metadata first and render thumbnails lazily for
     visible cells/detail/gallery surfaces through the platform thumbnail API or
     a bounded lazy cache.
     Desktop directory scans keep the existing generated thumbnail cache.
  5. Progress throttling:
     scan progress is reported at start,
     completion,
     errors,
     periodic item-count thresholds,
     or a short time interval,
     instead of rebuilding UI once per asset.
	  6. Verification:
	     added Dart/app-service tests for skipped progress and no scan-time thumbnail
	     reads on lazy-capable mobile sources,
	     Flutter widget tests for full-count versus first-page count including a
	     225-photo fixture,
	     and Android deep E2E assertions rejecting first-page count being labeled
	     as a catalog total.
- Follow-up completed on 2026-05-12:
  1. Focused detail/gallery totals:
     mobile focused Detail and Gallery surfaces now receive the full current
     filtered result set instead of the first visible waterfall page,
     so counters such as `1 / N` reflect the full result scope while the
     waterfall renderer still lazy-loads visible pages.
  2. Waterfall gesture handling:
     photo cards no longer open detail on raw pointer down.
     Mobile opens on resolved tap,
     desktop selection remains single tap,
     and desktop open remains double tap,
     so drag/scroll gestures are not treated as card activation.
  3. Settings totals:
     mobile/desktop settings statistics use repository/app-service counts for
     catalog and favorite totals instead of deriving totals from a capped photo
     list.
  4. Regression coverage:
     `mobile_productization_test.dart` now asserts dragging a waterfall card does
     not open focused Detail,
     and a 25-photo mobile catalog opened from the first page displays
     `1 / 25` rather than `1 / 20`.
  5. Verification:
     `flutter analyze`,
     `flutter test packages/chronopic_ui/test apps/chronopic/test`,
     `flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
     `flutter build apk --debug`,
     and `git diff --check` pass.
- Explicit non-goals:
  do not change desktop directory thumbnail cache semantics;
  do not remove desktop `Image.file` preview behavior;
  do not add OCR,
  vector search,
  person recognition,
  cloud sync,
  AI thumbnail analysis,
  or EXIF writeback;
  do not claim iOS live verification from this Linux workstation.
- Exit gate:
  complete.
  Local verification passed with Flutter analyze,
  Dart package tests,
  Flutter UI/app tests,
  focused mobile productization tests,
  Android deep E2E,
  Android debug APK build,
  and `git diff --check`.
  iOS live verification remains blocked until macOS/Xcode evidence exists.

### 13. Flutter Mobile UX Refinement From Real Screenshots

- Implementation plan:
  [docs/superpowers/plans/2026-05-13-flutter-mobile-ux-refinement-real-screenshots.md](docs/superpowers/plans/2026-05-13-flutter-mobile-ux-refinement-real-screenshots.md)
- Status:
  complete on 2026-05-14.
- Source input:
  real Android screenshots and user-provided mobile UI refine proposal:
  `.tmp/diagnostics/mobile-import-screenshot.jpg`,
  `.tmp/screenshots/mobile-count-scroll-2026-05-12.jpg`,
  and `.tmp/user-input/mobile-ui-refine.png`.
- Goal:
  refine the Android mobile UI from real phone evidence now that Phase 11
  established the mobile-native structure and Phase 12 fixed the count,
  lazy-thumbnail,
  and scroll-gesture correctness issues.
  This phase should make the mobile app easier to scan and operate without
  changing the local-first data model or scan pipeline.
- Core decision:
  this is the formal Phase 13.
  The earlier `13b` wording was only a candidate label;
  the durable plan sequence should continue from Phase 12 directly to Phase 13.
- Planned surfaces:
  1. Real-screenshot UX audit:
     record the confirmed issues from the Android import/home screenshot,
     focused Detail screenshot,
     and the earlier mobile UI refine proposal.
  2. Mobile home hierarchy:
     keep Phase 12 count semantics correct,
     but reduce repeated first-viewport count copy and make scan/catalog status
     easier to parse.
  3. Browse and bottom navigation spacing:
     keep filter/search/browse controls reachable while ensuring content does not
     feel clipped by the persistent bottom navigation.
  4. Focused mobile Detail:
     prioritize media and a light phone topbar,
     move inspector/editing affordances into a clearer secondary action,
     and avoid desktop-like shortcut or command density.
  5. Mobile Gallery:
     keep full-result counters,
     lazy thumbnails,
     and filmstrip navigation while simplifying mobile action placement.
  6. Documentation and verification:
     update the mobile productization contract,
     mobile E2E evidence notes,
     and AGENTS execution record after implementation.
- Implemented result:
  mobile home now keeps the full indexed count in the All Photos shortcut while
  the scan/status card communicates readiness or activity instead of repeating
  the same total.
  Waterfall browse has explicit mobile bottom spacing around the persistent
  navigation.
  Focused Detail now uses a lighter mobile topbar,
  a separate primary touch-action row,
  and an inspector/details entry before the edit metadata area.
  Mobile Gallery now keeps the full-result counter and adds a compact action row
  for previous,
  next,
  and Detail/inspector entry.
  The app-owned mobile integration test now rejects the old
  `25 indexed locally` repeated-count copy.
- Explicit non-goals:
  do not change repository/domain schemas;
  do not change Android import count semantics;
  do not change the lazy-thumbnail pipeline;
  do not redesign Flutter Linux desktop;
  do not start Play Store submission work;
  do not add OCR,
  vector search,
  person recognition,
  cloud sync,
  AI thumbnail analysis,
  or EXIF writeback;
  do not claim iOS live verification from this Linux workstation.
- Exit gate:
  complete.
  Local verification passed with Flutter analyze,
  focused mobile productization tests,
  Flutter UI/app tests,
  app-owned mobile integration test,
  Android debug APK build,
  and `git diff --check`.
  iOS live verification remains blocked until macOS/Xcode evidence exists.

### 14. Flutter Mobile Memory Creation Completion

- Implementation plan:
  [docs/superpowers/plans/2026-05-15-flutter-mobile-memory-creation-completion.md](docs/superpowers/plans/2026-05-15-flutter-mobile-memory-creation-completion.md)
- Status:
  completed locally on 2026-05-15.
- Source input:
  user selected `Mobile Memory Creation Completion` as the next phase after
  Phase 13 and `v0.1.11`.
- Goal:
  complete the phone-native memory creation flow so Android users can select
  photos,
  edit title and description,
  choose a cover,
  confirm creation,
  and land on the editable memory detail page.
- Closed gap:
  Phase 11 added a guided mobile Create Memory wizard,
  but the mobile flow was still mostly a prompt sequence.
  Phase 14 replaces that prompt-only path with a real local creation lifecycle
  from selected photos through cover choice and post-confirm navigation.
- Core decision:
  Phase 14 should use existing local-first memory semantics.
  Creating a mobile memory must create a normal editable `Memory`,
  link photos through the existing memory-photo relationship,
  and use existing cover and detail editing behavior after confirmation.
- Implemented surfaces:
  1. Mobile entry points:
     Memories page Create Memory,
     home first-memory CTA,
     and selected-photo Detail/Add-to-Memory fallback.
  2. Photo selection:
     selectable mobile photo tiles,
     visible selected count,
     no progression to details until at least one photo is selected,
     and preserved Phase 12/13 scroll/tap semantics.
  3. Details and cover:
     title field,
     optional description field,
     selected-photo cover strip,
     and a confirm summary before commit.
  4. Commit and navigation:
     create the memory through `ChronoPicAppService.createMemory`,
     attach selected photos through `addPhotoToMemory`,
     set the selected cover,
     clear draft state,
     and open the created memory detail page.
  5. Verification:
     focused mobile widget tests,
     app-owned mobile integration coverage,
     Flutter analyze,
     Android debug APK build,
     docs update,
     and `git diff --check`.
- Explicit non-goals:
  do not change repository/domain schemas;
  do not change Android import count semantics;
  do not change the lazy-thumbnail pipeline;
  do not redesign Flutter Linux desktop;
  do not start Play Store submission work;
  do not add OCR,
  vector search,
  person recognition,
  cloud sync,
  AI thumbnail analysis,
  or EXIF writeback;
  do not claim iOS live verification from this Linux workstation.
- Exit gate:
  completed locally.
  Verification evidence:
  `cd chronopic_flutter && flutter analyze`;
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`;
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`;
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`;
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`;
  and `git diff --check`.
  The integration test still prints Flutter's known `integration_test` plugin
  warning,
  but exited 0 with `All tests passed`.

- Person / face grouping:
  add person-like memory grouping only after the app has a real person-recognition or clustering signal.
  Do not pretend to identify people from generic captions or tags.
- OCR and text-in-image search:
  useful for screenshots, documents, receipts, posters, and travel photos.
  Should feed the same discovery/search model rather than creating a separate OCR-only search surface.
- Vector / embedding search:
  useful once semantic search needs fuzzy matching beyond inspectable text fields.
  Must preserve local-first semantics and explain provider/storage tradeoffs clearly.
- Import/export sidecar metadata:
  consider JSON sidecars before EXIF writeback.
  EXIF writeback remains out of scope until the app has stronger backup and rollback guarantees.

