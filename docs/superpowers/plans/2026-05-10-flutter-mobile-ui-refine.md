# Flutter Mobile UI Refine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the Flutter Android mobile UI into a production-quality touch experience while keeping the existing desktop contract intact.

**Architecture:** Mobile refinement is platform-specific and should not copy desktop density or overlay assumptions. The phase should first collect real Android evidence, then adjust mobile layout boundaries, touch targets, import/search/detail/gallery flows, and product identity in focused slices with Android E2E evidence after each high-risk change.

**Tech Stack:** Flutter Material, Android emulator, `adb`/`uiautomator`, Flutter widget tests, Flutter integration tests, `photo_manager`, existing Android deep E2E runner, `docs/mobile-e2e-verification.md`, `docs/mobile-productization.md`, release signing docs, and `AGENTS.md`.

**Status:** Completed locally on 2026-05-10. Closeout evidence is recorded in `docs/flutter-mobile-ui-refine-audit.md`, `docs/mobile-e2e-verification.md`, `docs/mobile-productization.md`, `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md`.

---

### Task 1: Create The Mobile UI Evidence Matrix

**Files:**
- Create: `docs/flutter-mobile-ui-refine-audit.md`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Create the audit document**

Create `docs/flutter-mobile-ui-refine-audit.md` with this structure:

```markdown
# Flutter Mobile UI Refine Audit

Date: 2026-05-10
Primary target: Android
iOS status: Blocked until macOS/Xcode live evidence exists
Production Android package id decision: ai.chronopic.app

## Evidence Matrix

| Flow | Evidence | Status | Notes |
| --- | --- | --- | --- |
| First run | Pending screenshot/XML | Pending | Entry choices must be readable and touch-sized |
| Permission denied | Pending screenshot/XML | Pending | Recovery path must be visible |
| Scoped import | Pending screenshot/XML | Pending | User chooses All Photos or album/scope |
| Scan progress | Pending screenshot/XML | Pending | Progress must not look frozen |
| Browse waterfall | Pending screenshot/XML | Pending | Initial 20 items, lazy load, mobile density |
| Search/filter/sort | Pending screenshot/XML | Pending | Controls must not wrap into clutter |
| Detail overlay | Pending screenshot/XML | Pending | Inspect/edit must fit small screens |
| Gallery overlay | Pending screenshot/XML | Pending | Media, controls, filmstrip, safe areas |
| Edit metadata | Pending integration evidence | Pending | Caption/tags/datetime/status feedback |
| Favorites | Pending integration evidence | Pending | Toggle and persistence |
| Memories | Pending screenshot/XML | Pending | Create/add/detail/remove flows |
| Settings/backup | Pending screenshot/XML | Pending | Paths and actions readable |
| Restart persistence | Pending screenshot/XML | Pending | State survives relaunch |
| Restore backup | Pending backup artifact | Pending | Metadata and memories restore |
```

- [x] **Step 2: Record iOS boundary explicitly**

Append to `docs/flutter-mobile-ui-refine-audit.md`:

```markdown
## iOS Boundary

iOS UI refine cannot be called live-verified from this Linux workstation.
Allowed here:

- static Dart/Flutter UI changes shared with mobile,
- iOS plist/bundle identifier preparation,
- documentation of required screenshots.

Blocked here:

- simulator screenshots,
- iOS permission prompts,
- iOS signing,
- App Store archive validation.
```

- [x] **Step 3: Link the matrix from mobile E2E docs**

In `docs/mobile-e2e-verification.md`, add a short pointer under the Android evidence section:

```markdown
Mobile UI refine evidence is tracked in
[flutter-mobile-ui-refine-audit.md](flutter-mobile-ui-refine-audit.md).
```

### Task 2: Apply Mobile Product Identity

**Files:**
- Modify: `chronopic_flutter/apps/chronopic/android/app/build.gradle.kts`
- Modify: `chronopic_flutter/apps/chronopic/android/app/src/main/kotlin/com/example/chronopic/MainActivity.kt`
- Move if needed: `chronopic_flutter/apps/chronopic/android/app/src/main/kotlin/com/example/chronopic/MainActivity.kt`
- Modify: `chronopic_flutter/apps/chronopic/ios/Runner.xcodeproj/project.pbxproj`
- Modify: `chronopic_flutter/apps/chronopic/linux/CMakeLists.txt`
- Modify: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Modify: `chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`
- Modify: `README.md`
- Modify: `docs/flutter-release-checklist.md`
- Modify: `docs/mobile-productization.md`

- [x] **Step 1: Update Android package identity**

Change Android release identity to:

```kotlin
namespace = "ai.chronopic.app"
applicationId = "ai.chronopic.app"
```

Move `MainActivity.kt` from:

```text
chronopic_flutter/apps/chronopic/android/app/src/main/kotlin/com/example/chronopic/MainActivity.kt
```

to:

```text
chronopic_flutter/apps/chronopic/android/app/src/main/kotlin/ai/chronopic/app/MainActivity.kt
```

Change its package declaration to:

```kotlin
package ai.chronopic.app
```

- [x] **Step 2: Update iOS bundle identifier metadata**

In `chronopic_flutter/apps/chronopic/ios/Runner.xcodeproj/project.pbxproj`, replace app target bundle identifiers:

```text
PRODUCT_BUNDLE_IDENTIFIER = ai.chronopic.app;
```

Keep test bundle identifiers under the app id:

```text
PRODUCT_BUNDLE_IDENTIFIER = ai.chronopic.app.RunnerTests;
```

Do not claim iOS build verification from Linux.

- [x] **Step 3: Update Linux application id**

In `chronopic_flutter/apps/chronopic/linux/CMakeLists.txt`, set:

```cmake
set(APPLICATION_ID "ai.chronopic.app")
```

- [x] **Step 4: Update Android E2E package constants**

In both Android deep E2E scripts, set:

```bash
PACKAGE_NAME="ai.chronopic.app"
```

- [x] **Step 5: Verify identity changes**

Run:

```bash
cd chronopic_flutter
flutter analyze
flutter test packages/chronopic_ui/test/mobile_productization_test.dart
cd apps/chronopic
flutter build apk --debug
```

Expected:

- Analyzer reports no issues.
- Mobile productization tests pass.
- Debug APK builds.
- `adb shell pm list packages | rg 'ai.chronopic.app'` finds the package after installing on an emulator.

### Task 3: Refine Mobile Shell And First-Run Entry

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add mobile-first assertions**

In `mobile_productization_test.dart`, add coverage that at a narrow phone width:

```dart
tester.view.physicalSize = const Size(390, 844);
tester.view.devicePixelRatio = 1;
await tester.pumpWidget(ChronoPicHome(service: service));
expect(find.byKey(const Key('mobile-entry-actions')), findsOneWidget);
expect(find.byKey(const Key('choose-photos-button')), findsOneWidget);
expect(find.byKey(const Key('add-library-button')), findsNothing);
```

Expected before implementation: fail if desktop folder-first actions leak into mobile.

- [x] **Step 2: Refine mobile entry actions**

Ensure mobile first-run shows:

- primary `Choose Photos`,
- secondary `Restore Backup`,
- permission recovery text only after a denied state,
- no desktop folder-path field in the first viewport.

Use a stable wrapper key:

```dart
const Key('mobile-entry-actions')
```

- [x] **Step 3: Verify first-run layout**

Run:

```bash
cd chronopic_flutter
flutter test packages/chronopic_ui/test/mobile_productization_test.dart --plain-name "mobile first run"
```

Expected: the mobile first-run test passes.

### Task 4: Refine Mobile Scoped Import And Scan Progress

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify: `chronopic_flutter/packages/chronopic_media/lib/src/photo_manager_gateway.dart`
- Modify if needed: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Modify: `docs/flutter-mobile-ui-refine-audit.md`

- [x] **Step 1: Audit the scoped import sheet**

Run the Android deep E2E runner on a clean emulator:

```bash
ANDROID_DEVICE_ID=emulator-5554 MOBILE_E2E_RUN_ID=mobile-ui-refine-scope chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

Expected:

- `03-scope.png` and `03-scope.xml` exist.
- `04-scope.png` and `04-scope.xml` exist.
- The selected scope name is readable.

- [x] **Step 2: Refine sheet density if evidence shows clutter**

If the sheet is crowded, implement a mobile list row with:

- 48px minimum height,
- scope title,
- media count as secondary text,
- explicit selected state,
- no multi-line overflow beyond two lines.

- [x] **Step 3: Refine scan progress**

Ensure progress copy distinguishes:

- requesting permission,
- waiting for library selection,
- scanning selected scope,
- imported count,
- skipped count,
- completed state.

Keep the existing progress evidence keys from the Android runner.

### Task 5: Refine Mobile Browse, Search, Filter, And Lazy Loading

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`

- [x] **Step 1: Add mobile browse assertions**

At a 390x844 viewport, assert:

```dart
expect(find.byKey(const Key('photo-grid')), findsOneWidget);
expect(find.text('20 items'), findsOneWidget);
expect(find.byKey(const Key('filter-toggle-button')), findsOneWidget);
```

- [x] **Step 2: Make mobile filters bottom-sheet or stacked controls**

If current mobile controls are cramped, move filter controls into a mobile-specific bottom sheet while keeping desktop toolbar unchanged.

Use keys:

```dart
const Key('mobile-filter-sheet')
const Key('mobile-filter-apply-button')
const Key('mobile-filter-clear-button')
```

- [x] **Step 3: Preserve lazy loading**

Run the large-library widget coverage and confirm initial 20-item behavior remains:

```bash
cd chronopic_flutter
flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart --plain-name "renders a larger scanned Linux library with adaptive grid"
```

Expected: initial count is 20 and scroll loads the rest.

### Task 6: Refine Mobile Detail, Gallery, And Edit Feedback

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Modify: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`

- [x] **Step 1: Add mobile overlay assertions**

In mobile widget tests, assert:

```dart
await tester.tap(find.byKey(const Key('photo-card-photo-city')));
await tester.pump();
await tester.sendKeyEvent(LogicalKeyboardKey.enter);
await tester.pumpAndSettle();
expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
expect(find.byKey(const Key('focused-detail-inspector')), findsOneWidget);
```

- [x] **Step 2: Refine detail overlay for small screens**

At mobile widths:

- media preview should appear before inspector,
- edit fields must be reachable by scrolling inside the overlay,
- close/back action must stay visible,
- save/validation status must be inside the overlay,
- no horizontal overflow.

- [x] **Step 3: Refine gallery overlay for safe areas**

At mobile widths:

- top controls avoid system status areas,
- bottom filmstrip does not cover metadata,
- arrow navigation has touch alternatives,
- Escape/back closes overlay.

- [x] **Step 4: Verify app-owned mobile workflows**

Run:

```bash
cd chronopic_flutter/apps/chronopic
flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554
```

Expected: edit, favorite, memory, detail/gallery, search/filter, and settings workflows pass.

### Task 7: Refine Mobile Memories, Settings, And Backup

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/settings/`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
- Modify: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`

- [x] **Step 1: Add mobile memory assertions**

Assert that at 390x844:

```dart
expect(find.byKey(const Key('memories-nav')), findsOneWidget);
await tester.tap(find.byKey(const Key('memories-nav')));
await tester.pump();
expect(find.byKey(const Key('memory-list-page')), findsOneWidget);
```

- [x] **Step 2: Refine memory pages for touch use**

Make memory list/detail controls:

- one primary action per row/card,
- destructive actions behind explicit secondary controls,
- 48px minimum tap target,
- no nested card-in-card visual clutter.

- [x] **Step 3: Refine settings and backup paths**

Settings must expose:

- backup export,
- backup restore,
- locale,
- AI disabled/configured state,
- map disabled/configured state,
- no desktop-only path copy in the mobile first viewport.

### Task 8: Close The Phase

**Files:**
- Modify: `PLAN.md`
- Modify: `AGENTS.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/flutter-mobile-ui-refine-audit.md`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `docs/mobile-productization.md`

- [x] **Step 1: Run local Flutter verification**

Run:

```bash
cd chronopic_flutter
flutter analyze
dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test
flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/mobile_productization_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart
```

Expected: all pass.

- [x] **Step 2: Run Android debug build**

Run:

```bash
cd chronopic_flutter/apps/chronopic
flutter build apk --debug
```

Expected: debug APK builds with package id `ai.chronopic.app`.

- [x] **Step 3: Run Android deep E2E**

Run:

```bash
ANDROID_DEVICE_ID=emulator-5554 MOBILE_E2E_RUN_ID=mobile-ui-refine-final chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android/mobile-ui-refine-final
```

Expected:

- runner exits 0,
- artifact assertion exits 0,
- screenshot/XML/backup artifacts exist,
- package id in adb commands is `ai.chronopic.app`.

- [x] **Step 4: Update docs and commit**

Update phase status and evidence paths in `PLAN.md`, `AGENTS.md`, `docs/flutter-refactor-phases.md`, and `docs/flutter-mobile-ui-refine-audit.md`.

Run:

```bash
git add PLAN.md AGENTS.md docs/flutter-refactor-phases.md docs/flutter-mobile-ui-refine-audit.md docs/mobile-e2e-verification.md docs/mobile-productization.md chronopic_flutter
git commit -m "Refine Flutter mobile UI"
```

Expected: commit succeeds with mobile UI/product-identity files only.

## Self-Review

- Spec coverage: this plan covers mobile UI refine, Android package id `ai.chronopic.app`, Android evidence, iOS blocked boundary, browse/import/detail/gallery/memory/settings flows, and verification.
- Placeholder scan: no task uses TBD/TODO or unspecified verification.
- Type consistency: package id and test keys are used consistently across Android, iOS metadata, Linux app id, docs, and E2E scripts.
