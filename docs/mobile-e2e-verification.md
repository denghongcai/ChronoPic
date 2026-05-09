# Mobile E2E Verification

## Purpose

This document records repeatable mobile end-to-end verification for ChronoPic
after Phase 6 mobile productization and before Phase 7 release/cutover.

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
