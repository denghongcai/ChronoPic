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
