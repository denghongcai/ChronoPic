# Flutter Electron UI Functional Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drive Flutter Linux desktop to Electron UI and feature parity through repeatable two-side tests, screenshots, and gap-fixing loops.

**Architecture:** Treat Electron as the reference product surface and Flutter as the candidate implementation. Build deterministic capture scripts for both apps, store screenshots and machine-readable findings under ignored `test-results/`, then fix Flutter gaps in small UI/function slices while keeping the full Phase 5.5/5.6 verification gate green.

**Tech Stack:** Electron Playwright E2E, Flutter widget tests, Flutter Linux debug bundle, Xvfb, scrot, Dart app-service fixtures, existing ChronoPic domain/database/app packages.

---

## File Structure

- Create `docs/flutter-electron-ui-functional-parity.md`: durable parity matrix with one row per surface and workflow.
- Create `docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md`: design/acceptance spec for this phase.
- Create `scripts/capture-electron-parity.mjs`: launch Electron through Playwright, seed deterministic data, navigate reference surfaces, and save screenshots.
- Create `chronopic_flutter/tool/capture_flutter_parity.sh`: build/launch Flutter Linux under Xvfb with `LIBGL_ALWAYS_SOFTWARE=1`, run deterministic UI entry states, and save screenshots.
- Modify `tests/e2e/runtime.spec.ts`, `tests/e2e/backup.spec.ts`, `tests/e2e/ai-productization.spec.ts`, and `tests/e2e/i18n.spec.ts` only when a reference flow needs a stable selector or setup hook for capture.
- Modify `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`: add focused widget assertions for page separation, responsive layout, and keyboard paths discovered during comparison.
- Modify `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`: extend Linux desktop parity coverage for any functional gaps found during screenshot comparison.
- Modify Flutter UI modules under `chronopic_flutter/packages/chronopic_ui/lib/src/` in focused slices:
  `shell/`,
  `home/`,
  `browse/`,
  `detail/`,
  `gallery/`,
  `memories/`,
  `settings/`,
  `filters/`,
  `theme/`,
  and `l10n/`.
- Modify `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md` after each completed slice.

## Reference Surfaces

Every parity run must capture Electron and Flutter for these states:

1. Empty first-run home.
2. Populated grid/waterfall browse.
3. Map browse with geotagged fixture data or explicit disabled-map state.
4. Timeline browse.
5. Detail inspector with metadata and edit controls.
6. Fullscreen gallery with filmstrip and keyboard affordances.
7. Favorites filter.
8. Memories list.
9. Memory detail, including title, description, cover, add/remove photo actions.
10. Settings: library, language, backup, AI, map, sources, and stats.
11. Notifications/AI queue and memory candidates.
12. Chinese locale for shell, browse, settings, backup, memories, and notifications.
13. Restart persistence after scan/edit/favorite/memory/settings changes.

## Current Completion Plan

This phase remains open until the parity matrix has no unexamined `Gap` rows.
Continue from the current evidence instead of restarting broad redesign work.

Use this loop for every remaining row:

1. Open the Electron PNG and matching Flutter PNG from
   `test-results/flutter-electron-parity/{electron,flutter}/`.
2. Name the exact user-visible difference in
   `docs/flutter-electron-ui-functional-parity.md`.
3. Add or tighten a Flutter widget/parity assertion when the difference is
   functional, navigational, responsive, persistent, or localized.
4. Make the smallest coherent Flutter UI or service change that closes the row
   without diverging from existing package boundaries.
5. Run the focused Flutter test command for the touched surface.
6. Recapture only the affected Flutter surface with
   `bash tool/capture_flutter_parity.sh <surface>`.
7. Re-open both PNGs and decide whether the row is now `Matched`, is still a
   concrete `Gap`, or should be an `Accepted Difference` with a written reason.
8. Update `PLAN.md`, `docs/flutter-refactor-phases.md`,
   `docs/flutter-electron-ui-functional-parity.md`, this plan, and `AGENTS.md`
   before moving to the next row.

Current row order:

1. Empty first-run home: remove empty-state control clutter that Electron does
   not show in the first viewport; keep only the onboarding hero, recent-memory
   hierarchy, compact browse/search row, and empty result area.
2. Populated grid, favorites, and restart persistence: finish Select/Filter
   affordance treatment, media-card crop height, and fallback edge styling.
3. Map and timeline: close discovery-chip/top-density differences after the
   disabled-map and timeline-card structures already added.
4. Detail and gallery: close top-button styling, fallback edge rendering, and
   default scroll-position differences.
5. Memories list and memory detail: close card proportion, timestamp/icon
   placement, and candidate action differences.
6. Settings and notifications: close section width, button color semantics,
   chip color, and lower map/source/stat panel differences.
7. Chinese locale: verify remaining source-authored text is intentional data,
   then close or document accepted differences.
8. Full two-side gate: rerun Electron tests/capture, Flutter tests/capture,
   `flutter pub outdated`, `git diff --check`, and final matrix closure.

## Task 1: Record The Phase And Acceptance Contract

**Files:**
- Create: `docs/flutter-electron-ui-functional-parity.md`
- Create: `docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md`
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Create the parity matrix**

  Write `docs/flutter-electron-ui-functional-parity.md` with these columns:

  ```markdown
  # Flutter Electron UI Functional Parity Matrix

  | Surface / Workflow | Electron Reference Evidence | Flutter Evidence | Status | Gap | Fix Commit |
  | --- | --- | --- | --- | --- | --- |
  | Empty first-run home | Pending | Pending | Pending | Capture both sides | Pending |
  | Populated grid/waterfall browse | Pending | Pending | Pending | Capture both sides | Pending |
  | Map browse / disabled-map state | Pending | Pending | Pending | Capture both sides | Pending |
  | Timeline browse | Pending | Pending | Pending | Capture both sides | Pending |
  | Detail inspector and edits | Pending | Pending | Pending | Capture both sides | Pending |
  | Fullscreen gallery | Pending | Pending | Pending | Capture both sides | Pending |
  | Favorites filter | Pending | Pending | Pending | Capture both sides | Pending |
  | Memories list | Pending | Pending | Pending | Capture both sides | Pending |
  | Memory detail management | Pending | Pending | Pending | Capture both sides | Pending |
  | Settings | Pending | Pending | Pending | Capture both sides | Pending |
  | Notifications / AI queue | Pending | Pending | Pending | Capture both sides | Pending |
  | Chinese locale | Pending | Pending | Pending | Capture both sides | Pending |
  | Restart persistence | Pending | Pending | Pending | Capture both sides | Pending |
  ```

- [x] **Step 2: Create the acceptance spec**

  Write `docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md` with:

  ```markdown
  # Flutter Electron UI Functional Parity Spec

  ## Goal

  Make Flutter Linux desktop match Electron's current UI information architecture and user-visible behavior before mobile work starts.

  ## Rules

  - Electron is the reference for desktop UI and workflow behavior.
  - Flutter must be compared with Electron through screenshots and tests, not memory.
  - Every changed surface needs before/after evidence in `test-results/flutter-electron-parity/`.
  - Screenshots are evidence for rendering only; functional parity still requires tests.
  - Do not start Android/iOS work while any desktop parity row is `Pending` or `Gap`.

  ## Completion Criteria

  - All matrix rows are `Matched` or have a documented, accepted platform-specific difference.
  - The full Flutter local gate passes.
  - Electron reference E2E tests used for comparison pass.
  - `AGENTS.md` records screenshot paths, commands, and skipped scenes with reasons.
  ```

- [x] **Step 3: Add Phase 5.7 to durable plans**

  Add `Phase 5.7: Flutter Electron UI And Functional Parity Phase` to `docs/flutter-refactor-phases.md` before Phase 6.

  Add `### 4.35 Flutter Electron UI And Functional Parity Phase` to `PLAN.md` after Phase 5.6.

- [x] **Step 4: Record the start in `AGENTS.md`**

  Add a new step stating that this phase compares Electron and Flutter with repeatable screenshots/tests before mobile work.

- [x] **Step 5: Verify documentation formatting**

  Run:

  ```bash
  git diff --check
  ```

  Expected: no output.

## Task 2: Build Electron Reference Capture

**Files:**
- Create: `scripts/capture-electron-parity.mjs`
- Modify only if needed: `tests/e2e/runtime.spec.ts`
- Modify only if needed: `tests/e2e/backup.spec.ts`
- Modify only if needed: `tests/e2e/ai-productization.spec.ts`
- Modify only if needed: `tests/e2e/i18n.spec.ts`

- [x] **Step 1: Add the Electron capture script**

  Create `scripts/capture-electron-parity.mjs` with a Playwright Electron launcher that:
  - creates `test-results/flutter-electron-parity/electron/`,
  - launches the Electron app through the existing desktop entry,
  - seeds a temporary user data directory,
  - uses existing E2E helper flows where possible,
  - captures the 13 reference surfaces listed above.

  The script must use stable screenshot names:

  ```text
  01-empty-home.png
  02-populated-grid.png
  03-map.png
  04-timeline.png
  05-detail.png
  06-gallery.png
  07-favorites.png
  08-memories-list.png
  09-memory-detail.png
  10-settings.png
  11-notifications.png
  12-zh-locale.png
  13-restart-persistence.png
  ```

- [x] **Step 2: Run Electron reference capture**

  Run:

  ```bash
  pnpm run e2e:prepare
  node scripts/capture-electron-parity.mjs
  ```

  Expected:
  - process exits `0`;
  - `test-results/flutter-electron-parity/electron/` contains all 13 PNG files;
  - no app console errors except documented test-environment noise.

- [x] **Step 3: Run Electron reference tests**

  Run:

  ```bash
  pnpm run e2e:runtime
  pnpm run e2e:backup
  pnpm run e2e:ai
  pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts
  ```

  Expected: all pass.

## Task 3: Build Flutter Capture Harness

**Files:**
- Create: `chronopic_flutter/tool/capture_flutter_parity.sh`
- Modify if capture needs deterministic setup: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`
- Modify if capture needs service fixture helpers: `chronopic_flutter/packages/chronopic_testkit/`

- [x] **Step 1: Add Flutter Linux screenshot script**

  Create `chronopic_flutter/tool/capture_flutter_parity.sh` that:
  - runs `flutter build linux --debug`,
  - launches `apps/chronopic/build/linux/x64/debug/bundle/chronopic` under `xvfb-run`,
  - exports `GDK_BACKEND=x11`,
  - exports `LIBGL_ALWAYS_SOFTWARE=1`,
  - exports a temporary `CHRONOPIC_USER_DATA_DIR`,
  - captures PNG files into `../test-results/flutter-electron-parity/flutter/`.

- [x] **Step 2: Capture empty first-run Flutter state**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh empty-home
  ```

  Expected:
  - `test-results/flutter-electron-parity/flutter/01-empty-home.png` exists;
  - screenshot shows the real Linux Flutter app window, not a black screen.

- [x] **Step 3: Add deterministic populated states**

  Extend the script or testkit helpers so populated states use the same fixture intent as Electron:
  - two or more photos,
  - at least one favorite,
  - one geotagged item,
  - one memory with a cover,
  - AI disabled/incomplete state plus one candidate where supported.

- [x] **Step 4: Capture all Flutter surfaces**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh all
  ```

  Expected:
  - `test-results/flutter-electron-parity/flutter/` contains all 13 PNG files;
  - no screenshot is black or blank;
  - filenames match Electron capture names.

## Task 4: Compare Evidence And Create Gap List

**Files:**
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Review screenshots side by side**

  Compare each Electron PNG with the matching Flutter PNG. For every surface, classify:

  ```text
  Matched
  Gap
  Accepted Difference
  Blocked
  ```

- [x] **Step 2: Update the matrix**

  For each gap, write a concrete fix target, for example:

  ```markdown
  | Settings | `test-results/.../electron/10-settings.png` | `test-results/.../flutter/10-settings.png` | Gap | Flutter settings lacks map credential panel and source stats grouping | Pending |
  ```

- [x] **Step 3: Record evidence in `AGENTS.md`**

  Add:
  - Electron screenshot directory,
  - Flutter screenshot directory,
  - exact commands run,
  - list of gap rows,
  - rows accepted as platform-specific differences.

## Task 5: Fix Shell, Home, And Browse Gaps

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/shell/desktop_shell.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/filters/filter_toolbar.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`

- [x] **Step 1: Add failing widget assertions for shell/home gaps**

  Add tests before implementation. Cover only concrete gaps found in Task 4.

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart
  ```

  Expected: fails on the missing or misaligned shell/home behavior.

- [x] **Step 2: Implement shell/home/browse fixes**

  Fix the smallest coherent group:
  - sidebar hierarchy,
  - first-run and populated home layout,
  - search/filter density,
  - grid/map/timeline affordances,
  - responsive behavior at 1280x720, 1600x1200, and 840x1200.

- [x] **Step 3: Verify shell/home/browse**

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  dart analyze packages/chronopic_ui
  ```

  Expected: all pass.

- [x] **Step 4: Recapture affected screenshots**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh all
  ```

  Expected: affected rows move from `Gap` to `Matched` or `Accepted Difference`.

## Task 6: Fix Detail, Gallery, Favorites, And Editing Gaps

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`

- [x] **Step 1: Add failing parity tests**

  Add assertions for the exact gaps:
  - detail metadata fields,
  - edit controls,
  - favorite state,
  - rollback affordance,
  - gallery counter,
  - gallery filmstrip,
  - keyboard close/next/previous behavior.

- [x] **Step 2: Implement detail/gallery fixes**

  Make Flutter match Electron behavior and visible hierarchy while preserving app-service boundaries.

  Progress:
  - Detail capture now uses a focused dark viewer surface with a large media canvas, right-side inspector, keyboard hint, and gallery strip.
  - The focused detail state now renders through an immersive shell for evidence capture so the normal Flutter sidebar/status/browse chrome no longer appears over the Electron-style viewer.
  - The right inspector now uses Electron-like metric cards and an AI insights card with generated caption, summary, tags, and AI health/error state from the existing semantic metadata model.
  - Focused detail header controls are wired to real actions:
    the add button routes the selected photo into the memory flow,
    the close button exits the focused detail capture state,
    and the gallery button opens the existing gallery dialog.
  - A widget regression test covers the focused detail surface, filmstrip, and actionable add/close controls.
  - Gallery view now removes the large metadata scrim, uses a bordered dark media frame, places title/date/memory/hint below the image, exposes an Open Inspector action, and frames the gallery strip as a separate dark container.
  - Browse/home now includes a functional Electron-like discovery lens row:
    Map switches to map browse,
    Timeline switches to timeline browse,
    and the memory chip opens the memory detail page.
  - Notifications now uses an Electron-like outer container with separate AI queue and Memory candidates cards while preserving the retry and memory-review actions.
  - Settings now uses Electron-like primary library actions, backup action grouping with `LOCAL JSON`, and an AI Enrichment readiness card with `PRESENT` pills while preserving path-based backup/restore and secret-safe AI editing.
  - Browse media cards now use a lower-density desktop grid, larger cards, a bottom gradient metadata layer, and improved missing-media fallback so populated/favorites/restart screenshots show media hierarchy closer to Electron.
  - Global Flutter desktop brand chrome now matches Electron's `ChronoPic` / `Photo workspace` labels instead of identifying the rewrite as `ChronoPic Flutter`.
  - Empty first-run now uses `Add Folder` as the primary folder-picker action while preserving the explicit path-based `Add Library` control below.
  - Empty first-run now also removes lower path-based library controls and full filter controls from the first viewport, keeps that functionality in Settings, adds a `Create First Memory` CTA to the recent-memory empty state, and preserves filter controls when an active filter returns zero photos.
  - Populated grid, Favorites, and Restart Persistence now use Electron-like compact `Select` / `Filter` affordances in the browse toolbar instead of rendering the full filter panel in the first viewport by default.
  - The full filter panel remains available behind the `Filter` button and stays visible for active search/tag/GPS/AI/date/sort filter states so functional filtering is still covered.
  - Map and Timeline were recaptured after the compact filter-toolbar pass; both now inherit the reduced first-viewport toolbar density while preserving their existing disabled-map and timeline-card behavior.
  - Browse media cards now use a taller card ratio and a shared edge-style fallback with top path/name text instead of a centered broken-image icon; memory cover fallback surfaces use the same treatment.
  - Memories list now has an Electron-like `SUGGESTED MEMORIES` header, a real Generate/refresh affordance, title-card candidate treatment, `Adjust photos`, and candidate accept/reject actions aligned more closely with Electron.

- [x] **Step 3: Verify and recapture**

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  dart analyze packages/chronopic_ui packages/chronopic_app
  bash tool/capture_flutter_parity.sh all
  ```

  Expected: tests pass and matching screenshot rows are updated in the matrix.

  Latest focused-detail verification:
  `dart analyze packages/chronopic_ui`,
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `bash tool/capture_flutter_parity.sh detail`,
  later `bash tool/capture_flutter_parity.sh gallery`,
  later `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence`,
  later `bash tool/capture_flutter_parity.sh settings notifications`,
  later `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence` again after the media-card pass,
  later `bash tool/capture_flutter_parity.sh all` after brand chrome alignment,
  later `bash tool/capture_flutter_parity.sh empty-home` after the first-run button label/action pass,
  later `bash tool/capture_flutter_parity.sh empty-home` again after the empty-first-run control-clutter and memory CTA pass,
  later `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence` after the compact Select/Filter browse-toolbar pass,
  later `bash tool/capture_flutter_parity.sh map timeline` to refresh Map and Timeline with the compact toolbar treatment,
  later `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence detail gallery memories-list memory-detail` after the taller media-card and shared edge-style fallback pass,
  later `bash tool/capture_flutter_parity.sh memories-list` after the memory-candidate header/card/Generate pass,
  later `bash tool/capture_flutter_parity.sh memory-detail` after the memory-detail timestamp/story-outline pass,
  later `bash tool/capture_flutter_parity.sh notifications` after the notification title/card/chip semantics pass,
  later `bash tool/capture_flutter_parity.sh settings` after the settings first-viewport/action/status semantics pass,
  later `bash tool/capture_flutter_parity.sh all` after the shared sidebar/header chrome pass,
  later `bash tool/capture_flutter_parity.sh populated-grid map timeline favorites zh-locale restart-persistence` after the Waterfall label and selected-banner copy pass,
  and later `bash tool/capture_flutter_parity.sh all` after the focused-detail top-controls and capture-selection pass.

## Task 7: Fix Memories, Settings, Notifications, And Locale Gaps

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/settings/settings_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/l10n/ui_strings.dart`
- Modify if needed: `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`

- [x] **Step 1: Add failing tests for page-level gaps**

  Cover:
  - memory list and detail state,
  - add/remove selected photo,
  - set cover,
  - backup/settings grouping,
  - AI readiness and retry/candidate actions,
  - Chinese labels on the affected surfaces.

- [x] **Step 2: Implement page-level fixes**

  Keep fixes scoped to the owning page modules. Add app-service helpers only when Flutter needs a real product action currently missing from the service boundary.

  Progress:
  - Memories list now has separate AI-assisted candidate and memory collection panels.
  - Memory detail now has a cover-led detail hero and story-outline panel.
  - Memory list/detail/home cards now use framed media-style cover fallback treatment instead of centered icon-only gradient blocks.
  - Memory detail now uses a read-first hero with compact actions and moves editable metadata controls into a lower management panel.
  - Memory detail now uses Electron-like updated timestamp formatting, `STORY OUTLINE` hierarchy, and chapter-card metadata for month/day, mapped count, and AI readiness.
  - Notifications now uses queue/candidate summary cards with settings and memories handoff.
  - Notifications now places the page title inside the white content card and uses Electron-like blue/red/green/yellow semantic chips for AI queue, failed, ready, and memory candidate states.
  - Settings now owns AI and map settings grouping.
  - Settings language controls now match the Electron interface-language / AI-output-language / save-button shape and persist through Dart backup settings.
  - Settings now keeps the first viewport focused on the Electron-like Library Settings card with Add Folder and Scan Library, moves manual path import into a lower panel, and uses Electron-like orange/white/blue/green action and status semantics for restore, language save, backup format, and AI readiness.
  - Shared desktop shell chrome now moves notifications into the sidebar header, replaces the previous Notifications nav row with an Electron-like Recent row, adds a bottom Create Memory action, and hides the idle scan status bar so non-immersive pages start at the same top content position as Electron.
  - Browse controls now use Electron's `Waterfall` label instead of `Grid`, including the Simplified Chinese `瀑布流` label, and the selected-photo banner now uses Electron's memory-membership copy.
  - Focused detail capture now selects the same first fixture photo as Electron and exposes Electron-like add, close, previous, next, and Gallery top controls with dark/disabled/highlight states.
  - Focused detail inspector status now reports file/index health as `HEALTHY` while keeping AI failure information in AI-specific fields, matching Electron's inspector semantics.
  - Fullscreen gallery now removes the extra back/X controls, uses dark Detail View/Open Inspector actions, shows date plus time, uses Electron's `NOT IN ANY MEMORY` and `2 ITEMS` copy, and keeps the dark framed media/filmstrip hierarchy.
  - Settings backup JSON path controls now live in a lower file-path panel so the first viewport matches Electron's backup card density while preserving path-based export/restore workflows.
  - Map browse now has an Electron-like pale disabled/provider-failure canvas with centered `MAP ERROR` copy, mapped counts, and GPS photo selection.
  - Timeline browse now has an Electron-like light timeline card with scope chips, a Select action, `TIMELINE SCOPE` strip, selected-photo banner, month grouping, selected-card highlight, and selectable photo cards.
  - Waterfall, Favorites, and Restart surfaces now show an Electron-like selected-photo banner above the grid when a photo is selected.
  - Flutter capture now uses the same 1440x920 evidence size as Electron by aligning the Linux runner default window and scrot crop.
  - Chinese locale now covers the first-viewport shell subtitle/status, library/memory labels, recent-memory section, new-memory card, browse controls, result count, filters, AI/sort controls, and visible detail heading.
  - Locale parity remains open for exact Electron selected-photo/banner placement and source fixture content that intentionally remains authored data.
  - Full Flutter parity evidence was recaptured after the screenshot-size fix; all 13 Flutter PNGs are now 1440x920.
  - Full Flutter-side Task 7 verification was rerun after the map, timeline, grid, and memory-detail refinements:
    `dart analyze packages/chronopic_app packages/chronopic_ui`,
    `flutter test packages/chronopic_ui apps/chronopic`,
    `bash tool/capture_flutter_parity.sh all`,
    and `file test-results/flutter-electron-parity/flutter/*.png`.

- [x] **Step 3: Verify and recapture**

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui apps/chronopic
  dart analyze packages/chronopic_app packages/chronopic_ui
  bash tool/capture_flutter_parity.sh all
  ```

  Expected: all pass and screenshot matrix rows are updated.

## Task 8: Full Two-Side Verification Gate

**Files:**
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Run Electron gate**

  Run:

  ```bash
  pnpm test
  pnpm typecheck
  pnpm build
  pnpm run e2e:runtime
  pnpm run e2e:backup
  pnpm run e2e:ai
  pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts
  node scripts/capture-electron-parity.mjs
  ```

  Expected: all pass and Electron screenshots exist.

  Progress:
  - Root Electron-side `pnpm test`, `pnpm typecheck`, and `pnpm build` pass after the latest changes.
  - `pnpm run e2e:runtime` initially exposed a real rollback-ordering bug in edit history; this was fixed in `packages/infra-db/src/index.ts` and covered by `tests/backup.test.ts`.
  - `pnpm run e2e:runtime`, `pnpm run e2e:backup`, `pnpm run e2e:ai`, and `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts` now pass.
  - `node scripts/capture-electron-parity.mjs` passes and all 13 Electron PNGs are 1440x920.

- [x] **Step 2: Run Flutter gate**

  Run:

  ```bash
  cd chronopic_flutter
  dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app
  cd packages/chronopic_database && dart test test/repository_test.dart test/drift_database_test.dart
  cd ../..
  dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui
  flutter test packages/chronopic_ui apps/chronopic
  flutter analyze packages/chronopic_ui apps/chronopic
  cd apps/chronopic && flutter build linux --debug
  cd ../..
  bash tool/capture_flutter_parity.sh all
  ```

  Expected: all pass and Flutter screenshots exist.

  Progress:
  - `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app` passes.
  - `dart test test/repository_test.dart test/drift_database_test.dart` passes in `packages/chronopic_database`.
  - `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui` passes with no issues.
  - `flutter test packages/chronopic_ui apps/chronopic` passes.
  - `flutter analyze packages/chronopic_ui apps/chronopic` passes with no issues.
  - `flutter build linux --debug` passes and builds `build/linux/x64/debug/bundle/chronopic`.
  - `bash tool/capture_flutter_parity.sh all` passes and all 13 Flutter PNGs are 1440x920.

- [x] **Step 3: Run repository hygiene**

  Run from repo root:

  ```bash
  flutter pub outdated
  git diff --check
  git status --short
  ```

  Expected:
  - direct Flutter dependencies remain newest resolvable versions,
  - `git diff --check` has no output,
  - only intended files are modified.

  Progress:
  - `flutter pub outdated` reports direct dependencies are all up to date and the listed newer dev/transitive versions are not mutually compatible with the current resolvable set.
  - `git diff --check` has no output.
  - `git status --short` shows only the intended Flutter parity, Electron capture/test, and plan/log files.

- [x] **Step 4: Close the matrix**

  Update `docs/flutter-electron-ui-functional-parity.md` so every row is `Matched` or `Accepted Difference`, with screenshot paths and commit IDs.

  Progress:
  - Every matrix row is now either `Accepted Difference` with a written reason or has no remaining concrete `Gap`.
  - Electron and Flutter evidence paths are recorded for all 13 surfaces.
  - The `Fix Commit` column remains pending until the implementation commit is created.

- [ ] **Step 5: Commit and push**

  Run:

  ```bash
  git add PLAN.md AGENTS.md docs/flutter-refactor-phases.md docs/flutter-electron-ui-functional-parity.md docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md scripts/capture-electron-parity.mjs chronopic_flutter/tool/capture_flutter_parity.sh chronopic_flutter/packages/chronopic_ui chronopic_flutter/packages/chronopic_app tests/e2e
  git commit -m "Align Flutter desktop with Electron UI flows"
  git push
  ```

  Expected: branch `flutter-refactor-phases` is pushed and worktree is clean.

## Self-Review

- Spec coverage: the plan covers two-side capture, matrix-driven gap triage, shell/home/browse, detail/gallery/editing, memories/settings/notifications/locale, and full verification.
- Placeholder scan: no task is allowed to finish with an unspecified gap; every gap must be written into the matrix before implementation.
- Type consistency: this plan uses existing package and file names from the current repo and keeps Flutter app-service boundaries explicit.
