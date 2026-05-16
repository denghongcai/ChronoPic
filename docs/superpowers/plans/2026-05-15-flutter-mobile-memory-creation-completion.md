# Flutter Mobile Memory Creation Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Android mobile create-memory workflow so a phone user can select photos, edit title/description/cover, confirm, and land on the editable memory detail page.

**Architecture:** Keep the existing local-first memory data model and `ChronoPicAppService` APIs. Add mobile-only draft state and a focused creation sheet in the Flutter UI layer, then commit accepted drafts through existing `createMemory`, `addPhotoToMemory`, and `setMemoryCover` service calls. Desktop memory creation remains unchanged.

**Tech Stack:** Flutter Material, Dart, `chronopic_ui` part files, `chronopic_app` memory service APIs, Flutter widget tests, Android app-owned integration test.

---

## File Structure

- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
  - Add the mobile-memory-creation part file.
  - Own draft state for selected photo IDs, title, description, cover photo, and sheet lifecycle.
  - Commit the draft through existing service APIs and route to memory detail.
- Create: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/mobile_memory_creation.dart`
  - Render the mobile creation flow as a safe-area-aware bottom sheet or full-height sheet.
  - Own the step UI for photo selection, details/cover editing, and final confirmation.
  - Keep UI-only validation and action enablement here.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
  - Remove the current private prompt-only `_showMobileMemoryWizard`.
  - Delegate mobile create-memory actions to the new app-owned flow.
  - Keep desktop create-memory text-field behavior unchanged.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
  - Expose a mobile entry point from the home surface when photos exist and no memory exists.
  - Keep first-run/import flows unchanged.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  - Add mobile-selectable photo tile affordances used by the creation sheet.
  - Preserve Phase 12/13 tap semantics: scroll gestures do not open detail, mobile normal tap still opens detail outside selection.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/l10n/ui_strings.dart`
  - Add English and Simplified Chinese strings for the new mobile flow.
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
  - Replace the old wizard-presence test with behavior tests for selection, details, cover, confirmation, and navigation.
- Modify: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
  - Extend app-owned mobile coverage to assert the new memory creation flow exists after import.
- Modify: `docs/mobile-productization.md`
  - Record the Phase 14 mobile memory creation contract and verification result.
- Modify: `docs/mobile-e2e-verification.md`
  - Add Phase 14 expected mobile E2E evidence.
- Modify: `PLAN.md`, `docs/flutter-refactor-phases.md`, `AGENTS.md`
  - Track Phase 14 plan, status, non-goals, and verification.

## Task 1: Add Failing Mobile Memory Creation Tests

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [ ] **Step 1: Replace the prompt-only wizard test with a creation-flow test**

Add a test that proves the desired behavior before implementation:

```dart
testWidgets('mobile memory creation selects photos and opens created detail', (
  tester,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ChronoPicHome(
      service: ChronoPicAppService(ChronoPicRepository()),
      entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
      mobileMediaSourceFactory: () => _mobileSource(count: 3),
    ),
  );

  await tester.tap(find.byKey(const Key('mobile-choose-photos')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('mobile-scan-library')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('mobile-shortcut-memories')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('mobile-create-memory')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('mobile-memory-creation-sheet')), findsOneWidget);
  expect(find.byKey(const Key('mobile-memory-step-select')), findsOneWidget);

  await tester.tap(find.byKey(const Key('mobile-memory-select-asset-1')));
  await tester.tap(find.byKey(const Key('mobile-memory-select-asset-2')));
  await tester.pumpAndSettle();
  expect(find.text('2 selected'), findsOneWidget);

  await tester.tap(find.byKey(const Key('mobile-memory-next')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('mobile-memory-title-field')),
    'Weekend Walk',
  );
  await tester.enterText(
    find.byKey(const Key('mobile-memory-description-field')),
    'Two favorite moments from the phone library.',
  );
  await tester.tap(find.byKey(const Key('mobile-memory-cover-asset-2')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('mobile-memory-next')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('mobile-memory-step-confirm')), findsOneWidget);
  expect(find.text('Weekend Walk'), findsWidgets);
  expect(find.text('2 photos'), findsOneWidget);

  await tester.tap(find.byKey(const Key('mobile-memory-create-confirm')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('memory-detail-page')), findsOneWidget);
  expect(find.text('Weekend Walk'), findsWidgets);
  expect(find.textContaining('2'), findsWidgets);
});
```

- [ ] **Step 2: Add a validation test for empty selection**

Add this test in the same file:

```dart
testWidgets('mobile memory creation requires selected photos before details', (
  tester,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ChronoPicHome(
      service: ChronoPicAppService(ChronoPicRepository()),
      entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
      mobileMediaSourceFactory: () => _mobileSource(count: 2),
    ),
  );

  await tester.tap(find.byKey(const Key('mobile-choose-photos')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('mobile-scan-library')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('mobile-shortcut-memories')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('mobile-create-memory')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('mobile-memory-next')), findsOneWidget);
  expect(
    tester.widget<FilledButton>(find.byKey(const Key('mobile-memory-next'))).onPressed,
    isNull,
  );
  expect(find.text('Select at least one photo'), findsOneWidget);
});
```

- [ ] **Step 3: Run the focused test and confirm it fails**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: FAIL because `mobile-memory-creation-sheet`, selectable memory tiles, title/description fields, cover selection, and confirm behavior are not implemented.

## Task 2: Add Mobile Memory Draft State And Commit Path

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`

- [ ] **Step 1: Add mobile creation state**

Add state fields near the existing `_selectedMemoryId` and `_status` fields:

```dart
final Set<String> _mobileMemoryDraftPhotoIds = <String>{};
final TextEditingController _mobileMemoryTitleController =
    TextEditingController();
final TextEditingController _mobileMemoryDescriptionController =
    TextEditingController();
String? _mobileMemoryCoverPhotoId;
```

Dispose the new controllers in `dispose()`:

```dart
_mobileMemoryTitleController.dispose();
_mobileMemoryDescriptionController.dispose();
```

- [ ] **Step 2: Add the part file declaration**

Add this part declaration below the existing memory part:

```dart
part 'memories/mobile_memory_creation.dart';
```

- [ ] **Step 3: Add draft helper methods**

Add these methods near `_createMemory()`:

```dart
void _resetMobileMemoryDraft() {
  _mobileMemoryDraftPhotoIds.clear();
  _mobileMemoryTitleController.text = _localized(
    _l10n,
    'New Memory',
    '新记忆',
  );
  _mobileMemoryDescriptionController.clear();
  _mobileMemoryCoverPhotoId = null;
}

void _toggleMobileMemoryDraftPhoto(String photoId) {
  setState(() {
    if (_mobileMemoryDraftPhotoIds.contains(photoId)) {
      _mobileMemoryDraftPhotoIds.remove(photoId);
      if (_mobileMemoryCoverPhotoId == photoId) {
        _mobileMemoryCoverPhotoId = _mobileMemoryDraftPhotoIds.isEmpty
            ? null
            : _mobileMemoryDraftPhotoIds.first;
      }
      return;
    }
    _mobileMemoryDraftPhotoIds.add(photoId);
    _mobileMemoryCoverPhotoId ??= photoId;
  });
}

void _setMobileMemoryDraftCover(String photoId) {
  if (!_mobileMemoryDraftPhotoIds.contains(photoId)) return;
  setState(() => _mobileMemoryCoverPhotoId = photoId);
}
```

- [ ] **Step 4: Add the commit method**

Add:

```dart
void _commitMobileMemoryDraft(BuildContext context) {
  final selectedIds = _mobileMemoryDraftPhotoIds.toList(growable: false);
  if (selectedIds.isEmpty) {
    setState(
      () => _status = _localized(
        _l10n,
        'Select at least one photo',
        '请至少选择一张照片',
      ),
    );
    return;
  }

  final title = _mobileMemoryTitleController.text.trim().isEmpty
      ? _localized(_l10n, 'New Memory', '新记忆')
      : _mobileMemoryTitleController.text.trim();
  final description = _mobileMemoryDescriptionController.text.trim();
  final memory = _service.createMemory(
    title,
    description: description.isEmpty ? null : description,
  );
  for (final photoId in selectedIds) {
    _service.addPhotoToMemory(memory.id, photoId);
  }
  final coverPhotoId = _mobileMemoryCoverPhotoId ?? selectedIds.first;
  _service.setMemoryCover(memory.id, coverPhotoId);

  setState(() {
    _selectedMemoryId = memory.id;
    _memoryTitleController.text = title;
    _memoryDescriptionController.text = description;
    _page = _DesktopPage.memoryDetail;
    _selected = _service.listPhotos(
      PhotoFilter(memoryId: memory.id),
      limit: 1,
    ).firstOrNull;
    _status = _labelValue(_localized(_l10n, 'Created memory', '已创建记忆'), title);
    _mobileMemoryDraftPhotoIds.clear();
    _mobileMemoryCoverPhotoId = null;
  });
  Navigator.of(context).pop();
}
```

If `firstOrNull` is unavailable in the current Dart SDK, use:

```dart
final memoryPhotos = _service.listPhotos(PhotoFilter(memoryId: memory.id), limit: 1);
_selected = memoryPhotos.isEmpty ? null : memoryPhotos.first;
```

- [ ] **Step 5: Run analyzer and confirm the new helpers compile or expose missing UI symbols**

Run:

```bash
cd chronopic_flutter && dart analyze packages/chronopic_ui
```

Expected: FAIL until Task 3 creates `MobileMemoryCreationSheet` and wires the callbacks.

## Task 3: Build The Mobile Creation Sheet

**Files:**
- Create: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/mobile_memory_creation.dart`

- [ ] **Step 1: Create `MobileMemoryCreationSheet`**

Create the file with:

```dart
part of '../chronopic_home.dart';

final class MobileMemoryCreationSheet extends StatefulWidget {
  const MobileMemoryCreationSheet({
    required this.coverPhotoId,
    required this.descriptionController,
    required this.labels,
    required this.onCommit,
    required this.onLoadMorePhotos,
    required this.onSetCover,
    required this.onTogglePhoto,
    required this.photos,
    required this.selectedPhotoIds,
    required this.titleController,
    required this.hasMorePhotos,
    super.key,
  });

  final String? coverPhotoId;
  final TextEditingController descriptionController;
  final bool hasMorePhotos;
  final UiStrings labels;
  final VoidCallback onCommit;
  final VoidCallback onLoadMorePhotos;
  final ValueChanged<String> onSetCover;
  final ValueChanged<String> onTogglePhoto;
  final List<PhotoRecord> photos;
  final Set<String> selectedPhotoIds;
  final TextEditingController titleController;

  @override
  State<MobileMemoryCreationSheet> createState() =>
      _MobileMemoryCreationSheetState();
}
```

- [ ] **Step 2: Add step state and scaffold**

Add:

```dart
final class _MobileMemoryCreationSheetState
    extends State<MobileMemoryCreationSheet> {
  int _step = 0;

  bool get _hasSelection => widget.selectedPhotoIds.isNotEmpty;
  bool get _isLastStep => _step == 2;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        key: const Key('mobile-memory-creation-sheet'),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileMemorySheetHeader(step: _step, labels: widget.labels),
            const SizedBox(height: 12),
            Flexible(child: _buildStep(context)),
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 3: Add step rendering**

Add:

```dart
  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => _MobileMemoryPhotoPicker(
        labels: widget.labels,
        photos: widget.photos,
        selectedPhotoIds: widget.selectedPhotoIds,
        onTogglePhoto: widget.onTogglePhoto,
        hasMorePhotos: widget.hasMorePhotos,
        onLoadMorePhotos: widget.onLoadMorePhotos,
      ),
      1 => _MobileMemoryDetailsStep(
        coverPhotoId: widget.coverPhotoId,
        descriptionController: widget.descriptionController,
        labels: widget.labels,
        onSetCover: widget.onSetCover,
        photos: widget.photos,
        selectedPhotoIds: widget.selectedPhotoIds,
        titleController: widget.titleController,
      ),
      _ => _MobileMemoryConfirmStep(
        coverPhotoId: widget.coverPhotoId,
        description: widget.descriptionController.text.trim(),
        labels: widget.labels,
        photos: widget.photos,
        selectedPhotoIds: widget.selectedPhotoIds,
        title: widget.titleController.text.trim(),
      ),
    };
  }
```

- [ ] **Step 4: Add navigation actions**

Add:

```dart
  Widget _buildActions(BuildContext context) {
    final nextEnabled = _step != 0 || _hasSelection;
    return Row(
      children: [
        TextButton(
          onPressed: () {
            if (_step == 0) {
              Navigator.of(context).pop();
              return;
            }
            setState(() => _step -= 1);
          },
          child: Text(_localized(widget.labels, _step == 0 ? 'Cancel' : 'Back', _step == 0 ? '取消' : '上一步')),
        ),
        const Spacer(),
        FilledButton(
          key: Key(_isLastStep ? 'mobile-memory-create-confirm' : 'mobile-memory-next'),
          onPressed: nextEnabled
              ? () {
                  if (_isLastStep) {
                    widget.onCommit();
                    return;
                  }
                  setState(() => _step += 1);
                }
              : null,
          child: Text(
            _isLastStep
                ? widget.labels.createMemory
                : _localized(widget.labels, 'Next', '下一步'),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Add the header and photo picker widgets**

Implement `_MobileMemorySheetHeader` and `_MobileMemoryPhotoPicker` in the same file. The picker must use stable keys:

```dart
Key('mobile-memory-select-${record.photo.id}')
```

It must show:

```dart
Text(_localized(labels, '$selectedCount selected', '已选择 $selectedCount 张'))
```

when selection is non-empty, and:

```dart
Text(_localized(labels, 'Select at least one photo', '请至少选择一张照片'))
```

when empty.

- [ ] **Step 6: Add details and confirmation widgets**

Implement `_MobileMemoryDetailsStep` with:

```dart
TextField(
  key: const Key('mobile-memory-title-field'),
  controller: titleController,
  decoration: InputDecoration(labelText: labels.memoryName),
)
```

and:

```dart
TextField(
  key: const Key('mobile-memory-description-field'),
  controller: descriptionController,
  minLines: 2,
  maxLines: 4,
  decoration: InputDecoration(
    labelText: _localized(labels, 'Description', '描述'),
  ),
)
```

Cover choices must use stable keys:

```dart
Key('mobile-memory-cover-${record.photo.id}')
```

Implement `_MobileMemoryConfirmStep` with `mobile-memory-step-confirm`, visible title, photo count, description preview, and selected cover marker.

- [ ] **Step 7: Run the focused UI test**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: still FAIL until Task 4 wires sheet entry points and commit callbacks.

## Task 4: Wire Mobile Entry Points Without Changing Desktop Behavior

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`

- [ ] **Step 1: Add `_openMobileMemoryCreationFlow`**

Add this method in `_ChronoPicHomeState`:

```dart
Future<void> _openMobileMemoryCreationFlow(BuildContext context) async {
  _resetMobileMemoryDraft();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          void refreshSheet(VoidCallback mutation) {
            setState(mutation);
            setSheetState(() {});
          }

          return MobileMemoryCreationSheet(
            coverPhotoId: _mobileMemoryCoverPhotoId,
            descriptionController: _mobileMemoryDescriptionController,
            hasMorePhotos: _hasMoreVisiblePhotos,
            labels: _l10n,
            onCommit: () => _commitMobileMemoryDraft(sheetContext),
            onLoadMorePhotos: () {
              refreshSheet(() => _photoResultLimit += _photoPageSize);
            },
            onSetCover: (photoId) {
              refreshSheet(() => _mobileMemoryCoverPhotoId = photoId);
            },
            onTogglePhoto: (photoId) {
              refreshSheet(() {
                if (_mobileMemoryDraftPhotoIds.contains(photoId)) {
                  _mobileMemoryDraftPhotoIds.remove(photoId);
                  if (_mobileMemoryCoverPhotoId == photoId) {
                    _mobileMemoryCoverPhotoId =
                        _mobileMemoryDraftPhotoIds.isEmpty
                            ? null
                            : _mobileMemoryDraftPhotoIds.first;
                  }
                } else {
                  _mobileMemoryDraftPhotoIds.add(photoId);
                  _mobileMemoryCoverPhotoId ??= photoId;
                }
              });
            },
            photos: _visiblePhotoPage().photos,
            selectedPhotoIds: _mobileMemoryDraftPhotoIds,
            titleController: _mobileMemoryTitleController,
          );
        },
      );
    },
  );
}
```

- [ ] **Step 2: Pass a context-aware callback into `MemoryListPage`**

Change `MemoryListPage` so mobile layout receives:

```dart
required this.onCreateMobileMemory,
```

with:

```dart
final ValueChanged<BuildContext> onCreateMobileMemory;
```

In the mobile create button, replace `_showMobileMemoryWizard(context)` with:

```dart
onCreateMobileMemory(context)
```

Keep desktop behavior:

```dart
onPressed: mobileLayout ? () => onCreateMobileMemory(context) : onCreateMemory,
```

- [ ] **Step 3: Wire the callback from `ChronoPicHome`**

In the `MemoryListPage` construction, add:

```dart
onCreateMobileMemory: _openMobileMemoryCreationFlow,
```

- [ ] **Step 4: Add a home-surface entry point for zero-memory mobile users**

In `HomePage`, add an optional mobile CTA near the existing memories/shortcut area:

```dart
if (mobileLayout && photos.isNotEmpty && memories.isEmpty)
  FilledButton.icon(
    key: const Key('mobile-create-first-memory'),
    onPressed: () => onCreateFirstMemory(),
    icon: const Icon(Icons.auto_stories_outlined),
    label: Text(labels.createMemory),
  ),
```

Wire `onCreateFirstMemory` in `ChronoPicHome` to call the mobile flow when in mobile layout and fall back to `_createMemory` for desktop:

```dart
onCreateFirstMemory: () {
  final context = _navigatorKey.currentContext;
  if (_entryMode == ChronoPicEntryMode.mobilePhotoLibrary && context != null) {
    _openMobileMemoryCreationFlow(context);
    return;
  }
  _createMemory();
},
```

- [ ] **Step 5: Run focused tests**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: PASS for the new mobile creation tests and existing Phase 11-13 mobile tests.

## Task 5: Preserve Browse And Detail Semantics

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [ ] **Step 1: Add selectable tile treatment used inside the creation sheet**

Add a small reusable tile wrapper or helper in `browse_surface.dart`:

```dart
Widget _mobileSelectablePhotoOverlay({
  required bool selected,
  required Widget child,
}) {
  return Stack(
    children: [
      child,
      Positioned(
        top: 8,
        right: 8,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: selected ? Colors.orange : Colors.white,
          child: Icon(
            selected ? Icons.check : Icons.add,
            size: 16,
            color: selected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    ],
  );
}
```

Use this helper only from the creation sheet photo picker. Do not alter normal `PhotoCardTile.onTap` behavior.

- [ ] **Step 2: Keep detail Add To Memory behavior compatible**

Verify `DetailSurface.onAddToMemory` still adds the selected photo to the currently selected memory. If no memory is selected, update the callback in `chronopic_home.dart` so mobile users are prompted to create a memory through `_openMobileMemoryCreationFlow(context)` seeded with the selected photo.

Use:

```dart
if (_selectedMemoryId == null && _entryMode == ChronoPicEntryMode.mobilePhotoLibrary) {
  final selected = _selected;
  if (selected != null) {
    _resetMobileMemoryDraft();
    _mobileMemoryDraftPhotoIds.add(selected.photo.id);
    _mobileMemoryCoverPhotoId = selected.photo.id;
    _openMobileMemoryCreationFlow(_navigatorKey.currentContext!);
  }
  return;
}
```

- [ ] **Step 3: Add a regression test for scroll gestures**

Keep the existing Phase 12/13 drag test and add a memory-selection assertion:

```dart
await tester.drag(
  find.byKey(const Key('mobile-memory-select-asset-1')),
  const Offset(0, -160),
);
await tester.pumpAndSettle();
expect(find.byKey(const Key('focused-detail-page')), findsNothing);
expect(find.byKey(const Key('mobile-memory-creation-sheet')), findsOneWidget);
```

- [ ] **Step 4: Run focused mobile tests**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: PASS.

## Task 6: Extend App-Owned Android Integration Evidence

**Files:**
- Modify: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
- Modify: `docs/mobile-e2e-verification.md`

- [ ] **Step 1: Add app-owned assertions**

In the integration test, after import and browse assertions, add:

```dart
await tester.tap(find.byKey(const Key('mobile-shortcut-memories')));
await tester.pumpAndSettle();
expect(find.byKey(const Key('mobile-create-memory')), findsOneWidget);

await tester.tap(find.byKey(const Key('mobile-create-memory')));
await tester.pumpAndSettle();
expect(find.byKey(const Key('mobile-memory-creation-sheet')), findsOneWidget);
expect(find.byKey(const Key('mobile-memory-step-select')), findsOneWidget);
```

Keep this integration test lightweight; the widget test owns full title/description/cover behavior.

- [ ] **Step 2: Run the app-owned integration test**

Run:

```bash
cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart
```

Expected: PASS with the known Flutter `integration_test` plugin warning.

- [ ] **Step 3: Update `docs/mobile-e2e-verification.md`**

Add a Phase 14 section with:

```markdown
2026-05-15 Phase 14 mobile memory creation completion planned gate:

- App-owned mobile integration verifies the Memories shortcut exposes the
  creation flow after import.
- Widget coverage verifies photo selection, title/description editing, cover
  choice, confirmation, and memory detail navigation.
- Android debug build remains the platform compile gate.
```

## Task 7: Documentation Closeout

**Files:**
- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/mobile-productization.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Mark Phase 14 implementation result**

After code lands, update Phase 14 in `PLAN.md` and `docs/flutter-refactor-phases.md` from `planned` to `complete`, including the exact verification commands that passed.

- [ ] **Step 2: Update mobile product contract**

In `docs/mobile-productization.md`, record that mobile memory creation now:

```markdown
- Starts from Memories, home first-memory CTA, or selected photo Detail.
- Requires at least one selected photo before moving to details.
- Captures title, optional description, selected cover, and selected photo IDs.
- Creates a normal editable Memory through existing repository semantics.
- Opens the created memory detail page after confirmation.
```

- [ ] **Step 3: Update `AGENTS.md`**

Append a new step with changed files, behavior, verification scenes, and skipped iOS evidence.

- [ ] **Step 4: Run docs whitespace check**

Run:

```bash
git diff --check
```

Expected: no output.

## Task 8: Final Verification

**Files:**
- Test-only commands.

- [ ] **Step 1: Run Flutter analyzer**

Run:

```bash
cd chronopic_flutter && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run focused and full Flutter UI tests**

Run:

```bash
cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart
cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test
```

Expected: all tests pass.

- [ ] **Step 3: Run app-owned mobile integration**

Run:

```bash
cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart
```

Expected: all tests pass; the known `integration_test` plugin warning is acceptable only if the process exits 0.

- [ ] **Step 4: Build Android debug APK**

Run:

```bash
cd chronopic_flutter/apps/chronopic && flutter build apk --debug
```

Expected: debug APK is built under `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 5: Run repository whitespace check**

Run:

```bash
git diff --check
```

Expected: no output.

## Non-Goals

- No repository/domain schema changes.
- No Android import pipeline changes.
- No lazy-thumbnail pipeline changes.
- No desktop UI redesign.
- No Play Store submission work.
- No OCR, vector search, person recognition, cloud sync, AI thumbnail analysis, or EXIF writeback.
- No iOS live verification claim from this Linux workstation.

## Self-Review

- Spec coverage: the plan covers mobile entry points, photo selection, title/description, cover choice, commit semantics, memory-detail navigation, widget tests, app-owned integration, docs, and verification.
- Placeholder scan: the plan contains no unresolved placeholder markers or vague implementation placeholders.
- Type consistency: planned callbacks use existing `PhotoRecord`, `Memory`, `PhotoFilter`, `UiStrings`, and `ChronoPicAppService` concepts already present in the Flutter UI and app-service layers.

## Execution Result

Completed locally on 2026-05-15.

- Added the mobile memory creation sheet with photo selection,
  selected count,
  details/cover editing,
  confirmation,
  and commit/navigation through existing local-first memory service calls.
- Wired the Memories page Create Memory action,
  the home first-memory CTA,
  and the selected-photo Detail/Add-to-Memory fallback into the app-owned draft
  state.
- Updated focused mobile widget coverage and app-owned mobile integration
  coverage for the completed creation lifecycle and Phase 12/13 scroll/tap
  regression.
- Updated `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  `docs/mobile-e2e-verification.md`,
  and `AGENTS.md`.
- Verification passed:
  `cd chronopic_flutter && flutter analyze`;
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`;
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`;
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`;
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`;
  and `git diff --check`.
- iOS live verification remains blocked on this Linux workstation.
