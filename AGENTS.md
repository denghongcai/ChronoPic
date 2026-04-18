# AGENTS.md

## Purpose

This file is the local execution record for ChronoPic. It complements `PLAN.md` and must be updated as implementation progresses.

## Working Rules

- Keep `PLAN.md` as the stable implementation plan.
- Update this file after each meaningful implementation step.
- Record what changed, why it changed, and what remains next.
- Do not mark a step complete unless the corresponding code or verification has landed locally.

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

## Next Immediate Tasks

1. Workspace skeleton is implemented.
2. Domain, persistence, indexing, and desktop UI are implemented.
3. Package boundary semantics have been tightened to match runtime and build-time dependency behavior.
4. The first UI refactor pass is implemented and verified at typecheck/build level.
5. Shared-package Tailwind extraction is fixed and rebuilt successfully.
6. The first dedicated detail-view and gallery-view implementation is landed and verified at typecheck/build level.
7. The first renderer/UI structural split is landed and verified at typecheck/build level.
8. Viewer ergonomics have received a first focused polish pass and remain build-valid.
9. Remaining follow-up: run a runtime smoke test in Electron and continue polish based on real use.
