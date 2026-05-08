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

## Task 1: Record The Phase And Acceptance Contract

**Files:**
- Create: `docs/flutter-electron-ui-functional-parity.md`
- Create: `docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md`
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Create the parity matrix**

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

- [ ] **Step 2: Create the acceptance spec**

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

- [ ] **Step 3: Add Phase 5.7 to durable plans**

  Add `Phase 5.7: Flutter Electron UI And Functional Parity Phase` to `docs/flutter-refactor-phases.md` before Phase 6.

  Add `### 4.35 Flutter Electron UI And Functional Parity Phase` to `PLAN.md` after Phase 5.6.

- [ ] **Step 4: Record the start in `AGENTS.md`**

  Add a new step stating that this phase compares Electron and Flutter with repeatable screenshots/tests before mobile work.

- [ ] **Step 5: Verify documentation formatting**

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

- [ ] **Step 1: Add the Electron capture script**

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

- [ ] **Step 2: Run Electron reference capture**

  Run:

  ```bash
  pnpm run e2e:prepare
  node scripts/capture-electron-parity.mjs
  ```

  Expected:
  - process exits `0`;
  - `test-results/flutter-electron-parity/electron/` contains all 13 PNG files;
  - no app console errors except documented test-environment noise.

- [ ] **Step 3: Run Electron reference tests**

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

- [ ] **Step 1: Add Flutter Linux screenshot script**

  Create `chronopic_flutter/tool/capture_flutter_parity.sh` that:
  - runs `flutter build linux --debug`,
  - launches `apps/chronopic/build/linux/x64/debug/bundle/chronopic` under `xvfb-run`,
  - exports `GDK_BACKEND=x11`,
  - exports `LIBGL_ALWAYS_SOFTWARE=1`,
  - exports a temporary `CHRONOPIC_USER_DATA_DIR`,
  - captures PNG files into `../test-results/flutter-electron-parity/flutter/`.

- [ ] **Step 2: Capture empty first-run Flutter state**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh empty-home
  ```

  Expected:
  - `test-results/flutter-electron-parity/flutter/01-empty-home.png` exists;
  - screenshot shows the real Linux Flutter app window, not a black screen.

- [ ] **Step 3: Add deterministic populated states**

  Extend the script or testkit helpers so populated states use the same fixture intent as Electron:
  - two or more photos,
  - at least one favorite,
  - one geotagged item,
  - one memory with a cover,
  - AI disabled/incomplete state plus one candidate where supported.

- [ ] **Step 4: Capture all Flutter surfaces**

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

- [ ] **Step 1: Review screenshots side by side**

  Compare each Electron PNG with the matching Flutter PNG. For every surface, classify:

  ```text
  Matched
  Gap
  Accepted Difference
  Blocked
  ```

- [ ] **Step 2: Update the matrix**

  For each gap, write a concrete fix target, for example:

  ```markdown
  | Settings | `test-results/.../electron/10-settings.png` | `test-results/.../flutter/10-settings.png` | Gap | Flutter settings lacks map credential panel and source stats grouping | Pending |
  ```

- [ ] **Step 3: Record evidence in `AGENTS.md`**

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

- [ ] **Step 1: Add failing widget assertions for shell/home gaps**

  Add tests before implementation. Cover only concrete gaps found in Task 4.

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart
  ```

  Expected: fails on the missing or misaligned shell/home behavior.

- [ ] **Step 2: Implement shell/home/browse fixes**

  Fix the smallest coherent group:
  - sidebar hierarchy,
  - first-run and populated home layout,
  - search/filter density,
  - grid/map/timeline affordances,
  - responsive behavior at 1280x720, 1600x1200, and 840x1200.

- [ ] **Step 3: Verify shell/home/browse**

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  dart analyze packages/chronopic_ui
  ```

  Expected: all pass.

- [ ] **Step 4: Recapture affected screenshots**

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

- [ ] **Step 1: Add failing parity tests**

  Add assertions for the exact gaps:
  - detail metadata fields,
  - edit controls,
  - favorite state,
  - rollback affordance,
  - gallery counter,
  - gallery filmstrip,
  - keyboard close/next/previous behavior.

- [ ] **Step 2: Implement detail/gallery fixes**

  Make Flutter match Electron behavior and visible hierarchy while preserving app-service boundaries.

- [ ] **Step 3: Verify and recapture**

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  dart analyze packages/chronopic_ui packages/chronopic_app
  bash tool/capture_flutter_parity.sh all
  ```

  Expected: tests pass and matching screenshot rows are updated in the matrix.

## Task 7: Fix Memories, Settings, Notifications, And Locale Gaps

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/settings/settings_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/l10n/ui_strings.dart`
- Modify if needed: `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`

- [ ] **Step 1: Add failing tests for page-level gaps**

  Cover:
  - memory list and detail state,
  - add/remove selected photo,
  - set cover,
  - backup/settings grouping,
  - AI readiness and retry/candidate actions,
  - Chinese labels on the affected surfaces.

- [ ] **Step 2: Implement page-level fixes**

  Keep fixes scoped to the owning page modules. Add app-service helpers only when Flutter needs a real product action currently missing from the service boundary.

- [ ] **Step 3: Verify and recapture**

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

- [ ] **Step 1: Run Electron gate**

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

- [ ] **Step 2: Run Flutter gate**

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

- [ ] **Step 3: Run repository hygiene**

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

- [ ] **Step 4: Close the matrix**

  Update `docs/flutter-electron-ui-functional-parity.md` so every row is `Matched` or `Accepted Difference`, with screenshot paths and commit IDs.

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
