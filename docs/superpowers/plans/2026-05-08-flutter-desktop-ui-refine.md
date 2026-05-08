# Flutter Desktop UI Refine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace the current Flutter desktop test-shell UI with an Electron-aligned, componentized desktop product interface.

**Architecture:** Keep `ChronoPicHome` as the service/state orchestration boundary, but split rendering into focused widgets under `chronopic_flutter/packages/chronopic_ui/lib/src/`. Rebuild the Flutter shell around Electron's page model: sidebar, home browse page, memories page, memory detail page, settings page, notifications/AI page, and focused viewer.

**Tech Stack:** Flutter Material 3, Dart workspace packages, existing `chronopic_app` service APIs, existing `chronopic_domain` DTOs, `file_selector`, `flutter_test`.

---

## File Structure

- Modify `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`: reduce to state, service actions, page routing, and composition only.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/l10n/ui_strings.dart`: UI locale enum and translations.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/theme/chronopic_theme.dart`: Material theme, colors, panel helpers, status tones.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/shell/desktop_shell.dart`: sidebar, top status banner, page frame.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`: first-run/guided panels, browse toolbar, active filters, browse surface composition.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/home/library_toolbar.dart`: library path, folder picker, scan, search.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/filters/filter_toolbar.dart`: tag/GPS/AI/date/sort controls.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`: grid/map/timeline switching and browse mode selector.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/browse/photo_card.dart`: desktop photo card and media preview.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`: selected-photo metadata, edit controls, gallery/favorite/rollback actions.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`: focused fullscreen gallery.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`: memory list/detail/edit/add/remove/cover flows.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/settings/settings_page.dart`: library/language/backup/AI/map/source panels.
- Create `chronopic_flutter/packages/chronopic_ui/lib/src/settings/ai_status_panel.dart`: AI readiness, queue counts, candidate actions.
- Modify `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`: add shell/page navigation tests and update text expectations.
- Modify `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`: preserve parity flow with new page navigation.
- Modify `PLAN.md`, `AGENTS.md`, and `docs/flutter-refactor-phases.md`: add and track this UI refine phase.

Implementation note:
the landed split keeps related secondary widgets in their page-owned Dart part modules when a separate file would only add import churn.
The resulting ownership boundaries are still separated by product surface:
shell,
home,
filters,
browse,
detail,
gallery,
memories,
settings,
localization,
and theme.

## Task 1: Record The UI Refine Phase

- [x] Add a new phase entry to `PLAN.md` after Phase 5.5 named `Flutter Desktop UI Refine And Component Parity Phase`.
- [x] Add a matching phase entry to `docs/flutter-refactor-phases.md`.
- [x] Add an `AGENTS.md` step recording the design and plan paths.
- [x] Run `git diff --check`.

## Task 2: Extract Localization And Theme

- [x] Move `_UiLocale`, `_UiStrings`, and `_uiStrings` into `l10n/ui_strings.dart`, renaming them to `UiLocale`, `UiStrings`, and `uiStrings`.
- [x] Add `ChronoPicTheme` in `theme/chronopic_theme.dart` with a Material 3 light theme, panel radius, sidebar width, and status colors.
- [x] Update `ChronoPicHome` to import `uiStrings` and use `ChronoPicTheme.light`.
- [x] Run `dart format chronopic_flutter/packages/chronopic_ui/lib/src`.
- [x] Run `dart analyze packages/chronopic_ui`.

## Task 3: Split Shared Browse And Detail Widgets

- [x] Move media preview and photo-card rendering into `browse/photo_card.dart`.
- [x] Move browse mode selector, grid, map, and timeline surfaces into `browse/browse_surface.dart`.
- [x] Move detail metadata and edit controls into `detail/detail_surface.dart`.
- [x] Move focused gallery into `gallery/gallery_dialog.dart`.
- [x] Keep current test keys: `photo-card-*`, `media-preview-*`, `video-preview-*`, `browse-mode-control`, `map-view`, `timeline-view`, `detail-favorite-button`, `rollback-button`, `gallery-dialog`.
- [x] Run `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`.

## Task 4: Build Electron-Aligned Desktop Shell

- [x] Add `DesktopShell`, `DesktopSidebar`, and page enum in `shell/desktop_shell.dart`.
- [x] Replace the top `AppBar` + `NavigationRail` structure with persistent left sidebar and scrollable main area.
- [x] Sidebar entries must include All Photos, Favorites, Memories, Settings, and Notifications with icon affordances.
- [x] Move backup and restore top-bar actions to Settings; keep test keys on their buttons inside settings.
- [x] Add notification badge count from AI queue states and pending memory candidates.
- [x] Add tests that navigate to Settings, Notifications, Memories, and back to All Photos.
- [x] Run `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`.

## Task 5: Rebuild Home Page

- [x] Add `HomePage` in `home/home_page.dart`.
- [x] Show a first-run panel only when no sources or no indexed photos exist.
- [x] Show a guided next-step panel when photos exist and memories are empty.
- [x] Keep the normal browse page focused on browse mode, search, filters, active filters, and result grid/map/timeline.
- [x] Move library controls into a compact toolbar and keep `library-path-field`, `choose-library-folder-button`, `add-library-button`, `scan-library-button`, and `search-field`.
- [x] Ensure AI, backup, and map settings are not rendered on the home browse surface.
- [x] Run `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`.

## Task 6: Build Settings And Notifications Pages

- [x] Add `SettingsPage` with sections for library actions, language, backup, AI settings, map settings, source list, and library stats.
- [x] Keep backup keys: `backup-path-field`, `choose-backup-export-path`, `choose-backup-restore-path`, `export-backup-file`, `preview-backup-file`, `restore-backup-file`.
- [x] Keep AI keys: `ai-provider-field`, `ai-base-url-field`, `ai-model-field`, `ai-api-key-field`, `save-ai-settings-button`, `retry-ai-queue-button`, `accept-candidate-*`, `reject-candidate-*`.
- [x] Add `NotificationPage` showing AI readiness, queue counts, memory candidates, and retry/action controls.
- [x] Update parity tests to navigate to Settings before backup actions and to Notifications before candidate actions if needed.
- [x] Run `flutter test packages/chronopic_ui`.

## Task 7: Rebuild Memories Pages

- [x] Add `MemoryListPage` and `MemoryDetailPage` in `memories/memory_pages.dart`.
- [x] Move memory creation, selection, rename, description, set cover, add/remove selected photo actions out of the browse toolbar.
- [x] Keep keys used by parity tests: `memory-name-field`, `create-memory-button`, `add-to-memory-button`, `memory-detail-panel`, `memory-title-field`, `memory-description-field`, `save-memory-button`, `set-memory-cover-button`, `remove-from-memory-button`.
- [x] Ensure selecting a memory opens detail page rather than only filtering the gallery.
- [x] Run `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`.

## Task 8: Visual Polish Pass

- [x] Apply consistent spacing, rounded panel shapes, status banners, icons, and typography from `ChronoPicTheme`.
- [x] Replace raw dense `Wrap` surfaces with named panels and compact tool rows.
- [x] Verify no button text overflows at 1600x1200 and 840x1200 test sizes.
- [x] Add widget assertions for sidebar presence, page titles, and settings/home separation.
- [x] Run `flutter test packages/chronopic_ui`.

## Task 9: Full Verification And Documentation

- [x] Run:

```bash
cd chronopic_flutter
dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app
cd packages/chronopic_database && dart test test/repository_test.dart test/drift_database_test.dart
cd ../..
dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui
flutter test packages/chronopic_ui apps/chronopic
flutter analyze packages/chronopic_ui apps/chronopic
cd apps/chronopic && flutter build linux --debug
cd ../../..
git diff --check
```

- [x] Update `PLAN.md` with verification results.
- [x] Update `AGENTS.md` with changed files, verification commands, and remaining risks.
- [x] Commit and push `flutter-refactor-phases`.

Closeout note:
commit/push is performed after this plan is marked with implementation and verification evidence.

Screenshot follow-up:
after `xvfb-run` and `scrot` became available locally,
the Linux debug bundle was launched under Xvfb with `LIBGL_ALWAYS_SOFTWARE=1`,
and the real app window was captured at
`test-results/flutter-ui-refine-xvfb-window.png`.

## Self-Review

- Spec coverage: every design requirement maps to tasks 2-9.
- Placeholder scan: no `TBD` or unspecified implementation placeholders remain.
- Type consistency: plan uses existing Flutter package names and existing test keys.
