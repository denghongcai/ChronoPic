# Agent Step Log — Flutter Line (Steps 101+)

Archived from `AGENTS.md`. Chronological execution record from Step 101 onward:
late Electron-line phases (4.17-4.26) plus the full Flutter rewrite line.
Follow `AGENTS.md` Working Rules for where new steps are appended.

- Reviewed the current roadmap after the completed i18n/date-localization work and confirmed that the previously planned product-expansion sequence is largely landed.
- Updated `PLAN.md` to make the next primary phase explicit:
  `Runtime QA and Release Readiness Phase` (then numbered `4.18`, later shifted to `4.19` after the UX refine phase was inserted).
- Scoped the runtime QA phase around real Electron/runtime validation rather than another product expansion:
  temporary app data,
  fixture media,
  real preload bridge,
  SQLite persistence,
  scan/browse/edit/memory/locale workflows,
  CI verification,
  and a root README/developer handoff.
- Added `First-Run and Onboarding UX Phase` as the next product-oriented direction after runtime QA (now numbered `4.20`).
- Added a `Future Product Backlog` section to keep candidate directions discoverable without treating them as approved implementation phases:
  person/face grouping,
  OCR,
  vector search,
  export/backup/restore,
  packaged desktop release,
  large-library performance,
  accessibility audit,
  and sidecar metadata import/export.
- No implementation code changed in this step.
- Next: begin the newly inserted UX refine phase before runtime QA.

### 2026-05-06 Step 102

- Inserted a new `4.18 UX Refine and Lazyweb Research Phase` before runtime QA in `PLAN.md`.
- Shifted the previously planned runtime QA phase to `4.19 Runtime QA and Release Readiness Phase`.
- Shifted the first-run onboarding direction to `4.20 First-Run and Onboarding UX Phase`.
- Updated the roadmap priority order so UX research/refinement happens before the real Electron/database runtime-readiness pass.
- Scoped the new UX phase around using Lazyweb as the research source of record:
  current-state screenshots,
  desktop-focused Lazyweb design research,
  a saved research report under `.lazyweb/design-research/chronopic-ux-refine-YYYY-MM-DD/`,
  a prioritized UX issue inventory,
  and only the top `must fix before runtime QA` implementation items.
- Explicitly constrained the phase to existing-product refinement:
  hierarchy,
  action density,
  empty states,
  browse-mode discoverability,
  memory authoring ergonomics,
  AI affordance prominence,
  notification usefulness,
  and settings clarity.
- Kept future feature candidates in the backlog rather than promoting them to implementation phases.
- No implementation code changed in this step.
- Next: execute `4.18` by running the Lazyweb research pass and producing the UX issue inventory before touching UI code.

### 2026-05-06 Step 103

- Executed the `4.18 UX Refine and Lazyweb Research Phase` first pass.
- Used the installed Lazyweb design-research skill structure, but recorded that Lazyweb MCP tools were not exposed as callable tools in the current Codex runtime.
- Created `.lazyweb/design-research/chronopic-ux-refine-2026-05-06/` with:
  `capture-notes.md`,
  picsum-based fixture images,
  current-state screenshots for empty home, populated waterfall, timeline, map, memories, memory-created state, notifications, settings, and focused viewer,
  `report.md`,
  and `report.html`.
- Grounded the fallback research in external UX references for empty states and navigation, then produced a prioritized issue inventory.
- Identified the top must-fix item before runtime QA:
  the empty first-run home read like a filter failure rather than a local-library setup path.
- Next: implement the first-run/empty-library refinement before completing runtime QA.

### 2026-05-06 Step 104

- Implemented the top `4.18` refinement and the first pass of `4.20 First-Run and Onboarding UX Phase`.
- Added a home-page first-run panel in `packages/ui-components/src/photo-home.tsx`.
- The panel now shows:
  `Add Folder` when there are no registered library sources,
  and `Scan Library` when sources exist but no photos have been indexed.
- Added localized onboarding strings in `packages/i18n/src/locales/en-US.ts` and `packages/i18n/src/locales/zh-CN.ts`.
- Kept the change in the UI/i18n layer and preserved existing IPC, database, package, and indexing contracts.
- Next: finish runtime QA with a real Electron/preload/SQLite integration path.

### 2026-05-06 Step 105

- Implemented the first pass of `4.19 Runtime QA and Release Readiness Phase`.
- Added `apps/desktop/main/paths.ts` and wired `CHRONOPIC_USER_DATA_DIR` into the desktop runtime, config store, thumbnail cache, database path, and debug log path so tests can isolate app state.
- Fixed new empty-database startup by applying the SQLite schema before running migrations in `ChronoPicDatabase`.
- Added `apps/desktop/main/electron-thumbnail-service.ts` and changed the Electron runtime to generate thumbnails through `nativeImage`, avoiding a `sharp` Node ABI mismatch inside Electron.
- Updated `scripts/ensure-native-modules.mjs` so the native rebuild guard tracks both `better-sqlite3` and `sharp` correctly.
- Fixed production renderer loading by setting Vite `base: "./"` so Electron `loadFile()` resolves built JS/CSS assets relative to `index.html`.
- Added `tests/e2e/runtime.spec.ts` and root scripts:
  `pnpm run e2e`,
  `pnpm run e2e:runtime`.
- The runtime E2E now launches the built Electron app with isolated user data, indexes deterministic fixture images, exercises caption/tag/datetime edit and rollback, favorites, memory creation/add, locale persistence, restarts the app, and verifies persisted state through the preload bridge.
- Added root `README.md` with setup, launch, verification, data-dir override, AI, map, and project-layout guidance.
- Added `.github/workflows/ci.yml` with install, test, typecheck, build, Playwright install, and runtime E2E under `xvfb-run`.
- Verified:
  `pnpm typecheck`
  `pnpm build`
  `pnpm run e2e:runtime`
  `pnpm test`
- Result: phases `4.18`, `4.19`, and the first critical `4.20` onboarding slice have landed locally.
- Next: re-run the final verification set after the documentation updates, then decide whether to continue into deeper guided memory onboarding or leave it in backlog.

### 2026-05-06 Step 106

- Reframed the requested agent verification "script" as a director-style Markdown document rather than an executable `.mjs` script.
- Added `docs/agent-verification-script.md`.
- The document tells future code agents when to run the verification script:
  after completing any `PLAN.md` phase, phase checklist item, or meaningful implementation slice,
  and before marking the work complete in `PLAN.md` / `AGENTS.md`.
- The director script defines Playwright-guided verification scenes for:
  launch and first impression,
  first-run/library setup,
  scan and browse,
  focused viewing,
  editing/favorites/rollback,
  memories,
  restart persistence,
  settings/locale/AI/map,
  and notifications/AI queue.
- Updated the `AGENTS.md` Working Rules to require future agents to follow `docs/agent-verification-script.md` and record scenes, commands, evidence, and skipped-scene reasons.
- Updated `README.md` and `PLAN.md` to point to the Markdown director script as the supplemental project-verification guidance.
- Removed the previously added executable agent verifier direction from the repo plan/docs in favor of the Markdown agent script.
- This correction is docs/process-only, so the Playwright runtime scenes in `docs/agent-verification-script.md` were not run; there was no runtime/UI behavior change to inspect.
- Verified:
  `pnpm test`
  `pnpm typecheck`
- Result: future agents now have a Markdown director script and `AGENTS.md` requires using it after completed plan slices.
- Next: commit the documentation correction when requested.

### 2026-05-06 Step 107

- Opened and completed `4.21 Guided Onboarding Completion Phase` in `PLAN.md`.
- Implemented the post-scan onboarding slice in `packages/ui-components/src/photo-home.tsx`.
- When photos are indexed but no memories exist, the home surface now replaces the empty Recent Memories card with a compact next-step panel.
- The panel guides the user toward:
  creating the first memory,
  entering photo selection mode,
  reviewing memory suggestions when candidates exist,
  and opening optional setup for AI/map/language configuration.
- Existing users with memories continue to see the normal Recent Memories surface instead of onboarding.
- Added localized strings for the new guided next-step panel in:
  `packages/i18n/src/locales/en-US.ts`
  and `packages/i18n/src/locales/zh-CN.ts`.
- Followed `docs/agent-verification-script.md` for this user-facing runtime flow.
- Playwright director scenes run with a temporary Electron data directory:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 6 - Memories,
  Scene 7 - Restart Persistence.
- Director-script evidence:
  screenshots written under `/tmp/chronopic-421-verify-UtYkDs`,
  fixture directory `/tmp/chronopic-421-fixtures-L2LUOB`,
  user data directory `/tmp/chronopic-421-userdata-cAtuLu`,
  3 fixture photos indexed,
  1 memory created from the onboarding panel,
  source/photo/memory state verified after Electron restart.
- Verified:
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
  `pnpm run e2e:runtime`
- Result: 4.21 is landed and verified locally.
- Next: commit and push the phase.

### 2026-05-06 Step 108

- Opened and completed `4.22 Accessibility and Keyboard Audit Phase` in `PLAN.md`.
- Used a TDD pass for the new accessibility coverage:
  the first Playwright accessibility spec failed because closing the Create Memory dialog with `Escape` did not restore focus to the trigger,
  then the implementation restored focus and the spec passed.
- Added focused accessibility and keyboard fixes in `@chronopic/ui-components`:
  Create Memory dialog focus restoration,
  photo-card keyboard activation with `Space` and `Enter`,
  selected-state `aria-pressed` metadata,
  accessible names for photo cards,
  and clearer filmstrip selected-state semantics.
- Added `tests/e2e/accessibility.spec.ts` and the root verification script:
  `pnpm run e2e:accessibility`.
- Added the accessibility E2E gate to `.github/workflows/ci.yml` and documented it in `README.md`.
- Followed `docs/agent-verification-script.md` for this user-facing runtime flow.
- Playwright director scenes run with a temporary Electron data directory:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 4 - Focused Viewing,
  Scene 6 - Memories,
  Scene 7 - Restart Persistence.
- Director-script evidence:
  screenshots written under `/tmp/chronopic-422-verify-ZBDIw5`,
  fixture directory `/tmp/chronopic-422-fixtures-8cn5II`,
  user data directory `/tmp/chronopic-422-userdata-Cy80pf`,
  2 fixture photos indexed,
  1 memory created,
  focus restoration and restart persistence verified.
- Verified:
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
  `pnpm run e2e:runtime`
  `pnpm run e2e:accessibility`
- Result: 4.22 is landed and verified locally.
- Next: decide whether to commit/push this phase or continue into the next roadmap slice.

### 2026-05-06 Step 109

- Opened and completed `4.23 Export, Backup, and Restore Phase` in `PLAN.md`.
- Used a TDD pass for the core backup contract:
  `tests/backup.test.ts` first failed because `ChronoPicAppService.createBackup()` and `previewBackupRestore()` did not exist,
  then passed after the backup service/database implementation landed.
- Added a versioned ChronoPic JSON backup format in `packages/domain`.
- Added backup support through the application, database, and config layers:
  export local projection data,
  restore-preview counts,
  conflict reporting for sources/photos/memories/memory candidates,
  replace-mode restore,
  settings export,
  and settings restore.
- Backup contents now include:
  library sources,
  photo projections,
  metadata,
  semantic/generated fields,
  index state,
  edit history,
  memories,
  memory-photo membership,
  memory candidates,
  AI settings,
  map settings,
  and locale settings.
- Added desktop main/preload bridge methods:
  `exportBackup`,
  `previewBackupRestore`,
  and `restoreBackup`.
- Added Library Settings controls for:
  `Export Backup`,
  `Preview Restore`,
  and `Restore Backup`,
  with localized English and Simplified Chinese copy explaining that backups are local JSON and do not copy original media files.
- Added `tests/e2e/backup.spec.ts` and the root script:
  `pnpm run e2e:backup`.
- Added backup E2E coverage to `.github/workflows/ci.yml` and documented the backup/restore flow in `README.md`.
- Fixed a local verification reliability issue discovered during testing:
  Node unit tests and Electron E2E require different native ABIs for `better-sqlite3`,
  so `pnpm test` now prepares the Node ABI and E2E scripts now prepare the Electron ABI before launching.
- Followed `docs/agent-verification-script.md` for this user-facing data-safety flow.
- Playwright director scenes run with temporary Electron data directories:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 5 - Editing, Favorites, And Rollback,
  Scene 6 - Memories,
  Scene 7 - Restart Persistence,
  Scene 8 - Settings, Locale, AI, And Map.
- Director-script evidence:
  screenshots and `evidence.json` written under `/tmp/chronopic-423-verify-Y5z1Ih`,
  fixture directory `/tmp/chronopic-423-fixtures-ZIxODw`,
  source user data directory `/tmp/chronopic-423-source-userdata-GyZUBu`,
  target user data directory `/tmp/chronopic-423-target-userdata-XeBwFj`,
  backup file `/tmp/chronopic-423-verify-Y5z1Ih/chronopic-423-backup.json`,
  2 fixture photos indexed,
  1 memory created,
  rollback verified,
  restore-preview conflicts verified in the source library,
  zero-conflict preview verified in the clean target library,
  and restored target data verified for photos, favorites, caption, tags, memory membership, locale, and map settings.
- Verified:
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
  `pnpm run e2e:runtime`
  `pnpm run e2e:accessibility`
  `pnpm run e2e:backup`
  `git diff --check`
- Result: 4.23 is landed and verified locally.
- Next: decide whether to commit/push this phase or promote the next backlog item.

### 2026-05-06 Step 110

- Recorded the product-priority decision that large-library performance optimization should not be promoted as the next phase.
- Updated `PLAN.md` so the `Large-library performance pass` remains explicitly in the Future Product Backlog and is marked as deprioritized on 2026-05-06.
- This is a planning-only update; no runtime code changed.
- Verified:
  `git diff --check`
- Next: choose a different next phase candidate, likely packaged desktop release readiness or another backlog item.

### 2026-05-06 Step 111

- Promoted `4.24 Packaged Desktop Release Readiness Phase` into `PLAN.md`.
- Defined the phase around proving the app can be packaged and launched from packaged output rather than only from `apps/desktop/dist/main/main.js`.
- Scoped the first pass to local/Linux packaging readiness and explicit platform limitations, leaving signing, notarization, auto-update, and macOS/Windows hardening as later follow-up unless verified locally.
- Added acceptance expectations for:
  packaging configuration,
  local packaging scripts,
  packaged runtime smoke testing,
  release artifact verification,
  README/CI handoff,
  and director-script runtime scenes.
- Removed the old packaged-release backlog bullet because it is now an explicit planned phase.
- This is a planning-only update; no runtime code changed.
- Verified:
  `git diff --check`
- Next: execute `4.24` when implementation is requested.

### 2026-05-06 Step 112

- Implemented `4.24 Packaged Desktop Release Readiness Phase`.
- Used a small TDD guard for release wiring:
  `tests/packaging.test.ts` first failed because package scripts and implementation files did not exist,
  then passed after the scripts and packaged E2E were added.
- Added `scripts/package-linux.mjs` as the local Linux packaging path:
  it stages the desktop production build,
  copies built workspace package `dist` outputs with sanitized package metadata,
  installs production dependencies in a non-workspace staging app,
  rebuilds `better-sqlite3` and `sharp` against the Electron runtime,
  and embeds the staged app into Electron's Linux distribution under `dist/release/chronopic-linux-x64`.
- Added `scripts/verify-package.mjs` to validate the unpacked artifact:
  executable presence and mode,
  packaged main/preload/renderer assets,
  explicit ChronoPic app metadata,
  `better-sqlite3` and `sharp` native modules,
  and absence of repo-local `tests`, `test-results`, `data`, and `thumbs` directories inside `resources/app`.
- Added root packaging scripts:
  `package:linux`,
  `package:verify`,
  `package:smoke`,
  and `e2e:packaged`.
- Added `tests/e2e/packaged.spec.ts` so packaged smoke verification launches `dist/release/chronopic-linux-x64/chronopic` directly instead of `apps/desktop/dist/main/main.js`.
- Updated `README.md` with local Linux packaging commands, packaged smoke verification, Xvfb guidance, and the current platform/release limitations:
  no signing,
  no notarization,
  no auto-update,
  and no verified macOS/Windows artifacts yet.
- Updated `.github/workflows/ci.yml` so CI packages the Linux artifact, verifies the artifact layout, and runs packaged E2E under Xvfb.
- Followed `docs/agent-verification-script.md` for this launch/distribution flow using the packaged executable.
- Playwright director scenes run with temporary packaged-app data:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 7 - Restart Persistence,
  Scene 8 - Settings, Locale, AI, And Map.
- Director-script evidence:
  screenshots and `evidence.json` written under `/tmp/chronopic-424-verify-owcuzM`,
  fixture directory `/tmp/chronopic-424-fixtures-5PyRBJ`,
  user data directory `/tmp/chronopic-424-userdata-Bq8wqx`,
  backup file `/tmp/chronopic-424-verify-owcuzM/chronopic-424-backup.json`,
  packaged executable `/home/dhc/workspace/ChronoPic/dist/release/chronopic-linux-x64/chronopic`,
  first-run `Add Folder` and preload bridge verified,
  2 fixture photos indexed,
  2 thumbnails generated,
  1 memory created,
  backup preview exercised,
  and restart persistence verified for source count, photo count, memory membership, caption, favorite state, locale, AI settings, and map settings.
- Verified:
  `node --experimental-strip-types --test tests/packaging.test.ts`
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
  `pnpm run e2e:runtime`
  `pnpm run e2e:accessibility`
  `pnpm run e2e:backup`
  `pnpm run package:linux`
  `pnpm run package:smoke`
- Result: 4.24 is landed and verified locally for local/Linux unpacked release readiness.
- Next: decide whether to commit/push this phase or promote the next product phase.

### 2026-05-06 Step 113

- Added a tag-triggered GitHub Release workflow in `.github/workflows/release.yml`.
- The release workflow runs on pushed tags matching `v*`.
- The workflow packages the Linux artifact, verifies the package layout, runs packaged E2E under Xvfb, archives `dist/release/chronopic-linux-x64` into a versioned tarball, writes a SHA-256 checksum, and publishes both files to the GitHub Release for the tag.
- The workflow uses the built-in `GITHUB_TOKEN` with `contents: write` permission and handles reruns by uploading assets with `--clobber` when the release already exists.
- Added README instructions for publishing by tag:
  `git tag v0.1.0`
  `git push origin v0.1.0`
- Expanded `tests/packaging.test.ts` so release workflow wiring is covered by the local packaging structure test.
- Verified:
  `node --experimental-strip-types --test tests/packaging.test.ts`
- Next: run broader verification, then commit/push when requested.

### 2026-05-06 Step 114

- Expanded release packaging from Linux-only to Linux, macOS, and Windows.
- Added `scripts/package-desktop.mjs` as the shared platform-aware packager and kept `scripts/package-linux.mjs` as a compatibility wrapper.
- The packager now emits:
  `dist/release/chronopic-linux-<arch>`,
  `dist/release/chronopic-macos-<arch>`,
  and `dist/release/chronopic-windows-<arch>` on matching runner platforms.
- Updated `scripts/verify-package.mjs` so package verification understands Linux, macOS app bundles, and Windows executables.
- Added `scripts/archive-release-artifact.mjs` so all release jobs create a tar.gz archive and SHA-256 checksum consistently.
- Updated packaged E2E default executable resolution to support:
  Linux `chronopic`,
  macOS `ChronoPic.app/Contents/MacOS/ChronoPic`,
  and Windows `chronopic.exe`.
- Updated `.github/workflows/release.yml` to use a three-platform matrix:
  `ubuntu-latest`,
  `macos-latest`,
  and `windows-latest`.
- The release workflow now creates or updates the GitHub Release once, then each platform job packages, verifies, smokes, archives, and uploads its own assets with `--clobber`.
- Updated `README.md` and `PLAN.md` to describe the three-platform tag release path and the remaining limitations around signing, notarization, auto-update, and installers.
- Verified locally on Linux:
  `node --experimental-strip-types --test tests/packaging.test.ts`
  `node --check scripts/package-desktop.mjs && node --check scripts/package-linux.mjs && node --check scripts/verify-package.mjs && node --check scripts/archive-release-artifact.mjs`
  `pnpm run package:linux`
  `pnpm run package:verify -- linux`
  `pnpm run e2e:packaged`
  `node scripts/archive-release-artifact.mjs linux v0.1.0-local`
- Result: Linux remains locally verified after the shared-packager refactor; macOS and Windows packaging are wired for real validation on GitHub Actions runners.
- Next: run the root test suite, then commit/push and trigger a new tag release when requested.

### 2026-05-06 Step 115

- Split project documentation by audience.
- Rewrote `README.md` as a user-facing product document:
  download/release entry,
  current limitations,
  core capabilities,
  local data behavior,
  optional AI/map setup,
  backup/restore behavior,
  and links to developer/project docs.
- Added `DEVELOPMENT.md` for contributor and code-agent details:
  setup,
  source launch,
  verification,
  E2E suites,
  local packaging,
  tag releases,
  architecture,
  project layout,
  main commands,
  and planning/agent workflow.
- Updated `PLAN.md` to record the documentation audience split under the 4.24 release-readiness status.
- Verified:
  `git diff --check`
- Result: README is now user-facing, while development and release mechanics live in `DEVELOPMENT.md`.
- Next: commit/push the documentation split when requested.

### 2026-05-06 Step 116

- Revised `README.md` again to make the user-facing document English-language.
- Added a GitHub Release badge at the top of the README that links to the latest release page.
- Changed the developer-documentation references in the README from inline-code filenames to Markdown links:
  [DEVELOPMENT.md](DEVELOPMENT.md),
  [PLAN.md](PLAN.md),
  [AGENTS.md](AGENTS.md),
  and [docs/agent-verification-script.md](docs/agent-verification-script.md).
- Kept developer setup, verification, packaging, release, architecture, and workflow details in `DEVELOPMENT.md`.
- Verified:
  `git diff --check`
- Result: README is now an English user-facing entry page with a release badge and linked developer-doc references.
- Next: commit/push the documentation update when requested.

### 2026-05-06 Step 117

- Adjusted the user-facing README positioning to emphasize ChronoPic as an AI-powered, local-first desktop photo workspace.
- Expanded the AI wording around searchable semantics, story-ready Memories, reviewable organization suggestions, and AI-powered enrichment for captions, summaries, tags, Memory suggestions, and candidate Memories.
- Preserved the existing user-facing boundary that AI is optional, core library workflow remains local-first, and generated content does not overwrite user-authored edits.
- Verified:
  `git diff --check`
- Result: README now presents the product as AI-powered while keeping the privacy/local-first framing clear.
- Next: commit/push the README wording update when requested.

### 2026-05-06 Step 118

- Performed the requested maintenance close-out review after deciding not to pursue installable installers for now.
- Added `4.25 Maintenance Review and Platform Hygiene Phase` to `PLAN.md` and marked it complete after the maintenance fixes landed locally.
- Reviewed the current release/platform path and kept the portable unpacked-bundle model intact.
- Added `scripts/package-targets.mjs` so package target normalization and release folder naming are shared by:
  `scripts/package-desktop.mjs`,
  `scripts/verify-package.mjs`,
  and `scripts/archive-release-artifact.mjs`.
- Updated CI and release workflows from `actions/checkout@v4` / `actions/setup-node@v4` to `actions/checkout@v5` / `actions/setup-node@v5`, matching the current Node 24-compatible official action line.
- Updated `tests/packaging.test.ts` to cover the new shared packaging helper and workflow action versions.
- Generalized the packaged E2E test title so the cross-platform packaged smoke no longer describes itself as Linux-only.
- Updated `README.md` and `DEVELOPMENT.md` to describe releases as portable unpacked bundles rather than installers.
- Tightened developer-document references in `DEVELOPMENT.md` so repo-file pointers are clickable links instead of inline-code file names.
- Verified:
  `node --check scripts/package-targets.mjs && node --check scripts/package-desktop.mjs && node --check scripts/verify-package.mjs && node --check scripts/archive-release-artifact.mjs`
  `node --experimental-strip-types --test tests/packaging.test.ts`
  `pnpm run package:linux`
  `pnpm run package:verify -- linux`
  `pnpm test`
  `pnpm typecheck`
  `git diff --check`
- Result: the current product logic was left untouched, release/platform maintenance gaps were narrowed, and Linux packaging remains verified after the helper extraction.
- Next: review the diff, then commit/push the maintenance close-out when requested.

### 2026-05-07 Step 119

- Added `4.26 AI Productization Tightening Phase` to `PLAN.md`.
- Scoped the phase as a small AI productization close-out rather than a larger AI capability expansion.
- Defined the next implementation direction around:
  AI setup clarity,
  AI enrichment queue visibility,
  memory candidate guidance,
  first-run/empty-state integration,
  and verification.
- Explicitly excluded OCR, vector embedding search, face/person recognition, installer work, and large-library performance work from this phase.
- Verification for this planning-only change:
  `git diff --check`
- Result: the next phase is now recorded locally and ready for implementation when requested.
- Next: implement `4.26` or commit/push the planning update when requested.

### 2026-05-07 Step 120

- Implemented `4.26 AI Productization Tightening Phase`.
- Added `getAIReadiness()` to the domain package so AI setup state can be derived without exposing secrets.
- Added unit coverage for AI readiness in `tests/domain.test.ts`.
- Added a clearer AI setup status card in Library Settings:
  configured,
  incomplete,
  and disabled states are visible,
  required AI fields are listed,
  and API-key state is shown only as present/missing.
- Added direct Notifications recovery for incomplete AI setup:
  Notifications now shows missing setup fields and a `Configure AI` action back to Library Settings.
- Kept the existing queue model but made the review boundary clearer:
  generated captions, summaries, tags, and memory suggestions remain separate from user-authored edits.
- Tightened Suggested Memories copy so candidates explain accept/reject semantics, source, confidence, and included-photo count.
- Added an accessible label/title to the sidebar Notifications icon button, which the new E2E coverage needed to navigate the AI queue surface.
- Added `tests/e2e/ai-productization.spec.ts` and root script `pnpm run e2e:ai`.
- Added `e2e:ai` to CI and documented the suite in `DEVELOPMENT.md`.
- Explicitly deferred live provider health checking because the current provider abstraction has no separate non-generating health probe.
- Verified:
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
  `pnpm run clean && pnpm run build:packages && node --experimental-strip-types --test tests/domain.test.ts tests/i18n.test.ts`
  `pnpm run e2e:ai`
  `pnpm run e2e:accessibility`
- Result: AI setup/readiness, queue recovery, and memory-candidate review semantics are more visible without adding OCR, vector search, person recognition, installers, or performance work.
- Next: run the broader final verification set, then commit/push when requested.

### 2026-05-07 Step 121

- Tightened the GitHub Actions pnpm setup path before cutting the next release.
- Removed `pnpm/action-setup@v4` from both CI and release workflows so the workflows no longer depend on the deprecated Node 20 action runtime.
- Switched pnpm activation to `corepack enable pnpm` after `actions/setup-node@v5` with Node 24.
- Updated `tests/packaging.test.ts` so the workflow guard now checks for Node 24, Corepack pnpm setup, and absence of the old pnpm action/cache wiring.
- Verified:
  `node --experimental-strip-types --test tests/packaging.test.ts`
  `git diff --check`
- Result: CI and tag release workflows are ready for a cleaner v0.1.3 verification/release run.
- Next: commit/push, wait for main CI, tag `v0.1.3`, then verify the release workflow and published assets.

### 2026-05-07 Step 122

- Investigated the failed main CI run after the Corepack pnpm setup cleanup.
- Root cause: `actions/setup-node@v5` needed `pnpm` available before it could finish the Node setup/cache step, but the workflow only enabled pnpm after that step.
- Verified that `pnpm/action-setup@v6` exists and runs on Node 24.
- Updated CI and release workflows to run `pnpm/action-setup@v6` before `actions/setup-node@v5`, with pnpm pinned to `10.0.0` and `cache: pnpm` restored in the Node setup step.
- Updated `tests/packaging.test.ts` so the workflow guard now requires `pnpm/action-setup@v6` and rejects the old `v4` action.
- Verified:
  `node --experimental-strip-types --test tests/packaging.test.ts`
  `git diff --check`
- Result: the local workflow guard passes with the v6 pnpm action setup.
- Next: commit/push this CI fix and wait for main CI again before tagging the release.

### 2026-05-07 Step 123

- Created the `flutter-refactor-phases` branch from `main` for Flutter rewrite planning.
- Added `docs/flutter-refactor-phases.md` with the staged rewrite phases:
  parity contract,
  Dart domain and backup contract,
  Drift database and repositories,
  media source abstraction,
  indexer and AI pipeline,
  Flutter desktop MVP,
  Android/iOS productization,
  and release/migration cutover.
- Added a short `PLAN.md` assumption pointing to the Flutter plan while keeping the current Electron desktop plan as the active implementation line.
- Verification for this planning-only change:
  `git diff --check`
- Next: review the phase plan, then commit/push the planning branch when requested.

### 2026-05-07 Step 124

- Reviewed the Flutter phase plan before publishing the planning branch.
- No blocking product-order issues were found in the phase sequence:
  parity contract,
  Dart domain/backup,
  Drift persistence,
  media adapters,
  indexer/AI,
  Flutter desktop MVP,
  mobile productization,
  and release/migration remain in the right order.
- Tightened document quality by converting repository-path references in `docs/flutter-refactor-phases.md` and the `PLAN.md` Flutter-plan pointer into Markdown links.
- Verification for this planning/documentation review:
  `git diff --check`
- Next: push the reviewed planning branch and use it as the handoff point for later Flutter rewrite implementation.

### 2026-05-07 Step 125

- Started the Flutter rewrite execution line at `Phase 0: Freeze Parity Contract`.
- Added `docs/flutter-parity-contract.md` as the first Phase 0 artifact.
- The parity contract keeps the Electron app as the reference implementation and defines:
  required workflow parity,
  current Electron reference tests,
  backup compatibility baseline,
  accepted platform differences,
  and the Phase 0 exit gate.
- Updated `docs/flutter-refactor-phases.md` to link Phase 0 to the new parity contract.
- Updated `PLAN.md` with `4.27 Flutter Rewrite Phase 0: Freeze Parity Contract`.
- Explicitly left Phase 0 incomplete until the sanitized backup fixture, expected-count fixture, and fixture refresh path are added.
- Next: create `tests/fixtures/flutter-parity/chronopic-backup-v1.json`, its expected-count fixture, and the refresh command/script before starting Dart domain implementation.

### 2026-05-07 Step 126

- Completed the remaining `Phase 0: Freeze Parity Contract` artifacts.
- Added sanitized Flutter parity fixtures:
  `tests/fixtures/flutter-parity/chronopic-backup-v1.json`
  and `tests/fixtures/flutter-parity/chronopic-backup-v1.expected.json`.
- Added `scripts/write-flutter-parity-fixtures.mjs` and root script `pnpm run fixtures:flutter-parity` so the fixture baseline can be regenerated deterministically.
- Added `tests/flutter-parity-fixtures.test.ts` to validate fixture counts plus migration-critical authored/generated fields:
  favorites,
  memories,
  memory candidates,
  authored captions,
  generated semantic fields,
  failed AI state,
  and GPS-bearing records.
- Updated `docs/flutter-parity-contract.md` and `PLAN.md` so Phase 0 is now marked complete.
- Verified:
  `node --check scripts/write-flutter-parity-fixtures.mjs`
  `node --experimental-strip-types --test tests/flutter-parity-fixtures.test.ts`
  `git diff --check`
- Next: start Flutter rewrite Phase 1 by planning Dart domain and backup compatibility against the committed parity fixtures, not by building UI first.

### 2026-05-07 Step 127

- Installed a user-local Flutter SDK without sudo at:
  `/home/dhc/.local/share/flutter`
- Linked user commands through:
  `/home/dhc/.local/bin/flutter`
  and `/home/dhc/.local/bin/dart`.
- Confirmed `/home/dhc/.local/bin` is already configured in the shell startup files, so new shells should find the commands.
- Enabled Linux desktop support with:
  `flutter config --enable-linux-desktop`
- Verified installed tool versions:
  Flutter `3.41.9` on stable,
  Dart `3.11.5`,
  DevTools `2.54.2`.
- Ran `flutter doctor -v`.
- Result:
  Flutter SDK and network resources are available,
  but full Linux desktop builds still need system packages installed with apt/sudo:
  `ninja-build`,
  `libgtk-3-dev`,
  and optionally `mesa-utils` for driver info.
- Additional doctor gaps:
  Android command-line tools are missing,
  and Chrome/Web development is not configured.
- Next: before building Flutter Linux desktop, install the missing apt packages; before Android work, install Android command-line tools and accept Android licenses.

### 2026-05-07 Step 128

- Re-checked the Flutter environment after the missing apt packages were installed outside this session.
- Confirmed system packages are installed:
  `ninja-build`,
  `libgtk-3-dev`,
  and `mesa-utils`.
- Confirmed tool visibility:
  `/usr/bin/ninja`,
  GTK `3.24.33` through `pkg-config --modversion gtk+-3.0`,
  and `/usr/bin/eglinfo`.
- Re-ran `flutter doctor -v`.
- Result:
  Flutter SDK passes,
  Linux desktop toolchain passes,
  Linux desktop device is available,
  and network resources pass.
- Remaining doctor issues:
  Android command-line tools are still missing,
  and Chrome/Web development is not configured.
- Next: Flutter/Dart Phase 1 and Linux desktop work can proceed; Android-specific work should wait until Android command-line tools are installed and licenses are accepted.

### 2026-05-07 Step 129

- Started executing Flutter rewrite Phase 1 through Phase 5 from the written phase plan.
- Created the new Dart/Flutter workspace under `chronopic_flutter/` with package boundaries for:
  domain,
  database,
  media,
  AI,
  app services,
  UI,
  testkit,
  and the app shell.
- Queried the active Flutter stable toolchain before finalizing dependency constraints:
  `flutter upgrade --verify-only` reports Flutter `3.41.9` stable is already current.
- Queried package freshness with:
  `flutter pub outdated`.
- Result:
  direct dependencies are up to date,
  and newer latest-only versions such as `test 1.31.1` are not resolvable under the current Flutter stable dependency graph.
- Kept package constraints on the newest resolvable stable versions instead of forcing incompatible latest versions.
- Next: complete package implementation and run phase verification.

### 2026-05-07 Step 130

- Completed Flutter Rewrite Phase 1: Dart Domain And Backup Contract.
- Added `chronopic_domain` with typed Dart models for photos, metadata, semantic state, index state, library sources, edit history, memories, memory candidates, filters, settings, backups, and AI readiness.
- Added `chronopic_testkit` so Dart tests load the committed Flutter parity fixture from `tests/fixtures/flutter-parity/`.
- Implemented backup parse, validation, preview counts, and JSON re-emission against the Electron-derived fixture.
- Verified with:
  `dart test packages/chronopic_domain`
  `dart analyze packages/chronopic_domain packages/chronopic_testkit`
- Next: continue with Drift database and repository parity.

### 2026-05-07 Step 131

- Completed Flutter Rewrite Phase 2: Drift Database And Repositories.
- Added `chronopic_database` with a repository facade for backup preview/restore/export, photo listing, caption/tag/favorite edits, memories, memory membership, and memory candidates.
- Added Drift schema/codegen coverage for the first Flutter catalog projection and a separate `chronopic_database_testing.dart` export for package-level Drift tests.
- Kept app-facing database imports focused on the repository facade so generated Drift row classes do not leak into UI/app package namespaces.
- Verified with:
  `dart run build_runner build`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  `dart analyze packages/chronopic_database`
- Note:
  the Drift runtime test is run from `chronopic_flutter/packages/chronopic_database` so sqlite native asset build hooks are available.
- Next: continue with media source abstraction.

### 2026-05-07 Step 132

- Completed Flutter Rewrite Phase 3: Media Source Abstraction.
- Added `chronopic_media` with `MediaSourceAdapter`, media asset metadata, read results, permission state, stable IDs, supported-media filtering, and missing-asset handling.
- Implemented both deterministic fixture media and a recursive desktop directory adapter.
- Verified with:
  `dart test packages/chronopic_media`
  `dart analyze packages/chronopic_media`
- Next: continue with the app/indexer and AI service layer.

### 2026-05-07 Step 133

- Completed Flutter Rewrite Phase 4: Indexer And AI Pipeline.
- Added `chronopic_ai` with disabled, fixture-success, and fixture-failure AI clients.
- Added `chronopic_app` with backup orchestration and an indexer service that consumes media adapters, skips unchanged assets, records missing assets, and writes AI state through the repository boundary.
- Verified with:
  `dart test packages/chronopic_ai packages/chronopic_app`
  `dart analyze packages/chronopic_ai packages/chronopic_app`
- Next: continue with the Flutter desktop MVP shell.

### 2026-05-07 Step 134

- Completed Flutter Rewrite Phase 5: Flutter Desktop MVP.
- Added `chronopic_ui` with the first Flutter Material desktop MVP surface:
  first-run/library actions,
  scan action,
  search/filter controls,
  photo grid,
  favorites,
  memories,
  detail/edit surface,
  gallery surface,
  and backup/restore actions.
- Added the Linux app shell under `chronopic_flutter/apps/chronopic`.
- Verified with:
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
- Result:
  Linux debug build emits `build/linux/x64/debug/bundle/chronopic`.
- Remaining environment gaps:
  Android command-line tools and Chrome/Web are still not configured,
  but they are outside Phase 1-5 and do not block Linux/Dart verification.
- Next:
  Phase 6 should cover Android/iOS productization only after Android tooling and mobile permission work are explicitly started.

### 2026-05-07 Step 135

- Completed the final Flutter Phase 1-5 audit and repository-record update.
- Updated `PLAN.md` with completed Phase 1 through Phase 5 entries and verification evidence.
- Updated `docs/flutter-refactor-phases.md` with the local completion status for Phase 1 through Phase 5.
- Updated `docs/superpowers/plans/2026-05-07-flutter-phase-1-5-implementation.md` so its checklist reflects the completed implementation steps.
- Updated `.gitignore` for nested Flutter/Dart generated directories:
  `.dart_tool/`,
  `.flutter-plugins-dependencies`,
  `.pub-cache/`,
  `.pub/`,
  and `build/`.
- Re-verified repository formatting with:
  `git diff --check`
- Result:
  no whitespace errors,
  and generated Flutter/Dart cache and build directories are excluded from the untracked file set.

### 2026-05-08 Step 136

- Inserted `Flutter Rewrite Phase 5.5: Linux Desktop Feature Parity And E2E Gate` before Android/iOS productization.
- Added the Phase 5.5 implementation plan at:
  `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Updated `docs/flutter-refactor-phases.md` and `PLAN.md` so Phase 6 remains blocked until Linux desktop parity is stronger.
- Added `docs/flutter-linux-desktop-parity-matrix.md` to make the Electron-vs-Flutter Linux workflow gaps explicit.
- Implemented the first executable Linux parity slice:
  repository incremental `upsertPhotoRecord`,
  library source tracking,
  edit history and latest-edit rollback,
  memory listing and membership count updates,
  missing-asset marking,
  app-service `scanDesktopDirectory`,
  and indexer upsert behavior so scanning multiple files no longer replaces the catalog per asset.
- Rewired `chronopic_ui` so the Linux desktop shell can:
  enter a local library path,
  add the library,
  run a scan,
  browse/search scanned files,
  toggle favorite,
  edit caption/tags,
  rollback latest edit,
  create a memory,
  add the selected photo to the memory,
  and exercise backup export/preview/restore smoke actions.
- Added tests:
  `chronopic_flutter/packages/chronopic_app/test/linux_desktop_scan_test.dart`
  and `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart`.
- Continued Phase 5.5 by adding:
  datetime correction through repository, app service, and Flutter UI,
  rollback coverage for caption, tags, favorite, and datetime edits,
  local image preview rendering for grid/detail surfaces,
  a focused gallery dialog with widget coverage for open/close,
  UI-level caption/tag/favorite/memory/backup smoke coverage,
  and Favorites navigation filtering coverage.
- Verified this slice with:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Important audit result:
  Phase 5.5 is not yet complete against full Electron desktop parity.
- Remaining at that point, before Step 137 continued the same phase:
  app-shell-level UI scan integration around real file IO,
  an Electron-vs-Flutter parity matrix,
  local preview parity,
  full detail/gallery keyboard parity,
  datetime correction UI,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  backup file workflow,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 137

- Continued Phase 5.5 by closing two more Linux desktop parity gaps.
- Added generated thumbnail cache support for scanned local images in the Flutter app-service/indexer path:
  `ChronoPicAppService.scanDesktopDirectory` now passes a per-library cache directory,
  `ChronoPicIndexerService` writes downscaled JPG thumbnails for image assets,
  and repository upsert preserves an existing thumbnail when an unchanged record is merged.
- Updated the Flutter UI preview path so grid/detail/gallery previews prefer `photo.thumbnailPath` and fall back to the original file path.
- Replaced backup smoke-only coverage with explicit Linux JSON file path coverage:
  `ChronoPicAppService` now exports, reads, previews, and restores backup JSON through a path,
  and the Flutter UI exposes path-driven export/preview/restore buttons.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified with:
  `dart test packages/chronopic_app`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_app packages/chronopic_database packages/chronopic_ui`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  app-shell-level UI scan integration around real file IO,
  video placeholders and larger-library desktop browse coverage,
  full detail/gallery adjacent-navigation and keyboard parity,
  date/time picker UX for datetime correction,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  malformed backup error coverage,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 138

- Continued Phase 5.5 by adding UI-driven Linux scan coverage instead of relying only on a pre-scanned service fixture.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` with an empty-to-scanned workflow:
  create a real temporary Linux directory,
  render `ChronoPicHome` with an empty repository,
  enter the directory into `library-path-field`,
  click `add-library-button`,
  click `scan-library-button`,
  then assert scanned images render, unsupported text files stay hidden, library sources persist, and generated thumbnail files exist.
- Updated the Phase 5.5 tracking docs so app-shell/UI scan integration is no longer listed as a remaining gap:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  video placeholders and larger-library desktop browse coverage,
  full detail/gallery adjacent-navigation and keyboard parity,
  date/time picker UX for datetime correction,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  malformed backup error coverage,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 139

- Continued Phase 5.5 by improving focused gallery parity.
- Reworked the Flutter gallery from a single-record fullscreen dialog into a stateful gallery dialog over the current visible result set.
- Added toolbar navigation:
  `previous-gallery-button`,
  `next-gallery-button`,
  and `close-gallery-button`.
- Added keyboard handling inside the gallery:
  `ArrowLeft` moves to the previous visible photo,
  `ArrowRight` moves to the next visible photo,
  and `Escape` closes the gallery while preserving the current gallery selection back into the detail surface.
- Added stable gallery title keys so widget tests can assert the currently focused media without colliding with grid/detail preview keys.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` to verify:
  adjacent navigation by button,
  adjacent navigation by keyboard,
  Escape close behavior,
  and detail selection synchronization after closing.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
  `flutter analyze packages/chronopic_ui apps/chronopic`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  video placeholders and larger-library desktop browse coverage,
  detail keyboard parity and full immersive gallery visual polish,
  date/time picker UX for datetime correction,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  malformed backup error coverage,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 140

- Continued Phase 5.5 by adding malformed backup error coverage.
- Extended `chronopic_flutter/packages/chronopic_app/test/app_service_test.dart` so `previewBackupFile` rejects malformed JSON with a `FormatException`.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` so the Flutter backup path flow surfaces `Preview restore failed:` for malformed JSON backup files.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `dart test packages/chronopic_app/test/app_service_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  video placeholders and larger-library desktop browse coverage,
  detail keyboard parity and full immersive gallery visual polish,
  date/time picker UX for datetime correction,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  restart persistence tests,
  and Flutter desktop i18n parity.
### 2026-05-08 Step 141

- Continued Phase 5.5 by adding explicit Flutter video placeholders.
- Updated `_MediaPreview` so records with `video/*` MIME types render a stable `video-preview-*` placeholder with a movie icon and `Video` label instead of falling through to a generic image placeholder.
- Extended the UI-driven Linux scan test with a fake `clip.mp4` fixture so the scan imports a supported video file, keeps unsupported text hidden, and asserts the video placeholder renders.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  date/time picker UX for datetime correction,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 142

- Continued Phase 5.5 by replacing the raw epoch-millisecond datetime edit field with desktop date/time inputs.
- Updated the Flutter detail surface to use:
  `date-field` with `YYYY-MM-DD`,
  and `time-field` with `HH:mm`.
- Added parser/formatter logic that:
  clears datetime when both fields are empty,
  saves valid local date/time values as epoch milliseconds through the existing repository/service boundary,
  rejects invalid calendar dates and times,
  and keeps the previous stored datetime unchanged when validation fails.
- Updated rollback behavior so the date/time fields are refreshed from the restored record.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` to verify valid date/time save, invalid-input UX, unchanged persistence after invalid input, and datetime rollback.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 143

- Continued Phase 5.5 by broadening Flutter search/filter parity.
- Extended repository `listPhotos` filtering to honor more of the Dart domain `PhotoFilter` contract:
  `mimePrefix`,
  `aiStatus`,
  `indexed`,
  `hasError`,
  `hasGps: false`,
  `fromDatetime`,
  and `toDatetime`.
- Added repository test coverage for tag, GPS, AI status, date range, and path sort semantics.
- Added a visible Flutter filter toolbar with:
  `tag-filter-field`,
  `gps-filter-chip`,
  `from-date-filter-field`,
  `to-date-filter-field`,
  `sort-by-control`,
  `sort-direction-control`,
  `ai-status-filter-control`,
  `apply-filter-button`,
  and `clear-filter-button`.
- Added UI validation for invalid date filters using the same `YYYY-MM-DD` desktop format.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` to verify tag filtering, GPS-only filtering, AI status filtering, invalid date-filter UX, and filter clearing in the real scanned desktop flow.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this slice with:
  `dart test test/repository_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_database packages/chronopic_ui`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 144

- Continued Phase 5.5 by adding the visible AI status filter that was still missing from the Flutter filter toolbar.
- Added `ai-status-filter-control` to the Flutter filter toolbar with `disabled`, `pending`, `processing`, `completed`, and `failed` states plus the default `AI: any` option.
- Wired the selected AI status into `PhotoFilter.aiStatus` and reset it through `Clear Filters`.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` to verify the visible control exists and that applying `disabled` vs `completed` AI status changes the scanned desktop result set as expected.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI readiness/queue/candidate notification parity,
  native backup import/export file picker UX,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 145

- Continued Phase 5.5 by adding native backup save/open picker entry points to the Flutter Linux desktop UI.
- Queried dependency resolution before adding the picker package:
  `dart pub add file_selector --dry-run`
  resolved `file_selector 1.1.0`.
- Added `file_selector: ^1.1.0` to `chronopic_flutter/packages/chronopic_ui/pubspec.yaml`.
- Verified dependency freshness after install with:
  `dart pub outdated`
  Result:
  direct dependencies are all up to date and the workspace is using the newest resolvable versions.
- Added backup picker buttons:
  `choose-backup-export-path`
  and `choose-backup-restore-path`.
- Wired those buttons through `file_selector`:
  `getSaveLocation` selects a JSON backup export path,
  and `openFile` selects a JSON backup restore file.
- Kept the existing `backup-path-field` path workflow because widget tests need deterministic non-interactive file paths.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 146

- Continued Phase 5.5 by adding visible AI readiness and queue-state surfaces to the Flutter desktop shell.
- Added app-service methods for:
  secret-safe AI setup readiness,
  per-status AI count aggregation,
  and pending memory candidate listing.
- Added a Flutter `AI` status panel that displays:
  `ai-readiness-status`,
  `ai-readiness-missing-fields`,
  `ai-status-count-*` chips,
  and `memory-candidate-count`.
- Extended app-service tests to verify readiness, completed/failed status counts, and memory candidate listing from the parity backup fixture.
- Extended the Linux desktop parity widget test to verify visible incomplete readiness, disabled queue count, and memory candidate count in the real scanned desktop flow.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `dart test packages/chronopic_app/test/app_service_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_app packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native backup dialog smoke coverage outside widget tests,
  restart persistence tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 147

- Continued Phase 5.5 by making the Flutter Linux desktop shell persist local app state across fresh service/shell starts.
- Added `ChronoPicAppService.persistent()` with a default local data path:
  `XDG_DATA_HOME/chronopic_flutter/chronopic-backup.json`
  or `~/.local/share/chronopic_flutter/chronopic-backup.json`.
- Reused the existing ChronoPic backup JSON contract as the desktop persistence format for this slice.
- Wired the default `ChronoPicHome` service creation to use the persistent app service instead of an in-memory-only repository.
- Persisted state after the core desktop mutations that currently exist in Flutter:
  backup restore,
  library source registration,
  desktop scan,
  caption/tag/datetime/favorite edits,
  rollback,
  memory creation,
  and add-photo-to-memory.
- Added service-level restart coverage in `chronopic_flutter/packages/chronopic_app/test/app_service_test.dart` for:
  library state,
  caption,
  tags,
  datetime,
  favorite,
  memory creation,
  and memory membership.
- Added Flutter shell reload coverage in `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` for:
  persisted caption,
  persisted tags,
  persisted favorite navigation,
  and persisted memory membership after constructing a fresh service and widget shell.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this slice with:
  `dart test packages/chronopic_app/test/app_service_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_app packages/chronopic_ui`
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 148

- Continued Phase 5.5 by adding a native folder-picker entry point to the Flutter Linux first-run library flow.
- Added `choose-library-folder-button` to the library toolbar.
- Wired the button through `file_selector.getDirectoryPath` with a Linux desktop folder-selection dialog.
- Kept the typed `library-path-field` flow because parity/widget tests need deterministic non-interactive local paths.
- Updated the empty-to-scanned Linux desktop parity test to assert the folder-picker entry point is visible before driving the typed path scan flow.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 149

- Continued Phase 5.5 by closing the core Flutter memory lifecycle gap from the desktop parity matrix.
- Added repository support for:
  `getMemory`,
  `updateMemory`,
  `removePhotoFromMemory`,
  and `setMemoryCover`.
- Added app-service wrappers for those memory lifecycle actions and persisted each mutation through the desktop persistence path.
- Added a Flutter selected-memory detail panel with:
  `memory-detail-panel`,
  `memory-title-field`,
  `memory-description-field`,
  `save-memory-button`,
  `set-memory-cover-button`,
  and `remove-from-memory-button`.
- Wired the memory detail panel so users can rename a memory, edit its description, set the selected photo as cover, and remove the selected photo from the active memory.
- Extended repository, service, and Linux desktop parity tests to cover memory rename, description editing, cover selection, remove-photo behavior, and persisted memory state reloads.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `dart test test/repository_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart test packages/chronopic_app/test/app_service_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_database packages/chronopic_app packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  richer datetime metadata/timezone display parity,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 150

- Continued Phase 5.5 by adding visible detail metadata and datetime display parity to the Flutter desktop detail surface.
- Added `metadata-grid` to the selected-photo detail panel.
- The metadata grid now displays:
  `metadata-captured`,
  `metadata-timezone`,
  `metadata-original-date`,
  `metadata-camera`,
  `metadata-gps`,
  `metadata-mime`,
  and `metadata-size`.
- Extended the Linux desktop parity test to verify captured local date/time, local UTC offset, and MIME metadata after datetime correction.
- Adjusted the long desktop parity test interactions to explicitly scroll to detail and memory action buttons after the detail surface grew taller.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  larger-library desktop browse layout and responsiveness coverage,
  detail keyboard parity and full immersive gallery visual polish,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 151

- Continued Phase 5.5 by adding larger-library and responsive browse-grid coverage.
- Replaced the fixed 4-column Flutter photo grid with an adaptive column count based on available desktop width.
- Added a stable `photo-grid` key for widget-level layout assertions.
- Extended `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart` to verify the adaptive grid delegate uses different column counts at wide and narrower desktop widths.
- Extended `chronopic_flutter/packages/chronopic_ui/test/linux_desktop_parity_test.dart` with an 18-photo temporary Linux directory scan and verified the scanned catalog renders through the adaptive grid.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  detail keyboard parity and full immersive gallery visual polish,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 152

- Continued Phase 5.5 by adding desktop keyboard parity for the selected-photo detail flow.
- Wrapped the Flutter desktop shell in a focused keyboard handler.
- Added selected-photo shortcuts:
  `F` toggles favorite,
  `R` rolls back the latest edit,
  and `Enter` / `G` opens the focused gallery.
- Extended `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart` to verify favorite toggle, rollback, and gallery-open keyboard behavior from a selected detail record.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `dart analyze packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  full immersive gallery visual polish,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 153

- Ran the full Phase 5.5 local verification gate after the latest memory lifecycle, metadata, adaptive-grid, and keyboard-parity slices.
- Verified with:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Completion audit:
  Phase 5.5 remains incomplete because the parity matrix still has Open/Partial rows.
- Remaining:
  full immersive gallery visual polish,
  map/timeline browse,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 154

- Continued Phase 5.5 by adding Flutter map and timeline browse modes.
- Added `browse-mode-control` with Grid, Map, and Timeline modes.
- Added `map-view` backed by the same visible result set; it lists GPS-backed photos with coordinates and lets the user select a mapped row into the existing detail surface.
- Added `timeline-view` backed by the same visible result set; it groups photos by local capture date and lets the user select a timeline row into the existing detail surface.
- Kept map/timeline implementation local to the Flutter UI layer and did not introduce a map SDK dependency for this parity slice.
- Extended `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart` to verify:
  map mode only shows geotagged fixture photos,
  map row selection updates detail,
  timeline mode shows both fixture photos,
  and timeline row selection updates detail.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `dart analyze packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  full immersive gallery visual polish,
  AI provider settings form, queue recovery actions, and candidate notification parity,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 155

- Continued Phase 5.5 by wiring AI provider settings, queue recovery, and memory candidate actions.
- Added repository/service support for:
  updating AI settings,
  retrying failed AI queue items by moving them back to `pending`,
  accepting a memory candidate into a real memory,
  and rejecting a memory candidate.
- Extended the Flutter AI panel with:
  `ai-provider-field`,
  `ai-base-url-field`,
  `ai-model-field`,
  `ai-api-key-field`,
  `save-ai-settings-button`,
  `retry-ai-queue-button`,
  visible candidate rows,
  `accept-candidate-*`,
  and `reject-candidate-*`.
- Extended repository, service, and Flutter UI tests for settings update, readiness changes, retrying failed AI items, and accepting a candidate into memory.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `dart test test/repository_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart test packages/chronopic_app/test/app_service_test.dart`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `dart analyze packages/chronopic_database packages/chronopic_app packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  full immersive gallery visual polish,
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 156

- Continued Phase 5.5 by polishing focused gallery parity.
- Updated the Flutter gallery dialog to use a dark fullscreen immersive shell.
- Added gallery affordances:
  `gallery-dialog`,
  `gallery-counter`,
  `gallery-keyboard-hint`,
  `gallery-filmstrip`,
  and `gallery-filmstrip-*`.
- Kept existing button navigation, arrow-key navigation, and Escape close behavior.
- Extended the Linux desktop parity test to verify the fullscreen gallery shell, counter, keyboard hint, and filmstrip in addition to existing navigation behavior.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Important audit result:
  Phase 5.5 remains incomplete.
- Remaining:
  native folder/backup dialog smoke coverage outside widget tests,
  and Flutter desktop i18n parity.

### 2026-05-08 Step 157

- Continued Phase 5.5 by closing the remaining documented Flutter Linux desktop parity rows.
- Added scan result separation for imported, updated, skipped, error, and missing counts in `IndexerStats` and the Flutter scan status.
- Extended Linux scan tests to verify incremental update counts after a changed local file.
- Added an active-filter summary surface to the Flutter desktop shell so applied search, tag, GPS, AI status, date, favorite, memory, and sort state is visible instead of hidden in controls.
- Added visible caption/tag validation:
  caption length,
  tag length,
  tag count,
  and duplicate-tag normalization.
- Extended the Linux desktop parity E2E to assert visible rollback state for caption, tags, favorite, and datetime edits.
- Extended backup export E2E to compare exported JSON photos, memories, memoryPhotos, and settings against the live backup snapshot.
- Documented native folder/save/open dialogs as an accepted headless-test difference for Phase 5.5:
  Flutter exposes the `file_selector` entry points,
  and deterministic widget E2E drives typed Linux paths because native portal dialogs are not operable inside Flutter widget tests.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-linux-desktop-parity-matrix.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Verified this targeted slice with:
  `dart test packages/chronopic_app/test/indexer_service_test.dart packages/chronopic_app/test/linux_desktop_scan_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `dart analyze packages/chronopic_app packages/chronopic_ui`
- Result:
  all targeted commands passed.
- Next:
  rerun the full Phase 5.5 local verification gate before marking the phase complete.

### 2026-05-08 Step 158

- Ran the full Phase 5.5 local verification gate after closing the final Linux desktop parity rows.
- Verified:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `git diff --check`
- Result:
  all commands passed.
- Updated Phase 5.5 records in:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md`.
- Final audit result:
  Phase 5.5 is complete locally against the documented Linux desktop parity gate.
- Next:
  review the completed diff, then commit and push the `flutter-refactor-phases` branch when ready.

### 2026-05-08 Step 159

- Started the `Flutter Desktop UI Refine And Component Parity Phase`.
- User explicitly rejected the current Flutter UI quality as unusable and approved a complete, non-compromised desktop UI refine.
- Audited the Electron UI reference and current Flutter UI structure:
  Electron has a product-oriented sidebar/page model,
  while Flutter had a 2300+ line `chronopic_home.dart` combining shell, filters, settings, AI, backup, detail, gallery, and memory flows.
- Added design spec:
  `docs/superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md`.
- Added implementation plan:
  `docs/superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md`.
- Updated phase records in:
  `PLAN.md`
  and `docs/flutter-refactor-phases.md`.
- Next:
  split the Flutter UI into focused modules, then rebuild the desktop shell around the Electron-aligned information architecture.

### 2026-05-08 Step 160

- Completed the first full implementation of the `Flutter Desktop UI Refine And Component Parity Phase`.
- Reduced `chronopic_flutter/packages/chronopic_ui/lib/src/chronopic_home.dart` to the desktop orchestration boundary:
  app service calls,
  controller lifetime,
  page routing,
  selection/filter state,
  and action handlers.
- Split Flutter desktop rendering into focused part modules under:
  `browse/`,
  `detail/`,
  `filters/`,
  `gallery/`,
  `home/`,
  `l10n/`,
  `memories/`,
  `settings/`,
  `shell/`,
  and `theme/`.
- Rebuilt the desktop shell around the Electron-aligned information architecture:
  persistent left sidebar,
  home browse surface,
  dedicated Memories page,
  Memory Detail page,
  Settings page,
  Notifications/AI work queue page,
  focused detail inspector,
  and fullscreen gallery dialog.
- Moved backup, AI settings, locale, source list, and library statistics out of the default browse surface and into Settings/Notifications.
- Preserved Phase 5.5 behavior and stable test keys while updating tests to navigate through the new page model.
- Added `ChronoPicAppService.setMemoryCover` so the memory detail page can promote the selected photo to a memory cover through the app-service boundary instead of reaching around it.
- Fixed the default-size app widget launch test by making the first-run setup panel responsive and by asserting stable shell/action keys instead of assuming duplicate visible button text is unique.
- Dependency audit:
  `flutter pub outdated` reports all direct dependencies are at the newest resolvable versions;
  newer transitive/dev versions are listed as not mutually compatible with the current resolved toolchain.
- Verification scenes from `docs/agent-verification-script.md` mapped to Flutter desktop:
  Scene 1 launch/first impression via `flutter test packages/chronopic_ui apps/chronopic` plus Linux bundle smoke launch,
  Scene 2 first-run/library setup via widget/parity tests,
  Scene 3 scan and browse via Linux parity tests,
  Scene 4 focused viewing via gallery/detail parity tests,
  Scene 5 edits/favorites/rollback via Linux parity tests,
  Scene 6 memories via Linux parity tests,
  Scene 7 restart persistence via Linux parity tests,
  Scene 8 settings/locale/AI via widget/parity tests,
  and Scene 9 notifications/AI queue via widget/parity tests.
- Runtime screenshot evidence:
  after `xvfb-run` and `scrot` were installed locally,
  the Linux debug bundle launched under Xvfb with `LIBGL_ALWAYS_SOFTWARE=1`
  and produced `test-results/flutter-ui-refine-xvfb-window.png`.
  The 1280x720 capture shows the real Linux app window with the persistent sidebar,
  first-run setup panel,
  library toolbar,
  browse mode controls,
  and filter panel.
- Verified:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`
  `dart test test/repository_test.dart test/drift_database_test.dart`
  from `chronopic_flutter/packages/chronopic_database`
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`
  `dart analyze packages/chronopic_app packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter build linux --debug`
  `flutter pub outdated`
  `xvfb-run -a -s "-screen 0 1600x1200x24" ... scrot -a 0,0,1280,720 test-results/flutter-ui-refine-xvfb-window.png`
  `git diff --check`
- Result:
  all verification commands passed;
  the Xvfb/scrot runtime screenshot now covers the previously skipped desktop visual evidence.
- Next:
  commit and push the completed `flutter-refactor-phases` branch.

### 2026-05-08 Step 161

- Planned the next desktop-first phase:
  `Flutter Electron UI And Functional Parity Phase`.
- User clarified that the next work should continue UI and feature alignment,
  and that alignment should repeatedly compare Electron and Flutter through tests and screenshots.
- Added the durable parity matrix:
  `docs/flutter-electron-ui-functional-parity.md`.
- Added the acceptance spec:
  `docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Added the implementation plan:
  `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Updated phase records in:
  `PLAN.md`
  and `docs/flutter-refactor-phases.md`.
- Next:
  implement the Electron reference screenshot capture and Flutter Xvfb/scrot capture harness,
  then use the matrix to drive focused Flutter UI/function fixes.

### 2026-05-08 Step 162

- Started executing Phase 5.7.
- Added Electron reference capture script:
  `scripts/capture-electron-parity.mjs`.
- Added Flutter Linux capture harness:
  `chronopic_flutter/tool/capture_flutter_parity.sh`.
- Added a `CHRONOPIC_CAPTURE_SURFACE` environment hook to Flutter desktop so the real Linux bundle can open deterministic first-run, populated, map, timeline, detail, gallery, favorites, memories, memory-detail, settings, notifications, Chinese-locale, and restart-persistence surfaces without a window automation dependency.
- Verified Electron reference capture with:
  `pnpm run e2e:prepare`
  `node scripts/capture-electron-parity.mjs`
- Verified Flutter capture with:
  `dart analyze packages/chronopic_ui`
  `bash tool/capture_flutter_parity.sh empty-home`
  `bash tool/capture_flutter_parity.sh all`
- Screenshot evidence:
  Electron screenshots under `test-results/flutter-electron-parity/electron/`
  and Flutter screenshots under `test-results/flutter-electron-parity/flutter/`.
- Updated `docs/flutter-electron-ui-functional-parity.md` with the first screenshot-backed gap matrix.
- Current gap summary:
  first-run/home hierarchy,
  populated browse hierarchy,
  map/timeline presentation,
  detail first-viewport visibility,
  gallery metadata richness,
  memories list candidate section,
  memory detail story/chapter layout,
  settings AI/map grouping,
  notifications queue/candidate layout,
  Chinese locale after aligned surfaces,
  and restart persistence visual state.
- Next:
  fix the highest-impact Flutter home/browse/detail/settings/memory gaps,
  then recapture both sides and update the matrix.

### 2026-05-08 Step 163

- Implemented the first Phase 5.7 Flutter alignment slice for shell/home/browse/detail.
- Changed the Flutter first-run home from a dense setup+filter page into a hero-first surface with recent-memory/discovery hierarchy.
- Changed populated home so recent memories lead the page, browse/search/filter controls are more compact, and the photo grid is visible at 1280x720.
- Removed the always-on wide right detail column from the normal browse flow so the gallery is no longer squeezed by selection state.
- Added a capture-only detail-first state and rebuilt `DetailSurface` into a wide media-plus-inspector layout with metadata, favorite, rollback, caption, tag, and datetime controls visible in the first viewport.
- Updated responsive grid expectations after removing the persistent detail column:
  wide desktop now uses five columns instead of four.
- Updated the parity matrix with the improved first-run, populated browse, detail, favorites, and restart-persistence evidence.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh all`
  `bash tool/capture_flutter_parity.sh detail`
- Screenshot evidence:
  refreshed Flutter screenshots under `test-results/flutter-electron-parity/flutter/`,
  with key reviewed files:
  `01-empty-home.png`,
  `02-populated-grid.png`,
  and `05-detail.png`.
- Result:
  Task 5 in the Phase 5.7 implementation plan is complete,
  and the detail screenshot is now a valid first-viewport comparison surface.
- Next:
  continue Task 6 and Task 7 by aligning gallery metadata/filmstrip,
  memory list/detail product surfaces,
  settings grouping,
  notifications/AI queue layout,
  and locale parity.

### 2026-05-08 Step 164

- Continued Phase 5.7 page-level alignment for memories.
- Reworked the Flutter memories list into two Electron-aligned panels:
  AI-assisted grouping candidates,
  and browse memory collections.
- Moved memory candidate accept/reject actions into the memories page while preserving the existing notification-page actions and service methods.
- Reworked memory detail from a flat form/action panel into a cover-led detail hero plus a story-outline/chapter panel.
- Fixed the deterministic `memory-detail` capture state so title and description controllers are initialized when the app opens directly into that surface.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh memories-list`
  `bash tool/capture_flutter_parity.sh memory-detail`
- Screenshot evidence:
  refreshed Flutter `08-memories-list.png`
  and `09-memory-detail.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  memories list/detail are closer to Electron's product structure,
  but still remain open gaps until visual media treatment, read-first editing, and action placement are fully aligned.
- Next:
  align notifications so it becomes a queue/candidate center with settings handoff,
  then align settings AI/map grouping and gallery filmstrip metadata.

### 2026-05-09 Step 165

- Continued Phase 5.7 page-level alignment for notifications and settings.
- Moved editable AI configuration out of Notifications and into Settings so Notifications behaves like Electron's queue/candidate review center.
- Added map settings persistence through:
  `ChronoPicRepository.updateMapSettings`,
  `ChronoPicAppService.updateMapSettings`,
  and the Flutter settings UI.
- Reworked Notifications into two summary cards:
  AI queue,
  and memory candidates,
  with handoffs to Settings and Memories.
- Reordered Settings so the first viewport follows Electron more closely:
  library settings,
  language,
  backup/restore,
  then AI settings,
  with map settings and source/stat sections below.
- Tightened tests so candidate accept/reject is verified from Memories and AI/map configuration is verified from Settings.
- Fixed the Flutter capture harness so it can capture multiple named surfaces in one command,
  for example:
  `bash tool/capture_flutter_parity.sh settings notifications`.
- Verified:
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_app packages/chronopic_ui`
  `dart test packages/chronopic_app`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash -n chronopic_flutter/tool/capture_flutter_parity.sh`
  `bash tool/capture_flutter_parity.sh settings notifications`
- Screenshot evidence:
  refreshed Flutter `10-settings.png`
  and `11-notifications.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`,
  `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`,
  `PLAN.md`,
  and `docs/flutter-refactor-phases.md`.
- Result:
  Notifications and Settings are now structurally closer to Electron,
  but the matrix rows remain open until section density, wording, and exact first-viewport composition are finalized.
- Next:
  continue Task 6 for gallery filmstrip/metadata and focused viewer affordances,
  then recapture all 13 Flutter surfaces.

### 2026-05-09 Step 166

- Completed the focused Phase 5.7 Task 6 pass for gallery/detail/favorites/editing parity coverage.
- Added stronger gallery assertions in `linux_desktop_parity_test.dart` for:
  gallery metadata,
  memory/tag badge,
  detail-view affordance,
  filmstrip,
  and `D` key return-to-detail behavior.
- Reworked the Flutter fullscreen gallery so it now shows:
  a `Gallery View` label,
  counter,
  `Detail View` action,
  readable bottom metadata scrim,
  captured date,
  memory/tag badge,
  keyboard hint,
  and labeled gallery strip with item count.
- Fixed compact video thumbnail rendering so filmstrip thumbnails and small grid cells no longer overflow in tests.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `bash tool/capture_flutter_parity.sh gallery`
- Screenshot evidence:
  refreshed Flutter `06-gallery.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Task 6 is complete in the implementation plan,
  but the gallery matrix row remains open until final Electron-level visual/card framing is accepted or fully matched.
- Next:
  finish Task 7 by tightening remaining locale/map/timeline/page-level gaps,
  then run a full 13-surface recapture.

### 2026-05-09 Step 167

- Continued Phase 5.7 Task 7 by tightening map and timeline first-viewport parity.
- Reworked Flutter map browse from a simple GPS list into a desktop disabled/provider-failure map canvas with:
  mapped-photo count,
  map-provider status,
  placeholder route/marker treatment,
  and GPS photo selection below the canvas.
- Reworked Flutter timeline browse from a simple list into a timeline-specific hierarchy with:
  Year/Month/Day scope chips,
  date range summary,
  dated-photo count,
  grouped cards,
  and selectable photo cards.
- Fixed the Flutter screenshot harness parity size:
  `tool/capture_flutter_parity.sh` now captures 1440x920,
  and the Linux runner default window now opens at 1440x920 so screenshots no longer contain black unused areas.
- Expanded widget coverage for the new map disabled canvas and timeline scope controls.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash -n chronopic_flutter/tool/capture_flutter_parity.sh`
  `bash tool/capture_flutter_parity.sh map timeline`
- Screenshot evidence:
  refreshed Flutter `03-map.png`
  and `04-timeline.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`,
  `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`,
  `PLAN.md`,
  and `docs/flutter-refactor-phases.md`.
- Result:
  map and timeline are now screenshot-backed first-viewport parity improvements,
  but the matrix rows remain open until exact Electron card/chip/banner treatment is matched or accepted.
- Next:
  continue Task 7 with locale parity and remaining page-level polish,
  then rerun the full 13-surface capture.

### 2026-05-09 Step 168

- Continued Phase 5.7 Task 7 by tightening Chinese-locale first-viewport parity.
- Localized the visible Flutter home/shell surfaces that were still hard-coded in English:
  sidebar subtitle and section label,
  scan idle status,
  discovery/recent-memory labels,
  new-memory card,
  memory count/custom-cover badges,
  browse result count,
  filter labels,
  AI status choices,
  sort/date controls,
  active-filter prefix,
  and visible detail-panel heading/actions.
- Added widget assertions that the Chinese shell shows the localized scan status, library label, subtitle, recent-memory heading, new-memory card, and filter controls.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh zh-locale`
- Screenshot evidence:
  refreshed Flutter `12-zh-locale.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`,
  `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`,
  `PLAN.md`,
  and `docs/flutter-refactor-phases.md`.
- Result:
  Chinese first-viewport parity is materially improved,
  but the row remains open because the app title still identifies the Flutter build,
  source fixture memory/photo text remains authored data,
  and Electron's selected-photo banner differs from Flutter's detail-panel placement.
- Next:
  run a broader full-surface recapture and decide whether the remaining visual differences are accepted differences or need another UI pass.

### 2026-05-09 Step 169

- Re-ran the full Flutter parity capture after aligning the Linux window size with Electron.
- Confirmed every Flutter evidence screenshot is now 1440x920:
  `01-empty-home.png`,
  `02-populated-grid.png`,
  `03-map.png`,
  `04-timeline.png`,
  `05-detail.png`,
  `06-gallery.png`,
  `07-favorites.png`,
  `08-memories-list.png`,
  `09-memory-detail.png`,
  `10-settings.png`,
  `11-notifications.png`,
  `12-zh-locale.png`,
  and `13-restart-persistence.png`.
- Fixed the app-shell widget test so it no longer assumes persistent test state is empty and instead verifies stable shell navigation.
- Verified:
  `bash tool/capture_flutter_parity.sh all`
  `file test-results/flutter-electron-parity/flutter/*.png`
  `flutter analyze packages/chronopic_ui apps/chronopic`
  `flutter test apps/chronopic`
  `git diff --check`
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`.
- Result:
  Flutter screenshot evidence is now dimensionally comparable to Electron across all tracked surfaces,
  and the app package smoke test is stable against persistent state.
- Next:
  continue closing the remaining `Gap` rows by either matching the exact Electron card/chip/banner treatments or documenting accepted platform differences.

### 2026-05-09 Step 170

- Continued Phase 5.7 Settings parity.
- Replaced the simple Flutter language segmented control on the Settings page with an Electron-aligned language card:
  interface language select,
  AI output language select,
  and a `Save Language Settings` action.
- Added real locale-setting persistence through:
  `ChronoPicRepository.updateLocaleSettings`,
  `ChronoPicAppService.updateLocaleSettings`,
  and the Flutter settings/shell handlers.
- Kept ordinary parity captures in English by leaving the UI locale controlled by current UI/capture state rather than forcing the raw fixture backup locale onto every loaded surface.
- Fixed a responsive overflow in the new AI-output locale select by making both dropdowns expanded.
- Expanded widget coverage so changing to Chinese writes `LocaleSetting.zhCN` into backup settings and the Settings page exposes both locale controls plus the save action.
- Verified:
  `dart analyze packages/chronopic_database packages/chronopic_app packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh settings`
- Screenshot evidence:
  refreshed Flutter `10-settings.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `docs/flutter-electron-ui-functional-parity.md`
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Settings language controls now match Electron's functional shape more closely,
  while remaining Settings gaps are mostly section density, AI readiness card treatment, and backup action grouping.
- Next:
  continue with one of the remaining high-impact visual gaps:
  backup/AI settings card treatment,
  empty/populated home card composition,
  or memory card media treatment.

### 2026-05-09 Step 171

- Continued Phase 5.7 Map parity after comparing the Electron and Flutter `03-map.png` screenshots.
- Reworked Flutter's disabled-map canvas from a dark simulated route/map into an Electron-aligned pale failure surface:
  centered `MAP ERROR` label,
  `Map view failed to initialize` title,
  AMap-unavailable detail copy,
  and a retained mapped-count stat.
- Removed the duplicate in-panel Map header so the failed map surface is the first visual object inside the browse result panel, closer to the Electron first viewport.
- Kept the GPS photo selection list below the failed-map canvas and updated the widget test to scroll to that list before selecting a mapped photo.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `bash tool/capture_flutter_parity.sh map`
- Screenshot evidence:
  refreshed Flutter `03-map.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Map disabled-state styling and copy are now much closer to Electron,
  while the row remains open because top-of-page density and discovery-chip layout still differ.
- Next:
  continue with Timeline selected-photo/banner treatment or the home/grid discovery-chip/card composition.

### 2026-05-09 Step 172

- Continued Phase 5.7 Timeline parity after comparing Electron and Flutter `04-timeline.png`.
- Reworked Flutter's Timeline surface away from the dark hero treatment and toward Electron's light timeline card:
  Year/Month/Day scope chips,
  compact `Select` action,
  `TIMELINE SCOPE` summary strip,
  `SELECTED PHOTO` banner with `Open Detail`,
  month grouping,
  and selected-card highlighting.
- Threaded the selected photo into `TimelineBrowseView` so the timeline surface can show the current timeline focus instead of only listing grouped media.
- Updated widget coverage to assert the new `TIMELINE SCOPE` strip, selected-photo banner, and open-detail action while preserving map/timeline photo selection behavior.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `bash tool/capture_flutter_parity.sh timeline`
- Screenshot evidence:
  refreshed Flutter `04-timeline.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Timeline now has the key Electron visible structures,
  while the row remains open because exact top-of-page discovery-chip density and card proportions still differ.
- Next:
  continue with home/grid discovery-chip/card composition or memory card media treatment.

### 2026-05-09 Step 173

- Continued Phase 5.7 Home/Grid parity after comparing Electron and Flutter populated-grid screenshots.
- Added an Electron-like `SELECTED PHOTO` banner above the Flutter waterfall grid when a photo is selected.
- Scoped the banner to waterfall-style browse surfaces so populated grid, favorites, and restart-persistence captures gain the Electron selection affordance without adding the same banner to Map or Timeline, which have their own surface-specific structures.
- Updated widget coverage to assert the new `browse-selected-photo-banner` after selecting a grid photo.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence`
- Screenshot evidence:
  refreshed Flutter `02-populated-grid.png`,
  `07-favorites.png`,
  and `13-restart-persistence.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Waterfall-style browse surfaces now share the key Electron selected-photo affordance,
  while remaining browse gaps are mostly discovery-chip density, Select/Filter affordance placement, media-card proportions, and thumbnail fallback treatment.
- Next:
  continue with memory card media treatment or the remaining Electron-style discovery/search/filter composition.

### 2026-05-09 Step 174

- Continued Phase 5.7 memory card media parity after comparing Electron and Flutter memory-list/detail screenshots.
- Reworked shared Flutter memory cover fallback treatment:
  memory covers now render as framed media-style surfaces with a subtle image fallback marker and edge label instead of large centered book icons on gradient blocks.
- Reused the same cover treatment across:
  home recent-memory cards,
  memory list collection cards,
  memory detail hero cover,
  and memory detail story/chapter cards.
- Preserved the existing memory editing and management contract:
  title/description fields,
  save,
  add to memory,
  set cover,
  and remove from memory remain available and test-covered.
- Expanded widget coverage to assert the reusable `memory-cover-memory-weekend` surface is present in the desktop shell.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh memories-list memory-detail populated-grid`
- Screenshot evidence:
  refreshed Flutter `08-memories-list.png`,
  `09-memory-detail.png`,
  and `02-populated-grid.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Memory media fallback treatment is closer to Electron,
  while memory rows remain open because Electron's detail page is more read-first,
  actions are icon-positioned differently,
  and card proportions still differ.
- Next:
  continue with read-first memory detail treatment or the remaining Electron-style discovery/search/filter composition.

### 2026-05-09 Step 175

- Continued Phase 5.7 memory detail parity.
- Reworked the Flutter memory detail first viewport from a form-led layout into a read-first hero:
  large framed cover,
  compact top-right cover/remove actions,
  display title,
  cover status,
  description display card,
  and lightweight navigation/add actions.
- Moved editable memory metadata and membership controls into a lower `Memory management` panel so existing save/add/set-cover/remove behavior remains available but no longer dominates the Electron-comparison first viewport.
- Updated the Linux desktop parity test to scroll to the lower `add-to-memory-button` before tapping it, matching the new layout.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh memory-detail memories-list`
- Screenshot evidence:
  refreshed Flutter `09-memory-detail.png`
  and `08-memories-list.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Memory detail now matches Electron's read-first hierarchy much more closely,
  while remaining differences are mostly timestamp formatting,
  exact icon placement,
  and chapter-card proportions.
- Next:
  continue with Electron-style discovery/search/filter composition or remaining Settings/Notifications card-density polish.

### 2026-05-09 Step 176

- Ran the broader Flutter-side Phase 5.7 Task 7 verification after the recent map, timeline, grid, and memory-detail refinements.
- Verified:
  `dart analyze packages/chronopic_app packages/chronopic_ui`
  `flutter test packages/chronopic_ui apps/chronopic`
  `bash tool/capture_flutter_parity.sh all`
  `file test-results/flutter-electron-parity/flutter/*.png`
- Result:
  analysis passed,
  Flutter package/app tests passed,
  all 13 Flutter parity screenshots were recaptured,
  and every refreshed Flutter PNG is 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Note:
  Phase 5.7 is still not complete because the parity matrix still contains `Gap` rows and the full two-side Task 8 gate has not been run after the latest Flutter changes.
- Next:
  continue remaining Flutter visual polish or run the Electron-side gate when ready to assess final closure.

### 2026-05-09 Step 177

- Ran the Electron-side Phase 5.7 Task 8 gate after the Flutter-side recapture.
- `pnpm run e2e:runtime` initially failed because rapid same-millisecond edits could make `rollbackLatestEdit` roll back the wrong edit-history row.
- Fixed the real persistence bug in `packages/infra-db/src/index.ts`:
  rollback now orders ties by insertion order with `rowid DESC`,
  handles `caption` separately from `datetime`,
  and list history uses the same deterministic ordering.
- Added regression coverage in `tests/backup.test.ts` for rapid caption/tag/datetime edits with identical timestamps.
- Fixed the i18n E2E harness in `tests/e2e/i18n.spec.ts` so it runs against the built Electron app instead of forcing a Vite dev-server URL during the release-style gate; it now also uses an isolated `CHRONOPIC_USER_DATA_DIR`.
- Verified:
  `pnpm run native:node`
  `node --experimental-strip-types --test tests/backup.test.ts`
  `pnpm run e2e:runtime`
  `pnpm run e2e:backup`
  `pnpm run e2e:ai`
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`
  `node scripts/capture-electron-parity.mjs`
  `file test-results/flutter-electron-parity/electron/*.png`
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
- Result:
  Electron unit/type/build, runtime E2E, backup E2E, AI E2E, i18n E2E,
  and screenshot capture all pass;
  all 13 Electron parity screenshots are 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Note:
  Phase 5.7 still remains open because `docs/flutter-electron-ui-functional-parity.md`
  still contains `Gap` rows that need either additional visual/function work or explicit accepted-difference decisions.
- Next:
  audit the matrix row by row and decide whether to continue polishing remaining gaps or record accepted platform differences.

### 2026-05-09 Step 178

- Continued Phase 5.7 Detail inspector parity after comparing Electron and Flutter `05-detail.png`.
- Reworked Flutter's detail capture state from a plain inline detail panel into an Electron-like focused dark viewer:
  large media canvas,
  right-side inspector,
  keyboard hint,
  and gallery strip.
- Wired focused detail header controls to real behavior instead of visual placeholders:
  the add button routes the selected photo into the memory flow,
  the close button exits the focused detail state,
  and the gallery button opens the existing gallery dialog.
- Added widget regression coverage for the focused detail surface, filmstrip, and actionable add/close controls.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh detail`
- Screenshot evidence:
  refreshed Flutter `05-detail.png`
  under `test-results/flutter-electron-parity/flutter/`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Detail parity is materially closer to Electron's focused viewer model,
  while the row remains open for inspector card hierarchy,
  AI insight blocks,
  exact top-button treatment,
  and media fallback edge rendering.
- Next:
  continue row-by-row polishing of the remaining matrix gaps before closing Phase 5.7.

### 2026-05-09 Step 179

- Continued Phase 5.7 Detail inspector parity after reviewing the refreshed Flutter `05-detail.png`.
- Removed the remaining normal Flutter desktop chrome from the focused detail evidence path:
  the detail capture now uses an immersive shell without the sidebar,
  status banner,
  or browse toolbar.
- Reworked the focused detail inspector into a closer Electron-style read-first hierarchy:
  filename header,
  AI health pill,
  metadata metric cards,
  and an AI insights card backed by existing semantic metadata
  (`generatedCaption`, `summary`, `generatedLabels`, `aiStatus`, and `aiError`).
- Preserved the editing path by keeping caption, tag, datetime, favorite,
  rollback,
  and gallery actions inside the focused inspector scroll area.
- Extended widget regression coverage for the focused detail inspector grid and AI insights.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh detail`
  `file test-results/flutter-electron-parity/flutter/05-detail.png`
- Screenshot evidence:
  refreshed Flutter `05-detail.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  the Detail row is now much closer to Electron's focused overlay and inspector composition,
  while the parity matrix still keeps it open for exact button treatment,
  fallback media edge rendering,
  and lower edit-field scroll positioning.
- Next:
  continue with the remaining matrix rows rather than closing Phase 5.7.

### 2026-05-09 Step 180

- Continued Phase 5.7 Fullscreen gallery parity after comparing Electron and Flutter `06-gallery.png`.
- Reworked Flutter gallery layout to better match Electron's focused viewer hierarchy:
  a bordered dark media frame,
  metadata below the image instead of a large gray scrim,
  a visible Open Inspector action,
  and a separate framed gallery-strip container.
- Preserved the existing gallery behavior:
  previous/next buttons,
  filmstrip selection,
  `D` / Open Inspector returning to detail,
  and `Esc` close remain covered by existing widget tests.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh gallery`
  `file test-results/flutter-electron-parity/flutter/06-gallery.png`
- Screenshot evidence:
  refreshed Flutter `06-gallery.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Gallery parity is closer to Electron's viewer composition,
  while the row remains open for exact top chrome,
  media fallback edge rendering,
  and button styling.
- Next:
  continue with remaining browse/home/settings/notifications matrix gaps.

### 2026-05-09 Step 181

- Continued Phase 5.7 populated browse, favorites, and restart-persistence parity after comparing Electron and Flutter `02-populated-grid.png`.
- Added a functional Electron-like discovery lens row to the populated Flutter home/browse surface:
  Map switches to map browse,
  Timeline switches to timeline browse,
  and the Memory chip opens the corresponding memory detail page.
- Kept the discovery lens out of empty first-run state so the first-run screen does not gain extra non-reference controls.
- Extended widget coverage so the discovery chips are present in populated state and each chip navigates to a real surface.
- Cleaned up the timeline test interaction by ensuring the offscreen timeline card is visible before tapping it.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence`
  `file test-results/flutter-electron-parity/flutter/02-populated-grid.png test-results/flutter-electron-parity/flutter/07-favorites.png test-results/flutter-electron-parity/flutter/13-restart-persistence.png`
- Screenshot evidence:
  refreshed Flutter `02-populated-grid.png`,
  `07-favorites.png`,
  and `13-restart-persistence.png`
  under `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  browse-related surfaces now match Electron's discovery-lens model more closely,
  while the matrix remains open for exact Select/Filter affordances,
  card proportions,
  and thumbnail fallback styling.
- Next:
  continue with remaining Settings and Notifications density/action gaps,
  or tighten media card proportions and fallback styling.

### 2026-05-09 Step 182

- Continued Phase 5.7 Settings and Notifications parity after comparing Electron and Flutter `10-settings.png` / `11-notifications.png`.
- Reworked Flutter Notifications into an Electron-like outer container with two separate cards:
  AI queue and Memory candidates.
- Preserved notification behavior:
  `Enrich Queue` still retries failed AI queue items,
  and `Refresh Suggestions` still routes to memory review.
- Reworked Flutter Settings first viewport:
  library controls now lead with Electron-like primary actions,
  backup uses an `Export, Backup, and Restore` section with `LOCAL JSON` and three primary backup actions,
  and AI settings now show an `AI Enrichment` section with a readiness card and secret-safe `PRESENT` pills.
- Preserved existing functional controls:
  path-based library add,
  path-based backup export/restore,
  AI settings editing,
  and map settings editing remain available and covered.
- Updated widget tests so offscreen save controls are scrolled into view before tapping after the settings layout changed.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh settings notifications`
  `file test-results/flutter-electron-parity/flutter/10-settings.png test-results/flutter-electron-parity/flutter/11-notifications.png`
- Screenshot evidence:
  refreshed Flutter `10-settings.png`
  and `11-notifications.png`
  under `test-results/flutter-electron-parity/flutter/`,
  both confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  Settings and Notifications are materially closer to Electron's first-viewport hierarchy,
  while matrix rows remain open for exact chip/button color semantics,
  lower settings panels,
  and page/sidebar branding.
- Next:
  continue with media card proportions/fallback styling or run a row-by-row matrix audit before the next full two-side gate.

### 2026-05-09 Step 183

- Continued Phase 5.7 media-card parity after comparing Flutter populated-grid output against Electron's larger media cards.
- Reworked the Flutter photo grid density from a high-density 5-column desktop grid to a lower-density 3-column desktop grid with larger cards.
- Reworked photo cards from separate white preview/text cards into Electron-like media cards:
  full-card media/fallback surface,
  bottom gradient metadata layer,
  prominent title,
  favorite marker,
  and selected amber border.
- Improved missing-media fallback from a flat white placeholder to a soft gradient media surface.
- Updated adaptive-grid tests to reflect the new desktop media-card contract:
  3 columns on wide desktop,
  1 column on the narrow 840px fixture viewport.
- Verified:
  `dart analyze packages/chronopic_ui`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`
  `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence`
  `file test-results/flutter-electron-parity/flutter/02-populated-grid.png test-results/flutter-electron-parity/flutter/07-favorites.png test-results/flutter-electron-parity/flutter/13-restart-persistence.png`
- Screenshot evidence:
  refreshed Flutter `02-populated-grid.png`,
  `07-favorites.png`,
  and `13-restart-persistence.png`
  under `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  populated/favorites/restart media hierarchy is closer to Electron's large-card treatment,
  while rows remain open for exact filter affordances,
  crop height,
  and fallback edge treatment.
- Next:
  run a row-by-row matrix audit and decide whether remaining differences need more UI work or documented accepted-difference treatment before the next full two-side gate.

### 2026-05-09 Step 184

- Continued Phase 5.7 global shell and first-run parity after reviewing the refreshed Flutter screenshots.
- Aligned Flutter desktop brand chrome with Electron:
  app title now displays `ChronoPic`,
  and the sidebar subtitle now displays `Photo workspace`.
- Updated the Flutter app shell widget test and home widget test to assert the Electron-aligned app title.
- Re-ran a full Flutter parity capture after the brand change so all 13 Flutter evidence screenshots use the aligned shell chrome.
- Tightened first-run primary action naming and behavior:
  the hero now uses `Add Folder` for the folder-picker action,
  while the lower library toolbar still keeps the explicit path-based `Add Library` action.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui apps/chronopic`
  `bash tool/capture_flutter_parity.sh all`
  `file test-results/flutter-electron-parity/flutter/*.png`
  `bash tool/capture_flutter_parity.sh empty-home`
  `file test-results/flutter-electron-parity/flutter/01-empty-home.png`
- Screenshot evidence:
  all 13 Flutter parity screenshots were refreshed under `test-results/flutter-electron-parity/flutter/`
  and confirmed as 1440x920 after the brand update;
  `01-empty-home.png` was refreshed again after the `Add Folder` first-run action update.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  the global shell and empty first-run surfaces are closer to Electron,
  while Phase 5.7 remains open for row-by-row audit,
  remaining filter/control differences,
  and the final full two-side gate.
- Next:
  perform the matrix completion audit before deciding whether any remaining rows can be accepted or need more implementation.

### 2026-05-09 Step 185

- Wrote the explicit continuation plan for the remaining Phase 5.7 UI and functional parity work.
- Updated the implementation plan with a row-by-row closure loop:
  compare Electron and Flutter screenshots,
  record the precise gap,
  add or tighten functional tests where needed,
  implement the smallest coherent Flutter change,
  recapture the affected Flutter surface,
  re-check both screenshots,
  then update the matrix and execution logs before moving on.
- Added the current closure order:
  empty first-run home,
  populated grid/favorites/restart media surfaces,
  map/timeline,
  detail/gallery,
  memories list/detail,
  settings/notifications,
  Chinese locale,
  then the full two-side verification gate.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Verification:
  `git diff --check`
  passes.
- Next:
  execute the first remaining row,
  starting with empty first-run home screenshot parity.

### 2026-05-09 Step 186

- Executed the first remaining Phase 5.7 row:
  empty first-run home parity.
- Rechecked Electron and Flutter `01-empty-home.png` screenshots.
- Tightened Flutter empty-first-run behavior:
  the home first viewport no longer renders the lower path-based library
  toolbar or the full filter toolbar when there are no photos and no active
  filters.
- Preserved operational functionality by keeping path-based add/scan controls
  in Settings,
  and updated the Linux directory scan test to add/scan from Settings before
  returning to All Photos.
- Added a `Create First Memory` CTA to the recent-memory empty state and wired
  it to the Memories page so the Flutter empty-state card matches Electron's
  visible creation affordance more closely.
- Fixed a related filtered-empty regression:
  filter controls now remain visible when an active search/filter returns zero
  photos,
  so the app does not fall back to first-run onboarding during filtered results.
- Added widget coverage for the empty first-run composition:
  no lower library path field,
  no Add Library / Scan Library toolbar buttons,
  no Tag/GPS/Apply/Clear filter controls,
  and a functional Create First Memory handoff.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh empty-home`
  `file test-results/flutter-electron-parity/flutter/01-empty-home.png`
- Screenshot evidence:
  refreshed Flutter `01-empty-home.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  empty first-run parity is materially closer to Electron,
  while the matrix row remains open for exact spacing,
  button styling,
  top status chrome,
  and sidebar utility placement.
- Next:
  continue with populated grid/favorites/restart media surfaces,
  especially Select/Filter affordances,
  media-card crop height,
  and fallback edge treatment.

### 2026-05-09 Step 187

- Executed the next Phase 5.7 browse-surface parity slice for:
  populated grid,
  Favorites,
  and Restart Persistence.
- Compared Electron and Flutter `02-populated-grid.png` / `07-favorites.png`
  screenshots and confirmed Flutter's full first-viewport filter panel was the
  main remaining browse-toolbar mismatch.
- Reworked Flutter home browse controls so the first viewport now shows compact
  Electron-like `Select` and `Filter` buttons beside search instead of rendering
  the full filter panel by default.
- Kept filtering functional:
  the `Filter` button expands the existing filter panel,
  and active search/tag/GPS/AI/date/sort states keep the panel visible even when
  results are empty.
- Kept navigation-scoped Favorites from forcing the full filter panel open,
  so Favorites now matches Electron's compact toolbar shape more closely.
- Updated widget/parity tests to open the filter panel explicitly before using
  tag/GPS/AI controls,
  while retaining coverage for filtered-empty states.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence`
  `file test-results/flutter-electron-parity/flutter/02-populated-grid.png test-results/flutter-electron-parity/flutter/07-favorites.png test-results/flutter-electron-parity/flutter/13-restart-persistence.png`
- Screenshot evidence:
  refreshed Flutter `02-populated-grid.png`,
  `07-favorites.png`,
  and `13-restart-persistence.png`
  under `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  browse toolbar parity is materially closer to Electron for populated,
  Favorites,
  and Restart Persistence surfaces,
  while matrix rows remain open for exact card crop height,
  fallback edge treatment,
  memory-card fallback rendering,
  and shell chrome.
- Next:
  continue with media-card crop/fallback treatment or move to map/timeline
  discovery-chip top-density differences.

### 2026-05-09 Step 188

- Re-ran Map and Timeline parity capture after the compact Select/Filter
  browse-toolbar pass because that shared toolbar affects their first viewport.
- Verified:
  `bash tool/capture_flutter_parity.sh map timeline`
  `file test-results/flutter-electron-parity/flutter/03-map.png test-results/flutter-electron-parity/flutter/04-timeline.png`
- Screenshot evidence:
  refreshed Flutter `03-map.png`
  and `04-timeline.png`
  under `test-results/flutter-electron-parity/flutter/`,
  both confirmed as 1440x920.
- Result:
  Map and Timeline now inherit reduced toolbar density while preserving the
  disabled-map canvas and timeline card behavior already implemented.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact discovery-chip density,
  timeline card/header proportions,
  map canvas vertical position,
  and shell/sidebar chrome.
- Next:
  continue with media-card crop/fallback treatment or memory list/detail card
  proportions.

### 2026-05-09 Step 189

- Continued Phase 5.7 media-card and fallback parity.
- Reworked Flutter browse media cards from a short card ratio to a taller card
  ratio,
  closer to Electron's first-viewport media card crop.
- Replaced centered missing-media icons with a shared edge-style fallback:
  top-left broken-image icon plus path/name text,
  light-to-grey vertical gradient,
  and no large centered placeholder.
- Applied the same fallback treatment to memory cover surfaces so home,
  memory list,
  and memory detail use the same visual language.
- Updated the widget expectation that selected map photo path text may now
  appear both in the fallback surface and detail text.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh populated-grid favorites restart-persistence detail gallery memories-list memory-detail`
  `file test-results/flutter-electron-parity/flutter/02-populated-grid.png test-results/flutter-electron-parity/flutter/05-detail.png test-results/flutter-electron-parity/flutter/06-gallery.png test-results/flutter-electron-parity/flutter/07-favorites.png test-results/flutter-electron-parity/flutter/08-memories-list.png test-results/flutter-electron-parity/flutter/09-memory-detail.png test-results/flutter-electron-parity/flutter/13-restart-persistence.png`
- Screenshot evidence:
  refreshed Flutter `02-populated-grid.png`,
  `05-detail.png`,
  `06-gallery.png`,
  `07-favorites.png`,
  `08-memories-list.png`,
  `09-memory-detail.png`,
  and `13-restart-persistence.png`
  under `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  media-card crop and fallback treatment are materially closer to Electron
  across browse,
  detail/gallery,
  and memory surfaces.
- Next:
  continue with memory list/detail proportions and candidate generate/refresh
  affordances,
  or tighten remaining shell/sidebar chrome differences.

### 2026-05-09 Step 190

- Continued Phase 5.7 Memories List parity after comparing Electron and Flutter
  `08-memories-list.png`.
- Reworked the Flutter memory-candidate panel with:
  `SUGGESTED MEMORIES` eyebrow,
  longer Electron-like explanatory copy,
  a `1 READY` chip,
  and a `Generate` button.
- Wired `Generate` to a real refresh/read action instead of a fake generation
  path:
  it recounts pending memory candidates and updates the shell status with
  `Memory suggestions refreshed: 1 ready`.
- Reworked the candidate card closer to Electron:
  larger cover,
  source/confidence chips on the cover,
  title in a bordered title card,
  suggested-photo/confidence detail text,
  `Adjust photos`,
  and icon+text Reject / Accept Memory actions.
- Added widget coverage for the Generate/refresh affordance and Adjust photos
  text.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh memories-list`
  `file test-results/flutter-electron-parity/flutter/08-memories-list.png`
- Screenshot evidence:
  refreshed Flutter `08-memories-list.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  memories-list candidate affordances and card hierarchy are much closer to
  Electron,
  while exact candidate/card proportions remain open.
- Next:
  continue with memory detail proportions/timestamps or Settings/Notifications
  color and panel density.

### 2026-05-09 Step 191

- Continued Phase 5.7 Memory Detail parity after comparing Electron and Flutter
  `09-memory-detail.png`.
- Tightened the Flutter memory-detail hero and story section toward the
  Electron reference:
  full updated timestamp formatting,
  calendar icon row,
  `MEMORY DETAIL` / custom-cover / description hierarchy,
  `STORY OUTLINE` section,
  and chapter-card metadata for month/day,
  mapped count,
  and AI readiness.
- Kept the editable title/description/add/remove/cover controls available in
  the lower management panel so the first viewport stays read-first like
  Electron.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh memory-detail`
  `file test-results/flutter-electron-parity/flutter/09-memory-detail.png test-results/flutter-electron-parity/electron/09-memory-detail.png`
- Screenshot evidence:
  refreshed Flutter `09-memory-detail.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920 alongside the Electron reference.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact shell/sidebar chrome,
  chip colors,
  icon treatment,
  and card spacing.
- Next:
  continue with Settings/Notifications visual semantics or the shared
  shell/sidebar chrome gaps that still affect most matrix rows.

### 2026-05-09 Step 192

- Continued Phase 5.7 Notifications parity after comparing Electron and
  Flutter `11-notifications.png`.
- Moved the Flutter Notifications title and subtitle into the same white
  content card as the AI queue and Memory candidates cards,
  matching Electron's page hierarchy more closely.
- Replaced uniform notification chips with Electron-like semantic chips:
  blue for AI queue / memory candidates,
  red for failed,
  green for ready queue items,
  and yellow for ready memory candidates.
- Kept the existing retry and memory-review actions wired to the real callbacks.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh notifications`
  `file test-results/flutter-electron-parity/flutter/11-notifications.png test-results/flutter-electron-parity/electron/11-notifications.png`
- Screenshot evidence:
  refreshed Flutter `11-notifications.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920 alongside the Electron reference.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact button color semantics,
  card spacing,
  and global sidebar/top chrome.
- Next:
  continue with Settings panel density/button semantics,
  then return to shared shell/sidebar chrome if it remains the dominant gap
  across rows.

### 2026-05-09 Step 193

- Continued Phase 5.7 Settings parity after comparing Electron and Flutter
  `10-settings.png`.
- Reworked the Flutter Settings first viewport so `Library Settings`,
  its description,
  and the Add Folder / Scan Library actions live in one Electron-like top card.
- Moved manual path import into a lower `Manual library path` panel,
  preserving path-based add-library support without cluttering the first
  viewport.
- Updated the path-import parity test to scroll the now-lower
  `add-library-button` into view before tapping it.
- Tightened settings visual semantics:
  Add Folder and Restore Backup now use Electron-like orange primary treatment,
  Save Language Settings uses a white secondary action,
  `LOCAL JSON` uses a blue status chip,
  and AI readiness uses green `CONFIGURED` / `PRESENT` chips.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh settings`
  `file test-results/flutter-electron-parity/flutter/10-settings.png test-results/flutter-electron-parity/electron/10-settings.png`
- Screenshot evidence:
  refreshed Flutter `10-settings.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920 alongside the Electron reference.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact section heights,
  backup path controls still appear earlier than Electron,
  and global sidebar/top chrome.
- Next:
  return to shared shell/sidebar chrome or continue reducing backup/settings
  lower-panel density before the full two-side gate.

### 2026-05-09 Step 194

- Continued Phase 5.7 shared desktop shell parity after reviewing the refreshed
  non-immersive Flutter screenshots against Electron.
- Reworked the Flutter sidebar/top chrome toward Electron:
  moved Notifications from the Library nav list into a header bell button with
  the same `notifications-nav` key,
  added an Electron-like `Recent` library row,
  added a bottom `Create Memory` action,
  and removed the always-visible idle scan-status top bar from normal pages.
- Kept scan status available for non-idle states and kept the Notifications
  route reachable through the header bell.
- Updated the Chinese locale widget test to switch language through the real
  Settings language control instead of the removed sidebar-bottom locale
  switcher.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh all`
  `file test-results/flutter-electron-parity/flutter/*.png`
- Screenshot evidence:
  refreshed all 13 Flutter parity screenshots under
  `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Spot-checked:
  `02-populated-grid.png`,
  `10-settings.png`,
  and `12-zh-locale.png`
  to verify the sidebar notification button,
  bottom Create Memory action,
  Recent row,
  and removed idle top bar.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  page-specific card dimensions,
  browse spacing,
  backup/settings lower-panel density,
  and detail/gallery exact button treatment.
- Next:
  continue row-by-row from the matrix,
  likely with browse card dimensions/spacing or detail/gallery top controls,
  before attempting the final two-side gate.

### 2026-05-09 Step 195

- Continued Phase 5.7 browse parity after comparing Electron and Flutter
  `02-populated-grid.png`.
- Renamed the primary browse mode from `Grid` to Electron's `Waterfall`,
  including the Simplified Chinese label `瀑布流`.
- Updated the selected-photo banner copy from filename/focus text to
  Electron's memory-membership message:
  `This photo is not saved to any memory yet.`
- Updated the affected widget expectations for the renamed browse mode and the
  Settings-driven Chinese locale switch path.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh populated-grid map timeline favorites zh-locale restart-persistence`
  `file test-results/flutter-electron-parity/flutter/02-populated-grid.png test-results/flutter-electron-parity/flutter/03-map.png test-results/flutter-electron-parity/flutter/04-timeline.png test-results/flutter-electron-parity/flutter/07-favorites.png test-results/flutter-electron-parity/flutter/12-zh-locale.png test-results/flutter-electron-parity/flutter/13-restart-persistence.png`
- Screenshot evidence:
  refreshed Flutter `02-populated-grid.png`,
  `03-map.png`,
  `04-timeline.png`,
  `07-favorites.png`,
  `12-zh-locale.png`,
  and `13-restart-persistence.png`
  under `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact browse card dimensions,
  memory-card proportions,
  detail/gallery top controls,
  and final full two-side gate.
- Next:
  continue with detail/gallery top-control parity or reduce the remaining
  browse/card spacing differences before closure audit.

### 2026-05-09 Step 196

- Continued Phase 5.7 Detail inspector parity after comparing Electron and
  Flutter `05-detail.png`.
- Added Electron-like focused detail top controls:
  Add,
  Close,
  Previous,
  Next,
  and Gallery,
  with dark enabled buttons,
  disabled navigation state,
  and highlighted Add treatment.
- Wired Previous / Next to the real selected-photo callback instead of adding
  visual-only buttons.
- Fixed the Flutter capture fixture selection order so capture surfaces select
  the same first fixture photo as Electron (`backup-city.png`) instead of
  starting on the second item.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh all`
  `file test-results/flutter-electron-parity/flutter/*.png`
- Screenshot evidence:
  refreshed all 13 Flutter parity screenshots under
  `test-results/flutter-electron-parity/flutter/`,
  all confirmed as 1440x920.
- Spot-checked:
  `05-detail.png`
  to verify the first-photo selection and top-control group.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  detail inspector status-chip semantics,
  exact focused-view button sizing,
  lower editable-field scroll position,
  and the remaining row-level matrix gaps.
- Next:
  inspect and align detail inspector health/status semantics,
  then reassess whether the remaining row gaps are close enough for accepted
  differences or require more implementation.

### 2026-05-09 Step 197

- Continued Phase 5.7 Detail inspector parity after the focused-detail
  top-controls pass.
- Corrected the inspector status chip semantics:
  it now reports file/index health from `IndexState`
  and shows `HEALTHY` for indexed, present, error-free media,
  while AI pipeline failure remains visible in the AI metric and AI insights.
- This matches the Electron detail reference where `backup-city.png` is
  inspector-healthy despite an AI fixture error.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh detail`
  `file test-results/flutter-electron-parity/flutter/05-detail.png test-results/flutter-electron-parity/electron/05-detail.png`
- Screenshot evidence:
  refreshed Flutter `05-detail.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920 alongside the Electron reference.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact focused-view top-button sizing,
  lower editable-field scroll position,
  gallery top chrome,
  and unresolved matrix rows.
- Next:
  compare `06-gallery.png` and tighten gallery controls/selection state,
  or begin a completion audit to identify the next highest-value remaining
  matrix gap before running the full two-side gate.

### 2026-05-09 Step 198

- Continued Phase 5.7 Fullscreen Gallery parity after comparing Electron and
  Flutter `06-gallery.png`.
- Removed Flutter-only gallery chrome that Electron does not show:
  the top-left back arrow and top-right close icon.
- Restyled gallery actions toward Electron:
  `Detail View` and `Open Inspector` now use dark button treatment,
  side navigation uses dark translucent buttons,
  and the filmstrip count uses `2 ITEMS`.
- Aligned gallery metadata:
  captured date now includes time,
  and the memory badge now shows `NOT IN ANY MEMORY` instead of photo tags.
- Updated gallery tests to assert the dialog via `gallery-dialog` and close it
  through `open-inspector-button`,
  matching the new Electron-style control surface.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh gallery`
  `file test-results/flutter-electron-parity/flutter/06-gallery.png test-results/flutter-electron-parity/electron/06-gallery.png`
- Screenshot evidence:
  refreshed Flutter `06-gallery.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920 alongside the Electron reference.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact top chip styling,
  media-frame height,
  navigation opacity,
  and the broader matrix closure/final gate.
- Next:
  audit the matrix rows to decide whether remaining visual differences should
  be implemented,
  accepted with reasons,
  or left for another focused parity slice before the full gate.

### 2026-05-09 Step 199

- Continued Phase 5.7 Settings parity after the matrix audit identified backup
  path controls as the clearest remaining non-micro Settings gap.
- Moved backup JSON path input and choose-file actions out of the primary
  backup card into a lower `Backup file path` panel.
- Preserved path-based export/restore functionality and existing backup tests.
- Verified:
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart apps/chronopic`
  `bash tool/capture_flutter_parity.sh settings`
  `file test-results/flutter-electron-parity/flutter/10-settings.png test-results/flutter-electron-parity/electron/10-settings.png`
- Screenshot evidence:
  refreshed Flutter `10-settings.png`
  under `test-results/flutter-electron-parity/flutter/`,
  confirmed as 1440x920 alongside the Electron reference.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Remaining gaps:
  exact section heights,
  lower AI/map/source panel density,
  and final matrix/gate closure.
- Next:
  perform a fuller matrix audit and decide whether remaining visual deltas are
  implementation work or documented accepted differences before running the
  full two-side verification gate.

### 2026-05-09 Step 200

- Ran the full Phase 5.7 two-side verification gate after closing the
  row-by-row parity matrix.
- Electron verification:
  `pnpm test && pnpm typecheck && pnpm build`
  passed with 42 Node tests,
  successful TypeScript checks,
  and a production renderer build.
- Electron E2E verification:
  `pnpm run e2e:runtime`,
  `pnpm run e2e:backup`,
  `pnpm run e2e:ai`,
  and
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`
  each passed.
- Electron screenshot evidence:
  `node scripts/capture-electron-parity.mjs`
  refreshed all 13 reference PNGs under
  `test-results/flutter-electron-parity/electron/`;
  `file test-results/flutter-electron-parity/electron/*.png`
  confirmed every PNG is 1440x920.
- Flutter verification:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  database tests in `packages/chronopic_database`,
  full package `dart analyze`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  and `flutter build linux --debug` all passed.
- Flutter screenshot evidence:
  `bash tool/capture_flutter_parity.sh all`
  refreshed all 13 Flutter PNGs under
  `test-results/flutter-electron-parity/flutter/`;
  `file ../test-results/flutter-electron-parity/flutter/*.png`
  confirmed every PNG is 1440x920.
- Hygiene and dependency verification:
  `flutter pub outdated`
  reports all direct Flutter dependencies are up to date and that newer
  dev/transitive versions are not mutually compatible with the current
  resolvable set;
  `git diff --check`
  produced no output;
  `comm -3` over the Electron and Flutter screenshot filenames produced no
  output,
  confirming both capture directories contain the same 13 surface names.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and
  `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`.
- Result:
  the Phase 5.7 matrix has no remaining unexamined `Gap` rows;
  remaining visual differences are documented as accepted renderer or
  fixture-content differences.
- Implementation commit:
  `223d9e8`
  (`Align Flutter desktop with Electron UI flows`).
- Next:
  push `flutter-refactor-phases` after committing the matrix/doc update that
  records `223d9e8`.

### 2026-05-09 Step 201

- Completed the Phase 5.7 git handoff.
- Committed the implementation:
  `223d9e8 Align Flutter desktop with Electron UI flows`.
- Committed the matrix/evidence update:
  `50bba7c Record Flutter parity closure evidence`.
- Pushed branch `flutter-refactor-phases` to
  `github.com:denghongcai/ChronoPic.git`,
  advancing the remote from `eed8bd2` to `50bba7c`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and
  `docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md`
  to mark the handoff complete.
- Next:
  keep mobile Phase 6 blocked until the pushed desktop parity branch is
  reviewed or merged.

### 2026-05-09 Step 202

- Started Phase 5.8 Gallery Overlay Activation Parity after code comparison
  showed the direct photo-card activation path was not aligned.
- Electron finding:
  `packages/ui-components/src/photo-card.tsx`
  currently wires `onDoubleClick` to detail mode,
  while `packages/ui-components/src/photo-viewer-overlay.tsx`
  already has a fullscreen gallery overlay.
- Flutter finding:
  `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  currently wires browse photo cards only to selection,
  while `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
  already has a fullscreen `Dialog.fullscreen` gallery.
- Wrote the implementation plan:
  `docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md`.
- Reopened the relevant parity matrix rows:
  populated grid/waterfall browse,
  fullscreen gallery,
  favorites,
  and restart persistence.
- Added an explicit UI screenshot comparison gate:
  after interaction alignment,
  both Electron and Flutter must recapture and compare populated browse,
  gallery,
  favorites,
  and restart-persistence PNGs before the rows can close.
- Next:
  implement failing Electron and Flutter tests for double-click/double-tap
  focused viewer activation,
  then wire the activation path and rerun focused screenshots.

### 2026-05-09 Step 203

- Implemented the first Phase 5.8 attempt locally.
- This attempt was superseded by Step 205 after user review clarified the
  Electron reference model is Detail-first rather than direct-to-Gallery.
- Electron changes:
  `PhotoCard` now has explicit `onOpenGallery`;
  this first attempt incorrectly made double-click open gallery,
  while Enter remained detail;
  gallery activation is threaded through gallery,
  timeline,
  memory-detail,
  and app-level `PhotoHome` surfaces.
- Flutter changes:
  `BrowseSurface`,
  `PhotoGrid`,
  and `PhotoCardTile` now accept `onOpenGallery`;
  cards use an immediate custom tap/double-tap detector so single tap selects
  immediately and the second tap opens fullscreen `GalleryDialog`;
  selected-photo `G` opens gallery,
  and Enter opens focused detail.
- Red/green evidence:
  Electron accessibility E2E initially failed because card double-click did not
  expose a gallery dialog;
  Flutter parity test initially failed because card double-tap did not expose
  `gallery-dialog`.
- Verification:
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts`
  `pnpm run e2e:runtime`
  `pnpm typecheck`
  `pnpm build`
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`
- Screenshot evidence:
  `node scripts/capture-electron-parity.mjs`
  refreshed Electron screenshots;
  `bash tool/capture_flutter_parity.sh populated-grid gallery favorites restart-persistence`
  refreshed focused Flutter screenshots;
  all focused PNGs were confirmed as 1440x920.
- Screenshot comparison:
  generated side-by-side compare artifacts under
  `test-results/flutter-electron-parity/compare/`;
  inspected `06-gallery-compare.png`
  and `02-populated-grid-compare.png`
  to confirm fullscreen gallery hierarchy,
  navigation,
  metadata,
  filmstrip,
  and browse card hierarchy remain aligned.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and
  `docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md`.
- Implementation commit:
  `7efb12e Align gallery overlay activation`.
- Next:
  run `git diff --check`,
  write the implementation commit into the reopened matrix rows,
  and push `flutter-refactor-phases`.

### 2026-05-09 Step 204

- Completed the Phase 5.8 git handoff.
- Committed the implementation:
  `7efb12e Align gallery overlay activation`.
- Committed the matrix/evidence update, followed by handoff documentation:
  `fb01fe5 Record gallery overlay parity evidence`.
- Pushed branch `flutter-refactor-phases` to
  `github.com:denghongcai/ChronoPic.git`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and
  `docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md`
  to mark the handoff complete.
- Next:
  perform a completion audit against Phase 5.8 requirements.

### 2026-05-09 Step 205

- Re-reviewed Phase 5.8 after user feedback clarified the Electron reference
  interaction was misunderstood in Step 203.
- Corrected the target model:
  photo-card double-click/double-tap opens the focused Detail viewer overlay,
  not Gallery directly;
  Gallery remains the second viewer mode opened by `G` or the Detail overlay's
  Gallery action;
  Gallery `D`,
  `Detail View`,
  and `Open Inspector` return to focused Detail.
- Electron correction:
  restored `PhotoCard` double-click to `onOpenDetail`;
  updated accessibility E2E to assert double-click-to-Detail,
  Detail-to-Gallery,
  Gallery `D`-to-Detail,
  selected-card `G`-to-Gallery,
  and Escape close.
- Flutter correction:
  changed browse card double-tap to open focused Detail;
  changed `GalleryDialog` to return an explicit close/detail result so
  Gallery can switch back to focused Detail instead of silently dropping to the
  page;
  updated Linux parity tests for double-tap-to-Detail,
  focused Detail-to-Gallery,
  Gallery `D`-to-focused-Detail,
  and `Detail View` / `Open Inspector` return behavior.
- Verification:
  `pnpm typecheck`
  `pnpm build`
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts accessibility.spec.ts`
  `pnpm run e2e:runtime`
  `dart analyze packages/chronopic_ui apps/chronopic`
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`
- Screenshot evidence:
  recaptured Electron screenshots with
  `node scripts/capture-electron-parity.mjs`;
  recaptured Flutter screenshots with
  `bash tool/capture_flutter_parity.sh populated-grid detail gallery`;
  confirmed `02-populated-grid`,
  `05-detail`,
  and `06-gallery` PNGs are 1440x920 on both sides;
  generated side-by-side compare artifacts under
  `test-results/flutter-electron-parity/compare/`;
  inspected `05-detail-compare.png` and `06-gallery-compare.png`.
- Implementation correction commit:
  `96ba222 Restore detail-first viewer activation`.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  and
  `docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md`.
- Next:
  commit and push the corrected documentation handoff.

### 2026-05-09 Step 206

- Started Phase 5.9 Full Feature UI Parity Review after user requested the
  same evidence-first approach across all feature and UI points.
- Locked the method:
  Electron reference code/runtime first,
  Flutter code comparison second,
  behavior tests third,
  refreshed screenshots fourth,
  then explicit `Matched`,
  `Accepted Difference`,
  or `Gap` decisions.
- Created the review implementation plan:
  `docs/superpowers/plans/2026-05-09-feature-ui-parity-review.md`.
- Created the detailed review report:
  `docs/flutter-electron-feature-ui-review.md`.
- Updated:
  `PLAN.md`
  and
  `docs/flutter-refactor-phases.md`
  with the new review phase.
- Current evidence state:
  Electron has all 13 parity screenshots from the latest capture;
  Flutter currently has only the recently refreshed focused surfaces in
  `test-results/flutter-electron-parity/flutter/`.
- Next:
  refresh all 13 Flutter screenshots,
  regenerate all 13 side-by-side compare artifacts,
  then review each matrix surface in order.

### 2026-05-09 Step 207

- Refreshed Phase 5.9 evidence:
  Electron all 13 parity screenshots,
  Flutter all 13 parity screenshots,
  all 13 side-by-side compare images,
  and a contact sheet for first-pass visual inspection.
- Reviewed all 13 surfaces against code,
  tests,
  and screenshots:
  empty home,
  populated grid,
  map,
  timeline,
  detail,
  gallery,
  favorites,
  memories list,
  memory detail,
  settings,
  notifications,
  Chinese locale,
  and restart persistence.
- Updated `docs/flutter-electron-feature-ui-review.md` with per-surface
  decisions.
- Confirmed that the previous Detail/Gallery interaction issue is now aligned:
  double-click/double-tap enters focused Detail first,
  and Gallery is the second mode inside the viewer.
- Found one confirmed remaining parity gap:
  Flutter zh mode still contains app-owned English UI strings.
  The screenshot evidence is
  `test-results/flutter-electron-parity/compare/12-zh-locale-compare.png`,
  where the selected-photo banner remains English in Flutter.
- Static review found the localization issue is broader than that screenshot:
  active filter labels,
  status messages,
  Detail/Gallery controls,
  memory actions,
  settings actions,
  notifications,
  map controls,
  and timeline actions still have hardcoded English paths.
- Updated `docs/flutter-electron-ui-functional-parity.md` so the Chinese
  locale row is now `Gap` instead of `Accepted Difference`.
- Promoted the gap into Phase 5.10:
  Flutter Visible String Localization Parity.
- Created the Phase 5.10 implementation plan:
  `docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md`.
- Updated:
  `PLAN.md`
  and
  `docs/flutter-refactor-phases.md`
  to record Phase 5.10.
- Next:
  add failing zh locale tests for the selected-photo banner and active filter
  labels before changing implementation strings.

### 2026-05-09 Step 208

- Ran the Phase 5.9 verification gate after the review documentation and Phase
  5.10 promotion were recorded.
- Agent verification scenes covered:
  Scene 4 Focused Viewing through Electron accessibility E2E,
  Scene 7 Restart Persistence through Electron runtime E2E,
  Scene 8 Settings/Locale through the refreshed settings and zh-locale
  screenshots plus Flutter locale tests,
  and Scene 9 Notifications/AI Queue through the refreshed notifications
  screenshot and existing Electron AI productization coverage reference.
- Generated/inspected screenshot evidence:
  `test-results/flutter-electron-parity/electron/*.png`,
  `test-results/flutter-electron-parity/flutter/*.png`,
  `test-results/flutter-electron-parity/compare/*.png`,
  and
  `test-results/flutter-electron-parity/compare/all-surfaces-contact.png`.
- Verification commands passed:
  `node scripts/capture-electron-parity.mjs`,
  `file test-results/flutter-electron-parity/electron/*.png`,
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  `file test-results/flutter-electron-parity/flutter/*.png`,
  compare artifact generation with `montage`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm typecheck`,
  `pnpm build`,
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`,
  and
  `git diff --check`.
- Skipped scenes:
  no manual Electron mutation scene was added beyond the stable E2E coverage
  because this slice changed review/planning documentation and did not change
  runtime implementation.
- Next:
  start Phase 5.10 with red zh-locale tests before localizing Flutter strings.

### 2026-05-09 Step 209

- Started Phase 5.10:
  Flutter Visible String Localization Parity.
- Added a red Flutter zh regression test in
  `chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart`
  covering app-owned visible strings across:
  selected-photo banners,
  active filter labels,
  focused Detail/Gallery controls,
  memory list/detail actions,
  settings,
  notifications,
  map,
  timeline,
  and status messages.
- Confirmed the test failed before implementation on the selected-photo banner:
  expected `已选照片`,
  but the Flutter UI still rendered the English `SELECTED PHOTO` path.
- Localized the Flutter app-owned strings while preserving source-authored
  filenames,
  captions,
  memory names,
  imported descriptions,
  tags,
  and AI/fixture text.
- Updated the affected UI surfaces:
  `chronopic_home.dart`,
  `home_page.dart`,
  `browse_surface.dart`,
  `detail_surface.dart`,
  `gallery_dialog.dart`,
  `memory_pages.dart`,
  and
  `settings_pages.dart`.
- Refreshed focused visual evidence:
  Flutter zh/detail/gallery/settings/notifications/memories-list/memory-detail/map/timeline screenshots,
  Electron reference screenshots,
  and affected side-by-side compare artifacts under
  `test-results/flutter-electron-parity/compare/`.

### 2026-05-09 Step 210

- Ran the Phase 5.10 verification gate after implementation and documentation
  updates.
- Agent verification scenes covered:
  Scene 4 Focused Viewing through localized Detail/Gallery widget coverage and
  Electron accessibility E2E,
  Scene 8 Settings/Locale through the zh-locale screenshot,
  Flutter zh regression test,
  and Electron i18n E2E,
  and Scene 9 Notifications/AI Queue through localized notification assertions
  and refreshed screenshot evidence.
- Verification commands passed:
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts`,
  and
  `git diff --check`.
- Updated
  `docs/flutter-electron-feature-ui-review.md`
  to close `FUI-001`.
- Updated
  `docs/flutter-electron-ui-functional-parity.md`
  so the Chinese-locale row is no longer a `Gap`.
- Updated
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  and
  `docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md`
  to mark Phase 5.10 implemented and verified.
- Skipped broader Electron runtime/build gates in this slice because no
  Electron runtime implementation changed; the focused Electron i18n and
  accessibility E2E checks were rerun to cover the cross-surface parity risk.
- Next:
  continue the same evidence-first review process for any newly identified
  feature/UI deltas before opening Phase 6 mobile productization work.

### 2026-05-09 Step 211

- Performed the desktop baseline freeze gate after commit `acb6794`.
- Updated
  `docs/flutter-electron-ui-functional-parity.md`
  so the Chinese-locale row points to fix commit `acb6794` instead of
  `Pending local commit`.
- Refreshed full visual evidence:
  all 13 Electron parity screenshots,
  all 13 Flutter parity screenshots,
  all 13 side-by-side compare images,
  and
  `test-results/flutter-electron-parity/compare/all-surfaces-contact.png`.
- Verification commands passed:
  `node scripts/capture-electron-parity.mjs`,
  `file test-results/flutter-electron-parity/electron/*.png`,
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  `cd chronopic_flutter && file ../test-results/flutter-electron-parity/flutter/*.png`,
  compare artifact generation with `montage`,
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  and
  `git diff --check`.
- Gate-order note:
  after `pnpm test` runs, `pnpm build` must run again before direct Electron
  Playwright specs because the test script cleans desktop build output.
- Result:
  the Linux desktop Flutter/Electron baseline is frozen locally with no open
  parity-matrix `Gap` rows.

### 2026-05-09 Step 212

- Committed and pushed the desktop baseline freeze documentation as:
  `52fda73 Record desktop baseline freeze gate`.
- Used the writing-plans workflow to prepare Phase 6 before touching mobile
  implementation code.
- Confirmed the current Flutter app only has a Linux runner;
  Android and iOS runner directories still need to be generated.
- Confirmed `chronopic_media` already has the correct package boundary for
  Phase 6:
  `MediaSourceAdapter`
  plus `granted`,
  `denied`,
  and `limited` permission states.
- Checked current stable pub.dev versions for planned mobile dependencies:
  `photo_manager 3.9.0`,
  `file_picker 11.0.2`,
  `path_provider 2.1.5`,
  and `permission_handler 12.0.1`.
- Created the Phase 6 implementation plan:
  `docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md`.
- Updated:
  `PLAN.md`
  and
  `docs/flutter-refactor-phases.md`
  so Phase 6 points to the new plan and records Android-first / iOS-on-Linux
  verification constraints.
- Next:
  review and commit/push the Phase 6 planning docs,
  then begin Task 1 with `flutter doctor -v`,
  `flutter devices`,
  and Android/iOS runner generation.

### 2026-05-09 Step 213

- Started Phase 6 execution from:
  `docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md`.
- Ran the Task 1 toolchain gate:
  `cd chronopic_flutter && flutter doctor -v`
  and
  `cd chronopic_flutter && flutter devices`.
- Toolchain result:
  Flutter stable `3.41.9`,
  Dart `3.11.5`,
  and Linux desktop are available.
  Android SDK is detected at `/usr/lib/android-sdk`,
  but Android `cmdline-tools` are missing.
  Only the Linux desktop device is currently connected.
  iOS remains a Linux-host constraint and cannot be real-device verified here.
- Generated Android and iOS runners with:
  `cd chronopic_flutter/apps/chronopic && flutter create --platforms=android,ios --project-name chronopic .`
- Preserved the existing Flutter app entrypoint:
  `chronopic_flutter/apps/chronopic/lib/main.dart`
  still launches `ChronoPicHome`.
- Added Android photo/media permissions in:
  `chronopic_flutter/apps/chronopic/android/app/src/main/AndroidManifest.xml`.
- Added iOS photo-library usage descriptions in:
  `chronopic_flutter/apps/chronopic/ios/Runner/Info.plist`.
- Created:
  `docs/mobile-productization.md`
  to record mobile toolchain state,
  platform scaffolding,
  permissions,
  and the iOS verification constraint.
- Verification passed:
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`.
- Follow-up:
  Task 1 still needs its commit,
  then Phase 6 should continue into Task 2 with red tests for the mobile
  photo-library media source.

### 2026-05-09 Step 214

- Implemented Phase 6 Task 2:
  Mobile Media Source Boundary.
- Added the latest stable compatible `photo_manager` dependency through:
  `cd chronopic_flutter/packages/chronopic_media && flutter pub add photo_manager:^3.9.0`.
- Verified dependency state with:
  `cd chronopic_flutter && flutter pub outdated`.
  Direct dependencies are up to date;
  newer dev/transitive versions are outside the current resolvable set.
- Added red tests in:
  `chronopic_flutter/packages/chronopic_media/test/mobile_photo_library_media_source_test.dart`.
  The first run failed because
  `PhotoLibraryGateway`,
  `PhotoLibraryPermissionSnapshot`,
  `PhotoLibraryAsset`,
  and
  `MobilePhotoLibraryMediaSource`
  did not exist.
- Added pure Dart mobile media-source contracts and adapter:
  `photo_library_gateway.dart`
  and
  `mobile_photo_library_media_source.dart`.
- Added the real Flutter plugin-backed gateway in:
  `photo_manager_gateway.dart`.
- Kept the public package boundary deliberate:
  `chronopic_media.dart`
  exports only pure Dart media contracts/adapters,
  while
  `chronopic_media_flutter.dart`
  exports the `photo_manager` gateway so pure Dart tests do not load
  Flutter's `dart:ui`.
- Verification passed:
  `cd chronopic_flutter && dart test packages/chronopic_media/test/mobile_photo_library_media_source_test.dart`,
  `cd chronopic_flutter && dart analyze packages/chronopic_media`,
  and
  `cd chronopic_flutter && dart test packages/chronopic_media/test`.
- Next:
  commit Task 2,
  then continue into Task 3 with red tests for mobile scan progress,
  pause,
  resume,
  and retry orchestration.

### 2026-05-09 Step 215

- Implemented Phase 6 Task 3:
  Mobile Scan Orchestration And Progress.
- Added red tests in:
  `chronopic_flutter/packages/chronopic_app/test/mobile_scan_test.dart`.
  The first run failed because `ScanProgress`,
  `ScanRunState`,
  and `ChronoPicAppService.scanMediaSource`
  did not exist.
- Added `ScanRunState` and `ScanProgress` in the app indexer layer.
- Extended `ChronoPicIndexerService` with:
  progress callbacks,
  failure progress reporting,
  cooperative pause checks,
  and partial paused stats.
- Added `ChronoPicAppService.scanMediaSource`
  and refactored `scanDesktopDirectory`
  to delegate through the shared media-source scan path.
- Test coverage now includes:
  limited mobile source scan,
  denied permission failure without mutating photos,
  pause after the current asset,
  resume while skipping unchanged assets,
  and retry by rescanning an asset that previously failed to read.
- Verification passed:
  `cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart`,
  `cd chronopic_flutter && dart test packages/chronopic_app/test/mobile_scan_test.dart packages/chronopic_app/test/linux_desktop_scan_test.dart`,
  and
  `cd chronopic_flutter && dart analyze packages/chronopic_app`.
- Next:
  commit Task 3,
  then continue into Task 4 with red widget tests for mobile onboarding,
  permission states,
  scan progress,
  and backup wording.

### 2026-05-09 Step 216

- Implemented Phase 6 Task 4:
  Adaptive Mobile Onboarding UI.
- Added red widget tests in:
  `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`.
  The first run failed because `ChronoPicEntryMode`,
  `entryModeOverride`,
  and the mobile photo-library entry factory did not exist.
- Added a public `ChronoPicEntryMode` and injectable
  `mobileMediaSourceFactory` so tests and platforms can select the
  mobile photo-library entry path without changing the desktop default.
- Split the first-run CTA:
  desktop keeps `choose-library-folder-button`,
  while mobile shows `choose-photo-library-button` with
  `Choose Photos` / `选择照片` copy.
- Wired mobile scan through
  `MobilePhotoLibraryMediaSource(PhotoManagerGateway())`
  and `ChronoPicAppService.scanMediaSource('photo-library', ...)`.
- Added limited-access and denied-permission status messages for the mobile
  scan path.
- Added a compact shell layout for narrow screens so the mobile first-run view
  no longer loses width to the desktop sidebar.
- Verification passed:
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  and
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`.
- Next:
  commit Task 4,
  then continue into Task 5 with Android toolchain verification,
  Android debug APK build,
  and device-smoke status recording.

### 2026-05-09 Step 217

- Partially completed Phase 6 Task 5:
  Android Build And Device Smoke.
- Ran:
  `cd chronopic_flutter && flutter doctor -v`
  and
  `cd chronopic_flutter && flutter devices`.
- Initial Android build attempt failed because Flutter was using system Java 11
  at `/usr/lib/jvm/java-11-openjdk-amd64`,
  while the Android Gradle plugin requires Java 17.
- Installed user-state Temurin JDK `17.0.19+10` under:
  `/home/dhc/.local/share/jdks/temurin-17`,
  then configured Flutter with:
  `flutter config --jdk-dir=/home/dhc/.local/share/jdks/temurin-17`.
- Installed user-state Android SDK command-line tools from Google's current
  Linux package:
  `commandlinetools-linux-14742923_latest.zip`.
- Installed Android SDK packages under:
  `/home/dhc/.local/share/android-sdk`,
  including `platform-tools`,
  `platforms;android-36`,
  `build-tools;36.0.0`,
  `build-tools;35.0.0`,
  and `ndk;28.2.13676358`.
- Configured Flutter with:
  `flutter config --android-sdk=/home/dhc/.local/share/android-sdk`.
- Updated the ignored Android runner local config so this checkout uses the
  user-state SDK:
  `chronopic_flutter/apps/chronopic/android/local.properties`.
- Verified `flutter doctor -v` reports the Android toolchain healthy with SDK
  version `36.0.0`,
  platform `android-36`,
  build-tools `36.0.0`,
  Java `17.0.19`,
  and accepted Android licenses.
- Verified `flutter devices` still lists only:
  `Linux (desktop)`.
- Verified Android debug build with:
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`.
  Result:
  `build/app/outputs/flutter-apk/app-debug.apk`
  was built successfully.
- Recorded the Android build gate and remaining real-device smoke blocker in:
  `docs/mobile-productization.md`.
- Remaining Task 5 blocker:
  no Android emulator or physical Android device is connected,
  so denied/limited/full permission flows,
  restart persistence,
  and backup restore cannot yet be real-device smoked.
- Next:
  commit the Task 5 documentation update,
  then continue into Task 6 iOS static review and constraint recording.

### 2026-05-09 Step 218

- Implemented Phase 6 Task 6:
  iOS Scaffold And Constraint Record.
- Ran:
  `sed -n '1,220p' chronopic_flutter/apps/chronopic/ios/Runner/Info.plist`.
- Static review result:
  `NSPhotoLibraryUsageDescription`
  and
  `NSPhotoLibraryAddUsageDescription`
  are present.
- Confirmed the add/write usage text says ChronoPic does not write originals.
- Updated `docs/mobile-productization.md` with the iOS static review evidence.
- The Linux workstation limitation remains:
  Xcode,
  iOS simulators,
  and iOS device signing cannot run here,
  so the iOS real-device exit gate still requires macOS/Xcode.
- Next:
  commit Task 6,
  then continue into Task 7 closeout gate while keeping the Android real-device
  smoke blocker explicit.

### 2026-05-09 Step 219

- Ran Phase 6 Task 7 closeout gates.
- Electron reference/runtime verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  and
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`.
- Flutter verification passed:
  `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`.
- Mobile platform gate passed for Android debug build:
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`.
- Rechecked device availability with:
  `cd chronopic_flutter && flutter devices`.
  Result:
  only `Linux (desktop)` is connected.
- Updated `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  and the Phase 6 implementation plan with closeout evidence.
- Phase 6 implementation and local build/test gates are complete on this
  workstation,
  but Android real-device smoke remains blocked until an Android emulator or
  physical device is connected.
- iOS real-device verification remains blocked until macOS/Xcode is available.

### 2026-05-09 Step 220

- Continued Phase 6 after adding a local Android emulator:
  AVD `chronopic_api36`,
  `emulator-5554`,
  `Android SDK built for x86_64`,
  Android 16/API 36.
- Reproduced the Android full-access scan failure:
  the app discovered two media-store assets but reported
  `0 imported, 2 errors`.
- Traced the failure to thumbnail generation:
  Android asset bytes could trigger `image.decodeImage` null assertions inside
  `_writeThumbnail`, which was incorrectly causing the whole asset import to
  fail.
- Fixed the Android import path:
  `PhotoManagerGateway` now keeps the `AssetEntity` instances returned by
  `listAssets()` available for later reads,
  falls back from empty `originBytes` to `AssetEntity.file.readAsBytes()`,
  the indexer records the last resource-level scan error,
  and thumbnail decode failures now return `null` thumbnail instead of failing
  the import.
- Added a regression test for image assets whose thumbnail decode fails:
  the asset is still imported with no thumbnail and no scan error.
- Verified Android emulator smoke:
  denied permission shows the recoverable denied state;
  full access imports two smoke PNGs with
  `2 imported, 0 errors`;
  limited selected-photo access imports the same two assets with
  `READ_MEDIA_VISUAL_USER_SELECTED=true` and full media permissions false;
  force-stop/relaunch returns to the existing browse surface;
  injecting the automatic metadata backup after `pm clear` restores the browse
  surface from the backup JSON.
- Updated:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  and
  `docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md`
  with the new Android emulator evidence.
- Final verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  `cd chronopic_flutter && dart analyze packages/chronopic_app packages/chronopic_media packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  Android emulator denied/full/limited/restart/backup smoke on `emulator-5554`,
  and `git diff --check`.
- Next:
  commit and push the Android smoke fix and documentation update.

### 2026-05-09 Step 221

- Added a new planned phase after Phase 6 and before Phase 7:
  `Phase 6.5: Flutter Mobile Deep E2E Verification`.
- Created the dedicated implementation plan:
  `docs/superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md`.
- Updated `PLAN.md` and `docs/flutter-refactor-phases.md` so the mobile deep
  E2E phase is now a tracked gate before release/migration cutover work.
- Phase 6.5 scope:
  Android clean-state E2E runner,
  stable mobile test hooks,
  app-owned Flutter integration tests for edit/favorite/memory/detail/gallery/search/settings flows,
  durable screenshot/XML/backup evidence,
  and explicit iOS macOS/Xcode evidence requirements.
- Current status:
  planning only;
  no Phase 6.5 implementation items are marked complete.
- Verification:
  `git diff --check` passed.
- Next:
  commit this phase-plan update when requested.

### 2026-05-10 Step 222

- Started executing Phase 6.5:
  `Flutter Mobile Deep E2E Verification`.
- Created the durable mobile E2E evidence matrix:
  `docs/mobile-e2e-verification.md`.
- The matrix now records Android target metadata,
  required Android scenarios,
  blocked iOS scenarios that need macOS/Xcode evidence,
  and a command-output section for exact verification records.
- Current status:
  Task 1 documentation has landed locally;
  Android and iOS scenario rows remain pending/blocked until real evidence is
  produced by the later Phase 6.5 runners and tests.
- Verification:
  `git diff --check` passed.
- Next:
  add stable mobile test hooks.

### 2026-05-10 Step 223

- Implemented Phase 6.5 Task 2:
  stable mobile E2E hooks.
- Added failing widget-test assertions first for:
  `mobile-choose-photos`,
  `mobile-browse-surface`,
  `mobile-select-mode`,
  `mobile-open-detail`,
  `mobile-open-gallery`,
  and `mobile-create-memory`.
- Confirmed the red state with:
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
  failing on missing mobile keys.
- Added stable `ValueKey<String>` test hooks without changing behavior for:
  choose photos,
  browse surface,
  select mode,
  open detail,
  open gallery,
  favorite toggle,
  add/remove memory,
  memory cover,
  memory rename,
  memory description,
  and create memory.
- Preserved the existing desktop/parity keys by wrapping existing controls
  instead of replacing their current keys.
- Verification passed:
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`.
- Next:
  build the Android deep E2E runner.

### 2026-05-10 Step 224

- Started Phase 6.5 Task 3:
  Android deep E2E runner.
- Added the runner skeleton:
  `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.
- The skeleton prepares an output directory,
  waits for `emulator-5554`,
  builds and installs the debug APK,
  clears app state,
  injects two PNG media fixtures,
  launches the app,
  and captures first-run screenshot/XML evidence.
- Hardened the install/capture path after the first run exposed two
  environment-specific emulator issues:
  plain `adb install -r` hung on this headless AVD,
  and Android system ANR dialogs could briefly cover the app during capture.
  The runner now uses bounded `adb install -r -t --no-streaming` and waits for
  the ChronoPic first-run UI before writing final evidence.
- Updated `docs/mobile-e2e-verification.md` with the runner command and
  expected skeleton evidence artifacts.
- Current status:
  script created and executed successfully on `emulator-5554`;
  `01-first-run.png` and `01-first-run.xml` were generated under
  `.tmp/mobile-e2e/android`,
  and the XML contains `Choose Photos`.
- Next:
  commit the runner skeleton,
  then automate Android permission and import checks.

### 2026-05-10 Step 225

- Implemented Phase 6.5 Task 4:
  Android permission and import E2E automation.
- Extended `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh` with:
  reusable `dump_ui`,
  `assert_ui_contains`,
  and `tap` helpers,
  XML-driven button tapping,
  bounded `adb install`,
  bounded `uiautomator`/screenshot capture,
  screen wake/keyguard handling,
  app-state and runtime-permission resets,
  media fixture preparation,
  denied/full/limited permission flows,
  restart persistence,
  and metadata backup restore.
- The runner now removes old ChronoPic smoke media directories before injecting
  the two Phase 6.5 PNG fixtures so full-access imports are deterministic.
- Verified the full Android runner with:
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.
- Result:
  command exited 0 and generated evidence under `.tmp/mobile-e2e/android`:
  `02-denied`,
  `03-full-access`,
  `04-limited-access`,
  `04-permissions.txt`,
  `05-restart`,
  `06-restore`,
  and `backup.json`.
- Evidence checks performed after the run:
  the denied/full/limited/restart/restore XML files contain their expected UI
  text,
  `04-permissions.txt` confirms selected-photo permission is granted while
  full image permission is false,
  and `backup.json` contains exactly 2 photos.
- Updated `docs/mobile-e2e-verification.md` so Android denied,
  limited,
  full-access,
  restart,
  and backup-restore scenarios are marked `Passed` with artifact paths.
- Next:
  add app-owned Flutter integration workflow tests for edit/favorite/memory/detail/gallery/search/settings coverage.

### 2026-05-10 Step 226

- Implemented Phase 6.5 Task 5:
  app-owned mobile workflow integration tests.
- Added `integration_test` to the Flutter app and declared the direct app-owned
  test dependencies used by
  `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`.
- Wrote the integration test against a restored real `ChronoPicAppService`
  backup and existing mobile stable keys.
- The test verifies:
  restored mobile browse,
  detail overlay open/close,
  gallery overlay open/close,
  favorite persistence,
  caption/tag/datetime edit persistence,
  memory create/add/cover/rename/description/remove,
  search/filter/sort controls,
  and locale settings after a restored app instance.
- Followed red/green verification:
  the first runs exposed that double-tap detail opening was rebuild-sensitive,
  focused detail controls were not reliably tappable on a 430px mobile viewport,
  and restored app instances did not load persisted locale settings.
- Fixed those defects by:
  keeping photo-card selection on raw pointer down,
  using pointer-event timestamps for double-tap detection,
  adding a narrow-layout branch for focused detail,
  and loading persisted locale settings on app startup while preserving the
  screenshot-specific `zh-locale` override.
- Verification passed:
  `cd chronopic_flutter/apps/chronopic && flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554`
  and
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`.
- Updated `docs/mobile-e2e-verification.md` so app-owned Android scenarios are
  marked `Passed` with the integration-test command as evidence.
- Next:
  record the iOS deep E2E gate and then run Phase 6.5 closeout verification.

### 2026-05-10 Step 227

- Implemented Phase 6.5 Task 6:
  iOS deep E2E gate recording.
- Updated `docs/mobile-e2e-verification.md` with the required macOS/Xcode
  commands:
  `flutter build ios --debug --no-codesign`
  and
  `flutter run -d <ios-device-or-simulator-id>`.
- Recorded the required iOS evidence:
  denied permission screenshot,
  limited-library screenshot and import count,
  full-library import/browse evidence,
  restart persistence screenshot,
  and metadata backup restore JSON plus relaunch screenshot.
- Updated `docs/mobile-productization.md` with the same iOS deep E2E gate so
  the mobile productization doc and Phase 6.5 evidence matrix stay aligned.
- Kept every iOS scenario marked `Blocked` because this Linux workstation cannot
  run Xcode, iOS simulators, or iOS signing.
- Next:
  run the full Phase 6.5 closeout verification suite and update phase status.

### 2026-05-10 Step 228

- Implemented Phase 6.5 Task 7:
  closeout verification and phase status update.
- Re-ran the full required closeout suite:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  `cd chronopic_flutter/apps/chronopic && flutter test integration_test/mobile_deep_e2e_test.dart -d emulator-5554`,
  and
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.
- All commands passed.
- Rechecked Android shell-runner evidence after the run:
  first-run,
  denied,
  full access,
  limited access,
  permissions,
  restart,
  restore,
  and backup JSON assertions all passed.
- During closeout, fixed two regressions exposed by the broader suite:
  parity fixtures with `zh-CN` settings are now explicitly converted to English
  for English UI tests,
  and photo-card single/double tap uses raw pointer timestamps so single-click
  selection remains immediate while double-click opens focused detail reliably
  on both widget tests and Android integration tests.
- Updated `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-e2e-verification.md`,
  and the Phase 6.5 implementation plan to mark the phase complete locally.
- Remaining:
  iOS live evidence still requires macOS/Xcode before iOS can be called
  release-verified.

### 2026-05-10 Step 229

- Recorded post Phase 6.5 candidate work instead of starting a new phase
  immediately.
- Updated `PLAN.md` with `6.6 Post Phase 6.5 Candidate Work`.
- Updated `docs/flutter-refactor-phases.md` with the same candidate backlog and
  removed a duplicate iOS gate bullet from the Phase 6.5 remaining-work list.
- Recommended next candidate:
  Flutter Linux desktop parity hardening before release packaging,
  using Electron-vs-Flutter fixture runs and screenshot comparison for
  home/library,
  gallery/detail overlay,
  memory list/detail,
  search/filter/sort,
  settings,
  and metadata editing flows.
- Other recorded candidate slices:
  Android E2E runner hardening,
  Android release signing/distribution readiness,
  migration and cutover compatibility,
  CI gate promotion,
  iOS live verification,
  and large-library/accessibility sweep.
- Verification:
  `git diff --check` passed for the documentation-only change.
- Next:
  choose a candidate slice and promote it into a numbered phase or dedicated
  implementation plan before touching code.

### 2026-05-10 Step 230

- Promoted the selected candidate into
  `6.6 Flutter Linux Desktop Parity Hardening`.
- Added the implementation plan:
  `docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md`.
- Updated `PLAN.md` and `docs/flutter-refactor-phases.md` so Phase 6.6 is now
  the active pre-release desktop hardening phase.
- Kept the remaining candidate slices under `Post 6.6 Candidate Work`.
- Phase 6.6 will reuse the existing Electron/Flutter 13-surface parity harness:
  Electron Playwright capture,
  Flutter Linux Xvfb/scrot capture,
  side-by-side compare artifacts,
  `docs/flutter-electron-ui-functional-parity.md`,
  and `docs/flutter-electron-feature-ui-review.md`.
- Next:
  run documentation formatting verification,
  then refresh Electron and Flutter Linux screenshot evidence.

### 2026-05-10 Step 231

- Started Phase 6.6 evidence refresh.
- Verified required local screenshot tools are installed:
  `montage`,
  `xvfb-run`,
  `scrot`,
  and `file`.
- Ran Electron preparation and capture:
  `pnpm build`,
  `pnpm run e2e:prepare`,
  `node scripts/capture-electron-parity.mjs`,
  and
  `file test-results/flutter-electron-parity/electron/*.png`.
- Result:
  all 13 Electron screenshots were refreshed and report 1440x920.
- Ran Flutter capture:
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`,
  then
  `file ../test-results/flutter-electron-parity/flutter/*.png`.
- Result:
  all 13 Flutter screenshots were refreshed and report 1440x920.
- Regenerated compare artifacts with ImageMagick `montage`.
- Result:
  all 13 compare screenshots report 2976x920.
- Created a temporary contact sheet for review:
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-6-6.png`.
- Found a real Phase 6.6 harness gap:
  non-zh Flutter parity screenshots were using the fixture's persisted
  `zh-CN` locale while Electron reference capture explicitly forces English
  for the same surfaces.
- Fixed the Flutter capture harness so normal fixture-backed surfaces write a
  temporary `en-US` / `follow-ui` backup copy,
  while `zh-locale` and `restart-persistence` keep the persisted zh state.
- Corrected the Phase 6.6 implementation plan to expect the actual
  2976x920 compare artifact size.
- Next:
  recapture affected Flutter English surfaces,
  regenerate compare artifacts,
  and inspect the refreshed contact sheet.

### 2026-05-10 Step 232

- Recaptured the Phase 6.6 affected Flutter English surfaces after the harness
  fix:
  `populated-grid`,
  `map`,
  `timeline`,
  `detail`,
  `gallery`,
  `favorites`,
  `memories-list`,
  `memory-detail`,
  `settings`,
  and `notifications`.
- Rechecked Flutter screenshot dimensions with:
  `file ../test-results/flutter-electron-parity/flutter/*.png`.
- Regenerated all 13 side-by-side compare artifacts and refreshed:
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-6-6.png`.
- Verified evidence counts:
  Electron `13`,
  Flutter `13`,
  compare `13`.
- Verified dimensions:
  all Electron and Flutter PNGs report 1440x920,
  and all compare PNGs report 2976x920.
- Reinspected the refreshed contact sheet.
- Result:
  `P66-001` is closed;
  normal surfaces now render English on both sides,
  while `zh-locale` and `restart-persistence` remain in Chinese on both sides.
- Updated
  `docs/flutter-electron-ui-functional-parity.md`,
  `docs/flutter-electron-feature-ui-review.md`,
  and the Phase 6.6 implementation plan with the finding and evidence.
- No new product UI/function gap was confirmed beyond the existing accepted
  renderer differences.
- Next:
  run the Phase 6.6 final verification gate.

### 2026-05-10 Step 233

- Phase 6.6 final evidence check exposed a second harness issue:
  running Electron Playwright gates removed
  `test-results/flutter-electron-parity/`.
- Cause:
  `tests/e2e/playwright.config.ts` used Playwright's default root
  `test-results` output directory,
  which conflicts with the parity screenshot evidence directory.
- Fixed the Playwright config to write artifacts under:
  `test-results/playwright-artifacts`.
- Recorded this as `P66-002` in
  `docs/flutter-electron-feature-ui-review.md` and
  `docs/flutter-electron-ui-functional-parity.md`.
- Next:
  recapture parity evidence after the Playwright output-dir fix,
  rerun Electron E2E gates,
  and verify parity screenshots survive the test run.

### 2026-05-10 Step 234

- Completed Phase 6.6 final recapture and verification after the Playwright
  output-dir fix.
- Recaptured Electron evidence with:
  `node scripts/capture-electron-parity.mjs`.
- Recaptured Flutter Linux evidence with:
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`.
- Regenerated all side-by-side compare artifacts with ImageMagick `montage`
  and refreshed:
  `test-results/flutter-electron-parity/compare/contact-sheet-phase-6-6.png`.
- Re-ran Electron E2E gates after the Playwright output-dir fix:
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  and
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`.
- Result:
  all three Electron E2E commands passed.
- Verified parity evidence survived the Electron E2E run:
  Electron screenshot count `13`,
  Flutter screenshot count `13`,
  compare screenshot count `13`,
  and total files under `test-results/flutter-electron-parity` `40`.
- Verified dimensions:
  all Electron and Flutter PNGs are 1440x920,
  all compare PNGs are 2976x920.
- Verified Flutter desktop gate:
  `cd chronopic_flutter && dart analyze packages/chronopic_ui apps/chronopic`
  passed with no issues,
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`
  passed with 13 tests.
- Verified formatting:
  `git diff --check` passed.
- Updated `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-electron-ui-functional-parity.md`,
  `docs/flutter-electron-feature-ui-review.md`,
  and the Phase 6.6 implementation plan.
- Result:
  Phase 6.6 is complete locally.
  No new product UI/function gap was found beyond existing accepted renderer
  differences;
  `P66-001` and `P66-002` are both closed as harness hardening fixes.
- Next:
  commit/push when requested,
  or move to the next Post 6.6 candidate such as Android E2E runner hardening,
  release signing,
  migration/cutover compatibility,
  CI gate promotion,
  or iOS live verification.

### 2026-05-10 Step 235

- Planned Phase 7 after user selected the remaining Post 6.6 work:
  Android deep E2E runner hardening,
  migration and cutover compatibility,
  release signing and Android distribution readiness,
  CI gate promotion,
  and Flutter release.
- Added implementation plan:
  `docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md`.
- Updated `PLAN.md` and `docs/flutter-refactor-phases.md` so Phase 7 is now
  `Flutter Release Readiness And Cutover`.
- Recorded the explicit release decision:
  Flutter is the release target;
  Electron is no longer released and remains only as reference and migration
  source until cutover is complete.
- Recorded the implementation order:
  harden Android deep E2E runner,
  prove Electron-backup migration into Flutter,
  add Android signing/release artifacts,
  add Flutter Linux release artifacts,
  promote Flutter gates into CI,
  and replace tag-triggered Electron release assets with Flutter Android/Linux
  assets.
- Recorded the dependency/version rule:
  before changing or adding dependencies,
  GitHub Actions,
  Android/Gradle/Flutter setup,
  or release tools,
  check the latest stable version from official sources and record the selected
  versions here.
- Next:
  run documentation formatting verification,
  then start Phase 7 Task 2 with Android deep E2E runner hardening when
  implementation is requested.

### 2026-05-10 Step 236

- Started Phase 7 Task 2:
  Android deep E2E runner hardening.
- Added the artifact assertion helper:
  `chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs`.
  It validates all required Android shell-runner screenshots,
  XML dumps,
  permission dumps,
  and `backup.json`,
  including the 2-photo import/restore contract.
- Hardened `chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh` with:
  timestamped logs,
  device id in every log line,
  scenario start/end markers,
  named `uiautomator dump` retry attempts,
  required artifact checks after capture,
  timestamped default output directories,
  `summary.json`,
  and the new artifact assertion helper before success exit.
- Added the two-run wrapper:
  `chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`.
  It creates clean `run-1` and `run-2` directories under
  `.tmp/mobile-e2e/android-repeat/<timestamp>/`,
  clears app/media state before each pass,
  runs the single Android deep E2E runner twice,
  rechecks artifacts after each pass,
  and writes `combined-summary.json`.
- Updated `docs/mobile-e2e-verification.md` with the hardened runner contract,
  artifact assertion command,
  two-run wrapper command,
  and output directory layout.
- Verification passed:
  `bash -n chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`,
  `bash -n chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`,
  `node --check chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs`,
  and a generated temporary complete artifact directory checked by
  `assert_android_deep_e2e_artifacts.mjs`.
- Remaining for Task 2:
  run
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`
  against a live clean emulator and record the two-pass evidence.

### 2026-05-10 Step 237

- Completed Phase 7 Task 2 live Android deep E2E hardening verification.
- Attempted to launch the AVD with Flutter first:
  `flutter emulators --launch chronopic_api36`.
  It failed because this WSL environment has no `/dev/kvm`.
- Confirmed the Android environment:
  `flutter doctor -v` reports Flutter stable `3.41.9`,
  Dart `3.11.5`,
  Android SDK `36.0.0`,
  Emulator `36.5.11.0`,
  and Android toolchain ready.
- Started the AVD through the SDK emulator in software mode:
  `/home/dhc/.local/share/android-sdk/emulator/emulator -avd chronopic_api36 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -accel off -no-snapshot-load -no-snapshot-save -no-metrics`.
- Live runner execution exposed two real hardening gaps:
  immediately after software-emulated boot,
  `/sdcard/Pictures` can briefly return
  `Transport endpoint is not connected`;
  and the system permission controller can miss the
  `ALLOW LIMITED ACCESS` tap on a slow emulator.
- Fixed both gaps:
  the single runner and two-run wrapper now wait for external storage before
  media cleanup and retry fixture cleanup;
  the limited-access flow now retries the permission tap until the Photo Picker
  text is actually present.
- Re-ran the full two-pass command:
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`.
- Result:
  passed.
  Evidence directory:
  `.tmp/mobile-e2e/android-repeat/20260510T035600Z/`.
  `combined-summary.json` reports `status: passed`,
  with both `run-1` and `run-2` marked `passed`.
- Post-run artifact helper verification passed for both runs:
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android-repeat/20260510T035600Z/run-1`
  and
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android-repeat/20260510T035600Z/run-2`.
- Evidence count:
  `63` files under `.tmp/mobile-e2e/android-repeat/20260510T035600Z`.
- Formatting verification passed:
  `git diff --check`.
- Next:
  start Phase 7 Task 3,
  proving Flutter migration/cutover compatibility with a sanitized real
  Electron backup fixture.

### 2026-05-10 Step 238

- Completed Phase 7 Task 3:
  migration and cutover compatibility.
- Found a real Electron-to-Flutter compatibility issue before adding the
  migration fixture:
  Electron backup JSON can contain fractional millisecond JavaScript numbers
  for filesystem-derived timestamps,
  while Flutter domain parsing used `as int` casts.
- Added a red/green domain contract test:
  `chronopic_flutter/packages/chronopic_domain/test/backup_contract_test.dart`
  now verifies fractional Electron timestamp numbers are accepted and truncated
  to Dart `int` values.
  The test failed before the parser change and passed after the fix.
- Updated Flutter domain backup/model parsing so integer-compatible JSON
  numbers accept both `int` and `num` values:
  backup `exportedAt`,
  library source timestamps,
  photo timestamps and size,
  metadata datetime,
  semantic AI processed timestamp,
  index timestamps,
  edit timestamps,
  memory timestamps,
  memory membership timestamp,
  and memory-candidate timestamps.
- Added the migration fixture generator:
  `scripts/write-flutter-migration-fixtures.mjs`.
  It reads the latest real Electron E2E backup,
  removes local `/tmp` and home paths,
  replaces Electron E2E secret placeholders,
  normalizes IDs and fixture paths,
  preserves the Electron JSON shape,
  and writes deterministic migration fixtures.
- Generated:
  `tests/fixtures/flutter-migration/electron-backup-v1.json`
  and
  `tests/fixtures/flutter-migration/electron-backup-v1.expected.json`.
- Added Flutter app-service import coverage:
  `chronopic_flutter/packages/chronopic_app/test/electron_backup_import_test.dart`.
  The test verifies preview counts,
  restore result counts,
  favorite state,
  captions,
  tags,
  edited datetimes,
  memory metadata,
  memory membership,
  locale settings,
  map settings,
  and AI status/generated-label fields.
- Added cutover documentation:
  `docs/flutter-migration-cutover.md`.
  Decision:
  direct old SQLite import is not required for Phase 7 while JSON backup export
  and Flutter restore are covered;
  keep Electron installed as fallback until user restore counts are verified.
- Verification passed:
  `pnpm run e2e:backup`,
  `node scripts/write-flutter-migration-fixtures.mjs`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test/backup_contract_test.dart`,
  and
  `cd chronopic_flutter && dart test packages/chronopic_app/test/electron_backup_import_test.dart`.
- Next:
  start Phase 7 Task 4,
  Android release signing and distribution readiness.

### 2026-05-10 Step 239

- Completed Phase 7 Task 4:
  Android release signing and distribution readiness.
- Checked official sources before changing release/signing behavior:
  Flutter Android deployment docs
  `https://docs.flutter.dev/deployment/android`,
  Android app-signing docs
  `https://developer.android.com/studio/publish/app-signing`,
  Google Play Photo and Video Permissions policy
  `https://support.google.com/googleplay/android-developer/answer/14115180`,
  and Google Play Data safety documentation
  `https://support.google.com/googleplay/android-developer/answer/10787469`.
- Recorded the Android identity gate:
  current `applicationId` is still `com.example.chronopic`,
  so generated APK/AAB artifacts are technical verification artifacts only and
  must not be uploaded as production until the final package id is chosen.
- Updated
  `chronopic_flutter/apps/chronopic/android/app/build.gradle.kts`:
  release builds no longer use debug signing,
  release signing reads ignored `android/key.properties` or CI environment
  variables,
  debug builds remain unaffected,
  and missing release signing material fails release tasks with a clear message.
- Added ignored signing template:
  `chronopic_flutter/apps/chronopic/android/key.properties.example`.
- Updated `.gitignore` so local Android signing properties and keystore files
  are not tracked.
- Added Android release tooling:
  `chronopic_flutter/tool/release/build_android_release.sh`
  and
  `chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`.
- Added release checklist:
  `docs/flutter-release-checklist.md`.
  It records Flutter-only release line,
  Android identity gate,
  signing material handling,
  release artifact names,
  photo permission rationale,
  Play Data safety notes,
  and the blocked iOS gate.
- Updated `docs/mobile-productization.md` with the Phase 7 Android release
  readiness gate and verified artifacts.
- Verification passed:
  `bash -n chronopic_flutter/tool/release/build_android_release.sh`,
  `node --check chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and missing-signing `flutter build apk --release` failed with the intended
  explicit signing error.
- Created a local temporary upload keystore under `.tmp/release-signing/` for
  technical verification only.
  No signing secret was committed.
- Signed local technical release verification passed:
  `CHRONOPIC_ANDROID_STORE_FILE=$PWD/.tmp/release-signing/chronopic-upload.jks CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh`.
- Artifact verification passed:
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`.
- Generated artifacts:
  `dist/flutter-release/android/chronopic-flutter-android-release.apk`,
  `dist/flutter-release/android/chronopic-flutter-android-release.apk.sha256`,
  `dist/flutter-release/android/chronopic-flutter-android-release.aab`,
  and
  `dist/flutter-release/android/chronopic-flutter-android-release.aab.sha256`.
- Next:
  start Phase 7 Task 5,
  Flutter Linux release artifact generation.

### 2026-05-10 Step 240

- Completed Phase 7 Task 5:
  Flutter Linux release artifact generation.
- Added:
  `chronopic_flutter/tool/release/build_linux_release.sh`.
  The script runs `flutter build linux --release`,
  stages the Flutter Linux bundle,
  archives it as
  `chronopic-flutter-linux-x64-0.1.3.tar.gz`,
  writes it under `dist/flutter-release/linux/`,
  and creates a `.sha256` file.
- Extended:
  `chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`.
  It now accepts target arguments:
  `android`,
  `linux`,
  or both,
  verifies sha256 files,
  and confirms the Linux archive contains the `chronopic` executable.
- Updated:
  `docs/flutter-release-checklist.md`
  with Linux release commands and artifact names.
- Updated:
  `README.md`
  so current release artifacts are the Flutter Android APK/AAB and Flutter
  Linux tarball.
  Electron archives are described as historical only.
- Verification passed:
  `bash -n chronopic_flutter/tool/release/build_linux_release.sh`,
  `node --check chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs`,
  `chronopic_flutter/tool/release/build_linux_release.sh`,
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs linux`,
  and
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`.
- Generated artifacts:
  `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.3.tar.gz`
  and
  `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.3.tar.gz.sha256`.
- Next:
  start Phase 7 Task 6,
  promoting Flutter gates into CI.

### 2026-05-10 Step 241

- Completed Phase 7 Task 6:
  CI gate promotion.
- Verified current action tags from official GitHub repositories:
  `actions/checkout` latest stable major is `v6`
  with latest tag `v6.0.2`;
  `actions/setup-node` latest stable major is `v6`
  with latest tag `v6.4.0`;
  `actions/setup-java` latest stable major is `v5`
  with latest tag `v5.2.0`;
  `pnpm/action-setup` latest stable major is `v6`
  with latest tag `v6.0.6`.
- Verified Flutter official stable branch:
  `https://github.com/flutter/flutter.git` `refs/heads/stable`
  points to `00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`,
  matching local Flutter stable `3.41.9`.
- Updated `.github/workflows/ci.yml`:
  `actions/checkout` is now `@v6`,
  `actions/setup-node` is now `@v6`,
  and existing `pnpm/action-setup@v6` remains current.
- Added a separate Flutter CI job that clones Flutter from the official stable
  branch rather than adding an unverified third-party Flutter setup action.
  The job uses `actions/setup-java@v5` with Temurin 17 for Android debug
  builds.
- The Flutter CI job runs:
  `dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `dart test packages/chronopic_media/test packages/chronopic_app/test`,
  Flutter UI/parity widget tests,
  and `flutter build apk --debug`.
- Removed Electron package-release gates from CI:
  `pnpm run package:linux`,
  `pnpm run package:verify`,
  and `pnpm run e2e:packaged` are no longer CI release-readiness steps.
  Electron runtime,
  accessibility,
  AI,
  and backup E2E checks remain while Electron is still the reference app.
- Documented the Android deep E2E runner as a local/manual Phase 7 release gate
  in `docs/flutter-release-checklist.md` rather than making every CI run pay
  for the full emulator/photo-picker workflow.
- Local verification of the new Flutter CI command set passed:
  `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  and
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`.
- Next:
  start Phase 7 Task 7,
  replacing tag-triggered Electron release assets with Flutter Android/Linux
  release assets.

### 2026-05-10 Step 242

- Completed Phase 7 Task 7:
  replace tag-triggered Electron release assets with Flutter release assets.
- Verified `actions/setup-java` official tags before adding it:
  latest stable major is `v5`,
  latest tag observed is `v5.2.0`.
- Rewrote `.github/workflows/release.yml`:
  the old Electron `desktop` matrix for Linux,
  macOS,
  and Windows is removed.
- Added `flutter-android` release job:
  checkout with `actions/checkout@v6`,
  Java setup with `actions/setup-java@v5`,
  Flutter from the official stable branch,
  Flutter validation,
  Android signing material restored from GitHub Secrets,
  signed APK/AAB build through
  `chronopic_flutter/tool/release/build_android_release.sh`,
  artifact verification,
  and upload of `dist/flutter-release/android/*`.
- Required Android release secrets are:
  `CHRONOPIC_ANDROID_KEYSTORE_BASE64`,
  `CHRONOPIC_ANDROID_STORE_PASSWORD`,
  `CHRONOPIC_ANDROID_KEY_ALIAS`,
  and
  `CHRONOPIC_ANDROID_KEY_PASSWORD`.
- Added `flutter-linux` release job:
  Linux build dependencies,
  Flutter from the official stable branch,
  `chronopic_flutter/tool/release/build_linux_release.sh`,
  Linux artifact verification,
  and upload of `dist/flutter-release/linux/*`.
- Kept iOS blocked:
  no iOS release job or asset upload was added because macOS/Xcode signing and
  iOS E2E evidence do not exist yet.
- Updated `docs/flutter-release-checklist.md` with the tag release workflow and
  required secrets.
- Next:
  run the Phase 7 final release readiness gate and close the phase docs.

### 2026-05-10 Step 243

- Completed Phase 7 Task 8:
  final Flutter release readiness gate and documentation closeout.
- Final Node/Electron reference verification passed:
  `pnpm test && pnpm typecheck && pnpm build`.
  Result:
  42 Node tests passed,
  TypeScript passed,
  and the workspace build completed.
- Final Flutter verification passed:
  `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  and
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`.
- Final Android hardening gate passed:
  `ANDROID_DEVICE_ID=emulator-5554 chronopic_flutter/tool/mobile_e2e/run_android_deep_e2e_twice.sh`.
  Evidence:
  `.tmp/mobile-e2e/android-repeat/20260510T044545Z/combined-summary.json`
  reports `passed`,
  with both clean emulator runs passed.
- Agent verification script scene mapping:
  Phase 7 changed release,
  migration,
  CI,
  and mobile E2E infrastructure rather than Electron desktop runtime UI.
  Manual Electron Playwright Scene 1 and Scene 7 were skipped for this final
  closeout because no new Electron UI/runtime behavior was changed after the
  existing Node/Electron reference gates;
  Android E2E covered first-run permission,
  denied recovery,
  full access,
  limited access,
  restart persistence,
  and backup/restore on the Flutter release line.
- Independent Android artifact assertions passed:
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android-repeat/20260510T044545Z/run-1`
  and
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android-repeat/20260510T044545Z/run-2`.
  Each run validated required screenshots,
  XML dumps,
  limited-permission state,
  restart evidence,
  restore evidence,
  backup JSON,
  and summary JSON.
- Final release artifact generation passed:
  `CHRONOPIC_ANDROID_STORE_FILE=$PWD/.tmp/release-signing/chronopic-upload.jks CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh`
  and
  `chronopic_flutter/tool/release/build_linux_release.sh`.
  The temporary signing key remains under ignored `.tmp/release-signing/` and
  is for technical verification only.
- Final release artifact verification passed:
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`.
  Verified artifacts:
  `dist/flutter-release/android/chronopic-flutter-android-release.apk`,
  `dist/flutter-release/android/chronopic-flutter-android-release.aab`,
  `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.3.tar.gz`,
  and matching `.sha256` files.
- Completion audit reran the Flutter migration gate:
  `cd chronopic_flutter && dart test packages/chronopic_app/test/electron_backup_import_test.dart`.
  Result:
  `00:00 +1: All tests passed!`.
- Final whitespace check passed:
  `git diff --check`.
- Completion audit clarification:
  `tests/packaging.test.ts` still keeps legacy Electron desktop packaging
  script coverage because those scripts remain available for reference/local
  use,
  but the test names now say `legacy desktop packaging` so they no longer imply
  Electron is still a release target.
  Targeted verification passed:
  `node --experimental-strip-types --test tests/packaging.test.ts`.
- Updated `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-e2e-verification.md`,
  `docs/flutter-migration-cutover.md`,
  `docs/flutter-release-checklist.md`,
  and the Phase 7 execution plan with final gate evidence.
- Result:
  Phase 7 is complete locally.
  Flutter is now the release line;
  new Electron release assets are no longer produced.
  Android artifacts are technical verification artifacts until the final
  `applicationId` and production upload key are chosen.

### 2026-05-10 Step 244

- Completion audit found and closed one remaining Phase 7 gap:
  the original CI promotion requirement asked for an optional/manual Android
  emulator E2E workflow,
  not only local documentation.
- Verified latest stable action tags from official GitHub repositories before
  adding the workflow:
  `reactivecircus/android-emulator-runner` latest stable tag is `v2.37.0`,
  and `actions/upload-artifact` latest stable tag is `v7.0.1`.
- Added `.github/workflows/android-deep-e2e.yml`.
  It is a `workflow_dispatch` workflow with default API level `36`,
  sets up Node 24,
  Temurin 17,
  Flutter stable,
  enables KVM,
  runs the hardened two-run Android deep E2E gate through
  `reactivecircus/android-emulator-runner@v2.37.0`,
  and uploads `.tmp/mobile-e2e/android-repeat/` artifacts with
  `actions/upload-artifact@v7.0.1`.
- Updated `tests/packaging.test.ts` so the release/CI contract now verifies the
  manual Android deep E2E workflow as well as the Flutter-only release
  workflow.
- Updated `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-release-checklist.md`,
  `docs/mobile-e2e-verification.md`,
  and the Phase 7 execution plan so Android deep E2E is recorded as both a
  local and manually triggered CI gate.
- Verification passed:
  `node --experimental-strip-types --test tests/packaging.test.ts`
  and
  `git diff --check`.
- Re-ran the root test suite after adding the manual workflow contract:
  `pnpm test`.
  Result:
  43 Node tests passed.
- Re-ran the root typecheck/build gate after adding the manual workflow:
  `pnpm typecheck && pnpm build`.
  Result:
  both commands passed;
  Vite emitted the existing large chunk warning only.

### 2026-05-10 Step 245

- Prepared the `v0.1.4` release after the Phase 7 branch was committed and
  pushed.
- Confirmed the latest existing tag and GitHub release are `v0.1.3`,
  so this release uses the next tag:
  `v0.1.4`.
- Bumped package versions from `0.1.3` to `0.1.4` across the root package,
  desktop app package,
  and workspace package manifests.
- Added Flutter app version metadata:
  `chronopic_flutter/apps/chronopic/pubspec.yaml` now declares
  `version: 0.1.4+4`.
- Updated `README.md`,
  `DEVELOPMENT.md`,
  `PLAN.md`,
  `docs/flutter-release-checklist.md`,
  `docs/flutter-refactor-phases.md`,
  and the Phase 7 execution plan so release docs and Linux artifact names point
  to `v0.1.4` /
  `chronopic-flutter-linux-x64-0.1.4.tar.gz`.
- Next:
  rerun release verification with the bumped version,
  commit the version preparation,
  merge `flutter-refactor-phases` into `main`,
  tag `v0.1.4`,
  and verify the GitHub Release.
- Verification passed after the version bump:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  Flutter analyze,
  Dart package tests,
  Electron backup import test,
  Flutter UI/parity tests,
  Android debug build,
  signed Android release APK/AAB build,
  Flutter Linux release build,
  Android/Linux release artifact verification,
  Android E2E run artifact assertions,
  workflow YAML parse,
  and `git diff --check`.
- Generated local release artifacts for `v0.1.4`:
  `dist/flutter-release/android/chronopic-flutter-android-release.apk`,
  `dist/flutter-release/android/chronopic-flutter-android-release.aab`,
  `dist/flutter-release/linux/chronopic-flutter-linux-x64-0.1.4.tar.gz`,
  and matching `.sha256` files.

### 2026-05-10 Step 246

- Merged `flutter-refactor-phases` into `main` with a fast-forward merge.
- Pushed `main` at commit:
  `63e4e6d`.
- Verified main CI before tagging:
  GitHub Actions run `25624645255` completed successfully for both jobs:
  `verify` and `flutter`.
- Created and pushed annotated tag:
  `v0.1.4`.
- Release workflow run:
  `25624767040`.
  `prepare-release` passed and created/updated the public GitHub Release.
  `flutter-linux` passed and uploaded the Linux tarball assets.
  `flutter-android` failed because the repo does not currently have the four
  required Android signing secrets:
  `CHRONOPIC_ANDROID_KEYSTORE_BASE64`,
  `CHRONOPIC_ANDROID_STORE_PASSWORD`,
  `CHRONOPIC_ANDROID_KEY_ALIAS`,
  and
  `CHRONOPIC_ANDROID_KEY_PASSWORD`.
- Completed the `v0.1.4` release by uploading the locally verified Android
  release assets:
  `dist/flutter-release/android/chronopic-flutter-android-release.apk`,
  `dist/flutter-release/android/chronopic-flutter-android-release.apk.sha256`,
  `dist/flutter-release/android/chronopic-flutter-android-release.aab`,
  and
  `dist/flutter-release/android/chronopic-flutter-android-release.aab.sha256`.
- Verified the published GitHub Release:
  `gh release view v0.1.4 --repo denghongcai/ChronoPic` reports
  `isDraft=false`,
  `isPrerelease=false`,
  and URL
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.4`.
- Downloaded the published release assets into
  `.tmp/release-verify/v0.1.4`
  and verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.4.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.4.tar.gz | rg '(^|/)chronopic$'`.
- Updated `docs/flutter-release-checklist.md` with the `v0.1.4` automation
  caveat:
  configure Android signing secrets before relying on the automated Android
  release job.

### 2026-05-10 Step 247

- Configured the four GitHub Actions Android release signing secrets for
  `denghongcai/ChronoPic`:
  `CHRONOPIC_ANDROID_KEYSTORE_BASE64`,
  `CHRONOPIC_ANDROID_STORE_PASSWORD`,
  `CHRONOPIC_ANDROID_KEY_ALIAS`,
  and
  `CHRONOPIC_ANDROID_KEY_PASSWORD`.
- Secret values were written through `gh secret set` from stdin,
  without printing the keystore base64 value in the terminal output.
- Verified secret presence with:
  `gh secret list --repo denghongcai/ChronoPic --app actions`.
  The four Android release secret names are now present.
- Attempted to rerun the failed `v0.1.4` Release workflow after adding the
  secrets,
  but GitHub reported the original run as `startup_failure` with no rerun jobs.
  Do not treat that old run as automated Android-release evidence.
- Updated `docs/flutter-release-checklist.md` to record that the secrets are now
  configured for the next tag-triggered Android release job.

### 2026-05-10 Step 248

- Investigated the reported Flutter UI/Android import performance issues from
  the attached screenshots and Android behavior.
- Confirmed the UI issue is real:
  the Flutter shell centers browse pages inside a max-width global scroll frame,
  which creates poor wide-desktop adaptation.
- Confirmed the waterfall performance issue is real:
  `PhotoGrid` uses `GridView.builder`, but it is shrink-wrapped and non-
  scrollable inside a page-level `SingleChildScrollView`, so the page does not
  get real viewport-based lazy rendering.
- Confirmed the Android scope issue is real:
  `PhotoManagerGateway` uses `onlyAll: true` and scans `paths.first`, so the
  current Android import silently targets the full photo library rather than a
  user-chosen album/folder-like scope.
- Confirmed the Android import latency risk is structural:
  the gateway fetches up to 100000 entities in one call,
  reads original asset bytes for imports,
  and thumbnail generation decodes/resizes/writes synchronously on the scan
  path.
- Checked dependency freshness for the package currently used by this path:
  the pub.dev package API reports `photo_manager` latest stable as `3.9.0`,
  matching `chronopic_flutter/packages/chronopic_media/pubspec.yaml`.
- Added Phase 8 to `PLAN.md` and created
  `docs/superpowers/plans/2026-05-10-flutter-adaptive-import-performance.md`.
- Next:
  implement Phase 8 in order:
  responsive browse viewport,
  lazy sliver waterfall,
  Android scoped photo-library selection,
  scan responsiveness,
  then screenshot/E2E verification.

### 2026-05-10 Step 249

- Implemented Phase 8 responsive/lazy browse fixes for Flutter.
- Reworked the Flutter shell so `HomePage` owns its own scroll viewport instead
  of being wrapped by a centered global `SingleChildScrollView`.
- Converted the home browse surface to a `CustomScrollView` plus
  `PhotoGridSliver`,
  with adaptive grid columns across desktop widths.
- Changed default visible photo query volume to 20 items,
  with scroll-near-end and fallback load-more behavior increasing the result
  limit by 20 each time.
- Reset the photo page limit when search, filters, sort, favorites, all-photos,
  or memory scope changes.
- Updated Linux desktop parity/widget coverage so large fixture libraries assert
  the initial `20 items` result window and scroll-loading expansion.
- Added width-controlled Linux runner support through
  `CHRONOPIC_WINDOW_WIDTH` / `CHRONOPIC_WINDOW_HEIGHT`,
  then captured adaptive browse/detail screenshots at:
  `test-results/flutter-adaptive-phase8/1366-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/1600-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/2048-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/1366-detail.png`,
  `test-results/flutter-adaptive-phase8/1600-detail.png`,
  and
  `test-results/flutter-adaptive-phase8/2048-detail.png`.

### 2026-05-10 Step 250

- Implemented Phase 8 Android scoped import and scan responsiveness fixes.
- Re-checked the official pub.dev API before relying on the existing Android
  photo library dependency:
  `photo_manager` latest stable remains `3.9.0`,
  matching `chronopic_flutter/packages/chronopic_media/pubspec.yaml`.
- Added `PhotoLibraryScope` to the media gateway contract,
  exposed photo-library scopes through `PhotoManagerGateway`,
  and replaced the silent `onlyAll: true` scan path with an explicit bottom
  sheet where the user chooses `All Photos` or a concrete album/path-like
  scope before scanning.
- Changed `PhotoManagerGateway` asset discovery from one 100000-item request to
  paged discovery batches.
- Added mobile thumbnail byte reads via `readThumbnailBytes`,
  so disabled-AI scans avoid reading full original asset bytes.
- Moved thumbnail decode/resize/write work into `Isolate.run`,
  keeping CPU-heavy thumbnail generation off the main scan isolate path.
- Fixed a live Android bug found during E2E:
  the scope bottom sheet originally used `State.context`,
  which is above `MaterialApp` in this widget tree and caused
  `No MaterialLocalizations found`.
  It now uses `_navigatorKey.currentContext`.
- Hardened the Android deep E2E runner for scoped import:
  it waits for the `Choose photo library` sheet,
  selects `ChronoPicDeepE2E` when available,
  records `03-scope` and `04-scope` artifacts,
  and can tap Flutter list rows whose Android `content-desc` includes a
  second line such as `2 items`.
- Re-verified Phase 8 with:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build linux --debug`,
  `ANDROID_DEVICE_ID=emulator-5554 MOBILE_E2E_RUN_ID=phase8-final-20260510T122821Z chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`,
  and
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android/phase8-final-20260510T122821Z`.
- Result:
  all listed commands passed,
  Android full-access and limited-access paths both showed scoped selection and
  imported the 2-photo `ChronoPicDeepE2E` fixture,
  backup restore artifacts were valid,
  and Phase 8 is recorded complete in `PLAN.md`.

### 2026-05-10 Step 251

- Prepared the `v0.1.5` release after Phase 8.
- Bumped the repo/package release metadata from `0.1.4` to `0.1.5`,
  including workspace package manifests,
  `chronopic_flutter/apps/chronopic/pubspec.yaml` as `0.1.5+5`,
  README release artifact names,
  DEVELOPMENT release commands,
  and the Flutter release checklist's Linux artifact expectation.
- Re-verified release artifacts locally with:
  `CHRONOPIC_ANDROID_STORE_FILE="$PWD/.tmp/release-signing/chronopic-upload.jks" CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh`,
  `chronopic_flutter/tool/release/build_linux_release.sh`,
  and
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`.
- Result:
  local signed Android APK/AAB and Linux release tarball verification passed
  for `0.1.5`;
  the Linux artifact name is
  `chronopic-flutter-linux-x64-0.1.5.tar.gz`.
- Re-ran source validation after the version bump:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`.
- Next:
  commit and push `main`,
  tag `v0.1.5`,
  watch the tag-triggered GitHub Release workflow,
  and verify the published assets from GitHub.

### 2026-05-10 Step 252

- Published `v0.1.5`.
- Committed Phase 8 and release metadata as:
  `6370c1c Complete Flutter adaptive import hardening`.
- Pushed `main` to `origin/main`.
- Created and pushed annotated tag `v0.1.5`.
- Observed GitHub Actions startup failures:
  Release run `25629990377` for tag `v0.1.5` completed with
  `startup_failure`,
  no jobs,
  and no retrievable logs;
  the `main` CI run `25629985588` for the same commit had the same startup
  failure shape.
- Since the tag-triggered release workflow did not create a release,
  published `v0.1.5` manually from the locally verified assets under
  `dist/flutter-release`.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.5`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.5 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.5` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.5.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.5.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.5` is public with locally built and post-download verified Flutter
  Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.

### 2026-05-10 Step 253

- Fixed the Flutter desktop selected-photo interaction reported from runtime
  screenshot review.
- Root cause:
  `HomePage` still rendered a normal browse-page inline `DetailSurface` when a
  photo was selected,
  so single click appended a detail editor below the waterfall page even though
  the Electron parity contract says single click only selects.
- Removed the normal browse inline detail rendering.
  Waterfall selection now keeps only the selected-photo banner and card
  highlight;
  focused Detail still opens through double click,
  Enter,
  or the existing focused-detail entry points.
- Updated Flutter tests that were still assuming inline detail:
  map/timeline tests now verify selected-photo state first and open focused
  Detail explicitly,
  Linux desktop parity edit/favorite/restart checks now enter focused Detail
  before asserting inspector/edit controls,
  and the first browse smoke test asserts that single-click selection does not
  show `Detail view and gallery view` or edit fields.
- Added focused-detail inspector status feedback for save/validation messages,
  so edit feedback remains visible inside the overlay instead of being hidden
  behind the shell status bar.
- Verification commands passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  and
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh populated-grid detail`.
- Verification scenes from `docs/agent-verification-script.md`:
  Scene 3 scan/browse covered by the refreshed populated-grid screenshot at
  `test-results/flutter-electron-parity/flutter/02-populated-grid.png`;
  Scene 4 focused viewing covered by
  `test-results/flutter-electron-parity/flutter/05-detail.png`;
  Scene 5 edit feedback covered by the Linux desktop parity edit flow;
  Scene 7 restart persistence covered by the Linux desktop parity restart test.
- Skipped full Electron recapture because this change is a Flutter-only
  correction back to the already documented Electron interaction contract.

### 2026-05-10 Step 254

- Prepared the `v0.1.6` Flutter release for the single-click/detail parity
  correction.
- Bumped release metadata from `0.1.5` to `0.1.6`,
  including root `package.json`,
  `chronopic_flutter/apps/chronopic/pubspec.yaml` as `0.1.6+6`,
  README current artifact names,
  DEVELOPMENT release examples,
  and the Flutter release checklist's Linux artifact expectation.
- Re-verified source gates with:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`.
- Rebuilt and verified release artifacts with:
  `CHRONOPIC_ANDROID_STORE_FILE="$PWD/.tmp/release-signing/chronopic-upload.jks" CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh`,
  `chronopic_flutter/tool/release/build_linux_release.sh`,
  and
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`.
- Result:
  source checks passed,
  Android APK/AAB were rebuilt,
  Linux release tarball
  `chronopic-flutter-linux-x64-0.1.6.tar.gz` was rebuilt,
  and the release verifier found all six expected Flutter assets.
- Next:
  commit and push `main`,
  tag `v0.1.6`,
  publish the GitHub Release,
  and verify downloaded public assets.

### 2026-05-10 Step 255

- Published `v0.1.6`.
- Committed and pushed the parity fix plus release metadata as:
  `5c01f57 Fix Flutter selected photo detail parity`.
- Created and pushed annotated tag `v0.1.6`,
  pointing at `5c01f57f5fc8555d7eaf2458957b3b2d284b13c2`.
- Observed the tag-triggered GitHub Actions Release run
  `25631210324` complete with `startup_failure`,
  no scheduled jobs,
  and no retrievable job logs.
- Since the automated release workflow did not create a release,
  published `v0.1.6` manually from locally verified Flutter assets under
  `dist/flutter-release`.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.6`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.6 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.6` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.6.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.6.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.6` is public with locally built and post-download verified Flutter
  Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.

### 2026-05-10 Step 256

- Recorded the next two planned phases after `v0.1.6`.
- User decisions captured:
  GitHub Actions `startup_failure` was handled by the user and should not be
  treated as the current next blocker;
  real Electron migration sample validation should not be pursued;
  Android production package id is `ai.chronopic.app`.
- Added
  `docs/superpowers/plans/2026-05-10-flutter-desktop-interaction-regression-audit.md`
  for Phase 9.
  The phase requires an evidence-first desktop interaction audit against the
  Electron reference,
  including single-click selection,
  double-click/Enter focused Detail,
  Gallery/Detail keyboard transitions,
  edit feedback visibility,
  incremental 20-item loading,
  and adaptive layout screenshots at 1366,
  1600,
  and 2048 widths.
- Added
  `docs/superpowers/plans/2026-05-10-flutter-mobile-ui-refine.md`
  for Phase 10.
  The phase covers Android package identity,
  mobile first-run,
  permission recovery,
  scoped import,
  scan progress,
  browse/search/filter,
  mobile Detail/Gallery overlays,
  edit feedback,
  memories,
  settings,
  backup/restore,
  Android E2E evidence,
  and the iOS macOS/Xcode blocked boundary.
- Updated `PLAN.md` with Phase 9 and Phase 10 entries.
- Updated `docs/flutter-refactor-phases.md` with the same phase summaries and
  exit gates.
- No code changes were made in this step;
  package id implementation remains part of Phase 10 execution.

### 2026-05-10 Step 257

- Executed Phase 9 and Phase 10 locally.
- Phase 9 desktop interaction audit:
  refreshed Electron screenshots with
  `node scripts/capture-electron-parity.mjs`;
  refreshed Flutter screenshots with
  `cd chronopic_flutter && bash tool/capture_flutter_parity.sh all`;
  generated compare artifacts with
  `node scripts/compare-flutter-electron-parity.mjs`;
  and captured desktop adaptive browse/detail screenshots at 1366,
  1600,
  and 2048 widths with
  `cd chronopic_flutter && bash tool/capture_flutter_adaptive_regression.sh`.
- Fixed the Electron parity capture script so it runs the desktop Electron and
  native-module guards before Playwright launches the app.
  This avoids stale Electron/native runtime state when capture bypasses the
  normal desktop startup scripts.
- Strengthened Flutter UI regression coverage:
  desktop single-click selection no longer opens an inline detail surface,
  double-click/Enter opens focused Detail,
  mobile first-run uses photo-library selection as the primary entry,
  mobile photo tap opens focused Detail,
  and a 25-photo fixture confirms the browse query starts at 20 items and
  lazy-loads to 25.
- Phase 10 product identity:
  updated Android namespace/applicationId,
  Android `MainActivity` package path,
  Android E2E package constants,
  iOS bundle metadata,
  Linux application id,
  README,
  and release/mobile docs to use `ai.chronopic.app`.
- Mobile UI refine:
  added mobile-specific first-run action keys,
  hid desktop add-folder entry from the mobile first viewport,
  made the mobile top navigation fit four actions at phone width,
  added safe-area and bottom padding for mobile content,
  improved narrow section-header wrapping,
  and kept desktop double-click behavior while allowing single-tap Detail on
  mobile.
- Updated evidence docs:
  `docs/flutter-desktop-interaction-regression-audit.md`,
  `docs/flutter-mobile-ui-refine-audit.md`,
  `docs/mobile-e2e-verification.md`,
  `docs/mobile-productization.md`,
  `PLAN.md`,
  and `docs/flutter-refactor-phases.md`.
- Verification passed:
  `pnpm build`,
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `MOBILE_E2E_RUN_ID=phase10-final-browse-state bash chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`.
- Final Android deep E2E evidence:
  `.tmp/mobile-e2e/android/phase10-final-browse-state/`.
  The runner summary reports `status: passed` and
  `packageName: ai.chronopic.app`;
  the artifact assertion helper passed as part of the run.
- `adb shell pm list packages | rg 'ai\.chronopic\.app'`
  returned `package:ai.chronopic.app`.
- Skipped iOS live verification because this Linux workstation still cannot run
  macOS/Xcode simulator or signing checks.

### 2026-05-11 Step 258

- Prepared the `v0.1.7` Flutter release after the desktop/mobile refinement
  phases.
- Bumped release metadata from `0.1.6` to `0.1.7`, including:
  root `package.json`,
  `chronopic_flutter/apps/chronopic/pubspec.yaml` as `0.1.7+7`,
  README current release artifact names,
  DEVELOPMENT release examples,
  `docs/flutter-release-checklist.md`,
  and the Flutter release artifact expectation in `PLAN.md`.
- Re-verified source gates with:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  and
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`.
- Rebuilt and verified release artifacts with:
  `CHRONOPIC_ANDROID_STORE_FILE="$PWD/.tmp/release-signing/chronopic-upload.jks" CHRONOPIC_ANDROID_STORE_PASSWORD=chronopic-local-pass CHRONOPIC_ANDROID_KEY_ALIAS=chronopic-upload CHRONOPIC_ANDROID_KEY_PASSWORD=chronopic-local-pass chronopic_flutter/tool/release/build_android_release.sh`,
  `chronopic_flutter/tool/release/build_linux_release.sh`,
  and
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`.
- Result:
  source checks passed,
  Android APK/AAB were rebuilt,
  Linux release tarball
  `chronopic-flutter-linux-x64-0.1.7.tar.gz` was rebuilt,
  and the release verifier found all six expected Flutter assets.
- Selected verification scenes:
  release artifact verification covers the Phase 7 release path;
  desktop browse/detail and mobile first-run/detail scenes were covered by the
  focused Flutter UI tests from this gate.
- Skipped full iOS live verification because this Linux workstation still
  cannot run macOS/Xcode simulator or signing checks.
- Next:
  commit and push `main`,
  tag `v0.1.7`,
  publish the GitHub Release,
  and verify downloaded public assets.

### 2026-05-11 Step 259

- Published `v0.1.7`.
- Pushed `main` with:
  `cfe582f Execute Flutter desktop and mobile refinement phases`,
  and
  `cfd5d9f Prepare v0.1.7 release`.
- Main CI run `25646589595` passed before tagging:
  `verify` completed in 1m47s with unit tests,
  typecheck,
  build,
  Runtime E2E,
  Accessibility E2E,
  AI Productization E2E,
  and Backup E2E;
  `flutter` completed in 5m11s with Flutter doctor,
  dependency install,
  Dart analyze,
  Dart package tests,
  Flutter UI/parity tests,
  and Android debug build.
- Created and pushed annotated tag `v0.1.7`,
  pointing at `cfd5d9f1f0197852886b83acb76543b3fcd2d160`.
- Observed the tag-triggered GitHub Actions Release run
  `25646732907` complete successfully:
  `prepare-release` created/updated the release,
  `flutter-linux` uploaded the Linux x64 tarball and checksum,
  and `flutter-android` uploaded the signed Android APK/AAB and checksums.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.7`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.7 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.7` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.7.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.7.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.7` is public with GitHub Actions-built and post-download verified
  Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.

### 2026-05-11 Step 260

- Reviewed the user-provided mobile UI refine proposal and promoted it into a
  new planned phase rather than treating it as a small Phase 10 patch.
- Added
  `docs/superpowers/plans/2026-05-11-flutter-mobile-native-experience-redesign.md`.
- Updated `PLAN.md` with
  `11. Flutter Mobile Native Experience Redesign`.
- Updated `docs/flutter-refactor-phases.md` with the same Phase 11 summary and
  exit gate.
- Captured the core product decision:
  Android mobile may diverge more strongly from desktop visual layout and
  interaction structure,
  while keeping the shared local-first data and workflow contracts.
- The new phase covers mobile design tokens,
  native shell/home information architecture,
  bottom navigation,
  search/filter sheets,
  media-first Detail/Gallery,
  grouped Settings,
  and a guided Create Memory flow.
- Verification:
  docs-only planning update;
  runtime scenes were skipped because no app code changed.
  `git diff --check` was run after the edit.

### 2026-05-11 Step 261

- Executed Phase 11: Flutter Mobile Native Experience Redesign.
- Added mobile-native UI structure:
  mobile theme tokens,
  phone shell header,
  bottom navigation for Waterfall / Map / Timeline / Settings,
  mobile home dashboard with search/shortcuts/status,
  filter bottom sheet,
  mobile active filter chips,
  grouped Settings rows with drill-in sheets,
  and a guided Create Memory wizard.
- Updated focused mobile Detail and Gallery:
  Detail now exposes mobile topbar/media/action surfaces and no longer shows
  desktop shortcut copy on phone layouts;
  Gallery now uses compact mobile chrome and icon action at phone widths.
- Updated mobile tests:
  `chronopic_flutter/packages/chronopic_ui/test/mobile_productization_test.dart`
  now covers mobile dashboard shortcuts,
  bottom navigation,
  filter sheet,
  Detail mobile layout,
  grouped Settings,
  and the Create Memory wizard.
- Updated Android deep E2E:
  `chronopic_flutter/apps/chronopic/integration_test/mobile_deep_e2e_test.dart`
  now drives the new mobile shell,
  Create Memory wizard,
  filter sheet,
  Settings drill-in,
  and restart/backup persistence path.
- Fixed issues found by verification:
  mobile Gallery chrome horizontal overflow,
  mobile memory detail date-row overflow,
  mobile Language settings drill-in overflow,
  and mobile active-filter chips not showing after filter-sheet apply.
- Updated durable docs:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/flutter-mobile-ui-refine-audit.md`,
  `docs/mobile-productization.md`,
  `docs/mobile-e2e-verification.md`,
  and
  `docs/superpowers/plans/2026-05-11-flutter-mobile-native-experience-redesign.md`.
- Verification scenes run from `docs/agent-verification-script.md`:
  Scene 1 was covered by Flutter app/widget launch tests and Android debug
  build,
  Scene 3 by mobile browse/search/filter/sort tests,
  Scene 4 by focused Detail and Gallery tests,
  Scene 5 by edit/favorite/datetime assertions in Android deep E2E,
  Scene 6 by the Create Memory and memory lifecycle E2E path,
  Scene 7 by backup/restore restart assertions,
  and Scene 8 by grouped Settings locale persistence.
- Verification commands passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-15 Step 272

- Executed Phase 14:
  `Flutter Mobile Memory Creation Completion`.
- Replaced the previous prompt-only mobile Create Memory path with an app-owned
  mobile creation sheet that supports:
  photo selection,
  visible selected count,
  required selection before details,
  title editing,
  optional description editing,
  cover choice,
  confirmation,
  and post-confirm navigation to the created memory detail page.
- Wired the completed flow through the Memories page Create Memory action,
  the home first-memory CTA,
  and the selected-photo Detail/Add-to-Memory fallback when no target memory is
  selected.
- Kept the implementation on existing local-first memory semantics:
  `ChronoPicAppService.createMemory`,
  `addPhotoToMemory`,
  `setMemoryCover`,
  and the existing editable memory detail surface.
- Preserved Phase 12/13 mobile browse behavior by adding regression coverage
  that dragging inside the mobile creation selector does not open focused
  Detail.
- Updated durable docs:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  `docs/mobile-e2e-verification.md`,
  and the Phase 14 implementation plan.
- Verification scenes from `docs/agent-verification-script.md`:
  Scene 3 is covered by mobile scan/browse/count widget tests,
  Scene 4 is covered by the new mobile creation sheet and memory detail tests,
  Scene 7 remains covered by the app-owned mobile backup/restart integration
  path,
  and Scene 8 remains covered by settings/locale persistence in the same
  integration path.
  Electron Playwright Scene 1 was skipped because this phase changes Flutter
  mobile memory UX,
  not the Electron runtime surface.
- Verification commands passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
- Known verification note:
  the integration test command still prints Flutter's known
  `integration_test` plugin warning,
  but the command exited 0 with `All tests passed`.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-15 Step 271

- Planned the next numbered Flutter phase:
  `14. Flutter Mobile Memory Creation Completion`.
- Added the implementation plan:
  `docs/superpowers/plans/2026-05-15-flutter-mobile-memory-creation-completion.md`.
- Updated `PLAN.md` with Phase 14 source input,
  goal,
  current gap,
  planned mobile surfaces,
  explicit non-goals,
  and exit gate.
- Updated `docs/flutter-refactor-phases.md` so Phase 14 follows Phase 13 in the
  durable Flutter tracker.
- Updated `docs/mobile-productization.md` with the Phase 14 mobile memory
  creation contract and planned local gate.
- Updated `docs/mobile-e2e-verification.md` with the planned Phase 14 widget and
  app-owned integration evidence.
- No implementation code was changed in this step.
- Verification:
  placeholder scan for the new plan found no unresolved markers,
  and `git diff --check` passed.

### 2026-05-11 Step 262

- Published `v0.1.8`.
- Pushed `main` with:
  `5e72edc Execute Flutter mobile native redesign`,
  and
  `f4aa0be Prepare v0.1.8 release`.
- Local pre-release verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  `chronopic_flutter/tool/release/build_android_release.sh`,
  `chronopic_flutter/tool/release/build_linux_release.sh`,
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`,
  and
  `git diff --check`.
- Main CI run `25655887335` passed before tagging:
  `verify` completed in 1m59s with unit tests,
  typecheck,
  build,
  Runtime E2E,
  Accessibility E2E,
  AI Productization E2E,
  and Backup E2E;
  `flutter` completed in 5m13s with Flutter doctor,
  dependency install,
  Dart analyze,
  Dart package tests,
  Flutter UI/parity tests,
  and Android debug build.
- Created and pushed annotated tag `v0.1.8`,
  pointing at `f4aa0be4394640249de3d7870648d8c08bcdcb36`.
- Observed the tag-triggered GitHub Actions Release run
  `25656116153` complete successfully:
  `prepare-release` created/updated the release,
  `flutter-linux` uploaded the Linux x64 tarball and checksum,
  and `flutter-android` uploaded the signed Android APK/AAB and checksums.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.8`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.8 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.8` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.8.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.8.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.8` is public with GitHub Actions-built and post-download verified
  Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.

### 2026-05-11 Step 263

- Reviewed the real Android mobile import screenshot:
  the scan status showed `406/5405` processed/imported while dashboard and
  browse count surfaces still showed `20`.
- Traced the count issue to mobile UI using the paged visible browse list
  (`_photoPageSize = 20`) as if it were the catalog total.
- Traced the remaining import-speed issue to mobile scans still performing
  per-asset thumbnail reads plus decode/resize/JPEG encode/cache writes during
  the scan,
  with progress reported to UI on every asset.
- Added a new planned phase:
  `12. Flutter Mobile Import Count And Lazy Thumbnail Pipeline`.
- Created the implementation handoff plan:
  `docs/superpowers/plans/2026-05-11-flutter-mobile-import-count-and-lazy-thumbnails.md`.
- Updated `PLAN.md` and `docs/flutter-refactor-phases.md` with the same phase
  scope,
  root causes,
  non-goals,
  and exit gate.
- Verification:
  docs-only planning update;
  runtime scenes were skipped because no app code changed.
  `git diff --check` was run after the edit.

### 2026-05-11 Step 264

- Executed Phase 12:
  `Flutter Mobile Import Count And Lazy Thumbnail Pipeline`.
- Added repository/app-service photo counting:
  `ChronoPicRepository.countPhotos()` uses the same filter predicate as
  `listPhotos()` while ignoring pagination,
  and `ChronoPicAppService.countPhotos()` exposes it to UI surfaces.
- Fixed mobile count copy:
  `ChronoPicHome` now separates catalog count,
  filtered result count,
  and visible page length;
  mobile dashboard/scan cards use catalog totals,
  while browse copy says `loaded / total` when only the first page is visible.
- Fixed scan progress semantics:
  skipped unchanged assets now count toward `ScanProgress.processed`,
  while imported,
  updated,
  skipped,
  errors,
  and missing remain distinct final buckets.
- Removed eager mobile JPEG thumbnail generation from lazy-capable sources:
  `MediaSourceAdapter.supportsLazyThumbnails` marks mobile photo-library
  sources as lazy,
  mobile scans upsert metadata with `thumbnailPath: null`,
  and visible `asset://` previews request thumbnail bytes lazily through the
  active mobile media source or platform gateway.
- Added deterministic progress throttling:
  progress reports are emitted at scan start,
  completion,
  errors,
  every 10 processed assets,
  or after 250 ms,
  instead of one UI callback per asset.
- Updated tests:
  `mobile_scan_test.dart` covers skipped progress,
  no scan-time thumbnail reads for lazy mobile sources,
  and 100-asset throttled progress;
  `mobile_productization_test.dart` covers 25-photo pagination and a 225-photo
  large mobile catalog total;
  `mobile_deep_e2e_test.dart` rejects `20 indexed` when a 25-photo mobile
  fixture is restored.
- Updated durable docs:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  `docs/mobile-e2e-verification.md`,
  and
  `docs/superpowers/plans/2026-05-11-flutter-mobile-import-count-and-lazy-thumbnails.md`.
- Verification scenes from `docs/agent-verification-script.md`:
  Scene 1 covered by Flutter widget/app launch tests and Android debug build,
  Scene 3 covered by mobile scan/browse/count tests,
  Scene 4 covered by the existing mobile detail/gallery E2E path,
  Scene 5 covered by edit/favorite/datetime assertions in Android deep E2E,
  Scene 6 covered by the memory lifecycle E2E path,
  Scene 7 covered by backup/restore restart assertions,
  and Scene 8 covered by grouped settings locale persistence.
- Verification commands passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-11 Step 265

- Published `v0.1.9`.
- Pushed the implementation and release-prep commits on `main`:
  `23c4a8f Execute Flutter mobile import pipeline`
  and
  `68a141f Prepare v0.1.9 release`.
- Local pre-release verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `xvfb-run -a pnpm run e2e:runtime`,
  `xvfb-run -a pnpm run e2e:accessibility`,
  `xvfb-run -a pnpm run e2e:ai`,
  `xvfb-run -a pnpm run e2e:backup`,
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  local Android/Linux release artifact builds,
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`,
  and
  `git diff --check`.
- Main CI run `25671715396` passed for commit `68a141f`:
  `verify` completed in `1m46s`
  and
  `flutter` completed in `5m29s`.
- Created and pushed annotated tag `v0.1.9`
  at
  `68a141f5c5fc97c4e7bec8a15a01b8547b6edb7a`.
- Observed the tag-triggered GitHub Actions Release run
  `25672015701` complete successfully:
  `prepare-release` completed in `4s`,
  `flutter-linux` completed in `2m38s`,
  and
  `flutter-android` completed in `6m18s`.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.9`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.9 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.9` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.9.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.9.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.9` is public with GitHub Actions-built and post-download verified
  Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.

### 2026-05-12 Step 266

- Reviewed the real Android screenshot from 2026-05-12 showing focused Detail
  with a top counter of `1 / 20` while the user expected the total to represent
  the full mobile photo result scope.
- Confirmed the counter issue was still downstream of pagination:
  the waterfall page correctly renders 20 visible items,
  but focused Detail and Gallery were receiving that same first-page list instead
  of the full filtered result set.
- Confirmed the scroll-to-open issue came from `PhotoCardTile` using raw
  `onPointerDown` handling;
  on mobile this opened focused Detail before Flutter could resolve whether the
  gesture was a tap or a scroll/drag.
- Added failing regression coverage first:
  dragging a mobile waterfall card must not open focused Detail,
  and opening focused Detail from a 25-photo mobile catalog must display
  `1 / 25` rather than `1 / 20`.
- Fixed focused viewer data flow:
  `ChronoPicHome` now keeps paged waterfall photos separate from full
  `viewerPhotos`,
  and focused Detail/Gallery use the full current filtered result set for
  position/count and adjacent navigation.
- Fixed waterfall card gestures:
  `PhotoCardTile` now uses resolved `GestureDetector` tap/double-tap callbacks
  instead of pointer-down activation,
  so scroll/drag gestures remain scroll gestures.
- Fixed settings statistics to use repository/app-service catalog and favorite
  counts instead of a capped full-photo list.
- Updated durable phase docs:
  `PLAN.md`
  and
  `docs/flutter-refactor-phases.md`.
- Verification so far:
  the targeted red-green command
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`
  now passes after failing on the two new regressions before the implementation.
- Verification scenes from `docs/agent-verification-script.md`:
  Scene 3 covered by mobile scan/browse/count regression tests,
  Scene 4 covered by focused Detail/Gallery result-scope tests,
  Scene 7 covered by the existing mobile deep E2E backup/restart path,
  and Scene 8 covered by the settings statistics path in the UI tests.
  Electron Playwright launch scenes were skipped because this slice changes the
  Flutter mobile UI/runtime path rather than the Electron app runtime.
- Verification commands passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-12 Step 267

- Published `v0.1.10`.
- Pushed the implementation and release-prep commits on `main`:
  `69b2135 Fix mobile viewer counts and scroll gestures`
  and
  `613a4f9 Prepare v0.1.10 release`.
- Local pre-release verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `xvfb-run -a pnpm run e2e:runtime`,
  `xvfb-run -a pnpm run e2e:accessibility`,
  `xvfb-run -a pnpm run e2e:ai`,
  `xvfb-run -a pnpm run e2e:backup`,
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  local Android/Linux release artifact builds,
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`,
  and
  `git diff --check`.
- Main CI run `25685549756` passed for commit `613a4f9`:
  `verify` completed in `1m50s`
  and
  `flutter` completed in `5m38s`.
- Created and pushed annotated tag `v0.1.10`
  at
  `613a4f970921986a211774b37832c97b368273f7`.
- Observed the tag-triggered GitHub Actions Release run
  `25685916285` complete successfully:
  `prepare-release` completed in `4s`,
  `flutter-linux` completed in `1m51s`,
  and
  `flutter-android` completed in `6m8s`.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.10`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.10 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.10` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.10.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.10.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.10` is public with GitHub Actions-built and post-download verified
  Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-13 Step 268

- Promoted the candidate `Phase 13b - Mobile UX Refinement From Real Screenshots`
  into the formal next numbered phase:
  `13. Flutter Mobile UX Refinement From Real Screenshots`.
- Added the implementation plan:
  `docs/superpowers/plans/2026-05-13-flutter-mobile-ux-refinement-real-screenshots.md`.
- Updated `PLAN.md` with Phase 13 source inputs,
  goal,
  planned mobile surfaces,
  explicit non-goals,
  and exit gate.
- Updated `docs/flutter-refactor-phases.md` with the same Phase 13 scope so the
  Flutter phase tracker continues from Phase 12 without a `13b` numbering gap.
- Updated `docs/mobile-productization.md` with the Phase 13 mobile
  real-screenshot UX contract and planned local gate.
- No implementation code was changed in this step.
- Verification:
  `git diff --check` passed for the tracked documentation changes,
  and the new Phase 13 implementation plan file was checked for trailing
  whitespace.

### 2026-05-14 Step 269

- Executed Phase 13:
  `Flutter Mobile UX Refinement From Real Screenshots`.
- Added the real-screenshot audit document:
  `docs/flutter-mobile-real-screenshot-ux-audit.md`.
- Updated mobile home hierarchy so the All Photos shortcut owns the primary
  indexed count,
  while the scan card reports readiness or indexing activity instead of
  repeating `indexed locally` count copy.
- Added explicit mobile bottom spacing below waterfall browse content and keyed
  the persistent bottom navigation for regression coverage.
- Rebalanced focused mobile Detail around a light topbar,
  media-first preview,
  primary touch-action row,
  filmstrip,
  and Details/inspector entry before the edit metadata area.
- Simplified mobile Gallery with a compact action row for previous,
  next,
  and Details/inspector entry while preserving full-result counters.
- Updated the app-owned mobile integration test so it rejects repeated
  `25 indexed locally` copy while still asserting `25 indexed`,
  `20 loaded / 25 total`,
  and rejection of `20 indexed`.
- Updated durable docs:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  `docs/mobile-e2e-verification.md`,
  and the Phase 13 implementation plan.
- Verification scenes from `docs/agent-verification-script.md`:
  Scene 3 covered by mobile scan/browse/count regression tests,
  Scene 4 covered by focused Detail and Gallery mobile widget/integration tests,
  Scene 7 covered by the app-owned mobile backup/restart integration path,
  and Scene 8 remains covered by mobile settings/locale persistence in the same
  integration path.
  Electron Playwright Scene 1 was skipped because this phase changes Flutter
  mobile presentation and Android app verification,
  not the Electron runtime surface.
- Verification commands passed:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test apps/chronopic/test`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  and
  `git diff --check`.
- Known verification note:
  the integration test command still prints Flutter's known
  `integration_test` plugin warning,
  but the command exited 0 with `All tests passed`.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.
- Next:
  prepare an add/commit/release pass if requested,
  or choose the next numbered Flutter phase from the updated plan.

### 2026-05-14 Step 270

- Published `v0.1.11`.
- Pushed the Phase 13 implementation and release-prep commits on `main`:
  `a46dd89 Refine Flutter mobile UX from real screenshots`
  and
  `613f32d Prepare v0.1.11 release`.
- Local pre-release verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `xvfb-run -a pnpm run e2e:runtime`,
  `xvfb-run -a pnpm run e2e:accessibility`,
  `xvfb-run -a pnpm run e2e:ai`,
  `xvfb-run -a pnpm run e2e:backup`,
  `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  local Android/Linux release artifact builds,
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`,
  and
  `git diff --check`.
- Main CI run `25865250376` passed for commit `613f32d`:
  `verify` completed in `1m42s`
  and
  `flutter` completed in `5m33s`.
- Created and pushed annotated tag `v0.1.11`
  at
  `613f32d1864441e14a8357795096d31a73be0ebd`.
- Observed the tag-triggered GitHub Actions Release run
  `25865257317` complete successfully:
  `prepare-release` completed in `4s`,
  `flutter-linux` completed in `2m3s`,
  and
  `flutter-android` completed in `6m23s`.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.11`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.11 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.11` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.11.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.11.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.11` is public with GitHub Actions-built and post-download verified
  Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-16 Step 273

- Published `v0.1.12`.
- Pushed the Phase 14 implementation and release-prep commits on `main`:
  `f31a9e4 Execute Flutter mobile memory creation completion`
  and
  `cbe83ae Prepare v0.1.12 release`.
- Local pre-release verification passed:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `xvfb-run -a pnpm run e2e:runtime`,
  `xvfb-run -a pnpm run e2e:accessibility`,
  `xvfb-run -a pnpm run e2e:ai`,
  `xvfb-run -a pnpm run e2e:backup`,
  `cd chronopic_flutter && dart analyze packages/chronopic_media packages/chronopic_app packages/chronopic_ui apps/chronopic`,
  `cd chronopic_flutter && dart test packages/chronopic_media/test packages/chronopic_app/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/mobile_productization_test.dart`,
  `cd chronopic_flutter && flutter test apps/chronopic/integration_test/mobile_deep_e2e_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build apk --debug`,
  local Android/Linux release artifact builds,
  `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`,
  and
  `git diff --check`.
- Main CI run `25949297431` passed for commit `cbe83ae`:
  `verify` completed in `1m33s`,
  and
  `flutter` completed in `5m2s`.
- Created and pushed annotated tag `v0.1.12`
  at
  `cbe83aeb2db4b8d34c95f6b26f5c01f4c08e897f`.
- Observed the tag-triggered GitHub Actions Release run
  `25949420131` complete successfully:
  `prepare-release` completed in `3s`,
  `flutter-linux` completed in `1m42s`,
  and
  `flutter-android` completed in `6m12s`.
- Public release URL:
  `https://github.com/denghongcai/ChronoPic/releases/tag/v0.1.12`.
- Verified the GitHub Release after publication:
  `gh release view v0.1.12 --repo denghongcai/ChronoPic`
  reported `isDraft=false`,
  `isPrerelease=false`,
  and the six expected Flutter assets.
- Downloaded the public release assets into `.tmp/release-verify/v0.1.12` and
  verified:
  `sha256sum -c chronopic-flutter-android-release.apk.sha256`,
  `sha256sum -c chronopic-flutter-android-release.aab.sha256`,
  `sha256sum -c chronopic-flutter-linux-x64-0.1.12.tar.gz.sha256`,
  and
  `tar -tzf chronopic-flutter-linux-x64-0.1.12.tar.gz | rg '(^|/)chronopic$'`.
- Result:
  `v0.1.12` is public with GitHub Actions-built and post-download verified
  Flutter Android APK,
  Android AAB,
  Linux x64 tarball,
  and matching checksum assets.
- Skipped:
  iOS live scenes remain blocked because this Linux workstation cannot provide
  macOS/Xcode simulator,
  signing,
  or device evidence.

### 2026-05-16 Step 274

- Removed the newly drafted large-library performance candidate from current
  planning per user direction.
- Updated the durable phase trackers to avoid treating large-library performance
  as the next phase:
  `PLAN.md`,
  `docs/flutter-refactor-phases.md`,
  `docs/mobile-productization.md`,
  and `docs/mobile-e2e-verification.md`.
- Next:
  audit the repo for user-facing feature loops that are not complete and choose
  a different next phase from that evidence.

### 2026-05-16 Step 275

- Audited the repo for non-performance feature loops that still look incomplete.
- Strongest candidate:
  AI/Map configuration validation.
  Settings can save AI and map credentials and show presence/configured states,
  but the current provider abstractions do not expose a live health probe or
  test-connection path.
- Second candidate:
  metadata portability.
  ChronoPic has JSON backup/restore for its local projection,
  but sidecar metadata export/import and EXIF writeback remain outside the
  current completed data-safety loop.
- Third candidate:
  iOS live completion.
  iOS metadata is scaffolded,
  but the required macOS/Xcode permission/import/restart/restore evidence is
  still blocked on Apple tooling.
- Treat OCR,
  vector search,
  and person/face grouping as larger future discovery features,
  not the next "finish an incomplete loop" candidate.

### 2026-10-11 Step 276

- Restructured agent planning/history documentation to stop loading the full
  execution history into every session context.
- `AGENTS.md` was reduced from 8215 lines to 49 lines:
  it now contains only Purpose, Working Rules, Current Plan Reference,
  and an update-in-place `Current State` summary.
- The 276-entry step log was split by line into
  `docs/superpowers/plans/agent-step-log-electron-line.md` (Steps 0-122)
  and
  `docs/superpowers/plans/agent-step-log-flutter-line.md` (Steps 101+,
  this file).
- The completed 66-item `Next Immediate Tasks` list was deleted; all items
  were already done and duplicated `PLAN.md` phase status.
- `PLAN.md` was reduced from 3380 lines to 83 lines:
  Summary, Active Direction (AI/map config validation, metadata portability,
  iOS verification), Future Product Backlog, a Completed Phases index,
  durable Product Scope Constraints, and a Verification pointer.
- Completed PLAN.md phases were archived to
  `docs/superpowers/plans/electron-development-plan-archive.md`
  (Phases 1-4.26 plus Phase 5, including the old Public Interfaces and
  Electron-era Test Plan)
  and
  `docs/superpowers/plans/flutter-development-plan-archive.md`
  (Phases 4.27-4.38 and 6-14).
- Updated stale cross-references so evidence-recording instructions point to
  the active step log instead of `AGENTS.md` in
  `DEVELOPMENT.md`,
  `docs/agent-verification-script.md`,
  and
  `docs/flutter-refactor-phases.md`.
- Verification for this docs-only change:
  `git diff --check` passed;
  no live references to the deleted `Next Immediate Tasks` section remain;
  runtime/E2E scenes were skipped because no application code changed.
