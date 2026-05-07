# Flutter Rewrite Phase 0 Parity Contract

## Purpose

This document starts `Phase 0: Freeze Parity Contract` from
[docs/flutter-refactor-phases.md](flutter-refactor-phases.md). It defines the
Electron reference behavior that a Flutter rewrite must preserve before any
Flutter scaffolding or Dart implementation is treated as the active product
line.

The Electron app remains the source of truth until the Flutter implementation
passes the parity gates below.

## Reference Sources

- Product roadmap and active assumptions: [PLAN.md](../PLAN.md)
- Execution log: [AGENTS.md](../AGENTS.md)
- Flutter rewrite roadmap: [docs/flutter-refactor-phases.md](flutter-refactor-phases.md)
- Runtime verification director script: [docs/agent-verification-script.md](agent-verification-script.md)
- Electron runtime E2E: [tests/e2e/runtime.spec.ts](../tests/e2e/runtime.spec.ts)
- Backup/restore E2E: [tests/e2e/backup.spec.ts](../tests/e2e/backup.spec.ts)
- Accessibility E2E: [tests/e2e/accessibility.spec.ts](../tests/e2e/accessibility.spec.ts)
- AI setup and queue E2E: [tests/e2e/ai-productization.spec.ts](../tests/e2e/ai-productization.spec.ts)
- Backup service tests: [tests/backup.test.ts](../tests/backup.test.ts)
- Domain tests: [tests/domain.test.ts](../tests/domain.test.ts)
- i18n tests: [tests/i18n.test.ts](../tests/i18n.test.ts)
- Discovery and memory tests:
  [tests/discovery-ui.test.ts](../tests/discovery-ui.test.ts),
  [tests/memory-candidates.test.ts](../tests/memory-candidates.test.ts),
  and [tests/memory-story-and-discovery.test.ts](../tests/memory-story-and-discovery.test.ts)

## Required Workflow Parity

The Flutter rewrite must preserve these user-visible workflows before it can
replace the Electron desktop app.

1. Library setup and manual scan
- Register a local media source.
- Run explicit manual scan.
- Index supported images from a fixture directory.
- Skip unchanged files on repeat scan.
- Mark missing files unavailable without deleting authored metadata.

2. Browse and discovery
- Browse indexed photos in the default waterfall/grid surface.
- Filter by text, tag, status, type, favorite, memory, GPS/map pivot, and timeline pivot where the Electron app exposes those pivots.
- Preserve selected photo state while switching browse modes.
- Render map and timeline zero states when data or settings are missing.

3. Focused viewing
- Single click selects a photo.
- Double click or Enter opens focused detail view.
- Gallery view supports adjacent navigation and Escape dismissal.
- Detail view exposes metadata, authored caption/tags, datetime correction, favorite state, and memory actions.

4. Editing and rollback
- Update caption.
- Update tags.
- Update corrected datetime.
- Record edit history.
- Roll back the latest supported edit.
- Preserve authored edits across scan, restart, backup, and restore.

5. Favorites and memories
- Toggle favorite state.
- Create, rename, describe, delete, and open memories.
- Add photos to memories and remove them.
- Set and preserve a memory cover photo.
- Keep memory cards, memory detail, recent memories, and memory-scoped photo browsing distinct from normal library filtering.

6. AI setup, queue, and memory candidates
- Distinguish disabled, incomplete, configured, pending, processing, failed, and completed AI states.
- Show required AI setup fields without exposing secrets.
- Keep generated captions, summaries, tags, and memory suggestions separate from user-authored edits.
- Require explicit accept or reject for memory candidates.
- Do not auto-create memories from AI suggestions.

7. Locale and settings
- Persist UI locale and AI output locale.
- Preserve locale-dependent render-time formatting for derived date text such as memory story dates.
- Persist map settings and AI settings safely.
- Keep secret-bearing settings out of logs and user-visible readbacks.

8. Backup, preview, and restore
- Export versioned ChronoPic JSON backup.
- Preview restore conflicts before replacement.
- Restore into an empty data directory.
- Preserve library sources, photos, metadata, semantic generated fields, edit history, favorites, memories, memberships, memory candidates, locale settings, AI settings metadata, and map settings.
- Do not copy original media files.
- Do not write EXIF or sidecar files.

9. Accessibility and desktop launch
- Keep keyboard access for core navigation, dialogs, photo-card activation, viewer close, and batch-selection surfaces.
- Preserve focus return from modal flows.
- Launch through the packaged/runtime entry points required by release verification.

## Reference Fixture Matrix

The first parity suite should be built from the current Electron tests instead
of inventing new product semantics.

| Area | Existing Electron reference | Flutter parity target |
| --- | --- | --- |
| Runtime catalog loop | [tests/e2e/runtime.spec.ts](../tests/e2e/runtime.spec.ts) | Service or integration fixture that imports two images, scans, restarts, and verifies persisted source/photo state |
| Backup and restore | [tests/e2e/backup.spec.ts](../tests/e2e/backup.spec.ts), [tests/backup.test.ts](../tests/backup.test.ts) | Dart backup parser/exporter round trip plus restore into an empty Drift database |
| Accessibility | [tests/e2e/accessibility.spec.ts](../tests/e2e/accessibility.spec.ts) | Flutter widget/integration checks for focus, keyboard activation, dialogs, and viewer close |
| AI setup and queue | [tests/e2e/ai-productization.spec.ts](../tests/e2e/ai-productization.spec.ts) | Dart service tests and Flutter UI tests for readiness states without provider secrets |
| Domain defaults and queries | [tests/domain.test.ts](../tests/domain.test.ts) | Dart model tests for defaults, filters, AI readiness, and JSON round trips |
| Locale | [tests/i18n.test.ts](../tests/i18n.test.ts) | Dart locale settings tests plus widget checks for visible locale-sensitive text |
| Memories and discovery | [tests/memory-candidates.test.ts](../tests/memory-candidates.test.ts), [tests/memory-story-and-discovery.test.ts](../tests/memory-story-and-discovery.test.ts), [tests/discovery-ui.test.ts](../tests/discovery-ui.test.ts) | Dart service tests for candidate lifecycle, story grouping, discovery pivots, and memory summaries |

## Backup Compatibility Baseline

Flutter must treat the Electron JSON backup as the first migration contract.

Required first fixture:

- Export one backup from the Electron app using [tests/e2e/backup.spec.ts](../tests/e2e/backup.spec.ts) semantics.
- Include two indexed fixture images.
- Include one memory with one member photo and a cover photo.
- Include authored caption, authored tags, favorite state, edit history, generated semantic fields, locale settings, and map settings.
- Store the sanitized fixture backup under
  [tests/fixtures/flutter-parity/chronopic-backup-v1.json](../tests/fixtures/flutter-parity/chronopic-backup-v1.json).
- Store expected derived counts under
  [tests/fixtures/flutter-parity/chronopic-backup-v1.expected.json](../tests/fixtures/flutter-parity/chronopic-backup-v1.expected.json).
- Refresh both fixture files with `pnpm run fixtures:flutter-parity`, which runs
  [scripts/write-flutter-parity-fixtures.mjs](../scripts/write-flutter-parity-fixtures.mjs).

The fixture must not contain real user paths, real API keys, or real personal
photos. Use deterministic temp-style paths and tiny synthetic image metadata.

## Accepted Platform Differences For First Flutter Release

These differences are acceptable for the first Flutter release if they are
documented in UI copy and tests.

- Desktop can keep folder registration as the primary library setup flow.
- Android and iOS should use photo-library permission flows and platform asset IDs instead of durable absolute file paths.
- Mobile restore may restore ChronoPic metadata before all original media assets are available.
- Mobile scan may require pause/resume and foreground progress where the OS restricts background work.
- Map availability may depend on platform WebView or native map SDK setup.
- Packaged Electron assets do not need to match Flutter packaging layout, but user data migration must work through the backup JSON path.

These differences are not acceptable:

- Dropping authored edits, favorites, memory metadata, memberships, or generated semantic fields during migration.
- Treating AI-generated suggestions as accepted user edits.
- Copying original media files during backup restore.
- Depending on Electron or Node as a permanent backend for Flutter.
- Removing the Electron reference app before the Flutter parity gates pass.

## Phase 0 Exit Gate

Phase 0 is complete only when these artifacts exist and pass static validation:

- This parity contract is reviewed and kept linked from [PLAN.md](../PLAN.md).
- The sanitized backup fixture and expected-count fixture exist under
  [tests/fixtures/flutter-parity/](../tests/fixtures/flutter-parity/).
- A short command or script exists to refresh the Electron reference backup fixture without real user data.
- The active Flutter Phase 1 plan can point to exact reference fixtures, expected counts, and existing Electron tests.
- `git diff --check` passes after the documentation and fixture changes.

Until those artifacts exist, the Flutter rewrite is considered started but not
ready for Dart domain implementation.
