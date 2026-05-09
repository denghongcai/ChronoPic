# Flutter Visible String Localization Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development for each visible-string repair and superpowers:verification-before-completion before marking the phase complete.

**Goal:** Bring Flutter desktop Chinese-locale UI parity up to the Electron reference by removing app-owned English strings from zh mode while preserving source-authored user content.

**Architecture:** Keep Flutter localization in the existing `UiStrings` layer and existing `_localized(labels, en, zh)` call pattern. Do not translate filenames, captions, memory names, imported descriptions, or other fixture/user-authored data. The Flutter desktop UI should localize shell controls, banners, active filters, status messages, viewer controls, memory actions, settings actions, notifications, map controls, and timeline actions.

**Confirmed Gap:** `docs/flutter-electron-feature-ui-review.md` finding `FUI-001`.

---

## Files

- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/l10n/ui_strings.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/detail/detail_surface.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/lib/src/settings/settings_pages.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
- Modify:
  `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`
- Update:
  `docs/flutter-electron-feature-ui-review.md`
- Update:
  `docs/flutter-electron-ui-functional-parity.md`
- Update:
  `PLAN.md`
- Update:
  `docs/flutter-refactor-phases.md`
- Update:
  `AGENTS.md`

## Task 1: Add Failing Locale Coverage

- [x] Add a zh test that selects a photo on the browse surface and asserts:
  `已选照片` is visible,
  `这张照片还没有保存到任何记忆。` is visible,
  and app-owned English `SELECTED PHOTO` is absent.
- [x] Add zh assertions for active filter chips:
  search,
  tag,
  GPS-only,
  AI status,
  favorites,
  memory,
  sort,
  from date,
  and to date.
- [x] Add zh assertions for Detail and Gallery focused surfaces:
  mode labels,
  switch controls,
  keyboard hints,
  inspector/open-gallery/open-detail actions,
  edit/save/rollback controls,
  and metadata prefixes.
- [x] Add zh assertions for Memory list/detail:
  Generate,
  Adjust photos,
  Reject,
  Accept Memory,
  Save Memory,
  Set Cover,
  Remove from Memory,
  empty-state text,
  and chapter labels.
- [x] Add zh assertions for Settings, Notifications, Map, Timeline, and status
  messages that currently have hardcoded English paths.

## Task 2: Localize Flutter UI Strings

- [x] Extend `UiStrings` only where reusable named strings are needed.
- [x] Replace one-off strings with `_localized(labels, en, zh)` where that
  matches the current code style and avoids unnecessary API expansion.
- [x] Localize status messages in `ChronoPicHome` while preserving interpolated
  source data such as paths, memory names, counts, and error text.
- [x] Keep source-authored values untranslated:
  filenames,
  memory names,
  captions,
  imported descriptions,
  labels/tags,
  and fixture-authored AI text.

## Task 3: Refresh Visual Evidence

- [x] Capture Flutter focused zh surfaces:

  ```bash
  cd chronopic_flutter
  bash tool/capture_flutter_parity.sh zh-locale detail gallery settings notifications memories-list memory-detail map timeline
  ```

- [x] Refresh Electron reference screenshots if the capture script or fixture
  state changed.
- [x] Regenerate compare artifacts for all affected surfaces.
- [x] Inspect the affected compare images and update both review docs.

## Task 4: Verification Gate

- [x] Run:

  ```bash
  cd chronopic_flutter
  dart analyze packages/chronopic_ui apps/chronopic
  flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart
  cd ..
  git diff --check
  ```

- [x] If any Electron-facing parity text changed in shared fixtures or docs,
  also run:

  ```bash
  pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts
  ```

Verification results on 2026-05-09:

- `dart analyze packages/chronopic_ui apps/chronopic` passed with no issues.
- `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  passed with 13 tests.
- `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts`
  passed with 2 tests.
- `git diff --check` passed.

## Completion Criteria

- `FUI-001` is closed in `docs/flutter-electron-feature-ui-review.md`.
- The Chinese-locale row in `docs/flutter-electron-ui-functional-parity.md`
  returns to `Accepted Difference` or `Matched` with test evidence.
- Updated compare screenshots show no app-owned English UI on zh surfaces except
  source-authored user/fixture content.
- `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and `AGENTS.md`
  record the completed phase and verification results.
