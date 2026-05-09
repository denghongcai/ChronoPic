# Mobile E2E Verification

## Purpose

This document records repeatable mobile end-to-end verification for ChronoPic
after Phase 6 mobile productization and before Phase 7 release/cutover.

## Android Target

- AVD/device: `chronopic_api36` / `emulator-5554`
- Android release: `16`
- API level: `36`
- App build: debug APK from `chronopic_flutter/apps/chronopic`
- Test media fixture:
  two launcher PNG files pushed to `/sdcard/Pictures/ChronoPicDeepE2E`

## Android Required Scenarios

| Scenario | Required Evidence | Status | Notes |
| --- | --- | --- | --- |
| Permission denied recovery | Screenshot and UI text showing recoverable denied state | Passed | `.tmp/mobile-e2e/android/02-denied.png`, `.xml` |
| Limited selected-photo access | Permission dump plus import count | Passed | `.tmp/mobile-e2e/android/04-limited-access.png`, `.xml`, `04-permissions.txt` |
| Full photo-library access | Import count and browse UI after scan | Passed | `.tmp/mobile-e2e/android/03-full-access.png`, `.xml` |
| Restart persistence | Relaunch screenshot showing browse state, not first-run state | Passed | `.tmp/mobile-e2e/android/05-restart.png`, `.xml` |
| Metadata backup restore | Backup JSON summary and relaunch screenshot after restore | Passed | `.tmp/mobile-e2e/android/backup.json`, `06-restore.png`, `.xml` |
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

### Android Runner

```bash
ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh
```

Expected skeleton evidence:

- `.tmp/mobile-e2e/android/01-first-run.png`
- `.tmp/mobile-e2e/android/01-first-run.xml`

2026-05-10 skeleton result:

- Command:
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`
- Result:
  exit 0 after APK build/install,
  two PNG media fixtures pushed,
  app launched,
  first-run evidence captured,
  permission/import/restart/restore scenarios verified,
  and backup JSON validated with 2 photos.
- First-run assertion:
  `01-first-run.xml` contains `Choose Photos`.
- Permission denied assertion:
  `02-denied.xml` contains
  `Photo library permission denied. Open settings to grant access.`
- Full access assertion:
  `03-full-access.xml` contains
  `Photo library scan complete: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing`
- Limited access assertion:
  `04-limited-access.xml` contains
  `Limited photo access: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing`
- Permission dump assertions:
  `04-permissions.txt` contains
  `android.permission.READ_MEDIA_VISUAL_USER_SELECTED: granted=true`
  and
  `android.permission.READ_MEDIA_IMAGES: granted=false`.
- Restart assertion:
  `05-restart.xml` contains `Select`.
- Restore assertion:
  `06-restore.xml` contains `Select` and `2 items`.
