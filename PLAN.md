# ChronoPic Development Plan

## Summary

ChronoPic is a local-first, AI-powered desktop/mobile photo workspace. The
Flutter app under `chronopic_flutter/` is the release line: signed Android
APK/AAB and Linux desktop artifacts are published by the tag-triggered GitHub
Actions release workflow. The original Electron/TypeScript app remains in the
repository as the reference implementation and as the source for Electron
backup JSON migration; it is no longer released.

## Active Direction

No numbered phase is currently in progress. The next phase should be promoted
from the strongest open candidates:

1. **AI / Map configuration validation** — Settings can save AI and map
   credentials and show presence/configured states, but the provider
   abstractions expose no live health probe or test-connection path.
2. **Metadata portability** — sidecar metadata export/import. JSON sidecars
   first; EXIF writeback stays out of scope until backup/rollback guarantees
   are stronger.
3. **iOS live verification** — metadata and runners are scaffolded, but the
   required permission/import/restart/restore evidence is blocked on
   macOS/Xcode tooling.

## Future Product Backlog

These are intentionally recorded as candidate directions rather than committed
phases. They should be promoted into explicit numbered phases only after the
current product risk is re-evaluated.

- Person/face grouping — blocked until a real person-recognition signal exists.
- OCR and vector search — larger future discovery features.
- Large-library performance pass — deprioritized (2026-05-06 and 2026-05-16);
  not to be promoted as the next phase without new evidence.
- Accessibility audit sweep beyond the completed keyboard/focus phase.
- Installable installers / store distribution — intentionally deferred;
  portable unpacked bundles are the current distribution model.
- Realtime file watching — permanently out of scope; manual `Scan Library`
  with incremental reconciliation is the committed sync model.

## Completed Phases

All implementation phases are complete. Details are archived; do not edit
archive files except to correct factual errors.

- **Electron line** (Phases 1 – 4.26, Phase 5 Editing and History):
  [docs/superpowers/plans/electron-development-plan-archive.md](docs/superpowers/plans/electron-development-plan-archive.md)
  with execution history in
  [docs/superpowers/plans/agent-step-log-electron-line.md](docs/superpowers/plans/agent-step-log-electron-line.md)
  (Steps 0 – 122).
- **Flutter line** (Phases 4.27 – 4.38 and Phases 6 – 14):
  [docs/superpowers/plans/flutter-development-plan-archive.md](docs/superpowers/plans/flutter-development-plan-archive.md)
  with execution history in
  [docs/superpowers/plans/agent-step-log-flutter-line.md](docs/superpowers/plans/agent-step-log-flutter-line.md)
  (Steps 101 onward).
- Durable Flutter phase tracker:
  [docs/flutter-refactor-phases.md](docs/flutter-refactor-phases.md).

Latest release: **v0.1.12**.

## Product Scope Constraints

- Local-first: no cloud sync; favorites, memories, edits, and semantic state
  are local-only.
- No realtime file watching. Manual `Scan Library` performs incremental
  reconciliation: new files are ingested, missing files are marked inactive,
  and changed files are reprocessed via `mtime` / `size` / `hash` detection.
- AI is optional and generated content never overwrites user-authored fields.
- OCR, vector search, person recognition, and EXIF writeback remain out of
  scope until explicitly promoted from the backlog.
- Package boundaries stay strict in both lines: the Electron workspace keeps
  renderer/main/shared separation, and the Flutter workspace keeps
  domain / database / media / ai / app / ui package separation.
- Mobile may diverge from desktop visual layout and interaction structure, but
  must keep the shared local-first data and workflow contracts.

## Verification

Verification commands, E2E suites, packaging, and release checks are documented
in [DEVELOPMENT.md](DEVELOPMENT.md). The scene-by-scene agent verification
guidance is [docs/agent-verification-script.md](docs/agent-verification-script.md).
