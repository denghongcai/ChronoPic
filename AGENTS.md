# AGENTS.md

## Purpose

This file is the local execution record for ChronoPic. It complements `PLAN.md` and must be updated as implementation progresses.

## Working Rules

- Keep `PLAN.md` as the stable implementation plan.
- Update this file after each meaningful implementation step.
- Record what changed, why it changed, and what remains next.
- Do not mark a step complete unless the corresponding code or verification has landed locally.
- After completing a phase or task (including each checklist item in PLAN.md), always update both `PLAN.md` and this file before considering the work done.

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
10. Memory description editing now uses `BlockNote`, and the desktop build/typecheck pipeline remains green with the new dependency surface.
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
32. Next: continue with smaller runtime/discoverability polish across waterfall/map/timeline, or shift to a new product phase once browse feels settled enough in actual use.
