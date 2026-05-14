# Flutter Mobile UX Refinement From Real Screenshots Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the Android mobile UI using the real screenshots from 2026-05-11 and 2026-05-12 so the app feels like a native phone product rather than a compressed desktop workspace.

**Architecture:** Keep the existing Flutter domain, app-service, scan, lazy-thumbnail, count, and release pipelines unchanged. Limit implementation to `chronopic_ui` mobile presentation, mobile widget/integration tests, and durable UX documentation.

**Tech Stack:** Flutter, Dart widget tests, existing `ChronoPicHome`, `HomePage`, `DetailSurface`, `GalleryDialog`, `DesktopShell` mobile branch, and the established Android deep E2E gate.

---

### Task 1: Record The Real-Screenshot UX Audit

**Files:**
- Create: `docs/flutter-mobile-real-screenshot-ux-audit.md`
- Modify: `docs/mobile-productization.md`
- Test: `git diff --check`

- [x] **Step 1: Create the audit document**

Create `docs/flutter-mobile-real-screenshot-ux-audit.md` with these sections:

```markdown
# Flutter Mobile Real-Screenshot UX Audit

## Source Screenshots

- `.tmp/diagnostics/mobile-import-screenshot.jpg`: Android import/home screenshot from 2026-05-11.
- `.tmp/screenshots/mobile-count-scroll-2026-05-12.jpg`: Android focused Detail screenshot from 2026-05-12.
- `.tmp/user-input/mobile-ui-refine.png`: user-provided mobile UI refine proposal.

## Confirmed UX Issues

1. Home information hierarchy is too dense after Phase 11 and Phase 12.
2. Scan/catalog/browse totals are now logically correct, but repeated count surfaces make the first viewport harder to scan.
3. Bottom navigation and browse controls need stronger bottom-safe spacing so content does not feel clipped by the persistent nav.
4. Focused Detail is functionally correct, but the top action cluster is visually heavy on phone widths.
5. Gallery is functionally correct, but mobile actions should be simplified around view, navigate, and inspect rather than desktop-like command grouping.

## Non-Goals

- No data model changes.
- No scan pipeline changes.
- No lazy-thumbnail cache changes.
- No Play Store submission work.
- No OCR, vector search, person recognition, cloud sync, AI thumbnail analysis, or EXIF writeback.
- No iOS live verification claim from this Linux workstation.
```

- [x] **Step 2: Add the Phase 13 contract to mobile productization docs**

Append a `Phase 13 Mobile Real-Screenshot UX Contract` section to `docs/mobile-productization.md` after the Phase 12 section. Include:

```markdown
## Phase 13 Mobile Real-Screenshot UX Contract

Captured on 2026-05-13 for Phase 13.

- Mobile home keeps the correct Phase 12 count semantics but reduces first-viewport repetition.
- Browse controls stay reachable without visually colliding with the bottom navigation.
- Focused Detail prioritizes media and a light phone topbar before inspector/editing controls.
- Gallery keeps full-result counters and lazy thumbnails while simplifying mobile action placement.
- Settings remains grouped and drill-in based; this phase does not redesign settings architecture.
- Android is the live verification target; iOS remains blocked until macOS/Xcode evidence exists.
```

- [x] **Step 3: Verify docs formatting**

Run:

```bash
git diff --check
```

Expected: no output and exit code `0`.

### Task 2: Refine Mobile Home Information Hierarchy

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Test: `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add a failing widget test for the refined mobile home**

In `mobile_productization_test.dart`, add a test that imports 25 fixture photos and asserts:

```dart
expect(find.byKey(const Key('mobile-dashboard-primary-count')), findsOneWidget);
expect(find.text('25 indexed'), findsOneWidget);
expect(find.text('25 indexed locally'), findsNothing);
expect(find.text('20 loaded / 25 total'), findsOneWidget);
expect(find.byKey(const Key('mobile-scan-progress-card')), findsOneWidget);
```

Expected before implementation: the test fails because `mobile-dashboard-primary-count` does not exist and the scan card still repeats `25 indexed locally`.

- [x] **Step 2: Simplify `_MobileHomeDashboard` count presentation**

In `home_page.dart`, keep the All Photos shortcut as the primary catalog count and add:

```dart
key: const Key('mobile-dashboard-primary-count'),
```

to the text that displays the primary catalog count.

Update the scan card subtitle so the idle state says `Ready for local browsing` / `可本地浏览`, and the scanning state says `Indexing without blocking browsing` / `索引中，可继续浏览`, rather than repeating the catalog count.

- [x] **Step 3: Verify the focused home test passes**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: all tests pass.

### Task 3: Tighten Bottom Navigation And Browse Spacing

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/shell/desktop_shell.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Test: `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add a failing test for bottom-safe browse content**

Extend the 25-photo mobile browse test with:

```dart
expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);
expect(find.byKey(const Key('mobile-browse-bottom-spacer')), findsOneWidget);
```

Expected before implementation: the test fails because these keys are absent.

- [x] **Step 2: Key the bottom navigation**

In `desktop_shell.dart`, add:

```dart
key: const Key('mobile-bottom-navigation'),
```

to the root `DecoratedBox` inside `_MobileBottomNavigation`.

- [x] **Step 3: Add explicit browse bottom spacing**

In `home_page.dart`, replace the unconditional final sliver padding with mobile-aware spacing:

```dart
SliverPadding(
  key: mobileLayout
      ? const Key('mobile-browse-bottom-spacer')
      : const Key('desktop-browse-bottom-spacer'),
  padding: EdgeInsets.only(bottom: mobileLayout ? 110 : 28),
),
```

- [x] **Step 4: Verify bottom spacing coverage**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: all tests pass.

### Task 4: Refine Focused Detail For Mobile Media Priority

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Test: `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add a failing test for the lighter Detail action model**

Extend the mobile focused-detail test to assert:

```dart
expect(find.byKey(const Key('mobile-detail-topbar')), findsOneWidget);
expect(find.byKey(const Key('mobile-detail-primary-actions')), findsOneWidget);
expect(find.byKey(const Key('mobile-detail-inspector-sheet-entry')), findsOneWidget);
expect(find.textContaining('Esc close'), findsNothing);
expect(find.textContaining('Left/Right'), findsNothing);
```

Expected before implementation: the test fails because `mobile-detail-primary-actions` and `mobile-detail-inspector-sheet-entry` do not exist.

- [x] **Step 2: Split mobile Detail actions**

In `detail_surface.dart`, keep the existing desktop focused layout intact. For mobile width, expose:

- `mobile-detail-topbar`: back/close, counter, more/inspector entry.
- `mobile-detail-media`: largest available media area.
- `mobile-detail-primary-actions`: favorite, add-to-memory, open-gallery.
- `mobile-detail-inspector-sheet-entry`: button opening or revealing the edit/metadata area.

Do not show desktop keyboard shortcut copy in mobile Detail.

- [x] **Step 3: Verify Detail tests**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: all tests pass.

### Task 5: Simplify Mobile Gallery Controls

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Modify: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
- Test: `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
- Test: `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`

- [x] **Step 1: Add widget coverage for Gallery mobile chrome**

Add assertions that opening Gallery on a 25-photo fixture shows:

```dart
expect(find.byKey(const Key('gallery-counter')), findsOneWidget);
expect(find.byKey(const Key('mobile-gallery-actions')), findsOneWidget);
expect(find.byKey(const Key('open-inspector-button')), findsOneWidget);
expect(find.text('1 / 25'), findsOneWidget);
```

Expected before implementation: the test fails because `mobile-gallery-actions` does not exist.

- [x] **Step 2: Add a compact mobile Gallery action row**

In `gallery_dialog.dart`, keep the AppBar counter and move mobile-specific controls into a compact row keyed as:

```dart
key: const Key('mobile-gallery-actions'),
```

The row should expose previous, next, and inspector/detail actions with icon buttons. Keep desktop Gallery layout unchanged.

- [x] **Step 3: Verify widget and integration gates**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart
```

Expected: both commands pass.

### Task 6: Close Phase 13 With Full Verification And Docs

**Files:**
- Modify: `PLAN.md`
- Modify: `AGENTS.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/mobile-e2e-verification.md`
- Test: full local verification bundle

- [x] **Step 1: Run focused Flutter verification**

Run:

```bash
cd chronopic_flutter && flutter analyze
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test
cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart
cd chronopic_flutter/apps/chronopic && flutter build apk --debug
git diff --check
```

Expected: all commands pass. The integration test may print the known `integration_test` plugin warning, but the command must exit `0`.

- [x] **Step 2: Update phase docs with results**

Update `PLAN.md`, `docs/flutter-refactor-phases.md`, `docs/mobile-productization.md`, and `docs/mobile-e2e-verification.md` with:

- completed Phase 13 summary,
- commands run,
- scenes covered,
- iOS live verification blocked reason,
- any screenshots or artifacts captured during the phase.

- [x] **Step 3: Update AGENTS.md**

Append a new step recording:

- what changed,
- why it changed,
- files touched,
- verification scenes and commands,
- skipped iOS evidence reason,
- next recommended phase.

- [ ] **Step 4: Commit if requested**

If the user asks for `add and commit`, run:

```bash
git status --short
git add PLAN.md AGENTS.md docs/flutter-refactor-phases.md docs/mobile-productization.md docs/mobile-e2e-verification.md docs/flutter-mobile-real-screenshot-ux-audit.md chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart chronopic_flutter/packages/chronopic_ui/lib/src/shell/desktop_shell.dart chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart
git commit -m "Refine Flutter mobile UX from real screenshots"
```

Expected: one focused commit containing Phase 13 implementation, tests, and docs.
