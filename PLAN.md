# ChronoPic Development Plan

## Summary

ChronoPic is a local-first, AI-powered desktop/mobile photo workspace. The
Flutter app under `chronopic_flutter/` is the release line: signed Android
APK/AAB and Linux desktop artifacts are published by the tag-triggered GitHub
Actions release workflow. The original Electron/TypeScript app remains in the
repository as the reference implementation and as the source for Electron
backup JSON migration; it is no longer released.

## Active Direction

Flutter Phase 17's AI connection-check implementation shipped in `v0.1.15`;
automated tests and Linux/Android debug builds pass. Keep the phase active until
the Linux first-frame launch is visually verified in a desktop-capable session;
the headless Xvfb run leaves the window unmapped. Phase 16 added portable JSON
photo metadata sidecars; the full backup format remains the option for Memories,
settings, generated fields, and edit history. EXIF writeback remains out of
scope.

Active phase plan:
[docs/superpowers/plans/2026-10-22-flutter-ai-provider-connection-validation.md](docs/superpowers/plans/2026-10-22-flutter-ai-provider-connection-validation.md).

Further candidates after Phase 17:

1. **Flutter Map browse completion** — Flutter's Map surface is currently a
   static error placeholder, and saved AMap settings are not consumed by a
   Flutter map renderer. Choose a rendering/provider approach before wiring
   those credentials into the release app.
2. **iOS live verification** — metadata and runners are scaffolded, but the
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

Flutter Phases 1-16 are complete; Phase 17 is active. Completed details are
archived; do not edit archive files except to correct factual errors.

- **Electron line** (Phases 1 – 4.26, Phase 5 Editing and History):
  [docs/superpowers/plans/electron-development-plan-archive.md](docs/superpowers/plans/electron-development-plan-archive.md)
  with execution history in
  [docs/superpowers/plans/agent-step-log-electron-line.md](docs/superpowers/plans/agent-step-log-electron-line.md)
  (Steps 0 – 122).
- **Flutter line** (Phases 4.27 – 4.38 and Phases 6 – 16):
  [docs/superpowers/plans/flutter-development-plan-archive.md](docs/superpowers/plans/flutter-development-plan-archive.md)
  with execution history in
  [docs/superpowers/plans/agent-step-log-flutter-line.md](docs/superpowers/plans/agent-step-log-flutter-line.md)
  (Steps 101 – 279) and
  [docs/superpowers/plans/agent-step-log-flutter-2026-10-12.md](docs/superpowers/plans/agent-step-log-flutter-2026-10-12.md)
  (Steps 280 onward).
- **Phase 16 — Photo Metadata Sidecars**:
  [docs/superpowers/plans/2026-10-12-flutter-photo-metadata-sidecars.md](docs/superpowers/plans/2026-10-12-flutter-photo-metadata-sidecars.md).
- Durable Flutter phase tracker:
  [docs/flutter-refactor-phases.md](docs/flutter-refactor-phases.md).

Latest release: **v0.1.15**.

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
