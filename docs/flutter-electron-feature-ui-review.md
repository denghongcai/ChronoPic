# Flutter Electron Feature UI Review

## Review Rules

- Electron is the reference, but code and screenshot evidence must confirm the
  actual Electron behavior before declaring a contract.
- A screenshot match is not sufficient; behavior must be covered by existing
  tests or a named missing-test item.
- Do not classify a difference as accepted unless it is renderer-specific and
  does not affect workflow, hierarchy, or semantics.
- Confirmed gaps must be promoted to follow-up phases before implementation.

## Surface Checklist

| Surface | Reference Code Checked | Flutter Code Checked | Tests Checked | Screenshots Compared | Decision | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Empty first-run home | `scripts/capture-electron-parity.mjs` first launch path | `CHRONOPIC_CAPTURE_SURFACE=empty-home` | `chronopic_home_test.dart` shell smoke | `01-empty-home-compare.png` | Accepted Difference | Same first-run hierarchy, sidebar, setup CTA, recent memories empty state, and browse placeholder. Flutter exposes a denser lower placeholder in the first viewport; accepted as renderer/layout density only. |
| Populated grid/waterfall browse | Electron capture restore + Waterfall path | `HomePage` + `BrowseSurface` waterfall path | `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` | `02-populated-grid-compare.png` | Accepted Difference | Selection, grid cards, filters, memory highlights, and detail-first activation are aligned. Card proportions and Material/CSS control chrome differ. |
| Map browse / disabled-map state | Electron Map button capture path | `BrowseSurface` map mode | `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` map assertions | `03-map-compare.png` | Accepted Difference | Disabled-map/error state, mapped count, GPS selection, and controls are present. Flutter shows the mappable-photo lower panel higher in the viewport; accepted as density, not workflow. |
| Timeline browse | Electron Timeline button capture path | `BrowseSurface` timeline mode | `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` timeline assertions | `04-timeline-compare.png` | Accepted Difference | Year/month/day controls, grouping, selected-photo context, and open-detail path are aligned. Timeline card density differs. |
| Detail inspector and edits | Electron Detail dialog capture path | `DetailSurface` focused mode | `accessibility.spec.ts`, `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` | `05-detail-compare.png` | Accepted Difference | Detail-first overlay is aligned: media/filmstrip on the left, inspector/edit controls on the right, Gallery action switches mode inside the viewer. Styling and scroll position differ. |
| Fullscreen gallery | Electron Gallery dialog capture path | `GalleryDialog` | `accessibility.spec.ts`, `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` | `06-gallery-compare.png` | Accepted Difference | Gallery is the second viewer mode, not the initial double-click target. `D`, Detail View, Open Inspector, arrows, filmstrip, and Escape are covered. Media frame and button chrome differ. |
| Favorites filter | Electron Favorites sidebar capture path | `_showFavorites()` + favorite filter | `linux_desktop_parity_test.dart` favorite flow | `07-favorites-compare.png` | Accepted Difference | Favorite toggling/filtering and detail-first card activation are aligned. Layout density differs. |
| Memories list | Electron See All memories capture path | `MemoryListPage` | `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` memory candidate flow | `08-memories-list-compare.png` | Accepted Difference | Suggested-memory generation, Adjust photos, Reject, Accept Memory, and collection cards are aligned. Candidate/card dimensions differ. |
| Memory detail management | Electron memory-card capture path | `MemoryDetailPage` | `chronopic_home_test.dart`, `linux_desktop_parity_test.dart` memory CRUD/cover/remove flow | `09-memory-detail-compare.png` | Accepted Difference | Hero, cover status, description/story, chapters, add/remove, set cover, save memory, and navigation are aligned. Chip styling and spacing differ. |
| Settings | Electron Settings nav capture path | `SettingsPage` | `chronopic_home_test.dart`, `linux_desktop_parity_test.dart`, Electron backup/i18n tests | `10-settings-compare.png` | Accepted Difference | Library, scan, language, backup/restore, AI, and map settings are present. Flutter exposes more lower settings in the first viewport; accepted as density. |
| Notifications / AI queue | Electron Notifications nav capture path | `NotificationsPage` | `ai-productization.spec.ts`, `chronopic_home_test.dart` candidate flow | `11-notifications-compare.png` | Accepted Difference | AI queue readiness, retry, memory candidates, semantic chips, and handoff are aligned. Button colors and spacing differ. |
| Chinese locale | Electron zh restart capture path | Flutter `UiStrings` plus localized visible strings | `i18n.spec.ts`, `chronopic_home_test.dart` zh shell and app-owned surface coverage | `12-zh-locale-compare.png` | Accepted Difference | Phase 5.10 localizes Flutter app-owned zh UI across selected-photo banners, active filter labels, Detail/Gallery controls, memory actions, settings actions, notifications, map/timeline controls, and status messages. Accepted difference: fixture-authored filenames, memory names, captions, imported descriptions, and AI text remain source content. |
| Restart persistence | Electron same-user-data restart capture path | Flutter backup restore launch path | `runtime.spec.ts`, `linux_desktop_parity_test.dart` backup/restore flow | `13-restart-persistence-compare.png` | Accepted Difference | Restored library, selected photo context, favorite/memory/settings state, and detail-first activation remain aligned. Card density differs. |

## Findings

### P66-001: Flutter parity captures used zh locale for normal English surfaces

- Severity:
  Medium for desktop parity evidence integrity.
- Evidence:
  Phase 6.6 contact-sheet review showed normal Flutter surfaces such as
  populated browse,
  map,
  timeline,
  detail,
  gallery,
  favorites,
  memories,
  settings,
  and notifications rendering app-owned Chinese UI while the Electron reference
  screenshots for the same surfaces rendered English.
- Cause:
  `tests/fixtures/flutter-parity/chronopic-backup-v1.json` intentionally stores
  `zh-CN` locale settings for locale and restart-persistence coverage.
  `scripts/capture-electron-parity.mjs` overrides normal fixture restores to
  English,
  but `chronopic_flutter/tool/capture_flutter_parity.sh` copied the fixture
  directly for every non-empty surface.
- Fix:
  `chronopic_flutter/tool/capture_flutter_parity.sh` now writes a temporary
  `en-US` / `follow-ui` backup copy for normal fixture-backed captures,
  while preserving the fixture's persisted zh settings for `zh-locale` and
  `restart-persistence`.
- Closure evidence:
  the affected Flutter surfaces were recaptured,
  all 13 compare artifacts were regenerated,
  and
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-6-6.png`
  now shows normal surfaces in English on both sides while zh-specific surfaces
  remain Chinese.
- Decision:
  closed by Phase 6.6 as a capture-harness gap,
  not a product UI gap.

### P66-002: Playwright E2E output cleanup removed parity evidence

- Severity:
  Medium for desktop parity evidence retention.
- Evidence:
  after the Phase 6.6 Electron E2E verification commands ran,
  `test-results/flutter-electron-parity/` no longer contained the refreshed
  parity PNGs,
  and only Playwright's `.last-run.json` remained under `test-results/`.
- Cause:
  `tests/e2e/playwright.config.ts` did not set `outputDir`,
  so Playwright used its default root `test-results` output directory and
  cleaned that directory before runs.
  The parity capture system also writes under `test-results/`,
  so the two evidence families conflicted.
- Fix:
  `tests/e2e/playwright.config.ts` now writes Playwright artifacts under
  `test-results/playwright-artifacts`,
  leaving `test-results/flutter-electron-parity/` available for durable
  Electron-vs-Flutter screenshot evidence.
- Closure evidence:
  Phase 6.6 recaptures parity screenshots after this fix,
  reruns the Electron E2E gates,
  and rechecks that Electron,
  Flutter,
  and compare PNG evidence still exists with the expected counts and
  dimensions.
- Decision:
  closed by Phase 6.6 as a test-harness evidence-retention gap.

### FUI-001: Flutter zh locale contained app-owned English strings

- Severity:
  High for locale/UI parity.
- Evidence:
  `test-results/flutter-electron-parity/compare/12-zh-locale-compare.png`
  shows Electron rendering the selected-photo banner in Chinese while Flutter
  renders `SELECTED PHOTO` and
  `This photo is not saved to any memory yet.`.
- Flutter code evidence:
  `chronopic_flutter/packages/chronopic_ui/lib/src/home/home_page.dart`
  hardcodes the selected-photo banner text.
- Additional static evidence:
  `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart`
  hardcodes active filter labels and status strings;
  `detail/detail_surface.dart` and `gallery/gallery_dialog.dart` hardcode
  Detail/Gallery overlay controls;
  `memories/memory_pages.dart` hardcodes memory-candidate and memory-detail
  actions;
  `settings/settings_pages.dart` hardcodes some settings actions and source
  status text;
  `browse/browse_surface.dart` hardcodes some map/timeline actions.
- Test gap:
  existing Flutter zh coverage checks the shell, settings controls, and browse
  filters, but it does not assert that selected-photo banners, active filter
  chips, viewer overlays, memory actions, settings actions, notifications, or
  status messages are free of app-owned English text.
- Decision:
  closed by Phase 5.10.
  Flutter now localizes the selected-photo banner,
  active filter labels,
  Detail/Gallery controls,
  memory actions,
  settings actions,
  notifications,
  map/timeline controls,
  and status messages in zh mode,
  while preserving source-authored fixture/user content.
- Closure evidence:
  `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
  includes a zh app-owned surface regression test that failed before the fix
  and passes after implementation.
  `test-results/flutter-electron-parity/compare/12-zh-locale-compare.png`
  now shows the Flutter selected-photo banner in Chinese.

## Accepted Renderer Differences

- Flutter Material and Electron CSS do not share a pixel-identical component
  system, so exact card heights, button chrome, chip color, and scroll density
  are accepted only when the workflow and hierarchy are preserved.
- Flutter often exposes lower sections slightly earlier in the first viewport
  because its desktop layout is denser. This is accepted for Map, Settings, and
  first-run Home after confirming the primary controls remain aligned.
- Fixture-authored content such as memory names, captions, filenames, and
  imported descriptions is source data and should not be translated as UI.

## Evidence Commands

```bash
node scripts/capture-electron-parity.mjs
file test-results/flutter-electron-parity/electron/*.png
```

```bash
cd chronopic_flutter
bash tool/capture_flutter_parity.sh all
file ../test-results/flutter-electron-parity/flutter/*.png
```

```bash
mkdir -p test-results/flutter-electron-parity/compare
for name in 01-empty-home 02-populated-grid 03-map 04-timeline 05-detail 06-gallery 07-favorites 08-memories-list 09-memory-detail 10-settings 11-notifications 12-zh-locale 13-restart-persistence; do
  montage "test-results/flutter-electron-parity/electron/${name}.png" "test-results/flutter-electron-parity/flutter/${name}.png" -tile 2x1 -geometry +24+0 "test-results/flutter-electron-parity/compare/${name}-compare.png"
done
file test-results/flutter-electron-parity/compare/*.png
```

## Phase 6.6 Refresh

- Refreshed after Phase 6.5 on 2026-05-10.
- Electron screenshots:
  `test-results/flutter-electron-parity/electron/*.png`.
- Flutter screenshots:
  `test-results/flutter-electron-parity/flutter/*.png`.
- Compare screenshots:
  `test-results/flutter-electron-parity/compare/*-compare.png`.
- Contact sheet:
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-6-6.png`.
- Evidence count:
  Electron `13`,
  Flutter `13`,
  compare `13`.
- Dimensions:
  Electron and Flutter captures are 1440x920;
  compare artifacts are 2976x920.
- Review decision:
  no new product UI/function gap was found after closing `P66-001` and
  `P66-002`.

## Verification Gate

Passed after the Phase 5.10 implementation:

```bash
cd chronopic_flutter
dart analyze packages/chronopic_ui apps/chronopic
flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart
cd ..
pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts
git diff --check
```
