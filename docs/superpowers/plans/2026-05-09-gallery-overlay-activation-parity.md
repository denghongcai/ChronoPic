# Gallery Overlay Activation Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make double-clicking a photo open the fullscreen gallery overlay consistently in Electron and Flutter Linux desktop.

**Architecture:** Treat gallery activation as a first-class viewer contract instead of an incidental detail-only action. Electron already has a fullscreen Radix `PhotoViewerOverlay` in gallery mode, and Flutter already has a `Dialog.fullscreen` `GalleryDialog`; this phase wires the primary photo cards and keyboard paths into those overlays, tests the behavior from both implementations, then compares refreshed screenshots before closing the matrix rows.

**Tech Stack:** React, Radix Dialog, Playwright Electron E2E, Flutter widgets, `Dialog.fullscreen`, Flutter `InkWell` with an immediate custom tap/double-tap detector, existing ChronoPic parity capture scripts.

---

## Code Comparison Findings

- Electron card activation currently selects on single click and opens **detail** on double-click:
  `packages/ui-components/src/photo-card.tsx` uses `onDoubleClick={onOpenDetail}` and Enter also calls `onOpenDetail()`.
- Electron fullscreen gallery overlay already exists:
  `packages/ui-components/src/photo-viewer-overlay.tsx` renders `DialogContent` with `fixed inset-0` via `packages/ui-components/src/dialog.tsx`, and gallery mode is selected by `viewerMode === "gallery"`.
- Electron keyboard shortcut `G` already opens gallery for the selected photo:
  `apps/desktop/renderer/src/app/use-viewer-shortcuts.ts`.
- Flutter grid cards currently only select:
  `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart` wires `PhotoCardTile.onTap` to `onSelectPhoto(record)` and has no double-tap path.
- Flutter fullscreen gallery overlay already exists:
  `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart` uses `Dialog.fullscreen` and carries `gallery-dialog`, navigation, filmstrip, and detail-return keys.
- Flutter gallery can currently be opened only through the detail surface or a capture route:
  `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart` `_openGallery(BuildContext)` depends on `_selected` and is not passed into `BrowseSurface`.

## Interaction Contract

- Single click/tap on a photo card selects the photo and keeps the user in the current browse surface.
- Double-click/double-tap on a photo card selects that photo and opens fullscreen gallery overlay directly.
- Keyboard `Enter` keeps the existing Electron detail-inspector behavior.
- Keyboard `G` opens fullscreen gallery for the selected photo on both implementations.
- Gallery overlay must cover the desktop window, expose previous/next navigation, expose the filmstrip, and close with `Escape` while preserving the active photo selection.
- In batch-selection mode, double-click must not open gallery; the card should toggle batch selection only.
- UI closure requires screenshot comparison after interaction alignment:
  Electron and Flutter must both recapture populated browse, gallery, favorites,
  and restart-persistence surfaces, then the agent must re-open or otherwise
  inspect the matching PNG pairs before marking a row closed.

## File Structure

- Modify `packages/ui-components/src/photo-card.tsx`
  - Add explicit `onOpenGallery` card prop.
  - Route double-click to gallery.
  - Preserve Enter-to-detail and Space-to-select.
- Modify `packages/ui-components/src/gallery-section.tsx`
  - Thread `onOpenGallery` into `PhotoCard`.
  - Suppress gallery opening while batch selection is active.
- Modify `packages/ui-components/src/photo-grid.tsx`
  - Thread `onOpenGallery` into `PhotoCard` for shared grid consumers.
- Modify `packages/ui-components/src/memory-detail-page.tsx`
  - Ensure memory-detail photo cards double-click into gallery with the memory photo list.
- Modify `packages/ui-components/src/photo-home.tsx`
  - Add `onOpenGallery(photoId)` prop and pass it to all photo-card surfaces.
- Modify `apps/desktop/renderer/src/App.tsx`
  - Wire `onOpenGallery={(photoId) => app.openViewer("gallery", photoId)}`.
- Modify `tests/e2e/accessibility.spec.ts`
  - Add Electron keyboard and double-click coverage for gallery overlay activation.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  - Add `onOpenGallery` through `BrowseSurface`, `PhotoGrid`, and `PhotoCardTile`.
  - Use an immediate custom tap/double-tap detector so single tap selection is not delayed by Flutter's double-tap recognizer.
  - Add focus/keyboard handling for `G` on the selected card if practical inside the widget tree; otherwise cover app-level `G` in `ChronoPicHome`.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
  - Pass `onOpenGallery` into browse surfaces.
- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
  - Add `_openGalleryFor(PhotoRecord, BuildContext)`.
  - Keep `_openGallery(BuildContext)` as selected-photo wrapper.
  - Wire `G` shortcut when a selected photo exists.
- Modify `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  - Add failing test for double-tapping a grid card into `gallery-dialog`.
  - Assert `Escape` closes and selected photo remains active.
- Modify `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
  - Add lightweight widget assertion for the no-photos/no-selected guard and selected-photo `G` shortcut if not covered by parity test.
- Modify `docs/flutter-electron-ui-functional-parity.md`
  - Reopen the relevant browse/gallery rows for this focused interaction contract.
- Modify `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md`
  - Record Phase 5.8 progress and verification.

## Task 1: Record Phase 5.8

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Add Phase 5.8 to durable plans**

  Add a new phase after Phase 5.7 and before Phase 6:

  ```markdown
  ## Phase 5.8: Gallery Overlay Activation Parity

  Purpose: fix the missing direct photo-to-gallery desktop interaction after Phase 5.7 exposed that screenshot parity did not prove the double-click activation contract.

  Deliverables:

  - Double-clicking a photo card opens fullscreen gallery overlay in Electron and Flutter.
  - Single-click selection, Enter-to-detail, and `G`-to-gallery keyboard paths remain explicit.
  - Gallery overlay remains fullscreen, navigable, and dismissible with `Escape`.
  - Electron and Flutter tests cover the activation path, not only the gallery view once opened.

  Status:

  - Planned on 2026-05-09.
  - Code comparison found Electron currently double-clicks into detail, while Flutter grid cards only select.
  ```

- [x] **Step 2: Reopen the relevant parity rows**

  Update these rows in `docs/flutter-electron-ui-functional-parity.md`:

  ```markdown
  | Populated grid/waterfall browse | ... | ... | Gap | Direct double-click/double-tap photo activation does not open fullscreen gallery overlay consistently across Electron and Flutter. | Pending |
  | Fullscreen gallery | ... | ... | Gap | Gallery view exists, but the primary browse-card activation path is not aligned: Electron double-click opens detail and Flutter card double-tap is missing. | Pending |
  | Favorites filter | ... | ... | Gap | Favorites photo cards must share the same double-click-to-gallery activation contract as the main browse grid. | Pending |
  | Restart persistence | ... | ... | Gap | Restored photo cards must preserve the same double-click-to-gallery activation after app restart. | Pending |
  ```

- [x] **Step 3: Record the phase start in `AGENTS.md`**

  Add:

  ```markdown
  ### 2026-05-09 Step 202

  - Started Phase 5.8 Gallery Overlay Activation Parity after code comparison showed the direct photo-card activation path was not aligned.
  - Electron currently wires `PhotoCard.onDoubleClick` to detail mode.
  - Flutter currently wires browse photo cards only to selection and opens gallery only from detail/capture paths.
  - Next: add failing Electron and Flutter tests for double-click/double-tap gallery activation before implementation.
  ```

- [x] **Step 4: Verify documentation formatting**

  Run:

  ```bash
  git diff --check
  ```

  Expected: no output.

## Task 2: Electron Gallery Activation Contract

**Files:**
- Modify: `packages/ui-components/src/photo-card.tsx`
- Modify: `packages/ui-components/src/gallery-section.tsx`
- Modify: `packages/ui-components/src/photo-grid.tsx`
- Modify: `packages/ui-components/src/memory-detail-page.tsx`
- Modify: `packages/ui-components/src/photo-home.tsx`
- Modify: `apps/desktop/renderer/src/App.tsx`
- Test: `tests/e2e/accessibility.spec.ts`

- [x] **Step 1: Write the failing Electron E2E test**

  Extend `tests/e2e/accessibility.spec.ts` after the existing Enter-to-detail assertion:

  ```ts
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog", { name: /detail/i })).not.toBeVisible();

  await photoCard.dblclick();
  await expect(page.getByRole("dialog", { name: /gallery/i })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText(/gallery view/i)).toBeVisible();
  await expect(page.getByText(/keyboard-lake\.png/i)).toBeVisible();

  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog", { name: /gallery/i })).not.toBeVisible();

  await photoCard.focus();
  await page.keyboard.press("g");
  await expect(page.getByRole("dialog", { name: /gallery/i })).toBeVisible({ timeout: 10_000 });
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog", { name: /gallery/i })).not.toBeVisible();
  ```

- [x] **Step 2: Run the Electron test to verify it fails**

  Run:

  ```bash
  pnpm run e2e:prepare
  pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts
  ```

  Expected before implementation: failure because double-click opens detail or no gallery dialog.

- [x] **Step 3: Add explicit gallery activation to `PhotoCard`**

  Update `packages/ui-components/src/photo-card.tsx`:

  ```ts
  export interface PhotoCardProps {
    record: PhotoRecord;
    selected: boolean;
    onSelect: () => void;
    onOpenDetail: () => void;
    onOpenGallery: () => void;
    // existing optional props stay unchanged
  }
  ```

  And update the root element handlers:

  ```tsx
  onClick={onSelect}
  onDoubleClick={onOpenGallery}
  onKeyDown={(event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      onOpenDetail();
      return;
    }

    if (event.key.toLowerCase() === "g") {
      event.preventDefault();
      onOpenGallery();
      return;
    }

    if (event.key === " ") {
      event.preventDefault();
      onSelect();
    }
  }}
  ```

- [x] **Step 4: Thread `onOpenGallery` through gallery surfaces**

  In `packages/ui-components/src/gallery-section.tsx`, add `onOpenGallery?: (photoId: string) => void` to props and pass:

  ```tsx
  onOpenGallery={() => {
    if (!isSelecting) {
      onOpenGallery?.(record.photo.id);
    }
  }}
  ```

  In `packages/ui-components/src/photo-grid.tsx`, add required `onOpenGallery: (photoId: string) => void` and pass:

  ```tsx
  onOpenGallery={() => props.onOpenGallery(record.photo.id)}
  ```

  In `packages/ui-components/src/memory-detail-page.tsx`, pass the same memory-local photo list into the existing viewer by calling the new prop:

  ```tsx
  onOpenGallery={() => {
    if (!isSelecting) {
      onOpenGallery(record.photo.id);
    }
  }}
  ```

- [x] **Step 5: Wire app-level gallery mode**

  In `packages/ui-components/src/photo-home.tsx`, add:

  ```ts
  onOpenGallery: (photoId: string) => void;
  ```

  Pass it to every `GallerySection`, `PhotoGrid`, and memory detail card surface that already receives `onOpenDetail`.

  In `apps/desktop/renderer/src/App.tsx`, wire:

  ```tsx
  onOpenGallery={(photoId) => app.openViewer("gallery", photoId)}
  ```

- [x] **Step 6: Verify Electron behavior**

  Run:

  ```bash
  pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts
  pnpm run e2e:runtime
  pnpm typecheck
  pnpm build
  ```

  Expected: all pass; double-click and `G` both open gallery, Enter still opens detail.

  Evidence:
  - Initial run failed because `photoCard.dblclick()` did not expose a gallery dialog.
  - After implementation,
    `pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts`,
    `pnpm run e2e:runtime`,
    `pnpm typecheck`,
    and `pnpm build` pass.

## Task 3: Flutter Gallery Activation Contract

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`

- [x] **Step 1: Write the failing Flutter parity test**

  In `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`, replace the detail-button-only gallery activation setup with a direct double-tap check:

  ```dart
  final first = records.first;
  final second = records[1];
  final firstCard = find.byKey(Key('photo-card-${first.photo.id}'));
  await tester.ensureVisible(firstCard);

  await tester.tap(firstCard);
  await tester.pump();
  expect(find.byKey(const Key('gallery-dialog')), findsNothing);

  await tester.tap(firstCard);
  await tester.pump(const Duration(milliseconds: 80));
  await tester.tap(firstCard);
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);
  expect(find.byKey(Key('gallery-title-${first.photo.id}')), findsOneWidget);
  expect(find.byKey(Key('gallery-filmstrip-${second.photo.id}')), findsOneWidget);
  ```

  Keep the existing next/previous/`D`/`Escape` assertions after this block.

- [x] **Step 2: Run the Flutter test to verify it fails**

  Run:

  ```bash
  cd chronopic_flutter
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  ```

  Expected before implementation: failure because `PhotoCardTile` has no double-tap gallery activation.

- [x] **Step 3: Add gallery callback through browse widgets**

  In `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`, update constructors:

  ```dart
  final class BrowseSurface extends StatelessWidget {
    const BrowseSurface({
      required this.mode,
      required this.onOpenGallery,
      required this.onSelectPhoto,
      required this.photos,
      required this.selected,
    });

    final ValueChanged<PhotoRecord> onOpenGallery;
    final ValueChanged<PhotoRecord> onSelectPhoto;
  }
  ```

  Pass the callback into `PhotoGrid`:

  ```dart
  BrowseMode.waterfall => PhotoGrid(
    onOpenGallery: onOpenGallery,
    onSelectPhoto: onSelectPhoto,
    photos: photos,
    selected: selected,
  ),
  ```

  Update `PhotoGrid` and `PhotoCardTile`:

  ```dart
  final ValueChanged<PhotoRecord> onOpenGallery;
  ```

  ```dart
  return PhotoCardTile(
    onOpenGallery: () => onOpenGallery(record),
    onSelect: () => onSelectPhoto(record),
    record: record,
    selected: selected?.photo.id == record.photo.id,
  );
  ```

- [x] **Step 4: Use immediate custom double-tap detection on Flutter cards**

  In `PhotoCardTile`, add the callback:

  ```dart
  final VoidCallback onOpenGallery;
  ```

  Use a stateful custom detector instead of `InkWell.onDoubleTap`,
  because Flutter's built-in double-tap recognizer delays ordinary single-tap
  selection. The final `InkWell` should keep single tap immediate:

  ```dart
  DateTime? _lastTapAt;

  void _handleTap() {
    final now = DateTime.now();
    final isDoubleTap =
        _lastTapAt != null &&
        now.difference(_lastTapAt!) <= const Duration(milliseconds: 320);
    _lastTapAt = isDoubleTap ? null : now;
    widget.onSelect();
    if (isDoubleTap) widget.onOpenGallery();
  }
  ```

- [x] **Step 5: Add selected-photo gallery open helper**

  In `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`, add:

  ```dart
  Future<void> _openGalleryFor(
    BuildContext dialogContext,
    PhotoRecord record,
  ) async {
    _selectPhoto(record);
    final result = await showDialog<PhotoRecord>(
      context: dialogContext,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => GalleryDialog(
        initialPhotoId: record.photo.id,
        photos: _visiblePhotos(),
      ),
    );
    if (result != null) _selectPhoto(result);
  }

  Future<void> _openGallery(BuildContext dialogContext) async {
    final selected = _selected;
    if (selected == null) return;
    await _openGalleryFor(dialogContext, selected);
  }
  ```

  Wire `BrowseSurface` from `home_page.dart`:

  ```dart
  onOpenGallery: (record) => onOpenGalleryFor(context, record),
  ```

  If the current `HomePage` callback shape only exposes `ValueChanged<BuildContext> onOpenGallery`, extend it with:

  ```dart
  final void Function(BuildContext context, PhotoRecord record) onOpenGalleryFor;
  ```

- [x] **Step 6: Add Flutter `G` shortcut if missing**

  In the existing app-level key handler in `chronopic_home.dart`, ensure:

  ```dart
  if (event.logicalKey == LogicalKeyboardKey.keyG && _selected != null) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null) {
      _openGallery(navigatorContext);
      return KeyEventResult.handled;
    }
  }
  ```

- [x] **Step 7: Verify Flutter behavior**

  Run:

  ```bash
  cd chronopic_flutter
  dart analyze packages/chronopic_ui apps/chronopic
  flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart
  bash tool/capture_flutter_parity.sh populated-grid gallery favorites restart-persistence
  file ../test-results/flutter-electron-parity/flutter/02-populated-grid.png ../test-results/flutter-electron-parity/flutter/06-gallery.png ../test-results/flutter-electron-parity/flutter/07-favorites.png ../test-results/flutter-electron-parity/flutter/13-restart-persistence.png
  ```

  Expected: tests pass and all four refreshed Flutter screenshots are 1440x920.

  Evidence:
  - Initial run failed because double-tapping the card did not produce
    `gallery-dialog`.
  - After implementation,
    `dart analyze packages/chronopic_ui apps/chronopic`,
    `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
    and
    `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
    pass.

## Task 4: Two-Side Parity Closure

**Files:**
- Modify: `docs/flutter-electron-ui-functional-parity.md`
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Rerun focused Electron capture**

  Run:

  ```bash
  node scripts/capture-electron-parity.mjs
  file test-results/flutter-electron-parity/electron/02-populated-grid.png test-results/flutter-electron-parity/electron/06-gallery.png test-results/flutter-electron-parity/electron/07-favorites.png test-results/flutter-electron-parity/electron/13-restart-persistence.png
  ```

  Expected: capture succeeds and the focused Electron PNGs are 1440x920.

- [x] **Step 2: Rerun focused Flutter capture**

  Run:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh populated-grid gallery favorites restart-persistence
  file ../test-results/flutter-electron-parity/flutter/02-populated-grid.png ../test-results/flutter-electron-parity/flutter/06-gallery.png ../test-results/flutter-electron-parity/flutter/07-favorites.png ../test-results/flutter-electron-parity/flutter/13-restart-persistence.png
  ```

  Expected: capture succeeds and the focused Flutter PNGs are 1440x920.

- [x] **Step 3: Compare refreshed screenshots**

  Compare these pairs before closing the matrix:

  ```text
  test-results/flutter-electron-parity/electron/02-populated-grid.png
  test-results/flutter-electron-parity/flutter/02-populated-grid.png

  test-results/flutter-electron-parity/electron/06-gallery.png
  test-results/flutter-electron-parity/flutter/06-gallery.png

  test-results/flutter-electron-parity/electron/07-favorites.png
  test-results/flutter-electron-parity/flutter/07-favorites.png

  test-results/flutter-electron-parity/electron/13-restart-persistence.png
  test-results/flutter-electron-parity/flutter/13-restart-persistence.png
  ```

  Required inspection:
  - populated and favorites cards still show Electron-aligned card hierarchy after the activation change;
  - gallery overlay still fills the window and does not fall back to an inline/detail view;
  - filmstrip, navigation, metadata, and `Detail View`/inspector affordance remain visible;
  - restart-persistence still restores the same selected-photo/gallery activation context.

  Optional local helper if visual diff tooling is useful:

  ```bash
  montage test-results/flutter-electron-parity/electron/06-gallery.png test-results/flutter-electron-parity/flutter/06-gallery.png -tile 2x1 -geometry +24+0 test-results/flutter-electron-parity/gallery-overlay-compare.png
  ```

  Expected: the agent records any new visual deltas in `docs/flutter-electron-ui-functional-parity.md` before deciding whether they are fixed or accepted.

  Evidence:
  - Created side-by-side comparison artifacts under
    `test-results/flutter-electron-parity/compare/`.
  - Inspected `06-gallery-compare.png` and `02-populated-grid-compare.png`.
  - Gallery comparison confirms both sides show fullscreen overlay hierarchy,
    navigation,
    metadata,
    inspector/detail action,
    and filmstrip.
  - Browse comparison confirms card hierarchy and selected-photo banner remain
    aligned after the activation change.

- [x] **Step 4: Close matrix rows**

  Update the reopened rows to `Matched` or `Accepted Difference` only after the tests above pass.

  Use this closure text if behavior is fully aligned and only renderer pixels differ:

  ```markdown
  Direct photo-card activation is aligned: single click selects, double-click/double-tap opens fullscreen gallery overlay, Enter opens detail, `G` opens gallery for the selected photo, and `Escape` closes the overlay while preserving selection. Accepted difference: exact overlay button and filmstrip rendering differs between Electron CSS/Radix and Flutter Material.
  ```

- [x] **Step 5: Run final focused gate**

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

  Expected: all pass.

  Evidence:
  - `pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts` passes.
  - `pnpm run e2e:runtime` passes.
  - `pnpm typecheck` passes.
  - `pnpm build` passes.
  - `dart analyze packages/chronopic_ui apps/chronopic` passes.
  - `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart` passes.

- [x] **Step 6: Commit and push**

  Run:

  ```bash
  git add PLAN.md AGENTS.md docs/flutter-refactor-phases.md docs/flutter-electron-ui-functional-parity.md docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md packages/ui-components/src/photo-card.tsx packages/ui-components/src/gallery-section.tsx packages/ui-components/src/photo-grid.tsx packages/ui-components/src/memory-detail-page.tsx packages/ui-components/src/photo-home.tsx apps/desktop/renderer/src/App.tsx tests/e2e/accessibility.spec.ts chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart
  git commit -m "Align gallery overlay activation"
  git push
  ```

  Expected: branch `flutter-refactor-phases` is pushed and worktree is clean.

  Progress:
  - Implementation commit `7efb12e` records the Electron and Flutter gallery
    activation changes.
  - Matrix rows now reference `7efb12e` for the four reopened surfaces.
  - Follow-up evidence and handoff commits record the phase closure.
  - `git push` updated `github.com:denghongcai/ChronoPic.git`
    branch `flutter-refactor-phases`.

## Self-Review

- Spec coverage: the plan covers code comparison, Electron double-click behavior, Flutter double-tap behavior, fullscreen overlay verification, keyboard parity, focused screenshots, docs, commit, and push.
- Placeholder scan: no task uses TBD/TODO or asks for unspecified tests; every test command and intended code path is named.
- Type consistency: `onOpenGallery(photoId)` is the Electron prop shape; Flutter uses `ValueChanged<PhotoRecord>` internally and a `BuildContext` wrapper where `showDialog` needs a context.
