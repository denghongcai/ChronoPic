# AGENTS.md

## Purpose

This file is the local execution record for ChronoPic. It complements `PLAN.md` and must be updated as implementation progresses.

## Working Rules

- Keep `PLAN.md` as the stable implementation plan.
- Update this file after each meaningful implementation step.
- Record what changed, why it changed, and what remains next.
- Do not mark a step complete unless the corresponding code or verification has landed locally.
- After completing a phase or task (including each checklist item in PLAN.md), always update both `PLAN.md` and this file before considering the work done.
- After completing any `PLAN.md` phase, phase checklist item, or meaningful implementation slice, follow `docs/agent-verification-script.md` before marking the work complete. Record which scenes were run, which commands passed, and any skipped scenes with reasons.

## Current Plan Reference

- Active plan: `PLAN.md`
- Current goal: bootstrap the greenfield monorepo and implement the first usable local-first desktop loop

## Step Log

### 2026-04-18 Step 0

- Read `PRD.md` and converted it into a concrete implementation plan.
- Created `PLAN.md` to store the agreed execution plan locally.
- Created initial directory scaffolding for the desktop app and core packages.
- Next: add workspace manifests and TypeScript build configuration.

### 2026-04-18 Step 1

- Added the workspace root manifests: `package.json`, `pnpm-workspace.yaml`, base TypeScript config, and `.gitignore`.
- Added package manifests and TypeScript configs for the desktop app and all planned shared packages.
- Established the initial dependency graph so implementation can proceed package by package.
- Next: implement shared domain types, SQLite schema/repositories, filesystem services, and the indexing pipeline.

### 2026-04-18 Step 2

- Implemented the shared domain model in `packages/domain`.
- Implemented shared helpers for IDs, serialization, path normalization, and bounded concurrency.
- Implemented the SQLite schema and repository layer, including library sources, photos, metadata, semantic state, index state, and edit history.
- Implemented filesystem scanning, content hashing, EXIF extraction with fallback timestamps, thumbnail generation, the disabled AI client, and the indexer service.
- Added the application service that exposes the app-level use cases over the repository and indexer.
- Next: wire Electron main/preload, build the React renderer, and connect UI actions to IPC.

### 2026-04-18 Step 3

- Wired the Electron runtime, main process, IPC handlers, and preload bridge.
- Added the React renderer entrypoint and the main application shell.
- Added reusable UI components for library management, filtering, grid browsing, and metadata editing.
- Implemented the initial desktop UX for folder import, manual scan, browsing, filtering, tag editing, datetime editing, and rollback.
- Next: tighten scripts/configs where needed, add lightweight tests, and run the available local verification commands.

### 2026-04-18 Step 4

- Fixed ESM path handling for the Electron main process and Vite config.
- Fixed the production renderer load path and ensured IPC handlers are registered only once for the app lifecycle.
- Switched workspace package exports from source files to built `dist` outputs so runtime resolution is valid after build.
- Added lightweight root-level TypeScript tests for shared defaults and utility helpers.
- Verified the current test baseline with `node --experimental-strip-types --test tests/*.test.ts` and confirmed both tests pass.
- Attempted to verify `pnpm`, but the sandbox cannot complete Corepack package-manager setup because it needs cache writes and network access.
- Next: install workspace dependencies outside the restricted sandbox, then run full build and typecheck.

### 2026-04-18 Step 5

- Installed workspace dependencies with `pnpm install` after sandbox restrictions were lifted.
- Enabled native dependency builds for `better-sqlite3`, `sharp`, `electron`, and `esbuild`, then rebuilt the native modules.
- Fixed workspace toolchain issues around `tsc` resolution, root dev typings, package export paths, and app-level TypeScript path resolution.
- Fixed package-level compile issues in `infra-db`, `infra-fs`, `ui-components`, and the desktop app renderer/main process.
- Verified the repository with:
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
- Result: all three commands pass and the desktop renderer production bundle is emitted under `apps/desktop/dist/renderer`.
- Note: this step still used a relaxed cross-package compile setup and was superseded by the boundary refactor below.

### 2026-04-18 Step 6

- Removed workspace-wide TypeScript `paths` aliases that pointed directly at package source files.
- Restored strict package build boundaries: every package now compiles only its own `src/` directory into its own `dist/` directory.
- Added explicit project references for package build ordering while keeping each project’s compile input local to itself.
- Aligned every package `package.json` export surface to the real build output:
  `main`, `types`, `files`, and `exports` now all point to `dist/index.*` (or package-local internal files such as `infra-db/dist/schema.*`).
- Removed source-tree build artifacts that had previously leaked into `packages/*/src`.
- Removed renderer-side Vite aliases to package source files so the desktop app now consumes workspace packages through their declared package interface.
- Tightened dependency declarations by adding missing explicit dependencies discovered by the stricter package resolution model.
- Switched root verification scripts so package tests run against built package exports rather than source paths.
- Re-verified the repository with the stricter boundary model:
  `pnpm build:packages`
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
- Result: all commands pass, package dist layouts are flat and package-local, and no package build pulls other package source trees into its own output.

### 2026-04-18 Step 7

- Added first-class Electron startup scripts so the app can be launched without manually composing commands.
- Desktop package now exposes:
  `dev` for one-command development startup
  `start` for running the built Electron app
  `build:main` and `build:renderer` for split build control
- Root package now exposes:
  `desktop:dev`
  `desktop:start`
  `desktop:build`
- Verified the refactored desktop build script with:
  `pnpm --filter @chronopic/desktop build`

### 2026-04-18 Step 8

- Investigated a failed `desktop:dev` startup and confirmed the issue was an incomplete Electron package install state: the package existed but its downloaded binary and `path.txt` were missing.
- Re-ran Electron's install script locally to restore the binary under the package `dist/` directory.
- Added `scripts/ensure-electron.mjs` as a startup guard.
- Updated desktop scripts so both `dev:launch` and `start` run `ensure:electron` before invoking Electron.
- Verified the guard with:
  `pnpm --filter @chronopic/desktop run ensure:electron`

### 2026-04-18 Step 9

- Investigated the next Electron startup failure and confirmed it was a native-module ABI problem for `better-sqlite3`.
- Rebuilt `better-sqlite3` against the installed Electron runtime using `@electron/rebuild`.
- Added `scripts/ensure-native-modules.mjs` as a startup guard for Electron-native dependencies.
- Updated desktop scripts so both `dev:launch` and `start` run `ensure:native` before launching Electron.
- Added a lightweight cache marker under `apps/desktop/node_modules/.cache/chronopic` so native rebuilds are skipped when the Electron and `better-sqlite3` versions are already prepared.
- Verified the guard with:
  `pnpm --filter @chronopic/desktop run ensure:native`

### 2026-04-18 Step 10

- Investigated the renderer-side `window.chronoPic` failures and traced them to a preload load failure.
- Confirmed the preload script had been emitted as ESM and was being executed by Electron as a classic preload script.
- Split preload type definitions into `apps/desktop/preload/bridge.ts` and converted the runtime preload entry to `apps/desktop/preload/index.cts`.
- Updated the BrowserWindow preload path to consume `dist/preload/index.cjs`.
- Rebuilt and verified the desktop app so preload now emits a CJS runtime artifact and the desktop build completes successfully again.

### 2026-04-18 Step 11

- Investigated thumbnail load failures in dev mode and confirmed the renderer was trying to open local files directly from a `localhost` origin.
- Replaced renderer-side `file://` thumbnail URLs with a custom Electron protocol served by the main process.
- Registered a privileged `chronopic-asset://` scheme in the main process and restricted it to the app's thumbnail cache directory.
- Updated UI components to request thumbnails through the new protocol instead of direct local file access.
- Rebuilt and re-verified the app with:
  `pnpm typecheck`
  `pnpm build`

### 2026-04-18 Step 12

- Updated `PLAN.md` to add a dedicated UI refactor phase using `shadcn/ui`.
- Locked the new phase as a renderer-only refactor that preserves the existing IPC, domain, indexing, and editing flows.
- Recorded that the next planned work should improve visual quality and interaction design without changing core product scope.

### 2026-04-18 Step 13

- Implemented the first pass of the desktop UI refactor using Tailwind v4 and `shadcn/ui`-style component primitives.
- Added renderer-side Tailwind integration in `apps/desktop/vite.config.ts` and replaced the old stylesheet with a Tailwind-driven global theme in `apps/desktop/renderer/src/styles.css`.
- Rebuilt the renderer shell in `apps/desktop/renderer/src/App.tsx` with a new dashboard layout, hero header, status cards, and cleaner panel composition while keeping existing app behavior unchanged.
- Reworked `@chronopic/ui-components` into a shared presentational layer with reusable button, panel, input, badge, filter, grid, and detail-panel primitives built on `class-variance-authority`, `clsx`, and `tailwind-merge`.
- Added the explicit UI-layer dependencies required by the refactor:
  `@tailwindcss/vite`
  `tailwindcss`
  `class-variance-authority`
  `clsx`
  `tailwind-merge`
  `lucide-react`
- Fixed a package-boundary issue discovered during verification by declaring `lucide-react` as an explicit dependency of `@chronopic/desktop` because the renderer now imports icons directly.
- Re-verified the repository after the UI refactor with:
  `pnpm install`
  `pnpm typecheck`
  `pnpm build`
- Result: the UI refactor builds cleanly, package boundaries remain explicit, and the desktop renderer production bundle is emitted successfully with the new styling layer.

### 2026-04-18 Step 14

- Investigated a broken-looking renderer screenshot after the UI refactor and traced it to incomplete Tailwind class extraction across package boundaries.
- Confirmed the renderer shell styles were present while many `@chronopic/ui-components` utilities were missing, which matched a bad `@source` path in `apps/desktop/renderer/src/styles.css`.
- Fixed the Tailwind v4 source registration from `../../../packages/ui-components/src` to `../../../../packages/ui-components/src` so the renderer build scans the shared package source tree correctly.
- Rebuilt the app with:
  `pnpm build`
- Result: the renderer CSS bundle now includes the shared component styles again, and the UI should render with the intended spacing, sizing, and component chrome.

### 2026-04-18 Step 15

- Reviewed the current thumbnail-click behavior and identified a product-level interaction gap: the grid supports selection, but it does not yet provide a strong "open asset" viewing mode.
- Updated `PLAN.md` to add a dedicated `Detail and Gallery Viewing Phase`.
- Defined the next UX phase around two explicit modes:
  `detail view` for large-preview plus metadata/editing,
  and `gallery view` for immersive browsing with reduced chrome.
- Locked the intended interaction model in the plan:
  single click remains lightweight selection,
  double click or Enter opens focused viewing,
  arrow keys navigate adjacent assets,
  and Esc exits detail/gallery mode.
- Captured the design direction using established product patterns from Apple Photos, Google Photos, and Adobe Lightroom so the next implementation step is guided by a concrete interaction model instead of generic UI polish.

### 2026-04-18 Step 16

- Implemented the first pass of the `Detail and Gallery Viewing Phase`.
- Extended the shared UI package with explicit viewer concepts:
  `ViewerMode`,
  double-click activation in the media grid,
  a selection inspector with open-detail/open-gallery actions,
  a focused detail overlay with inspector and filmstrip,
  and a dark immersive gallery overlay with keyboard-friendly adjacent navigation.
- Updated `apps/desktop/renderer/src/App.tsx` to manage viewer mode state, keep selection and focused viewing separate, and wire keyboard behavior:
  `Enter` opens detail view from the current selection,
  `ArrowLeft` / `ArrowRight` move across adjacent assets while viewing,
  and `Escape` closes the focused viewer.
- Updated `apps/desktop/main/main.ts` so the custom `chronopic-asset://` protocol now supports both thumbnail access and guarded original-media access for assets inside registered library roots.
- Kept the new viewing flow on top of the existing list query and selected-record data path rather than introducing a second retrieval channel.
- Re-verified the repository after the new viewer implementation with:
  `pnpm typecheck`
  `pnpm build`
- Result: the focused detail view, immersive gallery view, keyboard navigation, and original-media loading are implemented without breaking package boundaries or the existing build pipeline.

### 2026-04-18 Step 17

- Identified a new maintainability issue after the UI and viewer phases: too much renderer and shared-UI logic is now concentrated in single files, making modification cost and method boundaries unclear.
- Updated `PLAN.md` to add a dedicated `UI Structure and Component Boundary Phase`.
- Locked the next refactor goal around file/module decomposition rather than product behavior changes.
- Defined the intended split across:
  desktop renderer page/container files,
  viewer-specific compositions,
  shared presentational components,
  and low-level UI primitives/utilities.
- Captured a key constraint for the next phase:
  this is a behavior-preserving structural refactor that must keep package exports deliberate and package boundaries strict.

### 2026-04-18 Step 18

- Implemented the first pass of the `UI Structure and Component Boundary Phase`.
- Split `@chronopic/ui-components` from one oversized implementation file into focused modules:
  `primitives`,
  media helpers/preview,
  filter toolbar,
  library sidebar,
  photo grid,
  detail panel,
  filmstrip,
  metadata grid,
  edit controls,
  viewer overlay,
  and a deliberate package `index.ts` export surface.
- Split the desktop renderer from a monolithic `App.tsx` into:
  `use-chronopic-app` for page state and IPC-backed actions,
  `use-viewer-shortcuts` for keyboard behavior,
  `dashboard-shell` for page composition,
  `status-tile` for local shell presentation,
  and a thin top-level `App.tsx` that wires the page shell and overlay together.
- Preserved the existing runtime behavior while making ownership boundaries explicit:
  renderer owns orchestration/state,
  `@chronopic/ui-components` owns shared presentation and viewer compositions.
- Kept package semantics aligned with runtime/build behavior by using intentional relative module boundaries inside `@chronopic/ui-components` and an explicit public package index.
- Re-verified the repository after the structural split with:
  `pnpm typecheck`
  `pnpm build`
- Result: the structural refactor is landed, build-valid, and the UI surface is now organized into clearer modules with lower modification cost.

### 2026-04-18 Step 19

- Performed a follow-up viewer ergonomics pass after the structural split.
- Improved keyboard behavior in the renderer shortcut layer:
  `G` now opens or switches to gallery view,
  `D` switches to detail view while focused,
  `Esc` closes the viewer,
  and arrow navigation remains available during focused viewing.
- Improved focused-view affordances in `@chronopic/ui-components`:
  navigation buttons now reflect edge availability,
  overlays can be dismissed by clicking the backdrop,
  and the viewer surfaces now include explicit shortcut hints.
- Added a low-friction mode-switch gesture on the media surface:
  double-clicking media in detail view enters gallery view,
  and double-clicking media in gallery view returns to detail view.
- Re-verified the repository after the viewer polish with:
  `pnpm typecheck`
  `pnpm build`
- Result: focused viewing remains build-valid while offering clearer exit paths, better mode transitions, and more discoverable keyboard behavior.

### 2026-04-18 Step 20

- Reviewed the current UI layer and confirmed that the project is still using custom Tailwind primitives rather than actual `shadcn/ui` interaction components.
- Updated `PLAN.md` to add a dedicated `Real shadcn/ui Component Adoption Phase`.
- Locked this phase as a genuine component-stack migration rather than a visual cleanup task.
- Set the first migration targets to the most obvious gaps:
  `Select` controls in the filter toolbar,
  and viewer overlays moving toward dialog-style primitives instead of custom full-screen wrappers.
- Captured an explicit constraint for the next work:
  adopt only the minimal Radix-backed component set needed for current product surfaces, and keep those dependencies confined to the UI package layer.

### 2026-04-18 Step 21

- Implemented the first pass of the `Real shadcn/ui Component Adoption Phase`.
- Added the minimal Radix dependency set needed for current product surfaces inside `@chronopic/ui-components`:
  `@radix-ui/react-select`
  `@radix-ui/react-dialog`
- Introduced real `shadcn/ui`-style component modules backed by Radix primitives:
  `select.tsx`
  `dialog.tsx`
- Migrated the filter toolbar away from raw DOM `<select>` controls onto the new Radix-backed `Select` component set.
- Migrated the focused viewer overlays away from ad hoc fixed wrappers onto Radix-backed dialog primitives while preserving the existing detail/gallery layout and keyboard flow.
- Kept the migration deliberately narrow:
  only the interaction families currently in use were moved,
  while the broader UI package structure and page behavior remained intact.
- Re-verified the repository after the real component adoption pass with:
  `pnpm install`
  `pnpm typecheck`
  `pnpm build`
- Result: the project now uses genuine Radix-backed interaction primitives for `Select` and viewer dialogs instead of pure lookalike wrappers, and the build remains green.

### 2026-04-18 Step 22

- Tightened the `Real shadcn/ui Component Adoption Phase` further by migrating the shared base controls away from the previous catch-all custom primitives module.
- Added focused component files for the core `shadcn`-style base layer:
  `button.tsx`
  `input.tsx`
  `textarea.tsx`
  `badge.tsx`
  `label.tsx`
  `panel.tsx`
- Added the additional minimal Radix dependencies needed for those components:
  `@radix-ui/react-slot`
  `@radix-ui/react-label`
- Updated the shared UI package so feature modules now consume the new base components instead of the old monolithic primitives file.
- This means key surfaces such as the filter toolbar, edit controls, filmstrip, grid cards, detail panel, and viewer overlay are now composed through the new component files rather than directly relying on raw scattered element implementations.
- Re-verified the repository after the base-component migration with:
  `pnpm install`
  `pnpm typecheck`
  `pnpm build`
- Result: the UI layer is now materially closer to a real `shadcn` component model, with shared controls exposed as dedicated components and the build remaining green.

### 2026-04-18 Step 23

- Added the `Home Page Layout Restructure Phase` (Phase 4.5) to `PLAN.md` to capture the next refactor direction.
- Created new UI components for the restructured home page:
  `avatar.tsx`, `search-input.tsx`, `header.tsx`, `sidebar.tsx`, `recent-memories.tsx`, `gallery-section.tsx`, `photo-card.tsx`, `home-stats.tsx`, `library-dialog.tsx`, `icon-button.tsx`, `filmstrip-item.tsx`, `page-view.tsx`
- Added new Radix-backed components:
  `tooltip.tsx` (`@radix-ui/react-tooltip`)
  `dropdown-menu.tsx` (`@radix-ui/react-dropdown-menu`)
  `tabs.tsx` (`@radix-ui/react-tabs`)
- Extracted reusable card/thumbnail components from existing surfaces:
  `PhotoCard` extracted from `photo-grid`
  `FilmstripItem` extracted from `filmstrip`
  `IconButton` extracted from `photo-viewer-overlay`
- Wired the new layout into the renderer by replacing `DashboardShell` with `PhotoHome` in `App.tsx`.
- `PhotoHome` uses an internal `PageView` context to switch between home and library-settings views within the main content area — no dialog for library management.
- Header now has: logo (left), search + notification bell + user avatar (right-aligned).
- Library Settings accessible via header dropdown or sidebar item; switches main content to the settings page.
- Restored the full library management panel (stats, Add Folder, Scan, registered sources) on the library settings page.
- Removed the now-obsolete `HomeStats` hero section from the home page.
- Re-verified with:
  `pnpm typecheck`
  `pnpm build`
- Result: the restructured home page layout is implemented and the build is green.

### 2026-04-18 Step 24

- Implemented Phase 4.6 (Favorite and Memory) as planned.
- Added `favorite: boolean` to `Photo` domain, `favorite?: boolean` and `memoryId?: string` to `PhotoFilter`.
- Added `Memory` and `MemoryPhoto` domain interfaces; updated SQLite schema with `memories` and `memory_photos` tables.
- Added database migration so existing app databases automatically get the `favorite` column and new memory tables on next launch.
- Updated repository layer: `mapPhotoRow` now maps `favorite`, `listPhotos` supports `favorite`/`memoryId` filters, added memory CRUD methods.
- Preserved `favorite` in `upsertPhotoRecord` so re-indexing does not overwrite existing values.
- Added `updatePhotoFavorite` to database, application, and IPC layers; wired `toggleFavorite` in the renderer hook.
- Simplified `Sidebar` to only Library (All Photos, Favorites) and Memories sections — removed Albums/Collections placeholders.
- Added `memories` state, `handleCreateMemory`, `handleDeleteMemory`, `handleToggleFavorite` to `useChronoPicApp`.
- Updated `PhotoHomeProps` with `memories`, `onSelectMemory`, `onCreateMemory`, `onToggleFavorite`; wired through `App.tsx`.
- Added Favorites toggle to `FilterToolbar` backed by `filter.favorite`.
- Updated `PhotoCard` with a functional heart button (filled amber when favorited) and `onToggleFavorite` prop.
- Updated `GallerySection` to thread `onToggleFavorite` through to `PhotoCard`.
- Fixed `exactOptionalPropertyTypes` TypeScript issue by spreading `onToggleFavorite` conditionally in `GallerySection`.
- Re-verified with:
  `pnpm typecheck`
  `pnpm build`
- Result: all commands pass, favorite toggle and memory sidebar are functional.

### 2026-04-18 Step 25

- Implemented `CreateMemoryDialog` for naming new memories.
- Added `CreateMemoryDialog` component backed by Radix `Dialog` primitive with title, description, name input, and confirm/cancel buttons.
- Exported `DialogTitle` and `DialogDescription` from `dialog.tsx` (missing Radix re-exports).
- `PhotoHome` now manages dialog open state internally; `onCreateMemory` prop replaced with `onConfirmCreateMemory(name: string)`.
- Sidebar "Create Memory" button opens the dialog; confirmation calls `onConfirmCreateMemory` with the trimmed name.
- `App.tsx` updated to pass `onConfirmCreateMemory={app.handleCreateMemory}`.
- Re-verified with:
  `pnpm typecheck`
  `pnpm build`
- Result: all commands pass, dialog integrated into the home page layout.

### 2026-04-18 Step 26

- Designed and implemented Playwright E2E smoke test suite at `tests/e2e/smoke.spec.ts`.
- Set up `tests/e2e/playwright.config.ts` and installed `@playwright/test` as root dev dependency.
- Tests verify: app shell loads, sidebar (Library/Memories sections), header search, CreateMemoryDialog open/close/confirm, gallery section.
- All 6 tests pass. Verified against `pnpm desktop:dev` running on `http://localhost:5173`.
- Known limitation documented: `window.chronoPic` IPC errors are expected when production-built renderer loads outside Electron preload context — filtered in test assertions, not app defects.
- Updated PLAN.md with E2E test plan section.

### 2026-04-18 Step 27

- Audited Phase 5 (Editing and History) implementation: confirmed all components are wired end-to-end.
- Phase 5 is already fully implemented: `EditHistory` domain, `edit_history` SQLite table, `recordTagEdit`/`recordDatetimeEdit` write to history, `rollbackLatestEdit` reverses latest change, IPC handlers (`photos:updateTags`, `photos:updateDatetime`, `photos:rollback`), renderer hook (`handleSaveTags`, `handleSaveDatetime`, `handleRollback`), and `EditControls` component in viewer overlay.
- Attempted E2E test for edit/rollback flow: found that `window.chronoPic` IPC is provided by Electron preload and requires a live database connection — not mockable in HTTP-rendered smoke test environment.
- Marked Phase 5 as complete in PLAN.md. Full edit/rollback E2E requires integration test setup with real database (documented as known limitation).

### 2026-04-18 Step 28

- Phase 5 UX polish: replaced plain textarea tag input with chip-based `TagInput` component (removable chips, type-to-add, Enter/comma to commit).
- Added caption (name) field: extended domain `EditHistory.fieldName` with `"caption"`, added `updatePhotoCaption` to db/app/IPC/preload layers.
- Changed `draftTags` from comma-separated `string` to `string[]` to match TagInput API directly.
- Added `draftCaption` and `handleSaveCaption` to renderer hook; `EditControls` now shows Name input, TagInput, and Datetime controls.
- Deleted unused `dashboard-shell.tsx` (superseded by `PhotoHome`).
- All 6 E2E tests still pass. `pnpm typecheck` and `pnpm build` pass.

### 2026-04-18 Step 29

- Audited the latest home-page and memory/favorites implementation against `PLAN.md` and found a few state-model gaps after the recent layout refactor.
- Fixed sidebar navigation so `activeItem` now reflects the real app state instead of a mostly hard-coded `"all"`/`"settings"` split:
  `all`,
  `favorites`,
  selected `memoryId`,
  and `library-settings` now resolve correctly.
- Added a real `Library Settings` entry to the sidebar so the settings page is reachable from both the header dropdown and the sidebar, matching the plan.
- Wired sidebar actions to the real filter/page model:
  selecting Favorites clears `memoryId` and enables `favorite`,
  selecting All Photos clears both `favorite` and `memoryId`,
  selecting a memory switches back to the home view and applies that memory filter.
- Finished the `GallerySection` composition by restoring the `FilterToolbar` inside the section instead of leaving `filter` / `onFilterChange` as effectively unused props.
- Added `test-results` to `.gitignore` to keep Playwright artifacts out of the working tree.
- Re-verified the repository after the navigation/layout state cleanup with:
  `pnpm typecheck`
  `pnpm build`
- Result: the home-page navigation model is now more consistent with the plan, the gallery section owns its filter UI again, and the repository remains build-clean.

### 2026-04-18 Step 30

- Re-reviewed the latest memory implementation from a product perspective and confirmed that memory currently behaves more like a scoped photo filter than a first-class product object.
- Updated `PLAN.md` to add a dedicated `Memory Productization Phase`.
- Locked the next phase around turning memory into a real content surface with:
  memory cards,
  a memories list page,
  a memory detail page,
  cover/title/description metadata,
  and photo-management actions inside a memory.
- Captured the next implementation direction clearly:
  stop treating memory browsing as only a gallery filter,
  and instead split memory list navigation from memory-detail photo browsing.

### 2026-04-18 Step 31

- Implemented the first pass of the `Memory Productization Phase`.
- Expanded the memory data model and persistence layer so memories now carry richer product-facing summary data:
  `coverPhotoId`,
  derived `coverThumbnailPath`,
  and `photoCount`.
- Added memory metadata read/update support through the full desktop stack:
  database methods,
  application service methods,
  IPC handlers,
  preload bridge methods,
  and renderer hook support for `selectedMemory` and `handleUpdateMemory`.
- Reworked the desktop page model so memories are no longer only a gallery filter:
  `PageView` now includes
  `memories`
  and
  `memory-detail`,
  the sidebar has a dedicated `Memories` entry,
  the home surface shows actual recent memory cards,
  and selecting a memory opens a dedicated detail page instead of just reusing the gallery shell.
- Added the new memory UI surfaces:
  `MemoryCard`,
  `MemoryListSection`,
  `MemoryDetailPage`,
  and a shared memory-description helper.
- Implemented memory description editing with `BlockNote` in `MemoryDescriptionEditor`, and added the required renderer-side BlockNote stylesheet import.
- Declared the BlockNote packages explicitly where they are consumed so build-time CSS resolution matches runtime package semantics:
  `@chronopic/ui-components`
  and
  `@chronopic/desktop`
  now both declare the required BlockNote dependencies.
- Re-verified the repository after the new memory surfaces landed with:
  `pnpm typecheck`
  `pnpm build`
- Result: the memory experience now has a real list/detail split and BlockNote-backed description editing, while the workspace remains build-valid.

### 2026-04-18 Step 32

- Performed a focused UX correction pass on the new memory detail experience after runtime review.
- Changed memory description from always-inline editing to a read-first interaction model:
  memory detail now shows a display card by default,
  and clicking `Edit Description` or the description surface opens a dedicated modal editor backed by `BlockNote`.
- Reduced the delete affordance from a prominent full-width button to a compact icon action in the memory-detail header so destructive UI no longer dominates the page.
- Added the first explicit `Add to Memory` workflow so memory management is no longer hidden in the data model:
  gallery photo cards now expose an `Add to Memory` menu,
  and the focused viewer inspector / detail viewer also exposes the same action.
- Added removal inside memory detail so the current memory lifecycle is at least minimally closed:
  photo cards inside a memory now expose a `Remove from Memory` action.
- Wired the new memory actions through the renderer hook with:
  `handleAddPhotoToMemory`
  and
  `handleRemovePhotoFromMemory`,
  including memory-list refreshes and filtered-photo refreshes when the active memory is affected.
- Re-verified the repository after the memory UX/action pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: memory detail now reads more like a product page, destructive UI is less noisy, and the app finally has visible add/remove memory operations in the primary browsing flows.

### 2026-04-19 Step 33

- Fixed a nested-scroll issue in the home gallery flow by removing the inner vertical scroll container from `GallerySection`; the page now uses the main content area as the single scroll owner.
- Continued the memory lifecycle implementation beyond add/remove:
  memory detail now supports renaming the memory,
  selecting a photo inside the memory and promoting it to the memory cover,
  and keeping cover state consistent when the current cover photo is removed from that memory.
- Added a dedicated memory-actions panel to the memory detail page so cover management is explicit instead of hidden behind card hover affordances.
- Added a lightweight transient status banner in the main content area and an auto-reset behavior in the renderer hook so add/remove/update actions produce visible feedback instead of silently mutating state.
- Re-verified the repository after the scroll and memory-management pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: scrolling is simpler, memory detail has a clearer management model, and the user now gets immediate feedback for memory actions while the build remains green.

### 2026-04-19 Step 34

- Simplified the focused photo viewer memory action so detail view now keeps only a single `+` trigger in the preview-header action cluster; the duplicate inspector-side `Add to Memory` entry was removed.
- Added a real `photo -> memories` query path through the stack:
  database,
  application service,
  IPC,
  preload bridge,
  and renderer hook now support listing which memories currently contain the selected photo.
- Used that new relation in the inspector metadata area so focused viewing can show the memories the current photo belongs to, including an explicit marker when the photo is the cover of one of those memories.
- Improved memory-card legibility in list views by surfacing whether a memory is using a custom cover image.
- Re-verified the repository after the viewer/memory-membership pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the viewer has a cleaner action surface, and the app now exposes memory membership as an explicit user-facing concept instead of a hidden internal relation.

### 2026-04-19 Step 35

- Implemented the first real batch-add workflow for memories on the gallery surface.
- Added explicit batch-selection state in the renderer hook with:
  `selectedPhotoIds`,
  selection toggling,
  selection clearing,
  and automatic pruning when the filtered photo result set changes.
- Extended photo cards with a dedicated batch-select affordance so multi-select does not depend on keyboard modifiers or replace the primary single-photo selection model.
- Added a batch action bar to `GallerySection` which appears when one or more photos are batch-selected.
- Wired that action bar to a bulk memory assignment flow using the existing memory menu pattern:
  selected photos can now be added to a memory in one operation,
  the batch selection clears after completion,
  and feedback reflects full or partial completion counts.
- Re-verified the repository after the batch-memory implementation with:
  `pnpm typecheck`
  `pnpm build`
- Result: the app now supports multi-photo selection and one-shot memory assignment from the gallery without breaking the existing single-photo browsing and viewer flows.

### 2026-04-19 Step 36

- Refined the batch-selection interaction after runtime feedback showed the small card-corner affordance was too easy to miss or conflict with other pointer targets.
- Promoted batch selection into an explicit gallery-level `Select` mode so multi-select now has a stable primary entry point, while the card-corner control remains only as an in-mode assist.
- Tightened the renderer status-feedback model from a plain string into a structured `status` object with:
  `idle`,
  `info`,
  `success`,
  `warn`,
  and `error` kinds.
- Updated the main content feedback banner so action results now render with severity-appropriate tones instead of a single generic warning treatment.
- Added defensive error handling around the main memory-management and library-management actions in the renderer hook so failures produce visible feedback instead of silently failing.
- Removed the unused top-right user/avatar entry from the header, leaving search plus the notification affordance only.
- Re-verified the repository after the interaction/feedback cleanup with:
  `pnpm typecheck`
  `pnpm build`
- Result: batch selection now has a clearer primary interaction model, action feedback is more trustworthy, and the header no longer exposes a dead user affordance.

### 2026-04-19 Step 37

- Extended the memory lifecycle flow with a real batch-remove path inside `MemoryDetailPage` instead of forcing one-by-one removal through per-card hover actions only.
- Added an explicit `Select` mode to the memory-detail photo grid so multi-select in memories now matches the gallery interaction model.
- Added a memory-detail batch action bar with:
  selected-count feedback,
  `Remove Selected`,
  and `Clear Selection`.
- Added renderer-side `handleRemoveSelectionFromMemory` with the same partial-failure accounting model used by batch add-to-memory:
  empty selection warns,
  partial completion returns a warning,
  full completion returns success,
  and the active photo/memory data is refreshed afterward.
- Cleared stale batch selection when switching primary browsing contexts so selection state from one surface does not leak into another page unexpectedly.
- Re-verified the repository after the memory batch-removal pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: memories now support both batch add and batch remove flows with a clearer, symmetric selection model across gallery and memory-detail surfaces.

### 2026-04-19 Step 38

- Continued the `Memory Lifecycle Polish` work by making action feedback more object-aware instead of using generic success/warn copy.
- Memory add/remove flows now resolve the target memory name and distinguish between:
  successful changes,
  no-op cases such as "already there" / "already absent",
  and partial failures in batch operations.
- Updated batch add/remove messaging so counts for added/removed, already-present/already-absent, and failed items are surfaced explicitly in the transient status banner.
- Tightened the create-memory flow so the creation dialog stays open when creation fails instead of closing immediately and forcing the user to reopen it.
- Added explicit confirmation dialogs in `MemoryDetailPage` for:
  deleting the memory,
  removing the current batch selection from the memory,
  and removing a single photo from the memory.
- Updated async save flows in memory detail so rename/description/delete/remove confirmations only close after the underlying action succeeds.
- Re-verified the repository after the memory-feedback and confirmation pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: memory actions now communicate what actually happened, destructive operations have confirmation affordances, and failed create/save flows keep the user in context for retry.

### 2026-04-19 Step 39

- Continued the remaining polish by improving empty states and memory-relation visibility across the main product surfaces.
- `RecentMemories` no longer disappears when empty:
  it now shows a dedicated empty state with a direct `Create First Memory` CTA so the home page does not collapse into an unexplained gap.
- `MemoryListSection` now also exposes a create CTA in its empty state so the dedicated memories page has a complete zero-state loop.
- `GallerySection` now renders contextual scope messaging for:
  active memory browsing,
  favorites,
  search,
  and structured filter states,
  instead of always presenting the shelf as a generic unscoped gallery.
- Added a selected-photo relation banner inside the gallery shelf so the currently selected asset now surfaces which memories it belongs to, including whether it is serving as a cover image.
- Improved gallery empty-state copy so it responds to the active context:
  generic filtered results,
  search,
  favorites,
  or a specific memory scope.
- Added compact memory-membership badges to gallery-mode viewing so the immersive viewer still communicates memory relationships without forcing a switch back to the full inspector.
- Re-verified the repository after the relation-visibility and zero-state pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the app now better explains where the user is, why a shelf is empty, and how the current photo relates to memory objects across home, memories, gallery, and viewer surfaces.

### 2026-04-19 Step 40

- Added new product-planning phases to `PLAN.md` for GPS-driven browsing and browse-mode expansion.
- Captured a dedicated `Geospatial Browse and Map View Phase` covering:
  GPS-based place aggregation,
  Gaode / AMap JavaScript API 2.0 web-map rendering,
  viewport-aware photo browsing,
  and coordinate-normalization boundaries between shared logic and renderer-only map code.
- Captured a dedicated `Timeline View and Multi-Browse Shell Phase` covering:
  explicit browse-mode switching between waterfall, map, and timeline,
  shared browse-state preservation,
  and time-bucketed library exploration.
- Kept this step planning-only: no code paths were changed yet, and no execution step is marked complete beyond local plan updates.

### 2026-04-19 Step 41

- Refined the new geospatial and browse-expansion phases into implementation-ready task breakdowns inside `PLAN.md`.
- Broke the `Geospatial Browse and Map View Phase` into:
  geospatial domain/query foundation,
  renderer browse-shell changes,
  AMap / Gaode JS API 2.0 integration,
  map-to-photo interaction wiring,
  and map-specific zero/error states.
- Broke the `Timeline View and Multi-Browse Shell Phase` into:
  shared browse-shell state,
  timeline projection/grouping,
  timeline renderer implementation,
  cross-mode transition rules,
  and browse-mode UX completion.
- Recorded the intended architecture boundary explicitly:
  GPS/place aggregation logic belongs in shared/app layers,
  while Gaode map lifecycle and rendering remain renderer-only.
- Kept this step planning-only as well; no implementation code has landed yet for map/timeline browse.

### 2026-04-19 Step 42

- Added the recommended delivery order explicitly to both `PLAN.md` and the local execution record so future implementation does not drift or introduce contradictory sequencing.
- Locked the intended implementation order as:
  1. shared browse shell / `BrowseMode`,
  2. geospatial foundation and place aggregation,
  3. renderer-side Gaode map integration,
  4. timeline view.
- Captured the reasoning behind that order:
  map and timeline should plug into one stable browse-state model,
  and the AMap SDK should consume an already-defined query layer rather than shaping the business/data model itself.
- This step is still planning-only; the next implementation step should begin with browse-shell state and UI wiring rather than map SDK work.

### 2026-04-19 Step 43

- Started implementation of the new browse stack with the first concrete step: the shared browse shell and explicit `BrowseMode`.
- Added `BrowseMode` to `@chronopic/domain` and updated the home/library browse surface so it now switches explicitly among:
  `waterfall`,
  `map`,
  and `timeline`.
- Added a reusable `BrowseModeSwitcher` to the shared UI layer so browse-mode switching is now part of the product surface instead of only a plan concept.
- Added a `BrowseModePlaceholder` surface so non-waterfall modes have a stable container and state contract before their full renderers are implemented.
- Kept map/timeline rendering out of `@chronopic/ui-components` by introducing renderer-owned browse slots in `PhotoHome`, preserving the intended boundary between shared UI primitives and renderer-only map logic.
- Re-verified the repository after the browse-shell implementation with:
  `pnpm typecheck`
  `pnpm build`
- Result: the product now has a real multi-browse shell in code, with waterfall still functioning and map/timeline able to plug into a stable state model.

### 2026-04-19 Step 44

- Implemented the first geospatial foundation pass behind the new browse shell.
- Added shared geospatial browse types to `@chronopic/domain`:
  `GeoBounds`,
  `PlaceGroup`,
  and `PlaceGroupQuery`.
- Added database/application/IPC/preload support for:
  counting mappable photos in the current scope,
  and grouping GPS-bearing photos into local place buckets.
- Wired those geospatial queries into the renderer hook so browse-mode surfaces now receive real foundation data rather than inferring everything from the currently paged photo list.
- Added a renderer-only `MapBrowseSurface` and AMap loader utility:
  the map surface is now renderer-owned,
  consumes shared geospatial query results,
  renders a real Gaode map when `VITE_AMAP_API_KEY` is available,
  and falls back to clear zero/config/error states when GPS data or API configuration is missing.
- Added a place-group side list beside the map so the current geospatial foundation already participates in selection and the existing focused viewer flow, even before viewport-driven queries are implemented.
- Re-verified the repository after the browse-shell + geospatial-foundation + first map-surface pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the codebase now has a real browse shell, a shared geospatial query layer, and the first renderer-owned Gaode map surface wired to current product state.

### 2026-04-19 Step 45

- Continued the map phase by turning the first Gaode surface from a static map shell into a viewport-aware browse surface.
- Extended the lightweight AMap type layer with bounds and event capabilities so the renderer can react to map movement without leaking SDK types into shared packages.
- Updated `MapBrowseSurface` so map pan/zoom now refreshes the active place groups based on the current viewport bounds through the shared geospatial query layer.
- Added selection-aware marker styling and viewport-scoped group counts so the map surface reflects current selection/context more clearly.
- Kept the right-hand place list synchronized to the current viewport result rather than always showing the full initial place-group set.
- Re-verified the repository after the viewport-aware map-browse pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: map browse now behaves more like a real geographic exploration surface instead of a one-time rendering of all known place groups.

### 2026-04-19 Step 46

- Implemented the first `Timeline View` pass on top of the shared multi-browse shell instead of extending the old waterfall-only browse model.
- Added shared timeline browse types to `@chronopic/domain`:
  `TimelineGranularity`,
  `TimelineGroup`,
  and `TimelineGroupQuery`.
- Added timeline grouping to the application layer by projecting the current filtered photo scope into deterministic time buckets derived from persisted `metadata.datetime`.
- Exposed timeline grouping through the desktop IPC and preload bridge with:
  `photos:listTimelineGroups`.
- Wired the renderer hook to fetch and hold timeline-group data alongside photos/place groups so timeline mode is driven by a shared query path rather than local ad hoc grouping only.
- Added a renderer-owned `TimelineBrowseSurface` that:
  renders grouped monthly sections,
  reuses the existing photo-card interactions,
  supports explicit batch-selection mode,
  and keeps add-to-memory, favorite, and focused-viewer flows aligned with waterfall mode.
- Updated the local plan record so Phase 4.9 now reflects that the first timeline renderer is landed and remaining work is polish-oriented rather than foundational.
- Re-verified the repository after the timeline implementation with:
  `pnpm typecheck`
  `pnpm build`
- Result: browse is now materially split across waterfall, map, and timeline, with all three modes sharing the same underlying result scope and viewer pipeline.

### 2026-04-19 Step 47

- Performed the first multi-browse UX polish pass after the initial timeline landing.
- Added renderer-side timeline granularity state so timeline grouping is no longer hard-coded to month buckets:
  the current implementation now supports
  `year`,
  `month`,
  and
  `day`
  grouping through the existing shared timeline query contract.
- Updated the timeline browse surface to expose explicit granularity controls and a scope-summary bar that explains:
  how many dated photos are visible in the current result scope,
  how many timeline groups are shown,
  and how many photos are currently excluded because they lack usable datetime metadata.
- Tightened multi-browse transitions in `PhotoHome` so switching among waterfall/map/timeline now clears stale batch-selection state instead of carrying selection-mode artifacts across surfaces.
- Re-verified the repository after the browse-polish pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the multi-browse shell now behaves more coherently during mode switches, and timeline mode exposes clearer temporal controls and scope context instead of only rendering grouped cards.

### 2026-04-19 Step 48

- Continued the runtime browse-polish pass with a focus on map-mode continuity rather than adding another new browse surface.
- Added renderer-local map viewport state so the Gaode map now preserves its approximate center/zoom when the user switches away from map mode and later returns.
- Kept that viewport state renderer-only on purpose:
  no map SDK lifecycle or viewport model was pushed into shared packages or the application service layer.
- Updated `MapBrowseSurface` so viewport changes now also publish current center/zoom back into the renderer hook while still refreshing place groups from the shared geospatial query layer.
- Improved map/list selection synchronization:
  when the currently selected photo corresponds to a visible place group,
  the right-hand place card list now scrolls that group into view,
  and the map attempts to re-center on the selected place group instead of leaving the active selection off-screen.
- Re-verified the repository after the map-continuity polish with:
  `pnpm typecheck`
  `pnpm build`
- Result: browse-mode switching now feels less lossy for geographic exploration, and map-mode selection is more tightly synchronized between markers, place cards, and the shared photo/viewer state.

### 2026-04-19 Step 49

- Continued browse runtime polish by aligning contextual affordances across waterfall, map, and timeline instead of leaving map/timeline as thinner secondary views.
- Added selected-photo context surfaces to both `MapBrowseSurface` and `TimelineBrowseSurface`:
  the current selection is now called out explicitly,
  can be opened directly into detail view,
  and shows the same memory-membership / cover-role signals that waterfall browse already exposed.
- Added clearer browse-scope explanation to non-waterfall modes:
  map mode now explains when it is rendering a filtered/search/favorites/memory scope,
  and timeline mode now surfaces that same scope context instead of only showing grouped cards.
- Kept these changes renderer-owned and presentation-focused:
  no additional data model expansion was required,
  and the shared app/query layer remained unchanged except for already-landed browse state.
- Re-verified the repository after the cross-mode context-alignment pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the three browse modes now feel more like one coherent browsing product surface with different lenses, rather than one primary mode plus two detached alternates.

### 2026-04-19 Step 50

- Added a dedicated redesign-planning step before further UI implementation work.
- Created `DESIGN.md` as the design-direction document for the next UI/UX phase.
- Documented the redesign around a collection-first, editorial product direction informed by the provided reference screenshots:
  quiet sidebar,
  premium featured-memory cards,
  cleaner browse shell,
  and stronger alignment across waterfall/map/timeline.
- Updated `PLAN.md` to add a new `4.10 UI/UX Redesign Phase`.
- Recorded the redesign phase as a constrained UI/UX effort with explicit technical guardrails:
  preserve package boundaries,
  keep renderer-only composition and map lifecycle out of shared UI packages,
  and evolve the existing `shadcn` component layer rather than replacing the app architecture.
- This step is planning/documentation only:
  no UI implementation has landed yet for the redesign itself,
  and no execution step should treat the redesign phase as started beyond the new design/plan documents.

### 2026-04-19 Step 51

- Started the first implementation pass of the new `4.10 UI/UX Redesign Phase`.
- Kept this pass intentionally focused on shell-level composition and visual hierarchy rather than changing product behavior.
- Updated the top chrome so `Header` is now quieter and less dashboard-like.
- Reworked `Sidebar` toward a calmer navigation rail:
  stronger product identity,
  quieter sectioning,
  lighter nav-item styling,
  and a low-emphasis create-memory action near the bottom.
- Reworked `RecentMemories` and `MemoryCard` so the top of the home screen now behaves more like a highlights strip:
  larger featured cards,
  stronger image-led presentation,
  and a dedicated create-new tile instead of a small utility button.
- Started restructuring the home browse shell in `PhotoHome`:
  `Browse Library` now has a clearer editorial section heading,
  integrated search placement,
  and a lighter browse-mode switch presentation.
- Re-verified the repository after this first redesign pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the redesign phase has now started in code, and the home/library shell is beginning to move toward the new visual direction without changing business logic or package boundaries.

### 2026-04-19 Step 52

- Performed a small redesign-correction pass after reviewing wording and chrome decisions.
- Removed the top header bar from the main home shell so the layout now relies on the sidebar and main content regions instead of splitting attention with a thin top strip.
- Moved the notification affordance into the sidebar brand area so global chrome is consolidated into a single navigation rail.
- Corrected product naming in the sidebar brand block from the wrong placeholder label to the actual product name:
  `ChronoPic`.
- Standardized redesign terminology so collection-facing copy now uses `Memory` / `Memories` instead of `Collection` / `Collections` in the redesigned home-shell surfaces.
- Re-verified the repository after the shell/wording correction with:
  `pnpm typecheck`
  `pnpm build`
- Result: the redesign direction is now more internally consistent, with quieter global chrome and corrected product terminology.

### 2026-04-19 Step 53

- Continued the redesign from shell-level framing into the browse surfaces themselves.
- Reworked `FilterToolbar` so it now reads as a lighter refinement module instead of a nested dashboard panel with a second large title stack.
- Reworked `GallerySection` so waterfall browse feels more like one open content canvas:
  reduced duplicate section titling,
  lighter surface framing,
  and softer treatment for scope/selection/batch context blocks.
- Softened the top framing of `MapBrowseSurface` and `TimelineBrowseSurface` so all three browse modes now speak a more consistent visual language instead of each behaving like a separate heavy panel.
- Kept this pass UI-only:
  no query/data-flow behavior changed,
  and no package-boundary widening was introduced.
- Re-verified the repository after the browse-surface redesign pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the redesign is now moving beyond shell chrome and into the actual browsing canvases, with waterfall/map/timeline visually converging toward the same product language.

### 2026-04-19 Step 54

- Adjusted the browse-shell control model to better match the approved redesign direction and the provided reference screenshot.
- Made `Browse Library` the single visible heading for waterfall browse by removing the duplicate inner gallery-title treatment.
- Moved browse controls into one lighter shared control row:
  browse-mode switch on the left,
  search on the right,
  explicit `Select` action just left of `Filter`,
  and `Filter` itself acting as a disclosure toggle rather than an always-open block.
- Changed the filter panel to default-collapsed behavior.
- Removed the duplicate search field from the expanded filter surface so the shell now has one primary search entry instead of two competing search controls.
- Reworked the expanded filter surface so it behaves more like a lightweight refinement drawer/module than a second browse page stacked above the content.
- Re-verified the repository after the browse-control restructure with:
  `pnpm typecheck`
  `pnpm build`
- Result: the browse shell is now closer to the intended reference behavior, with lighter mode switching, a single browse heading, and collapsed filtering instead of permanent heavy filter chrome.

### 2026-04-19 Step 55

- Continued the redesign into the card layer so the product no longer feels like a gallery of small info panels under a redesigned shell.
- Reworked `PhotoCard` into a more image-first presentation:
  removed the heavy white metadata footer,
  moved identity/timestamp/media-type into the image surface,
  and kept hover actions and selection affordances intact.
- Finalized the main waterfall browse-shell corrections requested during review:
  removed the redundant outer `Browse Library` heading block,
  kept mode-switching left-aligned,
  and retained the lighter top-row control structure with collapsed filters.
- Re-verified the repository after the image-first card pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the core UX refine pass for the redesign is now effectively complete.
  Remaining work, if any, is further visual polish rather than unresolved browse-shell or interaction-structure issues.

### 2026-04-19 Step 56

- Performed a final UI-chrome interaction polish pass after runtime review exposed accidental text selection on non-editable browse surfaces.
- Marked non-editable chrome and browse-copy surfaces as non-selectable:
  sidebar/navigation,
  browse-mode switcher,
  recent-memory highlights,
  gallery shell copy,
  map/timeline surface framing,
  badges,
  labels,
  buttons,
  and photo cards now all opt into `select-none`.
- Preserved text selection where it is still semantically useful:
  form inputs and textareas explicitly retain `select-text`,
  so editing and copy workflows are not regressed by the chrome-level polish.
- Re-verified the repository after the selectability polish with:
  `pnpm typecheck`
  `pnpm build`
- Result: incidental text highlighting in the redesigned browse UI is reduced, while real text-entry surfaces remain selectable and editable.

### 2026-04-19 Step 57

- Fixed a redesign regression in the browse-mode switcher where the mode labels had lost their leading icons during the visual simplification pass.
- Restored explicit icons for all three browse modes:
  `Waterfall`,
  `Map`,
  and
  `Timeline`,
  while keeping the lighter segmented-control treatment introduced by the redesign.
- Re-verified the repository after the browse-mode icon fix with:
  `pnpm typecheck`
  `pnpm build`
- Result: the browse-mode switcher now matches the intended visual affordance again without regressing the redesigned layout or build health.

### 2026-04-19 Step 58

- Re-prioritized the post-redesign product roadmap after review of the now-landed memory, multi-browse, and redesign phases.
- Explicitly moved realtime library sync / incremental watch to the end of the near-term roadmap instead of treating it as the next implementation step.
- Updated `PLAN.md` to add and prioritize three forward-looking phases:
  `4.11 AI and Semantic Enrichment Phase`,
  `4.12 Search and Discovery Phase`,
  and
  `4.13 Realtime Library Sync and Incremental Watch Phase`.
- Locked the intended future execution order in the plan:
  first real AI/semantic enrichment,
  then broader search/discovery,
  and only after that realtime file watching/incremental sync.
- Captured the AI phase as the next expected implementation target, including:
  semantic data-model completion,
  real provider integration behind the existing `AIClient` abstraction,
  enrichment orchestration,
  and product-surface integration that preserves the distinction between generated fields and user-authored edits.
- This step is roadmap/planning only:
  no new runtime behavior has landed yet beyond the updated implementation order and phase definitions.

### 2026-04-20 Step 59

- Started the first implementation pass of `4.11 AI and Semantic Enrichment Phase`.
- Expanded the shared semantic model so AI-generated outputs are now stored separately from user-authored fields:
  `generatedLabels`,
  `generatedCaption`,
  `summary`,
  `aiProvider`,
  `aiModel`,
  `aiProcessedAt`,
  and
  `aiError`
  were added alongside the existing manual `labels` / `caption` fields.
- Updated the SQLite semantic schema and migration path to persist the new AI fields without forcing a fresh database.
- Added `updatePhotoSemanticEnrichment` in `infra-db` and `enrichPhotoSemantic` orchestration in the application layer so one photo can move through:
  `processing`,
  `completed`,
  or
  `failed`
  without overwriting manual edits.
- Replaced the permanently disabled AI implementation with a real `VercelCompatibleAIClient` inside `services-ai-pipeline`, backed by:
  `Vercel AI SDK`
  and an OpenAI-compatible provider created via `@ai-sdk/openai-compatible`.
- Added desktop runtime config for:
  `CHRONOPIC_AI_API_KEY`,
  `CHRONOPIC_AI_BASE_URL`,
  `CHRONOPIC_AI_MODEL`,
  and optional
  `CHRONOPIC_AI_PROVIDER`.
- Updated the indexer default semantic state so new records are marked `pending` when AI is configured instead of remaining permanently `disabled`.
- Wired a minimal product-facing AI action through main/preload/renderer:
  the viewer inspector now exposes `Generate AI Metadata`,
  and the metadata area now displays generated caption, summary, tags, status, model, and last AI error.
- Verified the local OpenAI-compatible test endpoint supplied by the user:
  model discovery at `http://192.168.1.39:8888/v1/models` succeeded,
  and `VercelCompatibleAIClient.analyzePhoto()` successfully returned structured output against
  `unsloth/gemma-4-E4B-it-GGUF`.
- Captured a compatibility quirk discovered during that smoke test:
  the local endpoint returns SSE-style responses even for non-streaming requests,
  so the provider implementation was updated to consume responses through `streamText()` rather than `generateText()`.
- Added unit-test coverage in line with the clarified requirement that business-logic and infra packages should have tests:
  `tests/application-ai-enrichment.test.ts`
  covers application-layer enrichment state flow and preservation of manual fields,
  and
  `tests/infra-db-semantic.test.ts`
  covers the infra semantic schema/export surface for the new AI columns.
- Re-verified the repository after the first AI-enrichment implementation pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: the first real AI enrichment slice is landed, build-valid, test-covered at business/infra level, and confirmed against the user-provided local model endpoint.

### 2026-04-20 Step 60

- Continued `4.11 AI and Semantic Enrichment Phase` past single-photo manual generation into actual queue orchestration.
- Extended `PhotoFilter` and infra query handling to understand `aiStatus`, so AI queue operations can address:
  `pending`
  and
  `failed`
  records explicitly instead of relying on renderer-local filtering only.
- Added `getSemanticQueueStats` in the database/application stack and wired it through IPC/preload so the renderer can show a real queue summary:
  `disabled`,
  `pending`,
  `processing`,
  `completed`,
  and
  `failed`.
- Added `enrichPendingSemantics(limit)` in the application layer and exposed it through main/preload as a batch queue operation.
- Updated the renderer hook and home shell so the product now surfaces an AI queue action bar when work remains:
  pending/failed/processing counts are visible,
  and the user can trigger `Enrich Pending` without opening assets one by one.
- Expanded business-layer test coverage with a new application test for batch queue processing:
  `ChronoPicAppService enrichPendingSemantics processes pending and failed photos only`.
- Re-verified the repository after the queue-orchestration pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: AI enrichment now has both per-photo and queue-level execution paths, the queue is visible in the desktop UI, and the business/infra test baseline has been extended accordingly.

### 2026-04-20 Step 61

- Continued `4.11` by making semantic enrichment more visible and controllable in the browse/search experience instead of leaving it only as a backend capability.
- Added an explicit AI status filter to the structured filter toolbar so users can narrow the library by:
  `AI Ready`,
  `Needs AI`,
  `Processing`,
  and
  `AI Failed`.
- Added a semantic-search context callout in waterfall browse so query-driven browsing now explicitly communicates that search matches:
  file path,
  manual metadata,
  and AI-generated captions, summaries, and tags.
- Added direct unit-test coverage for `services-ai-pipeline` internals by extracting and exporting a narrow `./internal` surface:
  `extractJsonObject`,
  `normalizeLabels`,
  and
  `normalizeText`
  are now covered by `tests/services-ai-pipeline.test.ts`.
- This closes the earlier gap where business-logic and infra packages needed direct unit tests:
  application,
  infra-db,
  and
  services-ai-pipeline
  now all have phase-relevant test coverage in the root suite.
- Re-verified the repository after the semantic-search visibility and AI-service test pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: AI-generated metadata is now more discoverable in the product UI, and the service-layer parsing/normalization logic has regression protection alongside the already-added application/infra tests.

### 2026-04-20 Step 62

- Continued `4.11 AI and Semantic Enrichment Phase` from photo-only enrichment into memory-level AI synthesis.
- Extended the `Memory` domain and SQLite schema with non-destructive generated AI fields:
  `generatedName`,
  `generatedDescription`,
  `generatedLabels`,
  plus memory-level AI status/provider/model/error metadata.
- Added memory-schema migration support in `infra-db` and a dedicated `updateMemorySemanticEnrichment` repository path so generated memory suggestions are persisted separately from user-authored title/description.
- Extended the `AIClient` contract with `analyzeMemory(memory, photos)` and implemented it in the Vercel-AI-backed provider as a text-only synthesis step over sampled photo semantics.
- Added `ChronoPicAppService.enrichMemorySemantic(memoryId)`:
  it gathers photos in the memory,
  records `processing/completed/failed` state,
  and preserves manual memory fields while saving generated suggestions.
- Wired the new memory-enrichment path through Electron IPC and the preload bridge via:
  `memories:enrichSemantic`
  and
  `window.chronoPic.enrichMemorySemantic(...)`.
- Added the first memory-level AI product surface in memory detail:
  users can now run `Generate AI Story`,
  review suggested title/summary/tags,
  and explicitly apply the generated title or summary without destructive overwrite.
- Expanded test coverage again in line with the business/infra requirement:
  `tests/application-ai-enrichment.test.ts`
  now covers non-destructive memory enrichment behavior,
  and
  `tests/infra-db-semantic.test.ts`
  now asserts the memory AI schema columns.
- Re-verified the repository after the memory-synthesis pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: AI enrichment now spans both photo and memory surfaces, stays non-destructive for user-authored memory metadata, and remains covered by application/infra regression tests.

### 2026-04-20 Step 63

- Filled the product gap that kept AI effectively env-only by adding an in-app AI settings flow.
- Added a new `@chronopic/infra-config` package to persist local desktop configuration in a package-bounded way instead of hardcoding all provider settings in Electron main.
- Added `AISettings` to the shared domain model and implemented `ChronoPicConfigStore` for local JSON-backed storage of:
  API key,
  base URL,
  model,
  and provider name.
- Updated Electron main/runtime so startup now reads persisted AI settings, and saving settings triggers a runtime rebuild so capability changes apply immediately without a manual app restart.
- Added new preload / IPC methods:
  `system:getAISettings`
  and
  `system:saveAISettings`.
- Extended the `Library Settings` page with an AI configuration form:
  provider,
  model,
  base URL,
  API key,
  current enabled/disabled state,
  and a save action.
- Closed a product gap after enabling AI late in the lifecycle:
  queue processing now includes previously `disabled` photos, so an existing library can be enriched after AI is configured without forcing a full re-index first.
- Added infra-package regression coverage for the new config package in:
  `tests/infra-config.test.ts`.
- Re-verified the repository after the AI-settings/configuration pass with:
  `pnpm install`
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: AI can now be enabled and configured from the desktop product surface itself, persisted locally, applied immediately at runtime, and regression-covered at the infrastructure layer.

### 2026-04-20 Step 64

- Performed a follow-up fix after runtime feedback on the new AI configuration flow.
- Hardened the `photos:enrichPendingSemantics` IPC handler so batch-enrichment responses are explicitly returned as plain serializable literals and thrown errors are normalized to clone-safe `Error(message)` values.
- Improved queue visibility by adding a dedicated `AI Queue` section to `Library Settings`, instead of relying only on the home-page queue banner.
- Updated queue wording in the home banner so previously disabled-but-now-eligible items are shown as `need AI` rather than the more confusing raw `disabled` label.
- Re-verified the repository after the IPC/queue-visibility fix with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: the batch AI queue path is safer across Electron IPC boundaries, and queue state is now visible both in the home surface and in settings.

### 2026-04-20 Step 65

- Performed a second hardening pass on the batch AI queue IPC after the first clone-safety fix still reproduced in runtime testing.
- Changed `photos:enrichPendingSemantics` so the main process no longer throws or returns structured objects across IPC for that action:
  it now always returns a JSON string payload,
  and preload performs local parse-and-throw on the renderer side.
- This intentionally bypasses Electron object/error cloning for the queue action completely while preserving the same renderer-facing API shape.
- Re-verified after the transport hardening with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: the queue action now uses the most conservative possible IPC transport path, reducing the remaining failure surface to stale dev runtime state or a different downstream refresh call.

### 2026-04-20 Step 66

- Identified the actual root cause of the persistent `An object could not be cloned` runtime error via the new debug log:
  the `Enrich Pending` / `Enrich Queue` buttons were passing the React click event object into `handleEnrichPendingSemantics(limit = 12)` instead of calling it with no arguments.
- This meant the renderer was attempting to send a DOM event through Electron IPC, which fails cloning before the main-process handler is even invoked.
- Fixed both queue-action buttons to call the handler explicitly:
  `onClick={() => void onEnrichPendingSemantics?.()}`
  instead of handing the click event through as the first argument.
- Re-verified after the click-handler fix with:
  `pnpm typecheck`
  `pnpm build`
- Result: the persistent clone error was traced to a renderer click-binding bug rather than the AI runtime, database, or IPC payload shape.

### 2026-04-20 Step 67

- Performed a small follow-up UX fix on the redesigned photo cards.
- Moved the `Double-click to open` affordance from its separate bottom floating strip into the main metadata stack so it now sits above the title instead of competing with the timestamp/media row.
- This reduces overlap/noise in the lower image overlay and matches the intended information hierarchy more closely.
- Re-verified after the card-overlay adjustment with:
  `pnpm typecheck`
  `pnpm build`
- Result: the photo-card interaction hint is better positioned within the card’s text hierarchy and the build remains green.

### 2026-04-20 Step 68

- Reworked AI queue visibility to match the intended product information architecture.
- Promoted the sidebar bell into a real notification-center entry with unread-count badge support instead of leaving it as a decorative icon.
- Added a dedicated `notifications` page in the shared page-view model and routed the bell button to that page.
- Moved AI queue status and queue action affordances out of the home-page banner and out of `Library Settings`.
- Added a dedicated `NotificationCenterPanel` that now owns:
  AI queue status,
  the queue action button,
  and the latest action/status summary for the current session.
- Kept `Library Settings` focused on configuration only by removing the queue-status block from that page.
- Re-verified after the notification-center change with:
  `pnpm typecheck`
  `pnpm build`
- Result: AI queue information now lives under the sidebar notification entry, which is closer to the intended product mental model than duplicating queue state across home and settings surfaces.

### 2026-04-20 Step 69

- Performed a follow-up polish/fix pass on the new notification-center workflow.
- Removed the duplicate `Recent Action` rendering on the notifications page by suppressing the global session-status banner when the dedicated notification page is active.
- Added startup recovery for interrupted AI jobs in `infra-db` / runtime:
  any photo or memory left in `processing` at app restart is now moved back to `pending` so the queue does not get stuck on stale in-flight state across restarts.
- Adjusted notification-center queue copy so pure in-flight state reads as currently running, while restarted/interrupted work is recoverable into the normal queue.
- Re-verified after the notification and queue-recovery pass with:
  `pnpm typecheck`
  `pnpm build`
- Result: the notifications page no longer duplicates the recent-action surface, and AI queue state is more durable across app restarts instead of leaving stale `processing` counts behind.

### 2026-04-20 Step 70

- Extended persisted desktop configuration beyond AI settings so Gaode map rendering can also be enabled from `Library Settings` instead of relying on env-only renderer configuration.
- Added `MapSettings` to the shared domain model and expanded `@chronopic/infra-config` so settings storage now persists both:
  `ai`
  and
  `map`
  sections.
- Added new desktop IPC/preload configuration calls:
  `system:getMapSettings`
  and
  `system:saveMapSettings`
  while keeping them separate from the AI runtime-rebuild path because map rendering is renderer-owned.
- Updated the renderer app hook to hydrate and save persisted map settings alongside AI settings.
- Updated the settings surface so `Library Settings` now includes a dedicated `Map Rendering` section with:
  `AMap API Key`
  and optional
  `Security JS Code`
  inputs plus explicit save behavior.
- Updated the renderer-owned AMap loader to resolve configuration from saved map settings first, with env fallback for development, and to apply `_AMapSecurityConfig` before script load when a security JS code is present.
- Updated the map browse surface so its missing-config empty state now points the user to `Library Settings` rather than only referencing `VITE_AMAP_API_KEY`.
- Expanded config-store unit coverage with a direct test for persisted/normalized map settings.
- Re-verified after the map-settings implementation with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: both AI and Gaode map configuration are now first-class desktop settings, and map browse no longer depends solely on build-time env injection.

### 2026-04-22 Step 71

- Fixed an HTML nesting/runtime warning in the map browse side list where a list-item `<button>` contained a nested shared `Button` that also rendered as `<button>`.
- Changed the inner `Open Photo` affordance to use the shared button styling with `asChild`, rendering a non-button inline element so the outer list item remains the only actual button element.
- Re-verified after the DOM-structure fix with:
  `pnpm typecheck`
  `pnpm build`
- Result: the map browse list no longer renders invalid `button > button` markup, preventing the associated hydration/runtime warning.

### 2026-04-22 Step 72

- Fixed a renderer crash in `PhotoHome` caused by reading `aiQueueStats.disabled` before queue stats were available during hydration or dev-runtime state transitions.
- Relaxed the `PhotoHome` prop shape so `aiQueueStats` can be temporarily absent and added a local empty-queue fallback used by:
  sidebar notification count
  and
  the notifications panel.
- Re-verified after the queue-state hardening with:
  `pnpm typecheck`
  `pnpm build`
- Result: the home shell no longer throws when AI queue stats are briefly undefined, and the notification surfaces degrade safely to zero counts until data arrives.

### 2026-04-22 Step 73

- Fixed the memory-description dialog crash that occurred when opening the description editor from memory detail.
- Identified the root cause as an effect in `MemoryDetailPage` depending on `onClearBatchSelection`, which is an unstable callback prop and was retriggering state updates on every render after the dialog opened.
- Tightened that effect so it resets selection only when `memory.id` changes, removing the infinite update loop.
- Added missing Radix accessibility metadata to dialog surfaces that previously rendered `DialogContent` without required title/description context:
  memory description editor,
  rename dialog,
  delete/remove confirmations,
  viewer overlay,
  and library dialog.
- Re-verified after the dialog/effect fix with:
  `pnpm typecheck`
  `pnpm build`
- Result: opening the memory description editor no longer triggers `Maximum update depth exceeded`, and the related dialog surfaces are now aligned with Radix accessibility requirements.

### 2026-04-22 Step 74

- Re-read `PLAN.md` after the recent AI/settings/runtime stabilization work to determine the next product phase rather than continuing with unplanned UI fixes.
- Confirmed that the next planned phase is now `4.12 Search and Discovery Phase`, because:
  `4.11 AI and Semantic Enrichment` is materially landed,
  and `4.13 Realtime Library Sync and Incremental Watch` remains intentionally deferred.
- Expanded `PLAN.md` with a more concrete implementation breakdown for `4.12`:
  unified discovery query contract,
  semantic search expansion,
  place/memory-aware discovery pivots,
  and final discovery UX completion.
- Next: begin `4.12` with the shared discovery query/search foundation rather than starting from isolated renderer polish.

### 2026-04-22 Step 75

- Started `4.12 Search and Discovery Phase` with the first shared/query-layer slice instead of jumping straight to renderer-only search polish.
- Added a shared `DiscoveryQuery` contract in `@chronopic/domain`, plus conversion helpers between:
  `DiscoveryQuery`
  and
  the current `PhotoFilter`
  so the app can evolve toward a clearer search model without breaking the existing browse pipeline.
- Added `ChronoPicAppService.listPhotosForDiscovery()` as the first application-layer entrypoint for the new discovery contract while keeping the underlying database query flow compatible with the current product surface.
- Expanded infra-db free-text search so `query` now matches linked memory metadata in addition to the existing photo fields:
  memory name,
  memory description,
  AI-generated memory title,
  AI-generated memory description,
  and AI-generated memory labels.
- Applied the same broader text-search clause to:
  `listPhotos`,
  `countMappablePhotos`,
  and
  `listPlaceGroups`
  so waterfall, map, and timeline can benefit from the expanded search coverage through the shared filter path.
- Removed a duplicated `aiStatus` SQL clause in `listPhotos` while touching the discovery query logic.
- Added regression coverage for:
  discovery-query/filter mapping in `tests/domain.test.ts`,
  application-layer discovery filter delegation in `tests/application-ai-enrichment.test.ts`,
  and infra search implementation coverage for memory-aware text matching in `tests/infra-db-semantic.test.ts`.
- Re-verified after the first `4.12` slice with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: `4.12` is now concretely started, and free-text discovery already reaches beyond photo-only fields into memory metadata while remaining compatible with the current multi-browse shell.

### 2026-04-22 Step 76

- Continued the second `4.12` slice by wiring the renderer onto the new discovery-query semantics instead of leaving the new contract unused behind the application layer.
- Added a dedicated renderer-side `discoveryQuery` state in `useChronoPicApp` and derived the existing `PhotoFilter` from it via the new shared conversion helpers.
- Kept the current product surfaces compatible by preserving `patchFilter()` for existing filter controls, but now implemented it by round-tripping through:
  `DiscoveryQuery -> PhotoFilter -> DiscoveryQuery`
  so filter UI and discovery UI share one search-state source of truth.
- Added `patchDiscoveryQuery()` for direct semantic/discovery-style updates and switched the primary free-text search input to update:
  `DiscoveryQuery.text`
  rather than mutating `PhotoFilter.query` directly.
- Added a new desktop IPC/preload route:
  `photos:listForDiscovery`
  and updated photo refresh in the renderer to fetch through `ChronoPicAppService.listPhotosForDiscovery()`.
- Re-verified after the renderer/query-state integration with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: the app is no longer treating search as only an incidental filter-field mutation; renderer state now explicitly models discovery query semantics while remaining compatible with the existing browse/filter surfaces.

### 2026-04-22 Step 77

- Continued `4.12` with the first shared discovery-context UX slice so waterfall, map, and timeline stop hard-coding separate scope/search explanation rules.
- Added a shared `getDiscoveryContext()` helper in `@chronopic/ui-components` that derives consistent discovery badges and explanatory copy from the active:
  memory scope,
  favorites scope,
  free-text search,
  tag/media/GPS/date filters,
  and AI pipeline-status filters.
- Updated `GallerySection` to replace its split memory/semantic banners with a single unified discovery-scope surface driven by the shared helper.
- Updated `MapBrowseSurface` to consume the shared discovery-context helper and display the current scope/search conditions with the same badge and description model used by waterfall view.
- Updated `TimelineBrowseSurface` so its timeline-scope summary now includes the same shared discovery-context badges and explanation rather than a one-off label heuristic.
- Passed the active memory name into map discovery rendering from the renderer shell so map mode can explain memory-scoped browsing as clearly as waterfall/timeline.
- Re-verified after the shared discovery-context pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: `4.12` now has a shared explanation layer for current discovery scope across all three browse modes, making search/discovery behavior easier to understand before adding deeper discovery pivots.

### 2026-04-23 Step 78

- Continued `4.12` with the first place-aware / memory-aware pivot slice so discovery is no longer only explanatory copy.
- Added a browse-shell `Discovery Pivots` strip in `PhotoHome` that summarizes the current result count and active search text, then offers direct transitions into:
  `Map View`,
  `Timeline`,
  `Browse Memories`,
  or the currently scoped memory detail page when applicable.
- Kept these pivots query-preserving by reusing the existing browse mode and memory selection handlers instead of inventing parallel routing or search state.
- Used current result characteristics to gate pivots intentionally:
  map pivot only appears when the scope contains GPS-bearing photos,
  timeline pivot only appears when the scope contains dated photos,
  and memory pivots reflect whether the current scope is already attached to a specific memory or only to the broader memories collection.
- Re-verified after the pivot pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: `4.12` now supports both shared discovery-context explanation and direct cross-surface pivots, so search/discovery can move between waterfall, map, timeline, and memories without forcing the user to reconstruct scope manually.

### 2026-04-23 Step 79

- Continued `4.12` with the first explicit match-explanation slice so discovery no longer stops at scope/context banners.
- Added a shared `getDiscoveryMatchSummary()` helper in `@chronopic/ui-components` that inspects the selected photo plus its linked memories and reports which fields matched the active free-text query:
  filename,
  manual caption/tags,
  AI caption/summary/tags,
  memory title/description,
  and AI-generated memory metadata.
- Updated `GallerySection`, `MapBrowseSurface`, and `TimelineBrowseSurface` so the selected-photo state now includes a concrete “matched in …” explanation whenever a discovery text query is active.
- Updated the viewer inspector `MetadataGrid` so detail view now has a dedicated `Discovery Match` card that surfaces the same per-result explanation inside the focused inspection workflow.
- Threaded the active search text through `PhotoHome` into `PhotoViewerOverlay` so the focused viewer can explain match origin without inventing a second search state.
- Added a root regression test in `tests/discovery-ui.test.ts` to verify the new match-summary helper reports AI-photo and AI-memory hit sources correctly.
- Re-verified after the match-explanation pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: `4.12` now explains both the current discovery scope and the concrete match origin for selected results, making the search/discovery UX substantially more inspectable before moving on to the next product phase.

### 2026-04-23 Step 80

- Investigated a renderer startup crash where `useChronoPicApp` tried to call:
  `initialize`,
  `listPhotosForDiscovery`,
  `countMappablePhotos`,
  and
  `listTimelineGroups`
  while `window.chronoPic` was still unavailable.
- Added an explicit renderer-side bridge guard in `useChronoPicApp` so initial hydration and the core refresh paths now no-op safely when the Electron preload bridge is missing instead of throwing repeated `Cannot read properties of undefined` errors.
- Added a single-shot user-facing error status for the missing-bridge case:
  `Desktop bridge unavailable. Restart the app or check preload startup.`
  so the failure mode is visible without flooding the UI with repeated messages.
- Applied the same guarded bridge access to the highest-frequency startup/runtime entrypoints:
  hydrate,
  photo refresh,
  geospatial refresh,
  timeline refresh,
  snapshot refresh,
  semantic queue refresh,
  memory refresh,
  selected-photo-memory refresh,
  add-library,
  scan,
  and settings-save actions.
- Re-verified after the bridge-availability hardening with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: preload/bridge failures now degrade into a stable renderer error state instead of crashing the app during initial discovery hydration.

### 2026-04-23 Step 81

- Removed two redundant discovery-explanation surfaces from the waterfall browse flow after runtime review:
  the browse-shell `Discovery Pivots` strip,
  and the generic “Scan the current library scope visually…” helper line above the gallery.
- Kept the stronger shared `Discovery Scope` and selected-photo/match-explanation surfaces, so the discovery UX now relies on the more concrete context blocks instead of stacking multiple layers of generic explanation.
- Re-verified after the discovery-UX de-duplication with:
  `pnpm typecheck`
  `pnpm build`
- Result: the browse header is lighter and less repetitive, while the more meaningful discovery context remains intact.

### 2026-04-23 Step 82

- Updated the local roadmap to remove the deferred realtime watch/sync phase entirely rather than leaving it as a future implementation target.
- Locked manual `Scan Library` in `PLAN.md` as the explicit long-term library sync model instead of a temporary fallback before directory watching.
- This means the current committed roadmap now ends with:
  `4.11 AI and Semantic Enrichment`
  and
  `4.12 Search and Discovery`,
  with no remaining planned watcher/incremental-sync phase after them.

### 2026-04-23 Step 83

- Refined the plan after clarifying that “no realtime watch” does not mean “no incremental scan semantics”.
- Updated `PLAN.md` so manual `Scan Library` is now explicitly expected to support incremental reconciliation:
  new files should be ingested,
  deleted files should be marked inactive or removed from the local projection,
  and modified files should be reprocessed using `mtime` / `size` / `hash` change detection instead of forcing a full rebuild.
- This keeps the product position clear:
  no automatic watcher,
  but manual scan remains a smart incremental sync operation rather than a naive full re-import.

### 2026-04-23 Step 84

- Implemented the first real incremental manual-scan pass in the indexing pipeline instead of leaving `Scan Library` as a full reprocess of every file.
- Extended index-state persistence with:
  `source_updated_at`
  and
  `missing_at`
  so the app can remember the last seen file mtime and whether a tracked file has disappeared from disk.
- Updated the SQLite schema/migration path and row mapping in `@chronopic/infra-db`, and added:
  `listTrackedPhotosInSource()`
  plus
  `markPhotosMissing()`
  to support source-root reconciliation during a manual scan.
- Updated repository query behavior so photos marked missing are excluded from:
  photo lists,
  snapshot counts,
  map counts,
  and place-group queries,
  while still keeping their records available for restoration if the same path reappears later.
- Updated `IndexerService.scanLibrary()` so a manual scan now:
  marks tracked-but-missing files as unavailable,
  skips unchanged files based on stored size + source mtime + mime,
  and fully reprocesses only new or changed files through:
  describe -> hash -> metadata -> thumbnail -> upsert.
- Preserved existing semantic/favorite state across reprocessing and stopped re-scan from unnecessarily resetting `aiProcessed` on unchanged surviving records.
- Added regression coverage in `tests/indexer-incremental.test.ts` for:
  unchanged-file skipping,
  modified-file reprocessing,
  and missing-file marking.
- Extended infra schema regression tests to cover the new incremental-scan columns and the new `missing` filtering semantics.
- Re-verified after the incremental manual-scan implementation with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: the product still avoids realtime watching, but manual `Scan Library` is now a true incremental reconciliation step rather than a naive full rebuild.

### 2026-04-24 Step 85

- Added the planned `4.13 Memory Authoring and Storytelling Phase` and `4.14 Advanced Discovery Phase` to `PLAN.md` before continuing implementation.
- Implemented the product-facing authoring/storytelling pass for memory detail:
  memory photos are now grouped into deterministic chronological story chapters,
  each chapter exposes a representative cover,
  photo count,
  mapped-photo count,
  and AI-ready count,
  and clicking a chapter lead opens the existing focused detail viewer.
- Implemented the product-facing advanced-discovery pass in the shared browse shell:
  a compact `Discover` pivot row now derives actionable suggestions from the current visible scope,
  including GPS, favorites, AI readiness, map/timeline switches, top labels, and memory pivots.
- Added shared helper coverage for:
  `buildMemoryStorySections()`
  and
  `buildDiscoverySuggestions()`.
- Verified the implementation with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory Authoring and Storytelling now has a visible chaptered story surface, Advanced Discovery now has compact actionable pivots, and the workspace remains typecheck/test/build clean.

### 2026-04-24 Step 86

- Added a new `4.15 AI Memory Auto-Grouping Phase` to `PLAN.md`.
- Defined the product scope for AI-generated memory candidates:
  ChronoPic should be able to propose memories from similar places,
  nearby timelines,
  semantic tags/captions/summaries,
  and future person clusters when a real person-recognition signal exists.
- Locked the key product constraint:
  generated groups are candidates, not automatic accepted memories.
- Defined the expected candidate review loop:
  title,
  reason,
  confidence,
  cover,
  photo preview,
  accept,
  reject,
  edit title,
  and remove photos before acceptance.
- Updated the test plan to require candidate/accepted-memory separation and explicit user acceptance semantics.
- Next: implement this phase after the current uncommitted story/discovery work is either committed or consciously carried forward.

### 2026-04-24 Step 87

- Implemented the `4.15 AI Memory Auto-Grouping Phase` end to end.
- Added domain types for:
  `MemoryCandidate`,
  candidate source/status,
  candidate input,
  and candidate acceptance input.
- Added SQLite persistence for reviewable memory candidates with:
  stable signatures,
  reason,
  confidence,
  source,
  status,
  photo IDs,
  generated labels,
  cover linkage,
  and accepted-memory linkage.
- Added application service methods for:
  listing pending candidates,
  generating candidates,
  accepting candidates into normal memories,
  and rejecting candidates.
- Implemented deterministic candidate generation from:
  GPS/place clusters,
  monthly timeline clusters,
  and manual/AI semantic labels.
- Wired the new flow through Electron IPC and preload.
- Added a `Suggested Memories` panel to the Memories page so candidates can be generated, reviewed, title-edited, photo-pruned, accepted, or rejected.
- Added regression tests for:
  candidate schema,
  candidate generation from place/time/semantic signals,
  and accept/reject persistence boundaries.
- Verified during implementation with:
  `pnpm test`
  `pnpm typecheck`
  `pnpm build`
- Result: AI Memory Auto-Grouping is landed and build-valid as a reviewable candidate workflow.

### 2026-04-24 Step 88

- Added `4.16 Memory Candidate Queue and Notifications Phase` to `PLAN.md`.
- Locked the product behavior:
  scan-triggered candidate generation may create reviewable pending suggestions,
  but it must not create accepted memories without explicit user confirmation.
- Planned the implementation around:
  scan-triggered candidate refresh,
  sidebar notification count integration,
  Notifications page candidate visibility,
  and a clear pending-candidate affordance on the Memories page.
- Implemented the renderer follow-up:
  `Scan Library` now refreshes memory candidates,
  scan completion reports suggested-memory readiness,
  sidebar notification count includes pending candidates,
  Notifications includes a Memory Candidates card with refresh action,
  and Memories shows the pending-candidate ready message.
- Verified the first pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory Candidate Queue and Notifications is landed and build-valid.

### 2026-04-24 Step 89

- Created branch `ux-simplify-surfaces` for a focused UI/UX simplification pass.
- Removed redundant information and duplicate affordances:
  the gallery no longer renders the large `Discovery Scope` explanation panel,
  discovery chips now focus on cross-view and memory pivots instead of duplicating filter controls,
  the memory story board no longer shows a secondary `Open chapter lead` button inside an already-clickable card,
  Notifications no longer renders `Recent Action` as a full card,
  and Suggested Memories now has a single ready-count badge instead of duplicate count text.
- Reduced candidate-card noise by hiding per-photo removal controls behind an explicit `Adjust photos` action.
- Verified the first pass with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: the UX simplification pass is landed on `ux-simplify-surfaces` and build-valid.

### 2026-04-24 Step 90

- Reviewed Memory detail AI Story presentation and agreed that default AI Story exposure made AI suggestions feel like primary memory content.
- Moved the AI Story panel out of the default Memory detail body.
- Added a compact `AI Suggestions` sparkles icon action in the memory header.
- Added a dedicated dialog for AI suggestions:
  status,
  generate action,
  suggested title,
  suggested summary,
  generated tags,
  and explicit apply controls now live inside the dialog.
- Preserved the existing rule that generated content is never applied automatically.
- Verified the refactor with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory detail now keeps AI suggestions behind an explicit action and remains build-valid.

### 2026-04-24 Step 91

- Replaced the Memory description editor from BlockNote to a simpler Tiptap editor.
- Removed BlockNote runtime dependencies and the BlockNote stylesheet import from the desktop renderer.
- Added explicit Tiptap dependencies to `@chronopic/ui-components`.
- Kept the existing description persistence API unchanged:
  descriptions are still stored as a string,
  legacy BlockNote JSON is converted into simple paragraph HTML when opened,
  and existing preview logic now supports both old BlockNote JSON and new Tiptap HTML.
- Implemented a minimal Tiptap schema for plain paragraph editing to keep the UI simple and avoid command-heavy markdown chrome.
- Verified the replacement with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory description editing now uses Tiptap, BlockNote is removed, and the production renderer bundle is materially smaller.

### 2026-04-26 Step 92

- Reviewed the memory description pipeline and removed the mixed-format model.
- Changed the description contract to raw Markdown source only:
  existing stored values are treated as Markdown as-is,
  no legacy BlockNote JSON or Tiptap HTML compatibility conversion is attempted,
  and the database/API continue to store the same `description` string field.
- Replaced the Tiptap editor with `@uiw/react-md-editor`.
- Updated the memory detail read view to render Markdown through the same editor package's Markdown preview instead of injecting saved HTML.
- Simplified memory-description preview extraction so cards strip common Markdown markers for compact text only.
- Added the explicit renderer CSS imports and package dependencies required by the Markdown editor/preview.
- Used lazy loading for the editor and preview components so importing `@chronopic/ui-components` in Node-based tests does not eagerly load browser CSS from `@uiw`.
- Verified the replacement with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory description editing and display now have one canonical Markdown-source format and the workspace remains build-valid.

### 2026-04-26 Step 93

- Refined Memory title and description editing interaction.
- Removed the redundant `Rename` button from Memory detail; clicking the title now opens the title editor directly.
- Removed the redundant `Edit Description` button; clicking the description surface remains the only edit entry point.
- Added magic-button AI actions inside both edit dialogs:
  empty title/description drafts show generate-oriented copy,
  existing drafts show optimize-oriented copy,
  and both actions reuse the existing `onEnrichSemantic(memory.id)` memory suggestion pipeline.
- Kept AI suggestions non-destructive:
  generated title/description values appear as suggestions,
  choosing `Use suggestion` only fills the local draft,
  and the user still has to save before the Memory is updated.
- Converted `MemoryDescriptionEditor` into a controlled Markdown editor so suggestion-filled drafts and manually typed drafts share the same dirty/save behavior.
- Verified the interaction update with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory title/description editing is less button-heavy and AI generation/optimization is available at the point of authoring without silently overwriting user content.

### 2026-04-26 Step 94

- Reviewed the Memory AI optimize path after observing that optimize behaved like a fresh generation.
- Found that the edit-dialog magic buttons only called `enrichMemorySemantic(memory.id)`, so the backend prompt used the last saved Memory title/description and could not see unsaved editor drafts.
- Added a `MemoryAIContext` override object to the AI service interface and app-service `enrichMemorySemantic` path.
- Threaded the context through Electron IPC, preload bridge, renderer hook, `PhotoHome`, and `MemoryDetailPage`.
- Updated title optimize to pass the current title draft as `context.name`.
- Updated description optimize to pass the current Markdown draft as `context.description`.
- Updated the memory AI prompt so non-empty working drafts are explicitly treated as optimization inputs whose intent and concrete details must be preserved.
- Added regression coverage asserting that `ChronoPicAppService.enrichMemorySemantic()` forwards draft context to `AIClient.analyzeMemory()` without overwriting manual Memory fields.
- Verified the fix with:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Result: Memory AI optimize now has access to the user's current unsaved title/description draft instead of regenerating solely from persisted Memory data.

### 2026-04-26 Step 95

- Added `4.17 Internationalization and AI Output Locale Phase` to `PLAN.md` before implementation.
- Locked the i18n approach around a new `@chronopic/i18n` package with typed locale IDs, typed translation keys, fallback/interpolation, and date/count formatting helpers.
- Planned persisted desktop settings for both UI locale and AI output locale, with AI output defaulting to the UI language unless explicitly configured.
- Planned React integration through `I18nProvider` / `useI18n()` in `@chronopic/ui-components` while keeping persistence in the desktop/config layer.
- Planned prompt-level AI output locale support so generated names, descriptions, labels, captions, summaries, and memory suggestions can follow the configured output language.
- Planned lightweight E2E coverage for switching to Simplified Chinese and verifying Sidebar, Header/Search, and Memory Detail key text.
- Next: implement `@chronopic/i18n`, config persistence, provider wiring, critical UI translations, AI output locale threading, and tests.

### 2026-04-26 Step 96

- Implemented the `4.17 Internationalization and AI Output Locale Phase`.
- Added `@chronopic/i18n` as a strict workspace package with typed locale IDs, typed translation keys, English/Simplified Chinese dictionaries, fallback interpolation, locale normalization, AI output-locale resolution, and formatting helpers.
- Added persisted desktop language settings through `@chronopic/infra-config`, Electron main IPC, preload bridge APIs, and renderer app state:
  `locale`
  and `aiOutputLocale`.
- Wired the renderer through `I18nProvider` / `useI18n()` from `@chronopic/ui-components`.
- Added Library Settings controls for UI language and AI output language using the existing Radix-backed `Select` component.
- Translated the first critical UI path:
  Sidebar,
  browse mode switcher,
  search placeholder,
  memory creation dialog,
  memory detail,
  and language/settings surfaces.
- Threaded resolved AI output locale through photo semantic enrichment, pending queue enrichment, and memory semantic enrichment prompts.
- Added unit coverage for i18n dictionary completeness, interpolation, normalization, count formatting, and AI output-locale resolution.
- Extended application AI tests to verify photo and pending queue enrichment receive the output-locale context.
- Added lightweight Electron E2E coverage in `tests/e2e/i18n.spec.ts` for switching to Chinese and checking Sidebar/Header/Memory Detail key text.
- Verified:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`
- Result: the i18n phase is landed and build-valid. The E2E spec is present and follows the existing dev-renderer prerequisite on `http://localhost:5173`.

### 2026-04-26 Step 97

- Performed a follow-up i18n coverage audit after reviewing the renderer and shared UI surfaces for remaining hard-coded English.
- Confirmed the first i18n pass was incomplete beyond the initial critical path.
- Expanded translation coverage across:
  filter toolbar,
  photo cards,
  add-to-memory menu,
  viewer overlays,
  memory cards/list/recent memories,
  suggested memories,
  memory description editor,
  edit controls,
  metadata inspector,
  memory story board,
  notification center,
  map browse surface,
  timeline browse surface,
  gallery selected/batch states,
  photo grid,
  and detail panel.
- Added the required English and Simplified Chinese translation keys to `@chronopic/i18n` while keeping dictionary-completeness tests active.
- Re-verified:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`
- Remaining known i18n debt:
  transient `showStatus(...)` messages in `use-chronopic-app.ts` are still stored as English strings,
  and a few legacy/exported-but-currently-unused components still contain English fallback copy.
  The main rendered product surfaces now have much broader locale coverage, but status/toast localization should be the next i18n cleanup if full polish is required.

## Next Immediate Tasks

1. Workspace skeleton is implemented.
2. Domain, persistence, indexing, and desktop UI are implemented.
3. Package boundary semantics have been tightened to match runtime and build-time dependency behavior.
4. The first UI refactor pass is implemented and verified at typecheck/build level.
5. Shared-package Tailwind extraction is fixed and rebuilt successfully.
6. The first dedicated detail-view and gallery-view implementation is landed and verified at typecheck/build level.
7. The first renderer/UI structural split is landed and verified at typecheck/build level.
8. The home-page layout, favorites, memories, edit UX, and memory list/detail productization phases have all landed in code.
9. Sidebar navigation and gallery-section composition are now aligned more closely with the current plan.
10. Memory description editing now uses raw Markdown source with `@uiw/react-md-editor`, and the desktop build/typecheck pipeline remains green with the new dependency surface.
11. Viewer ergonomics have received a focused polish pass and remain build-valid.
12. The real `shadcn/ui` / Radix-backed adoption pass is landed for `Select`, dialogs, and the base shared control layer.
13. The app now exposes visible add/remove memory actions in gallery, viewer, and memory-detail flows, but deeper lifecycle polish is still pending.
14. Memory detail now supports rename, set-cover, remove-from-memory, and transient action feedback; cover state is also cleared automatically when the removed photo was the active cover.
15. Focused viewing now exposes which memories the current photo belongs to, and marks when that photo is serving as a memory cover.
16. Gallery now supports batch photo selection and one-shot add-to-memory actions through a dedicated batch action bar.
17. Batch selection now has an explicit `Select` mode, and transient feedback is structured by severity rather than rendered as a single generic banner state.
18. The unused header avatar entry has been removed; header chrome is now closer to the actual product surface.
19. E2E smoke tests exist and pass via Playwright for the current shell-level flows; deeper memory-management runtime validation still needs a real Electron smoke test.
20. Memory detail now also supports batch selection and batch removal, giving memories a more complete lifecycle loop instead of one-way accumulation.
21. Memory feedback is now more specific and destructive actions in memory detail are confirmation-gated rather than firing immediately.
22. Empty states and relation visibility have now been strengthened across recent memories, memory list, gallery, and gallery-mode viewing surfaces.
23. The plan now includes explicit geospatial/map-browse and timeline/multi-browse phases for future product expansion.
24. The new browse work is now decomposed enough to implement without revisiting product shape from scratch.
25. The recommended implementation order is now explicit and should be treated as binding unless a later design change is consciously made.
26. The shared browse shell, geospatial foundation, and first renderer-owned map surface are now all landed and build-valid.
27. The map phase now includes viewport-aware group querying and better marker/selection synchronization.
28. The first timeline renderer is now landed and wired through the shared app/IPC/query path instead of being a renderer-only mock surface.
29. Timeline now supports multiple grouping granularities and clearer scope explanation, so the remaining browse work is primarily runtime polish rather than missing core structure.
30. Map mode now preserves viewport context and better syncs selected place groups, so the remaining browse polish is mostly about smaller runtime affordances rather than missing state foundations.
31. Browse modes now share stronger scope and selection context, so the remaining polish is mostly around finer discoverability and performance/runtime behavior rather than missing interaction semantics.
32. The next major UI work is now explicitly the `4.10 UI/UX Redesign Phase`, guided by `DESIGN.md` rather than ad hoc visual tweaks.
33. The redesign phase is now started in code at the shell/composition layer.
34. Next: continue the redesign by refining the browse surfaces themselves so waterfall/map/timeline visually align with the new home-shell direction.
35. The core redesign UX refine is now landed.
36. Any additional work from here is optional visual polish or follow-up tweaks rather than unfinished redesign foundations.
37. Realtime library sync has been intentionally deferred to the end of the next product-expansion sequence rather than being treated as the next implementation target.
38. The next implementation phase is now `4.11 AI and Semantic Enrichment Phase`.
39. Search and discovery strengthening should follow AI enrichment, with realtime incremental watch left for the last phase in the current roadmap.
40. The first AI-enrichment slice is now landed: semantic storage is expanded, a real Vercel-AI-backed provider exists, and the viewer inspector can manually trigger enrichment.
41. Business-logic and infra package unit tests are now explicitly part of the acceptance bar for this phase, and the first AI-related tests are already added at the root test layer.
42. AI enrichment is no longer limited to one-off manual generation; queue stats and pending-batch processing are now part of the product surface.
43. Semantic search is now user-visible through AI-status filters and explicit semantic-search context messaging, not just hidden in backend query behavior.
44. Business-logic and infra package coverage now includes the AI service layer itself, not just application and infra-db.
45. Memory-level AI synthesis is now landed as non-destructive suggestion storage plus explicit apply actions in memory detail.
46. AI provider configuration is now product-visible and no longer blocked on environment variables only.
47. The AI queue is now also visible in `Library Settings`, and the batch-enrichment IPC path is normalized for safer Electron transport.
48. The batch queue IPC path now uses string-only transport for maximum Electron compatibility.
49. The persistent queue clone error was actually caused by passing a React click event through IPC, and that binding bug is now fixed.
50. The photo-card double-click hint has been repositioned into the main text stack above the title.
51. AI queue visibility now lives in a dedicated notification-center page reached from the sidebar bell, rather than being split across home and settings.
52. Interrupted AI work is now recovered from stale `processing` back to `pending` on app startup.
53. Next: move into `4.12 Search and Discovery Phase` unless a smaller AI-polish task is explicitly prioritized first.
54. Memory Authoring and Storytelling now has a visible result: memory detail includes deterministic story chapters derived from current memory photos.
55. Advanced Discovery now has a visible result: browse exposes compact actionable pivots without adding another large explanatory panel.
56. The next planned product-expansion phase is now `4.15 AI Memory Auto-Grouping Phase`, focused on reviewable AI-proposed memories from place/time/semantic/person-like signals.
57. AI Memory Auto-Grouping is now implemented as a reviewable candidate workflow rather than silent memory creation.
58. The active follow-up phase is `4.16 Memory Candidate Queue and Notifications Phase`.
59. Active branch `ux-simplify-surfaces` is refining UI surfaces to reduce duplicate status text and repeated controls.
60. Memory detail AI suggestions are now being moved from default page content into an explicit compact action/dialog.
61. Memory description editing is now standardized on raw Markdown source and `@uiw/react-md-editor`.
62. Memory title and description now expose AI generate/optimize actions inside their edit dialogs, while direct title/description clicks replace separate rename/edit buttons.
63. Memory AI optimize now passes unsaved title/description drafts through to the AI prompt as working context.
64. The `4.17 Internationalization and AI Output Locale Phase` is now landed and has received a follow-up coverage pass across the main visible UI surfaces.
65. Transient app status/toast messages, discovery helper labels/descriptions, match summaries, browse fallback placeholders, legacy library dialog/sidebar copy, and remaining settings labels have now been converted to locale-backed strings.
66. The remaining hardcoded renderer scan hits are deliberate technical constants/placeholders rather than user-facing untranslated UI copy.

### 2026-04-26 Step 98

- Performed a full follow-up i18n coverage audit after the initial internationalization implementation.
- Moved `use-chronopic-app.ts` status/toast feedback onto locale keys, including library scan, AI settings, map settings, memory CRUD, batch add/remove, semantic enrichment, AI queue processing, and edit rollback messages.
- Threaded the active translator into pure discovery helper functions so discovery context badges, discovery suggestions, and search-match summaries localize correctly instead of returning English from library helpers.
- Localized remaining fallback/legacy UI surfaces:
  `Header`,
  `LibraryDialog`,
  `LibrarySidebar`,
  `BrowseModePlaceholder`,
  map/settings labels,
  source last-scan labels,
  and photo-card secondary action fallback copy.
- Re-ran the hardcoded UI string scan; remaining hits are technical constants/placeholders only:
  route ids,
  status tone ids,
  translation-key ids,
  the AMap missing-key error code,
  and AI provider/model/API example placeholders.
- Re-verified:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`

### 2026-04-26 Step 99

- Performed an additional stricter i18n scan after the user called out `Select` / `Filter` style omissions.
- Fixed the remaining visible browse toolbar hardcoded text:
  the waterfall `Select` / `Done` toggle and `Filter` button now use action translation keys.
- Localized remaining exported/fallback UI copy:
  `HomeStats` hero copy, status tile labels, AI enabled/deferred state,
  `TagInput` remove aria-label,
  AI settings input placeholders,
  and the memory delete icon label.
- Re-ran a focused visible-string scan for text nodes, labels, placeholders, aria-labels, and titles; remaining matches are TypeScript function signatures only.
- Re-verified:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`

### 2026-04-26 Step 100

- Fixed memory story chapter date formatting so it follows the active UI locale.
- Changed `buildMemoryStorySections` to keep raw `monthKey`, `fromDatetime`, and `toDatetime` data instead of pre-formatting English `title` / `subtitle` strings inside the helper.
- Moved chapter title and date-range formatting into `MemoryStoryBoard`, using the `I18nProvider` locale at render time.
- Added localized strings for undated story chapters, date ranges, and AI-ready story badges.
- Updated the story/discovery unit test to assert locale-neutral `monthKey` data rather than English month text.
- Re-verified:
  `pnpm typecheck`
  `pnpm test`
  `pnpm build`

### 2026-05-05 Step 101

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
