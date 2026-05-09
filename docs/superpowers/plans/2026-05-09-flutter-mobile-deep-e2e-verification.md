# Flutter Mobile Deep E2E Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Phase 6 Android smoke pass into repeatable, deeper mobile end-to-end verification before Phase 7 release and migration work starts.

**Architecture:** Keep product code changes narrow: add stable mobile test hooks, an Android emulator fixture runner, Flutter integration tests for in-app workflows, and durable evidence docs. Permission-dialog and media-library setup stays shell/ADB-driven because those surfaces live outside Flutter's widget tree; app workflows stay in Flutter tests where possible.

**Tech Stack:** Flutter `integration_test`, existing Dart/package tests, Android SDK `adb`/`uiautomator`/`screencap`, existing `photo_manager` media adapter, existing backup JSON model. Do not add a third-party mobile test framework in the first pass; if execution later proves one is needed, verify the latest stable version from the official package source before adding it.

---

## File Map

- Create: `docs/mobile-e2e-verification.md`
  Durable evidence matrix for Android and iOS mobile E2E coverage.
- Create: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
  Flutter integration tests for app-owned mobile workflows after media access has been prepared.
- Create: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
  Repeatable Android emulator runner for reset, media fixture injection, permission flows, screenshots, and backup restore checks.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
  Add stable keys/semantics only where current mobile controls are hard to target reliably.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  Add stable keys for mobile browse cards, select mode, favorite, detail, and gallery actions if missing.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
  Add stable keys for edit, favorite, memory, and close actions if missing.
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
  Add stable keys for create memory, add/remove memory, cover, rename, and description actions if missing.
- Modify: `chronopic_flutter/apps/chronopic/pubspec.yaml`
  Add `integration_test` under dev dependencies if it is not already present.
- Modify: `PLAN.md`
  Record Phase 6.5 and its exit gate.
- Modify: `docs/flutter-refactor-phases.md`
  Insert Phase 6.5 between Phase 6 and Phase 7.
- Modify: `AGENTS.md`
  Record each executed slice and verification evidence.

---

## Task 1: Write The Mobile E2E Matrix

**Files:**

- Create: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Create the evidence matrix**

Create `docs/mobile-e2e-verification.md` with these sections:

```markdown
# Mobile E2E Verification

## Purpose

This document records repeatable mobile end-to-end verification for ChronoPic after Phase 6 mobile productization and before Phase 7 release/cutover.

## Android Target

- AVD/device:
- Android release:
- API level:
- App build:
- Test media fixture:

## Android Required Scenarios

| Scenario | Required Evidence | Status | Notes |
| --- | --- | --- | --- |
| Permission denied recovery | Screenshot and UI text showing recoverable denied state | Pending | |
| Limited selected-photo access | Permission dump plus import count | Pending | |
| Full photo-library access | Import count and browse UI after scan | Pending | |
| Restart persistence | Relaunch screenshot showing browse state, not first-run state | Pending | |
| Metadata backup restore | Backup JSON summary and relaunch screenshot after restore | Pending | |
| Edit metadata | Caption/tags/datetime changed, persisted after relaunch | Pending | |
| Favorite toggle | Favorite state visible and persisted after relaunch | Pending | |
| Memory lifecycle | Create memory, add photo, cover, rename/description, remove photo | Pending | |
| Detail/gallery overlay | Open detail/gallery from mobile browse and close it | Pending | |
| Search/filter/sort | Query/filter result changes visible on mobile layout | Pending | |
| Locale/settings persistence | Locale or settings update survives relaunch | Pending | |

## iOS Required Scenarios

| Scenario | Required Evidence | Status | Notes |
| --- | --- | --- | --- |
| Photo permission denied | Simulator/device screenshot | Blocked | Requires macOS/Xcode |
| Limited library access | Simulator/device screenshot and import count | Blocked | Requires macOS/Xcode |
| Full library access | Import count and browse UI | Blocked | Requires macOS/Xcode |
| Restart persistence | Relaunch screenshot | Blocked | Requires macOS/Xcode |
| Metadata backup restore | Backup JSON summary and relaunch screenshot | Blocked | Requires macOS/Xcode |

## Commands

Record exact commands and outputs for every completed scenario.
```

- [x] **Step 2: Update AGENTS**

Add an `AGENTS.md` step stating that Phase 6.5 has started and the evidence matrix has been created.

- [x] **Step 3: Verify docs**

Run:

```bash
git diff --check
```

Expected: exit 0.

- [x] **Step 4: Commit**

```bash
git add docs/mobile-e2e-verification.md AGENTS.md
git commit -m "Add mobile E2E verification matrix"
```

---

## Task 2: Add Stable Mobile Test Hooks

**Files:**

- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
- Test: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add failing assertions for stable keys**

Extend `mobile_productization_test.dart` with assertions for these keys:

```dart
expect(find.byKey(const Key('mobile-choose-photos')), findsOneWidget);
expect(find.byKey(const Key('mobile-browse-surface')), findsOneWidget);
expect(find.byKey(const Key('mobile-select-mode')), findsOneWidget);
expect(find.byKey(const Key('mobile-open-detail')), findsWidgets);
expect(find.byKey(const Key('mobile-open-gallery')), findsWidgets);
expect(find.byKey(const Key('mobile-create-memory')), findsOneWidget);
```

Run:

```bash
cd chronopic_flutter
flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: fail until missing keys are added.

- [x] **Step 2: Add keys without changing behavior**

Add `ValueKey<String>` values to existing widgets only:

- `mobile-choose-photos`
- `mobile-browse-surface`
- `mobile-select-mode`
- `mobile-open-detail`
- `mobile-open-gallery`
- `mobile-create-memory`
- `mobile-favorite-toggle`
- `mobile-add-to-memory`
- `mobile-remove-from-memory`
- `mobile-memory-cover`
- `mobile-memory-rename`
- `mobile-memory-description`

Do not change layout, copy, navigation, or business logic in this task.

- [x] **Step 3: Verify keys**

Run:

```bash
cd chronopic_flutter
dart analyze packages/chronopic_ui apps/chronopic
flutter test packages/chronopic_ui/test/mobile_productization_test.dart
```

Expected: analyze passes and mobile widget tests pass.

- [x] **Step 4: Commit**

```bash
git add chronopic_flutter/packages/chronopic_ui
git commit -m "Add stable mobile E2E hooks"
```

---

## Task 3: Build The Android Deep E2E Runner

**Files:**

- Create: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Create the runner skeleton**

Create `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$ROOT_DIR/chronopic_flutter/apps/chronopic"
DEVICE_ID="${ANDROID_DEVICE_ID:-emulator-5554}"
PACKAGE_NAME="com.example.chronopic"
OUT_DIR="${MOBILE_E2E_OUT_DIR:-$ROOT_DIR/.tmp/mobile-e2e/android}"

mkdir -p "$OUT_DIR"

adb -s "$DEVICE_ID" wait-for-device
adb -s "$DEVICE_ID" shell getprop sys.boot_completed | grep -q 1

cd "$APP_DIR"
flutter build apk --debug
adb -s "$DEVICE_ID" install -r build/app/outputs/flutter-apk/app-debug.apk

adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" || true
adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME"

adb -s "$DEVICE_ID" shell mkdir -p /sdcard/Pictures/ChronoPicDeepE2E
adb -s "$DEVICE_ID" push android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png /sdcard/Pictures/ChronoPicDeepE2E/deep-1.png
adb -s "$DEVICE_ID" push android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png /sdcard/Pictures/ChronoPicDeepE2E/deep-2.png
adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/ChronoPicDeepE2E/deep-1.png
adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/ChronoPicDeepE2E/deep-2.png

adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity"
sleep 15

adb -s "$DEVICE_ID" exec-out screencap -p > "$OUT_DIR/01-first-run.png"
adb -s "$DEVICE_ID" shell uiautomator dump /sdcard/window.xml >/dev/null
adb -s "$DEVICE_ID" shell cat /sdcard/window.xml > "$OUT_DIR/01-first-run.xml"

echo "Android deep E2E runner prepared $OUT_DIR"
```

- [x] **Step 2: Make it executable**

Run:

```bash
chmod +x chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

- [x] **Step 3: Run the skeleton**

Run:

```bash
ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

Expected:

- APK builds.
- APK installs.
- Two PNG media fixtures are pushed.
- `.tmp/mobile-e2e/android/01-first-run.png` and `.xml` exist.

- [x] **Step 4: Commit**

```bash
git add chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh docs/mobile-e2e-verification.md AGENTS.md
git commit -m "Add Android mobile E2E runner"
```

---

## Task 4: Automate Android Permission And Import Checks

**Files:**

- Modify: `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Add reusable shell assertions**

Add functions to the runner:

```bash
dump_ui() {
  local name="$1"
  adb -s "$DEVICE_ID" shell uiautomator dump /sdcard/window.xml >/dev/null
  adb -s "$DEVICE_ID" shell cat /sdcard/window.xml > "$OUT_DIR/$name.xml"
  adb -s "$DEVICE_ID" exec-out screencap -p > "$OUT_DIR/$name.png"
}

assert_ui_contains() {
  local name="$1"
  local expected="$2"
  grep -F "$expected" "$OUT_DIR/$name.xml" >/dev/null
}

tap() {
  adb -s "$DEVICE_ID" shell input tap "$1" "$2"
}
```

- [x] **Step 2: Automate denied permission**

Use `tap 308 1173` for `Choose Photos`, then `tap 540 1516` for `DON'T ALLOW`.

Assert:

```bash
assert_ui_contains "02-denied" "Photo library permission denied. Open settings to grant access."
```

- [x] **Step 3: Automate full access**

After `pm clear` and relaunch, tap `Choose Photos`, then tap `ALLOW ALL` at `540 1360`.

Assert:

```bash
assert_ui_contains "03-full-access" "Photo library scan complete: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing"
```

- [x] **Step 4: Automate limited selected access**

After `pm clear` and relaunch, tap `Choose Photos`, tap `ALLOW LIMITED ACCESS` at `540 1202`, select two picker tiles, and tap `Allow (2)`.

Assert:

```bash
assert_ui_contains "04-limited-access" "Limited photo access: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing"
adb -s "$DEVICE_ID" shell dumpsys package "$PACKAGE_NAME" > "$OUT_DIR/04-permissions.txt"
grep -F "android.permission.READ_MEDIA_VISUAL_USER_SELECTED: granted=true" "$OUT_DIR/04-permissions.txt"
grep -F "android.permission.READ_MEDIA_IMAGES: granted=false" "$OUT_DIR/04-permissions.txt"
```

- [x] **Step 5: Automate restart and backup restore**

For restart:

```bash
adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME"
adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity"
sleep 20
dump_ui "05-restart"
assert_ui_contains "05-restart" "Select"
```

For backup restore:

```bash
adb -s "$DEVICE_ID" shell run-as "$PACKAGE_NAME" cat /data/user/0/$PACKAGE_NAME/code_cache/.local/share/chronopic_flutter/chronopic-backup.json > "$OUT_DIR/backup.json"
node -e "const fs=require('fs'); const data=JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); if (data.photos.length !== 2) process.exit(1);" "$OUT_DIR/backup.json"
adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME"
adb -s "$DEVICE_ID" push "$OUT_DIR/backup.json" /data/local/tmp/chronopic-backup.json
adb -s "$DEVICE_ID" shell run-as "$PACKAGE_NAME" mkdir -p /data/user/0/$PACKAGE_NAME/code_cache/.local/share/chronopic_flutter
adb -s "$DEVICE_ID" shell run-as "$PACKAGE_NAME" cp /data/local/tmp/chronopic-backup.json /data/user/0/$PACKAGE_NAME/code_cache/.local/share/chronopic_flutter/chronopic-backup.json
adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity"
sleep 20
dump_ui "06-restore"
assert_ui_contains "06-restore" "Select"
```

- [x] **Step 6: Verify runner**

Run:

```bash
ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

Expected:

- Exit 0.
- Evidence files under `.tmp/mobile-e2e/android`.
- Matrix updated with denied/full/limited/restart/backup evidence.

- [x] **Step 7: Commit**

```bash
git add chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh docs/mobile-e2e-verification.md AGENTS.md
git commit -m "Automate Android permission and import E2E"
```

---

## Task 5: Add App-Owned Deep Workflow Tests

**Files:**

- Create: `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
- Modify: `chronopic_flutter/apps/chronopic/pubspec.yaml`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Enable Flutter integration tests**

If `integration_test` is missing, add:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

- [x] **Step 2: Create the integration test**

Create `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart` with tests that use the existing app entrypoint and stable keys to verify:

- browse surface opens after existing catalog restore,
- detail overlay opens and closes,
- gallery overlay opens and closes,
- favorite toggle updates state,
- caption/tags/datetime edit controls persist,
- memory create/add/remove/cover flows are reachable,
- locale/settings persistence can be changed and observed after restart.

Use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` and target only app-owned UI. Do not try to drive Android permission dialogs from this Dart test.

- [x] **Step 3: Run the integration test**

Run:

```bash
cd chronopic_flutter/apps/chronopic
flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554
```

Expected: passes on the Android emulator.

- [x] **Step 4: Commit**

```bash
git add chronopic_flutter/apps/chronopic/pubspec.yaml chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart docs/mobile-e2e-verification.md AGENTS.md
git commit -m "Add mobile app workflow integration tests"
```

---

## Task 6: Record iOS Deep E2E Gate

**Files:**

- Modify: `docs/mobile-e2e-verification.md`
- Modify: `docs/mobile-productization.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Add macOS/Xcode command requirements**

Record:

```bash
cd chronopic_flutter/apps/chronopic
flutter build ios --debug --no-codesign
flutter run -d <ios-device-or-simulator-id>
```

Required iOS evidence:

- denied permission screenshot,
- limited access screenshot and import count,
- full access screenshot and import count,
- restart persistence screenshot,
- backup restore JSON summary and relaunch screenshot.

- [x] **Step 2: Mark iOS state accurately**

Status should remain `Blocked` or `Pending macOS/Xcode evidence` until it is actually run from macOS/Xcode. Do not mark iOS complete from Linux-only evidence.

- [x] **Step 3: Commit**

```bash
git add docs/mobile-e2e-verification.md docs/mobile-productization.md AGENTS.md
git commit -m "Record iOS mobile E2E gate"
```

---

## Task 7: Phase Closeout

**Files:**

- Modify: `PLAN.md`
- Modify: `docs/flutter-refactor-phases.md`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Run full verification**

Run:

```bash
pnpm test
pnpm typecheck
pnpm build
pnpm run e2e:accessibility
pnpm run e2e:runtime
pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts
cd chronopic_flutter
dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic
dart test packages/chronopic_media/test packages/chronopic_app/test
flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart
cd apps/chronopic
flutter build apk --debug
flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554
```

Run the Android shell runner:

```bash
ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

- [ ] **Step 2: Update phase status**

Update `PLAN.md` and `docs/flutter-refactor-phases.md`:

- Android deep E2E status,
- evidence artifacts path,
- passed scenarios,
- skipped scenarios with reasons,
- iOS macOS/Xcode gate status,
- remaining Phase 7 cutover requirements.

- [ ] **Step 3: Final docs check**

Run:

```bash
git diff --check
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add PLAN.md docs/flutter-refactor-phases.md docs/mobile-e2e-verification.md AGENTS.md chronopic_flutter
git commit -m "Complete mobile deep E2E verification phase"
```

---

## Exit Criteria

- Android deep E2E runner is repeatable from a clean app state.
- Android permission flows cover denied, limited selected access, and full access.
- Android app-owned workflows cover browse, detail/gallery, edits, favorites, memories, search/filter/sort, settings/locale, restart persistence, and metadata backup restore.
- Evidence screenshots/XML/backup summaries are recorded under `.tmp/mobile-e2e/android` and summarized in `docs/mobile-e2e-verification.md`.
- iOS deep E2E remains accurately marked as pending until macOS/Xcode evidence exists.
- Existing Electron and Flutter desktop gates still pass after mobile E2E additions.
