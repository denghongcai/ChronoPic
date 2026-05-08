# Flutter Electron UI Functional Parity Matrix

| Surface / Workflow | Electron Reference Evidence | Flutter Evidence | Status | Gap | Fix Commit |
| --- | --- | --- | --- | --- | --- |
| Empty first-run home | Pending | Pending | Pending | Capture both sides | Pending |
| Populated grid/waterfall browse | Pending | Pending | Pending | Capture both sides | Pending |
| Map browse / disabled-map state | Pending | Pending | Pending | Capture both sides | Pending |
| Timeline browse | Pending | Pending | Pending | Capture both sides | Pending |
| Detail inspector and edits | Pending | Pending | Pending | Capture both sides | Pending |
| Fullscreen gallery | Pending | Pending | Pending | Capture both sides | Pending |
| Favorites filter | Pending | Pending | Pending | Capture both sides | Pending |
| Memories list | Pending | Pending | Pending | Capture both sides | Pending |
| Memory detail management | Pending | Pending | Pending | Capture both sides | Pending |
| Settings | Pending | Pending | Pending | Capture both sides | Pending |
| Notifications / AI queue | Pending | Pending | Pending | Capture both sides | Pending |
| Chinese locale | Pending | Pending | Pending | Capture both sides | Pending |
| Restart persistence | Pending | Pending | Pending | Capture both sides | Pending |

## Evidence Rules

- Electron screenshots live under `test-results/flutter-electron-parity/electron/`.
- Flutter screenshots live under `test-results/flutter-electron-parity/flutter/`.
- Screenshot files are ignored by git; this matrix records their paths and findings.
- A row can only become `Matched` after both screenshots exist and the related test path passes.
- A row can become `Accepted Difference` only with a written reason in the `Gap` column.
- A row cannot be closed from screenshots alone; tests must cover behavior.
