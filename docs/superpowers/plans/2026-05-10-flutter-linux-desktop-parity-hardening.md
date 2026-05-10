# Flutter Linux Desktop Parity Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:systematic-debugging for any confirmed mismatch investigation and superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-freeze Flutter Linux desktop against the Electron reference after Phase 6 and Phase 6.5 mobile work, using refreshed tests, screenshots, compare artifacts, and only targeted fixes for confirmed gaps.

**Architecture:** Reuse the existing Electron and Flutter parity harnesses instead of creating a second comparison system. Treat Electron as the desktop reference, Flutter Linux as the parity target, and `docs/flutter-electron-ui-functional-parity.md` as the closure matrix. Screenshot evidence proves rendering only; behavior must still be covered by Electron E2E or Flutter widget/parity tests before a row can remain closed.

**Tech Stack:** Electron Playwright capture, Flutter Linux debug bundle, Xvfb, scrot, ImageMagick `montage`, Flutter widget/parity tests, Electron E2E tests, `docs/flutter-electron-ui-functional-parity.md`, `docs/flutter-electron-feature-ui-review.md`, `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md`.

---

## File Structure

- Modify `PLAN.md`
  - Promote the selected post Phase 6.5 candidate into active Phase 6.6.
- Modify `docs/flutter-refactor-phases.md`
  - Add Phase 6.6 with deliverables, evidence commands, and closeout gate.
- Modify `AGENTS.md`
  - Record every meaningful execution step, commands, evidence paths, and remaining gaps.
- Modify `docs/flutter-electron-ui-functional-parity.md`
  - Update the current closure status after fresh capture and review.
- Modify `docs/flutter-electron-feature-ui-review.md`
  - Add a Phase 6.6 refresh note if the review confirms no new feature/UI gaps.
- Modify Flutter UI files under `chronopic_flutter/packages/chronopic_ui/lib/src/` only if refreshed comparison proves a workflow, hierarchy, localization, or responsive gap.
- Modify Flutter tests under `chronopic_flutter/packages/chronopic_ui/test/` only when a confirmed gap needs behavioral coverage.
- Generated evidence under ignored `test-results/flutter-electron-parity/`
  - Electron PNGs in `electron/`
  - Flutter PNGs in `flutter/`
  - Side-by-side PNGs in `compare/`

## Reference Surfaces

Phase 6.6 rechecks the same 13 surfaces already used by the parity matrix:

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

## Task 1: Promote Phase 6.6

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Update `PLAN.md`**

  Convert the recorded candidate into active Phase 6.6:

  ```markdown
  ### 6.6 Flutter Linux Desktop Parity Hardening

  - Implementation plan:
    [docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md](docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md)
  - Scope:
    refresh Electron and Flutter Linux parity evidence after Phase 6/6.5,
    inspect all 13 side-by-side compare artifacts,
    preserve or repair desktop parity before Phase 7 release work starts.
  - Current status:
    started on 2026-05-10.
  ```

- [x] **Step 2: Update `docs/flutter-refactor-phases.md`**

  Add `Phase 6.6: Flutter Linux Desktop Parity Hardening` before Phase 7 with:

  ```markdown
  Deliverables:

  - Refresh all 13 Electron reference screenshots.
  - Refresh all 13 Flutter Linux screenshots.
  - Regenerate all 13 side-by-side compare artifacts.
  - Reinspect `docs/flutter-electron-ui-functional-parity.md` and `docs/flutter-electron-feature-ui-review.md`.
  - Fix any confirmed Flutter desktop workflow or UI gap with focused tests.
  ```

- [x] **Step 3: Record start in `AGENTS.md`**

  Add a new step with the selected phase, reused evidence harnesses, and next command.

- [x] **Step 4: Verify documentation formatting**

  Run:

  ```bash
  git diff --check
  ```

  Expected: no output.

## Task 2: Refresh Two-Side Screenshot Evidence

**Files:**
- Generated: `test-results/flutter-electron-parity/electron/*.png`
- Generated: `test-results/flutter-electron-parity/flutter/*.png`
- Generated: `test-results/flutter-electron-parity/compare/*.png`

- [x] **Step 1: Build and prepare Electron**

  Run:

  ```bash
  pnpm build
  pnpm run e2e:prepare
  ```

  Expected: both commands exit 0.

- [x] **Step 2: Refresh Electron screenshots**

  Run:

  ```bash
  node scripts/capture-electron-parity.mjs
  file test-results/flutter-electron-parity/electron/*.png
  ```

  Expected: exactly 13 Electron PNGs exist and each reports `PNG image data, 1440 x 920`.

- [x] **Step 3: Refresh Flutter screenshots**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh all
  file ../test-results/flutter-electron-parity/flutter/*.png
  ```

  Expected: exactly 13 Flutter PNGs exist and each reports `PNG image data, 1440 x 920`.

- [x] **Step 4: Regenerate compare artifacts**

  Run from repo root:

  ```bash
  mkdir -p test-results/flutter-electron-parity/compare
  for name in 01-empty-home 02-populated-grid 03-map 04-timeline 05-detail 06-gallery 07-favorites 08-memories-list 09-memory-detail 10-settings 11-notifications 12-zh-locale 13-restart-persistence; do
    montage "test-results/flutter-electron-parity/electron/${name}.png" "test-results/flutter-electron-parity/flutter/${name}.png" -tile 2x1 -geometry +24+0 "test-results/flutter-electron-parity/compare/${name}-compare.png"
  done
  file test-results/flutter-electron-parity/compare/*.png
  ```

  Expected: exactly 13 compare PNGs exist and each reports `PNG image data, 2976 x 920`.

## Task 3: Inspect Parity And Classify Gaps

**Files:**
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `docs/flutter-electron-feature-ui-review.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Verify evidence counts**

  Run:

  ```bash
  find test-results/flutter-electron-parity/electron -maxdepth 1 -name '*.png' | sort | wc -l
  find test-results/flutter-electron-parity/flutter -maxdepth 1 -name '*.png' | sort | wc -l
  find test-results/flutter-electron-parity/compare -maxdepth 1 -name '*-compare.png' | sort | wc -l
  ```

  Expected: `13`, `13`, and `13`.

- [x] **Step 2: Inspect compare artifacts**

  Open and inspect these files:

  ```text
  test-results/flutter-electron-parity/compare/01-empty-home-compare.png
  test-results/flutter-electron-parity/compare/02-populated-grid-compare.png
  test-results/flutter-electron-parity/compare/03-map-compare.png
  test-results/flutter-electron-parity/compare/04-timeline-compare.png
  test-results/flutter-electron-parity/compare/05-detail-compare.png
  test-results/flutter-electron-parity/compare/06-gallery-compare.png
  test-results/flutter-electron-parity/compare/07-favorites-compare.png
  test-results/flutter-electron-parity/compare/08-memories-list-compare.png
  test-results/flutter-electron-parity/compare/09-memory-detail-compare.png
  test-results/flutter-electron-parity/compare/10-settings-compare.png
  test-results/flutter-electron-parity/compare/11-notifications-compare.png
  test-results/flutter-electron-parity/compare/12-zh-locale-compare.png
  test-results/flutter-electron-parity/compare/13-restart-persistence-compare.png
  ```

  Classify each surface as:

  - `Closed`: still covered by the existing accepted-difference reason.
  - `Gap`: new Phase 6/6.5 drift changed hierarchy, workflow, localization, or visible desktop behavior.
  - `Needs test`: screenshot appears aligned but behavior is not covered by an existing Electron E2E or Flutter parity/widget test.

- [x] **Step 3: Update review docs**

  If no new gaps are found, add a Phase 6.6 refresh note to both parity docs.
  If gaps are found, add named findings such as `P66-001` with evidence paths,
  code paths, required tests, and repair order.

## Task 4: Repair Confirmed Gaps Only

Phase 6.6 found and repaired `P66-001`,
a capture-harness locale normalization gap.
Phase 6.6 also found and repaired `P66-002`,
a Playwright output-directory conflict that deleted parity PNG evidence.
No product Flutter UI/function gap was confirmed during contact-sheet review,
so no Flutter UI module repair was required.

**Files:**
- Modify only if required: `chronopic_flutter/packages/chronopic_ui/lib/src/**`
- Modify only if required: `chronopic_flutter/packages/chronopic_ui/test/**`
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `docs/flutter-electron-feature-ui-review.md`
- Modify: `AGENTS.md`

- [x] **Step 1: For each `Gap`, write or tighten a focused test**

  No product UI/function `Gap` was confirmed.
  Harness coverage came from `bash -n tool/capture_flutter_parity.sh`,
  focused recapture of affected surfaces,
  regenerated compare artifacts,
  and visual contact-sheet inspection.

  Use the nearest existing test file:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart
  ```

  Expected before repair: the new assertion fails for the confirmed gap.

- [x] **Step 2: Implement the smallest coherent Flutter fix**

  The only confirmed fix was in
  `chronopic_flutter/tool/capture_flutter_parity.sh`,
  which now writes temporary English locale settings for normal fixture-backed
  captures.
  The evidence-retention fix was in
  `tests/e2e/playwright.config.ts`,
  which now sends Playwright artifacts to
  `test-results/playwright-artifacts`.

  Keep changes inside the relevant surface module:

  - Browse/grid/map/timeline: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/`
  - Detail: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/`
  - Gallery: `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/`
  - Memories: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/`
  - Settings: `chronopic_flutter/packages/chronopic_ui/lib/src/settings/`
  - Shell/home/localization: `chronopic_flutter/packages/chronopic_ui/lib/src/shell/`, `home/`, or `l10n/`

- [x] **Step 3: Rerun focused tests**

  Ran `bash -n tool/capture_flutter_parity.sh` and focused recapture for:
  `populated-grid`,
  `map`,
  `timeline`,
  `detail`,
  `gallery`,
  `favorites`,
  `memories-list`,
  `memory-detail`,
  `settings`,
  and `notifications`.

  Run the focused command that failed before the fix.
  Expected after repair: the command exits 0.

- [x] **Step 4: Recapture affected Flutter surfaces**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh <surface-name>
  ```

  Expected: the affected Flutter PNG exists and remains 1440x920.

- [x] **Step 5: Regenerate affected compare artifacts**

  Run the same `montage` command for each repaired surface.
  Expected: the affected compare PNG exists and reflects the repaired UI.

## Task 5: Final Verification And Closeout

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `docs/flutter-electron-feature-ui-review.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Run Flutter desktop parity tests**

  Run:

  ```bash
  cd chronopic_flutter
  dart analyze packages/chronopic_ui apps/chronopic
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart
  ```

  Expected: both commands exit 0.

- [x] **Step 2: Run Electron desktop gates**

  Run:

  ```bash
  pnpm run e2e:accessibility
  pnpm run e2e:runtime
  pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts
  ```

  Expected: all commands exit 0.

- [x] **Step 3: Recheck evidence**

  Run:

  ```bash
  file test-results/flutter-electron-parity/electron/*.png
  file test-results/flutter-electron-parity/flutter/*.png
  file test-results/flutter-electron-parity/compare/*.png
  git diff --check
  ```

  Expected:
  Electron and Flutter PNGs report 1440 x 920,
  compare PNGs report 2976 x 920,
  and `git diff --check` has no output.

- [x] **Step 4: Close the phase docs**

  Update all phase docs with:

  - commands run,
  - screenshot directories,
  - gap decisions,
  - skipped scenes with reasons,
  - and whether Phase 7 can begin from the Linux desktop parity perspective.

## Completion Audit

- Objective:
  harden Flutter Linux desktop parity before Phase 7.
- Evidence refreshed:
  Electron `13`,
  Flutter `13`,
  compare `13`,
  plus contact sheet.
- Harness gaps closed:
  `P66-001` Flutter capture locale normalization,
  and `P66-002` Playwright artifact output isolation.
- Product UI/function gaps:
  none found beyond the existing accepted renderer differences after refreshed
  contact-sheet review.
- Final verification:
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  evidence count/dimension checks,
  and `git diff --check` passed.
