# Flutter Electron UI Functional Parity Spec

## Goal

Make Flutter Linux desktop match Electron's current UI information architecture and user-visible behavior before mobile work starts.

## Rules

- Electron is the reference for desktop UI and workflow behavior.
- Flutter must be compared with Electron through screenshots and tests, not memory.
- Every changed surface needs before/after evidence in `test-results/flutter-electron-parity/`.
- Screenshots are evidence for rendering only; functional parity still requires tests.
- Do not start Android/iOS work while any desktop parity row is `Pending` or `Gap`.
- Keep Flutter desktop implementation in focused modules; do not collapse back into a monolithic `chronopic_home.dart`.
- Keep secrets out of screenshots, logs, and committed files.

## Required Surfaces

- Empty first-run home.
- Populated grid/waterfall browse.
- Map browse with geotagged data or explicit disabled-map state.
- Timeline browse.
- Detail inspector and edit controls.
- Fullscreen gallery and filmstrip.
- Favorites filter.
- Memories list.
- Memory detail management.
- Settings.
- Notifications / AI queue.
- Chinese locale.
- Restart persistence after scan, edit, favorite, memory, and settings changes.

## Completion Criteria

- All matrix rows in `docs/flutter-electron-ui-functional-parity.md` are `Matched` or have a documented, accepted platform-specific difference.
- Electron reference E2E tests used for comparison pass.
- Flutter package tests, widget tests, analyze, Linux build, and Xvfb/scrot capture pass.
- `AGENTS.md` records screenshot paths, commands, skipped scenes, and remaining risks.
