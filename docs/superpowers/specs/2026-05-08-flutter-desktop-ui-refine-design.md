# Flutter Desktop UI Refine Design

## Goal

Refine the Flutter Linux desktop UI into a real desktop product surface that aligns with the current Electron reference app while preserving the Phase 5.5 parity behavior and verification gate.

## Current Problem

The Flutter UI currently proves behavior but is not a usable desktop experience:

- `chronopic_home.dart` is a 2300+ line monolith that mixes app state, localization, library setup, filters, grid, map, timeline, memory editing, AI settings, backup, detail editing, gallery, and media preview.
- The screen uses a default Material app bar plus a large scroll column, so controls for first-run setup, filtering, AI, backup, memory, and editing compete in one surface.
- The current layout does not match the Electron reference information architecture:
  left navigation,
  product home,
  memories page,
  memory detail page,
  settings page,
  notifications/AI work queue,
  browse mode toolbar,
  and focused viewer.

## Reference Model

The Electron UI in `packages/ui-components/src/photo-home.tsx` is the reference for this phase. The Flutter implementation should match its product structure, not its exact React/Tailwind implementation:

- persistent left sidebar with ChronoPic identity, library navigation, memories, settings, and notification count
- main content area with page routing: home, memories, memory detail, settings, notifications
- first-run panel when no library or no indexed photos exist
- guided next-step panel when photos exist but no memories exist
- browse toolbar with grid/map/timeline, search, filters, selection mode
- clean gallery grid with hover-like action equivalents for desktop Flutter
- focused detail/gallery dialog for deep viewing and editing
- settings page split into library, language, backup, AI, map, and source sections

## Design Requirements

1. Preserve behavior
- Keep all Phase 5.5 workflows working:
  library path entry, native picker entry points, scan, browse, search/filter/sort, map/timeline, details, caption/tags/datetime, rollback, favorites, memories, AI settings/queue/candidates, backup export/preview/restore, i18n, and gallery keyboard behavior.
- Keep existing test keys unless a test is intentionally updated in the same change.
- Keep the service/repository contracts unchanged unless a UI behavior requires a narrow app-service helper.

2. Split ownership
- `ChronoPicHome` should become a thin stateful shell that owns service calls and page state.
- UI files should be grouped by responsibility:
  `l10n`, `theme`, `shell`, `home`, `browse`, `filters`, `detail`, `gallery`, `memories`, `settings`, and shared widgets.
- A file should have one reason to change. No new large catch-all widget file should replace the old monolith.

3. Desktop layout quality
- Use a fixed-width desktop sidebar and a scrollable main content area.
- Keep settings, backup, AI, and memory management off the default browse surface.
- Use compact, scannable panels with consistent spacing, restrained colors, and clear hierarchy.
- Do not use oversized decorative hero sections that obscure the product workflow.
- The first viewport must make the app usable: navigation, browse mode, search/filter, and photo results must be obvious.

4. Visual system
- Add a Flutter theme/tokens layer for colors, text styles, panel shape, spacing, and status tones.
- Prefer icons for actions where familiar:
  folder, scan, search, filter, grid/map/timeline, favorite, rollback, backup, AI, settings.
- Use cards only for repeated items, settings panels, and tool surfaces. Avoid cards nested inside decorative cards.
- Ensure text does not overflow in navigation, buttons, chips, cards, or status rows at desktop and narrow widths.

5. Verification
- Add tests for shell structure and page navigation:
  sidebar, home, memories, memory detail, settings, notifications.
- Keep Linux desktop parity test passing.
- Add targeted assertions for the refined layout:
  first-run/guided panels are not mixed with settings panels,
  settings page contains backup/AI/source controls,
  home browse surface contains grid/map/timeline controls and active filters.
- Run the full Flutter gate before completion:
  Dart package tests,
  database tests,
  Dart analyzer,
  Flutter tests,
  Flutter analyzer,
  Linux debug build,
  and `git diff --check`.

## Accepted Non-Goals

- Do not implement mobile UI in this phase.
- Do not add new product features beyond UI restructuring and ergonomic refinement.
- Do not replace service/database/domain contracts for visual reasons.
- Do not remove the Electron app in this phase.
- Do not require pixel-perfect Tailwind parity; match information architecture, behavior, and desktop quality.

## Completion Criteria

- `chronopic_home.dart` is reduced to a readable orchestration shell.
- The Flutter desktop app has Electron-aligned navigation and page structure.
- Settings/backup/AI controls are moved out of the home browse surface.
- The home surface reads as a real desktop photo app, not a widget test harness.
- Existing Phase 5.5 parity workflows pass after the refactor.
- `PLAN.md` and `AGENTS.md` record the phase, verification commands, and remaining risks.
