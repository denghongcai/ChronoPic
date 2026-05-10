# Flutter Desktop Interaction Regression Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-audit Flutter Linux desktop interactions against the Electron reference and re-check adaptive desktop layout after the v0.1.6 selected-photo regression.

**Architecture:** Treat this phase as an evidence-first regression audit, not a redesign sprint. Electron remains the desktop interaction reference, while Flutter Linux is the release candidate; every confirmed mismatch must produce either a focused fix plus regression test or an explicit accepted-difference record.

**Tech Stack:** Flutter widget tests, Flutter Linux debug bundle, existing Electron and Flutter parity capture scripts, Xvfb/scrot, ImageMagick compare artifacts, `docs/flutter-electron-ui-functional-parity.md`, `docs/flutter-electron-feature-ui-review.md`, `PLAN.md`, and `AGENTS.md`.

**Status:** Completed locally on 2026-05-10. Closeout evidence is recorded in `docs/flutter-desktop-interaction-regression-audit.md`, `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md`.

---

### Task 1: Create The Audit Matrix

**Files:**
- Create: `docs/flutter-desktop-interaction-regression-audit.md`
- Modify: `PLAN.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Create the audit document with fixed rows**

Create `docs/flutter-desktop-interaction-regression-audit.md` with this structure:

```markdown
# Flutter Desktop Interaction Regression Audit

Date: 2026-05-10
Reference: Electron desktop
Candidate: Flutter Linux desktop

## Decisions

- Single click selects only.
- Double click opens focused Detail.
- Enter opens focused Detail for the selected photo.
- `G` opens or switches to Gallery.
- `D` switches to Detail from Gallery.
- Escape closes focused overlays.
- Waterfall browse uses incremental 20-item loading.
- Desktop adaptive layout must be rechecked at 1366, 1600, and 2048 widths.

## Audit Matrix

| Surface | Interaction | Evidence | Status | Notes |
| --- | --- | --- | --- | --- |
| Waterfall | Single click selects without inline detail | Pending | Pending | Must verify selected banner/card highlight only |
| Waterfall | Double click opens focused Detail | Pending | Pending | Must match Electron overlay model |
| Waterfall | Enter opens focused Detail | Pending | Pending | Selection must be enough; no inline editor |
| Waterfall | `G` opens Gallery from selection | Pending | Pending | Gallery is overlay |
| Waterfall | Incremental load starts at 20 and loads 20 more | Pending | Pending | No 80-item default |
| Detail | Escape closes overlay | Pending | Pending | Returns to browse with selection intact |
| Detail | Save/validation feedback visible inside overlay | Pending | Pending | No hidden shell-only feedback |
| Gallery | Arrow navigation and filmstrip update | Pending | Pending | Left/right behavior |
| Gallery | `D` switches to Detail | Pending | Pending | Same selected photo |
| Map | Selection does not open inline detail | Pending | Pending | Enter opens focused Detail |
| Timeline | Selection does not open inline detail | Pending | Pending | Enter opens focused Detail |
| Settings | Resize does not clip controls | Pending | Pending | 1366/1600/2048 |
| Memories list | Resize preserves card readability | Pending | Pending | 1366/1600/2048 |
| Memory detail | Resize preserves editor/actions | Pending | Pending | 1366/1600/2048 |
| Notifications | Resize preserves queue/action layout | Pending | Pending | 1366/1600/2048 |

## Accepted Differences

No new accepted differences recorded yet.

## Closeout Evidence

- Electron screenshots:
- Flutter screenshots:
- Compare artifacts:
- Commands:
- Remaining gaps:
```

- [x] **Step 2: Link this audit from `PLAN.md`**

Add the audit document under Phase 9 so future implementation does not rely on chat history.

- [x] **Step 3: Record the phase start in `AGENTS.md`**

Add a step entry stating that the audit matrix was created before behavior changes.

### Task 2: Strengthen Interaction Regression Tests

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`

- [x] **Step 1: Add or confirm red-path coverage for single-click selection**

In `chronopic_home_test.dart`, keep or add assertions with this shape after tapping a photo card:

```dart
expect(find.text('SELECTED PHOTO'), findsOneWidget);
expect(find.text('Detail view and gallery view'), findsNothing);
expect(find.byKey(const Key('focused-detail-view')), findsNothing);
```

Run:

```bash
cd chronopic_flutter
flutter test packages/chronopic_ui/test/chronopic_home_test.dart --plain-name "renders the Flutter desktop MVP surfaces"
```

Expected: the test passes with the v0.1.6 behavior and would fail if inline detail returns.

- [x] **Step 2: Add focused opening coverage for each browse mode**

In `chronopic_home_test.dart`, ensure Waterfall, Map, and Timeline each cover:

```dart
await tester.tap(find.byKey(const Key('photo-card-photo-city')));
await tester.pump();
expect(find.byKey(const Key('focused-detail-view')), findsNothing);
await tester.sendKeyEvent(LogicalKeyboardKey.enter);
await tester.pumpAndSettle();
expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
await tester.sendKeyEvent(LogicalKeyboardKey.escape);
await tester.pumpAndSettle();
expect(find.byKey(const Key('focused-detail-view')), findsNothing);
```

Use the existing per-mode card keys where Waterfall keys are not in scope:
`map-photo-photo-lake` and `timeline-photo-photo-city`.

- [x] **Step 3: Add keyboard and overlay transition coverage**

In `linux_desktop_parity_test.dart`, verify:

```dart
await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
await tester.pumpAndSettle();
expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);
await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
await tester.pumpAndSettle();
expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
await tester.sendKeyEvent(LogicalKeyboardKey.escape);
await tester.pumpAndSettle();
expect(find.byKey(const Key('focused-detail-view')), findsNothing);
```

- [x] **Step 4: Add incremental-load regression coverage**

In `linux_desktop_parity_test.dart`, keep or add coverage that starts with 25 scanned photos and asserts:

```dart
expect(find.text('20 items'), findsOneWidget);
await tester.fling(
  find.byType(CustomScrollView),
  const Offset(0, -5000),
  10000,
);
await tester.pumpAndSettle();
expect(find.text('25 items'), findsOneWidget);
```

- [x] **Step 5: Run focused tests**

Run:

```bash
cd chronopic_flutter
flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart
```

Expected: all tests pass.

### Task 3: Refresh Desktop Screenshot Evidence

**Files:**
- Modify if needed: `scripts/capture-electron-parity.mjs`
- Modify if needed: `chronopic_flutter/tool/capture_flutter_parity.sh`
- Modify: `docs/flutter-desktop-interaction-regression-audit.md`

- [x] **Step 1: Capture Electron reference surfaces**

Run:

```bash
node scripts/capture-electron-parity.mjs
```

Expected:

- Command exits 0.
- Electron screenshots exist under `test-results/flutter-electron-parity/electron/`.
- All expected 13 PNG files are present.

- [x] **Step 2: Capture Flutter candidate surfaces**

Run:

```bash
cd chronopic_flutter
bash tool/capture_flutter_parity.sh all
```

Expected:

- Command exits 0.
- Flutter screenshots exist under `test-results/flutter-electron-parity/flutter/`.
- All expected 13 PNG files are present.
- `02-populated-grid.png` shows selection without a bottom inline detail editor.
- `05-detail.png` shows the focused Detail overlay.

- [x] **Step 3: Rebuild compare artifacts**

Use the existing compare/montage workflow from Phase 6.6. If the compare helper is missing, create a small script in `scripts/compare-flutter-electron-parity.mjs` that pairs same-named files and writes side-by-side PNGs under `test-results/flutter-electron-parity/compare/`.

Run:

```bash
node scripts/compare-flutter-electron-parity.mjs
```

Expected:

- Command exits 0.
- All 13 compare PNGs exist.
- No compare artifact is blank.

- [x] **Step 4: Update the audit matrix**

For every row in `docs/flutter-desktop-interaction-regression-audit.md`, set `Status` to one of:

- `Matched`
- `Fixed`
- `Accepted Difference`
- `Gap`

Do not leave `Pending` rows after closeout.

### Task 4: Recheck Adaptive Desktop Layout

**Files:**
- Modify if needed: `chronopic_flutter/tool/capture_flutter_parity.sh`
- Modify if needed: `chronopic_flutter/packages/chronopic_ui/lib/src/`
- Modify: `docs/flutter-desktop-interaction-regression-audit.md`

- [x] **Step 1: Capture populated-grid and detail at 1366, 1600, and 2048 widths**

Use the existing Phase 8 adaptive capture approach. Expected output paths:

```text
test-results/flutter-adaptive-regression/1366-populated-grid.png
test-results/flutter-adaptive-regression/1600-populated-grid.png
test-results/flutter-adaptive-regression/2048-populated-grid.png
test-results/flutter-adaptive-regression/1366-detail.png
test-results/flutter-adaptive-regression/1600-detail.png
test-results/flutter-adaptive-regression/2048-detail.png
```

- [x] **Step 2: Inspect screenshots for known adaptive failures**

Check each screenshot for:

- sidebar overlap,
- toolbar wrapping into unreadable controls,
- selected-photo banner clipping,
- grid cards becoming too narrow or too sparse,
- overlay inspector clipping,
- edit fields hidden behind inaccessible scroll areas,
- 20-item incremental count still visible at first load.

- [x] **Step 3: Fix only confirmed adaptive gaps**

If a gap appears, patch the smallest owning component in:

```text
chronopic_flutter/packages/chronopic_ui/lib/src/shell/
chronopic_flutter/packages/chronopic_ui/lib/src/home/
chronopic_flutter/packages/chronopic_ui/lib/src/detail/
chronopic_flutter/packages/chronopic_ui/lib/src/gallery/
```

Do not mix mobile redesign into this desktop phase.

### Task 5: Close The Phase

**Files:**
- Modify: `PLAN.md`
- Modify: `AGENTS.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/flutter-desktop-interaction-regression-audit.md`

- [x] **Step 1: Run source verification**

Run:

```bash
cd chronopic_flutter
flutter analyze
flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart
```

Expected: analyzer reports no issues and all tests pass.

- [x] **Step 2: Run screenshot verification**

Run:

```bash
node scripts/capture-electron-parity.mjs
cd chronopic_flutter
bash tool/capture_flutter_parity.sh all
```

Expected: both commands pass and screenshot paths are recorded.

- [x] **Step 3: Update phase status**

Update `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md` with:

- commands run,
- screenshot paths,
- compare artifact paths,
- fixed gaps,
- accepted differences,
- skipped scenes with reasons.

- [x] **Step 4: Commit**

Run:

```bash
git add PLAN.md AGENTS.md docs/flutter-refactor-phases.md docs/flutter-desktop-interaction-regression-audit.md chronopic_flutter/packages/chronopic_ui scripts
git commit -m "Audit Flutter desktop interaction regressions"
```

Expected: commit succeeds with only desktop audit/fix files staged.

## Self-Review

- Spec coverage: this plan covers desktop interaction regression, Electron comparison, selected-photo behavior, keyboard overlays, incremental loading, and adaptive layout recheck.
- Placeholder scan: no task uses TBD/TODO or unspecified verification.
- Type consistency: file paths and keys match existing Flutter parity tests and capture scripts.
