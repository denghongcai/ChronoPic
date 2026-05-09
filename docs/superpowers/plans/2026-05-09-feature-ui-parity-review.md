# Feature UI Parity Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:systematic-debugging for defect investigation and superpowers:executing-plans to execute this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Review every Electron-vs-Flutter desktop feature surface and UI state with code evidence, tests, screenshots, and explicit defect decisions.

**Architecture:** Treat Electron as the reference implementation and Flutter as the parity target, but verify the Electron behavior from code and runtime screenshots before declaring the contract. Every reviewed surface must have refreshed two-side screenshots, a behavior checklist, and a clear `Matched`, `Accepted Difference`, or `Gap` decision. Confirmed gaps become follow-up repair phases with failing tests before code changes.

**Tech Stack:** Electron Playwright capture, Flutter Linux capture under Xvfb, ImageMagick `montage`, existing Flutter widget tests, Electron E2E tests, `docs/flutter-electron-ui-functional-parity.md`, `PLAN.md`, and `AGENTS.md`.

---

## Review Scope

The review covers the 13 parity surfaces already tracked in
`docs/flutter-electron-ui-functional-parity.md`:

1. Empty first-run home.
2. Populated grid/waterfall browse.
3. Map browse / disabled-map state.
4. Timeline browse.
5. Detail inspector and edits.
6. Fullscreen gallery.
7. Favorites filter.
8. Memories list.
9. Memory detail management.
10. Settings.
11. Notifications / AI queue.
12. Chinese locale.
13. Restart persistence.

For each surface, review these dimensions:

- Entry path: how the user reaches the surface in Electron and Flutter.
- First-viewport layout: major navigation, hierarchy, density, and visible controls.
- Core actions: buttons, keyboard shortcuts, menus, toggles, and text inputs.
- State semantics: selected item, active filters, empty/error/disabled states, persistence.
- Overlay/dialog behavior: focus, Escape, mode switches, close behavior, and return path.
- Test coverage: existing automated coverage and missing red-test opportunities.
- Screenshot evidence: Electron PNG, Flutter PNG, and compare PNG.

## Files

- Modify: `docs/flutter-electron-ui-functional-parity.md`
  - Record reviewed surfaces, gaps, accepted differences, and evidence.
- Modify: `PLAN.md`
  - Add the review phase and closure criteria.
- Modify: `docs/flutter-refactor-phases.md`
  - Add the review phase under Flutter desktop parity.
- Modify: `AGENTS.md`
  - Record every meaningful review step and verification command.
- Create or update: `docs/flutter-electron-feature-ui-review.md`
  - Store the detailed per-surface review notes so the parity matrix stays concise.
- Optional generated evidence: `test-results/flutter-electron-parity/compare/*.png`
  - Ignored screenshots used for visual review.

## Task 1: Establish Review Phase

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`
- Create: `docs/flutter-electron-feature-ui-review.md`

- [x] **Step 1: Add the phase to `PLAN.md`**

  Add a phase after the viewer overlay correction:

  ```markdown
  ### 4.37 Full Feature UI Parity Review Phase

  - Purpose: review every Electron-vs-Flutter desktop feature surface and UI state with code, tests, and refreshed screenshot evidence before further broad UI work.
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
  - Current status:
    planned on 2026-05-09.
  ```

- [x] **Step 2: Add the phase to `docs/flutter-refactor-phases.md`**

  Add:

  ```markdown
  ## Phase 5.9: Full Feature UI Parity Review

  Purpose: audit all desktop Flutter surfaces against the Electron reference one by one, using code comparison, behavioral tests, and refreshed screenshot comparison.

  Deliverables:

  - All 13 parity surfaces have refreshed Electron and Flutter screenshots.
  - All 13 side-by-side compare artifacts are generated and inspected.
  - `docs/flutter-electron-feature-ui-review.md` records per-surface behavior notes, UI differences, test coverage, and gap decisions.
  - Confirmed gaps are promoted into explicit follow-up phases before implementation.
  ```

- [x] **Step 3: Initialize the detailed review report**

  Create `docs/flutter-electron-feature-ui-review.md` with this structure:

  ```markdown
  # Flutter Electron Feature UI Review

  ## Review Rules

  - Electron is the reference, but code and screenshot evidence must confirm the actual Electron behavior before declaring a contract.
  - A screenshot match is not sufficient; behavior must be covered by existing tests or a named missing-test item.
  - Do not classify a difference as accepted unless it is renderer-specific and does not affect workflow, hierarchy, or semantics.
  - Confirmed gaps must be promoted to follow-up phases before implementation.

  ## Surface Checklist

  | Surface | Reference Code Checked | Flutter Code Checked | Tests Checked | Screenshots Compared | Decision | Notes |
  | --- | --- | --- | --- | --- | --- | --- |
  | Empty first-run home | Pending | Pending | Pending | Pending | Pending | Pending |
  | Populated grid/waterfall browse | Pending | Pending | Pending | Pending | Pending | Pending |
  | Map browse / disabled-map state | Pending | Pending | Pending | Pending | Pending | Pending |
  | Timeline browse | Pending | Pending | Pending | Pending | Pending | Pending |
  | Detail inspector and edits | Pending | Pending | Pending | Pending | Pending | Pending |
  | Fullscreen gallery | Pending | Pending | Pending | Pending | Pending | Pending |
  | Favorites filter | Pending | Pending | Pending | Pending | Pending | Pending |
  | Memories list | Pending | Pending | Pending | Pending | Pending | Pending |
  | Memory detail management | Pending | Pending | Pending | Pending | Pending | Pending |
  | Settings | Pending | Pending | Pending | Pending | Pending | Pending |
  | Notifications / AI queue | Pending | Pending | Pending | Pending | Pending | Pending |
  | Chinese locale | Pending | Pending | Pending | Pending | Pending | Pending |
  | Restart persistence | Pending | Pending | Pending | Pending | Pending | Pending |
  ```

- [x] **Step 4: Record start in `AGENTS.md`**

  Record the phase, method, and next command.

## Task 2: Refresh Evidence

**Files:**
- Generated: `test-results/flutter-electron-parity/electron/*.png`
- Generated: `test-results/flutter-electron-parity/flutter/*.png`
- Generated: `test-results/flutter-electron-parity/compare/*.png`

- [x] **Step 1: Refresh Electron screenshots**

  Run:

  ```bash
  node scripts/capture-electron-parity.mjs
  file test-results/flutter-electron-parity/electron/*.png
  ```

  Expected: all 13 Electron PNGs exist and are 1440x920.

- [x] **Step 2: Refresh Flutter screenshots**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh all
  file ../test-results/flutter-electron-parity/flutter/*.png
  ```

  Expected: all 13 Flutter PNGs exist and are 1440x920.

- [x] **Step 3: Generate side-by-side compare images**

  Run from repo root:

  ```bash
  mkdir -p test-results/flutter-electron-parity/compare
  for name in 01-empty-home 02-populated-grid 03-map 04-timeline 05-detail 06-gallery 07-favorites 08-memories-list 09-memory-detail 10-settings 11-notifications 12-zh-locale 13-restart-persistence; do
    montage "test-results/flutter-electron-parity/electron/${name}.png" "test-results/flutter-electron-parity/flutter/${name}.png" -tile 2x1 -geometry +24+0 "test-results/flutter-electron-parity/compare/${name}-compare.png"
  done
  file test-results/flutter-electron-parity/compare/*.png
  ```

  Expected: all 13 compare PNGs exist and are 2976x920.

## Task 3: Review Surfaces One By One

**Files:**
- Modify: `docs/flutter-electron-feature-ui-review.md`
- Modify if gaps are confirmed: `docs/flutter-electron-ui-functional-parity.md`

- [x] **Step 1: Review navigation and browse basics**

  Surfaces:
  `01-empty-home`,
  `02-populated-grid`,
  `07-favorites`,
  `13-restart-persistence`.

  Check:
  single click/tap selection,
  double-click/double-tap Detail overlay,
  `G` Gallery,
  `Enter` Detail,
  filter/search controls,
  selected-photo banner,
  sidebar active state,
  restart state.

- [x] **Step 2: Review spatial and temporal browsing**

  Surfaces:
  `03-map`,
  `04-timeline`.

  Check:
  entry buttons,
  disabled map state,
  mapped counts,
  GPS-only filter semantics,
  timeline grouping,
  selected-photo handling,
  and return to grid.

- [x] **Step 3: Review viewer overlays**

  Surfaces:
  `05-detail`,
  `06-gallery`.

  Check:
  Detail-first activation,
  left viewer/right inspector relationship,
  Gallery mode switch,
  `D` / `Detail View` / `Open Inspector` return path,
  arrow navigation,
  filmstrip selection,
  Escape close,
  edit controls,
  rollback,
  and AI metadata.

- [x] **Step 4: Review memories**

  Surfaces:
  `08-memories-list`,
  `09-memory-detail`.

  Check:
  memory card hierarchy,
  suggested memory actions,
  accept/reject,
  detail hero,
  cover/photo count,
  description/story sections,
  add/remove photo,
  set cover,
  and return navigation.

- [x] **Step 5: Review settings and notifications**

  Surfaces:
  `10-settings`,
  `11-notifications`.

  Check:
  library source controls,
  scan controls,
  backup/restore,
  locale settings,
  AI readiness,
  map settings,
  notification badge,
  AI queue retry,
  and memory suggestion handoff.

- [x] **Step 6: Review Chinese locale**

  Surface:
  `12-zh-locale`.

  Check:
  navigation labels,
  browse controls,
  filters,
  settings labels,
  notifications labels,
  and distinguish fixture-authored content from app UI strings.

## Task 4: Close Or Promote Findings

**Files:**
- Modify: `docs/flutter-electron-feature-ui-review.md`
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Classify every row**

  Use only these decisions:

  - `Matched`: behavior and first-viewport hierarchy are equivalent.
  - `Accepted Difference`: only renderer-specific pixel/styling differences remain.
  - `Gap`: workflow, hierarchy, state semantics, or test coverage does not match.

- [x] **Step 2: Promote gaps into follow-up phases**

  For each confirmed `Gap`, write a new phase with:
  exact reference behavior,
  code paths,
  failing test to add,
  screenshot scene to refresh,
  and verification command.

- [x] **Step 3: Run final review gate**

  Run:

  ```bash
  pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts
  pnpm run e2e:runtime
  pnpm typecheck
  pnpm build
  cd chronopic_flutter
  dart analyze packages/chronopic_ui apps/chronopic
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart
  cd ..
  git diff --check
  ```

  Expected: all pass before any review closure commit.
