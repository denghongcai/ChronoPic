# AGENTS.md

## Purpose

This file is the working instruction surface for ChronoPic agents. It complements
`PLAN.md` and must be kept current as implementation progresses. Full
chronological execution history lives in the archived step logs under
`docs/superpowers/plans/` — this file deliberately does not accumulate step
entries.

## Working Rules

- Keep `PLAN.md` as the stable implementation plan; update phase status there.
- Append each new execution step (what changed, why, what is next, verification
  evidence) to the active step log:
  [docs/superpowers/plans/agent-step-log-flutter-line.md](docs/superpowers/plans/agent-step-log-flutter-line.md).
- After appending, **update in place** (never append to) the `Current State`
  section below so it always reflects the latest step and next action.
- Do not mark a step complete unless the corresponding code or verification has
  landed locally.
- After completing a phase, phase checklist item, or meaningful implementation
  slice, follow `docs/agent-verification-script.md` before marking the work
  complete. Record which scenes were run, which commands passed, and any
  skipped scenes with reasons.
- If a step log file grows beyond ~3000 lines, start a new dated log file in
  `docs/superpowers/plans/` and link it from `PLAN.md` Completed Phases.

## Current Plan Reference

- Active plan: `PLAN.md` (summary, active direction, backlog, constraints).
- Completed phases and full execution history:
  `docs/superpowers/plans/electron-development-plan-archive.md`,
  `docs/superpowers/plans/flutter-development-plan-archive.md`,
  `docs/superpowers/plans/agent-step-log-electron-line.md` (Steps 0-122),
  `docs/superpowers/plans/agent-step-log-flutter-line.md` (Steps 101+).
- Durable Flutter phase tracker: `docs/flutter-refactor-phases.md`.

## Current State

- Latest step: **Step 279** (2026-10-12) — published `v0.1.13` with the real AI
  provider stack; main CI and the tag release workflow both passed, and the
  Android job built the signed artifacts in CI without a manual fallback.
  (Step 277 was the Flutter real AI provider phase — `OpenAiCompatibleAiClient`,
  AI client factory, photo + memory enrichment orchestration, and the inspector /
  memory-dialog / notification queue surfaces; Step 278 was its final-review
  polish for the memory dialog's in-flight guard.)
- Release line: Flutter (`chronopic_flutter/`); latest release **v0.1.13**
  (Android APK/AAB + Linux x64 tarball via tag-triggered GitHub Actions).
- The Electron app is reference/migration-only and no longer released.
- Flutter phases 1-15 are complete, including the mobile native experience
  redesign, lazy thumbnail/count pipeline, mobile memory creation flow, and
  the real AI provider stack (Flutter toolchain now 3.47.7,
  `openai_dart ^10.0.1`).
- Known open candidates (see `PLAN.md` Active Direction):
  sidecar metadata export/import, AI/Map configuration live validation
  (no test-connection path yet), iOS live verification (blocked on
  macOS/Xcode).
