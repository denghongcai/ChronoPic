# Flutter Mobile Native Experience Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Expand the mobile UI refine work from touch polish into a mobile-native ChronoPic experience. Mobile should keep the same local-first data model and core workflows as desktop, but it should no longer look or behave like a compressed desktop workspace.

**Architecture:** Keep domain, repository, service, backup, AI, memory, and release contracts shared. Split mobile presentation and navigation where the current desktop shell, inspector, and settings-panel assumptions make the phone experience dense or indirect. Android is the live target; iOS remains static-prepared but not live-verified until macOS/Xcode evidence exists.

**Source Input:** User-provided mobile UI refine proposal reviewed on 2026-05-11. Key direction: mobile needs a stronger divergence from desktop, with a native home dashboard, bottom navigation, media-first detail, grouped settings, and guided memory creation.

**Status:** Complete locally on 2026-05-11.

---

### Task 1: Define The Mobile Design Contract

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/theme/chronopic_theme.dart`
- Modify: `docs/flutter-mobile-ui-refine-audit.md`
- Modify: `docs/mobile-productization.md`

- [x] **Step 1: Codify mobile visual tokens**

Define mobile-specific usage guidance for:

- primary orange action color,
- neutral card backgrounds,
- 8-16px card radius depending on surface scale,
- 48px minimum touch targets,
- compact but readable type hierarchy,
- bottom safe-area padding,
- consistent icon-first actions.

- [x] **Step 2: Preserve desktop separately**

Document that mobile design tokens may diverge from desktop density and layout. Desktop parity remains functional, not visual, for this phase.

- [x] **Step 3: Add mobile visual regression expectations**

Add screenshot expectations for a 390x844 phone viewport and at least one tall Android emulator viewport.

### Task 2: Rebuild Mobile Shell And Home Information Architecture

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/shell/desktop_shell.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Replace top tab navigation with mobile shell navigation**

Move away from the current top-row All Photos / Favorites / Memories / Settings model on phones.

Use mobile shell structure:

- header with brand/avatar-style mark and notifications,
- search field directly below the header,
- shortcut cards for All Photos, Favorites, Memories, and Settings,
- scan progress card,
- Recent Memories section,
- bottom navigation for Waterfall, Map, Timeline, and Settings.

- [x] **Step 2: Make home shortcuts scope-aware**

All Photos, Favorites, and Memories should set the correct browse/memory scope without acting like desktop sidebar items.

- [x] **Step 3: Keep first-run mobile-first**

First-run remains photo-library first on Android. Desktop folder import must not appear in the first mobile viewport.

### Task 3: Mobile Search, Browse, And Filter Interaction

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/filters/filter_toolbar.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Make search a primary mobile affordance**

Search should be visible near the top of the mobile home/browse surface, with placeholder text that mentions photos, places, and people-like concepts only when supported by available searchable fields.

- [x] **Step 2: Move dense filters into a mobile sheet**

Sort, GPS-only, AI status, date range, tag, and clear/apply controls should use a mobile sheet or stacked surface instead of a desktop toolbar squeezed into the page.

- [x] **Step 3: Keep browse mode navigation stable**

Waterfall, Map, and Timeline remain primary browse modes from bottom navigation. Changing mode must preserve search/filter state.

### Task 4: Rebuild Mobile Detail And Gallery

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Make Detail media-first**

On phones, Detail should become a full-screen media-first route:

- top bar with back, index count, and more action,
- large media preview,
- floating favorite and add-to-memory actions,
- small filmstrip or adjacent navigation only when it does not crowd media,
- metadata/editing in bottom sheets or lower cards.

- [x] **Step 2: Remove desktop keyboard language from mobile**

Do not show `Esc`, `Left/Right`, `G`, or other desktop shortcut copy on mobile surfaces.

- [x] **Step 3: Keep edit feedback in the active surface**

Caption, tags, datetime, favorite, and memory actions must show feedback in Detail without relying on a hidden shell status banner.

### Task 5: Rebuild Mobile Settings As Grouped Lists

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/settings/settings_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Split mobile settings into grouped rows**

Replace long mobile panel stacks with grouped list sections:

- Library settings,
- Language,
- AI output language,
- Backup / restore,
- Map settings,
- Advanced local paths.

- [x] **Step 2: Drill into complex settings**

AI provider fields, map keys, backup file paths, and manual folder paths should open a subpage or bottom sheet instead of occupying the main mobile settings list.

- [x] **Step 3: Keep advanced desktop details available but de-emphasized**

Manual local path entry remains available for testing and desktop-like workflows, but it should not dominate mobile settings.

### Task 6: Add Guided Mobile Memory Creation

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify: `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`

- [x] **Step 1: Add a mobile Create Memory flow**

Add a guided flow:

1. Select photos,
2. edit title, description, and cover,
3. confirm and open the created memory.

- [x] **Step 2: Support selection-first memory authoring**

The flow should work from the home empty state, the Memories page, and selected browse photos.

- [x] **Step 3: Preserve existing memory lifecycle**

Existing add/remove photo, set cover, rename, delete, and memory detail flows must remain valid.

### Task 7: Evidence And Verification

**Files:**
- Modify: `docs/flutter-mobile-ui-refine-audit.md`
- Modify: `docs/mobile-e2e-verification.md`
- Modify: `AGENTS.md`

- [x] **Step 1: Extend widget tests**

Add or update mobile widget tests for:

- mobile shell/home shortcuts,
- bottom navigation,
- search/filter sheet,
- Detail media-first layout,
- mobile settings grouped rows,
- Create Memory wizard.

- [x] **Step 2: Refresh Android evidence**

Run Android deep E2E and capture screenshots/XML for first-run, scoped import, browse, detail, settings, memory creation, restart, and restore.

- [x] **Step 3: Keep iOS boundary explicit**

Do not claim iOS live verification until macOS/Xcode screenshots and signing/build evidence exist.

### Exit Gate

- Flutter analyze passes.
- Dart package tests pass.
- Flutter UI/mobile tests pass.
- Android debug build passes.
- Android deep E2E runner and artifact assertions pass.
- Mobile screenshots show no horizontal overflow at phone widths.
- Detail and Settings no longer expose desktop-specific layout/copy on mobile.
- `PLAN.md`, `docs/flutter-refactor-phases.md`, `docs/flutter-mobile-ui-refine-audit.md`, `docs/mobile-productization.md`, and `AGENTS.md` record the final evidence.

### Explicit Non-Goals

- Do not redesign Flutter Linux desktop in this phase.
- Do not add OCR, vector search, person recognition, cloud sync, or EXIF writeback.
- Do not change the release artifact model.
- Do not remove existing desktop parity tests.
- Do not claim iOS live readiness from Linux.

### Implementation Result

- Added mobile-specific theme tokens for card radius, touch target sizing,
  accent color, background, and surfaces.
- Replaced the phone top-tab shell with a mobile header and bottom navigation
  for Waterfall, Map, Timeline, and Settings.
- Added a mobile home dashboard with primary search, horizontal shortcut cards,
  and scan/catalog status.
- Moved mobile dense filters into a bottom sheet and kept active filter chips
  visible on mobile after applying filters.
- Reworked mobile focused Detail with explicit mobile topbar/media/action keys
  and removed desktop shortcut copy from the mobile Detail surface.
- Reworked Gallery chrome so phone widths use a compact title and icon action
  instead of overflowing desktop chip/button controls.
- Replaced mobile Settings panel stacks with grouped rows and bottom-sheet
  drill-in panels.
- Added a guided mobile Create Memory wizard and kept the post-create detail
  lifecycle for description, cover, add/remove photo, rename, and persistence.
- Updated mobile widget tests and the Android deep E2E test to cover the new
  mobile information architecture and persistence workflow.

### Verification Result

- `cd chronopic_flutter && flutter analyze`
- `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`
- `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`
- `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
- `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
- `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`
- `git diff --check`

Result:
all commands passed locally.
The integration test also caught and regressed the two phone-width overflow
risks that were fixed in this phase:
Gallery chrome and the mobile Language settings sheet.
iOS live verification remains blocked on this Linux workstation.
