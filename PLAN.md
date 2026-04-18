# ChronoPic Development Plan

## Summary

ChronoPic starts from a greenfield repository. The first implementation pass will build a desktop-first monorepo with a working local-media loop: library registration, file scanning, metadata extraction, thumbnail generation, SQLite persistence, browsing, filtering, and local edits. AI behavior will be deferred, but interfaces and state fields will be kept in place so a later provider integration does not require restructuring the app.

## Key Changes

### 1. Workspace and App Skeleton

- Create a `pnpm` workspace with an Electron desktop app and shared TypeScript packages.
- Keep process boundaries strict: renderer for UI only, main for IPC and local capabilities, shared packages for business logic.
- Start with the minimum package set required for a usable product: `domain`, `application`, `infra-db`, `infra-fs`, `infra-image`, `services-indexer`, `services-ai-pipeline`, `shared-utils`, and `ui-components`.

### 2. Local Persistence and State

- Implement a SQLite schema with `photos`, `metadata`, `semantic`, `index_state`, `library_sources`, and edit history tables.
- Enable WAL mode and add indexes for path, hash, datetime, and state lookups.
- Store thumbnail files in a separate cache directory keyed by stable IDs derived from content or path.
- Keep AI-related columns and pipeline states in the schema even though the provider is disabled for v1.

### 3. Indexing Pipeline

- Build a staged indexer pipeline: `scan -> hash -> exif -> thumbnail -> db write`.
- Support manual re-scan and idempotent reprocessing through DB-backed state instead of a separate checkpoint file in v1.
- Use bounded concurrency to avoid excessive filesystem and image-processing pressure.
- Fall back to file timestamps when EXIF datetime is unavailable and persist a confidence value.
- Detect duplicates by content hash and keep a single primary record per file path while exposing duplicate state through the data model.

### 4. Desktop UX

- Provide library source management, scan trigger, scan progress, media grid, detail panel, and structured filters.
- Support time sorting, basic status filtering, file type filtering, tag filtering, and text filtering over path/caption/tags.
- Use paginated queries and a virtualized-style rendering approach to avoid loading all assets eagerly.
- Surface AI as disabled or unavailable rather than exposing broken actions.

### 4.1 UI Refactor Phase

- Add a dedicated post-MVP phase to refactor the renderer UI with `shadcn/ui`.
- Keep the existing IPC, domain, application, and indexing flows unchanged; the refactor is presentation-layer only.
- Replace ad hoc layout and form primitives with `shadcn/ui` building blocks for navigation, panels, forms, dialogs, buttons, inputs, and feedback states.
- Introduce `tailwindcss` and the required `shadcn/ui` base setup in the desktop renderer only, without leaking frontend styling concerns into shared business packages.
- Preserve all current user-visible capabilities during the refactor:
  library import, scan trigger, media browsing, filtering, detail display, tag editing, datetime editing, and rollback.
- Use the refactor to improve interaction quality, empty states, loading states, and visual hierarchy rather than expanding product scope.

### 4.2 Detail and Gallery Viewing Phase

- Add a dedicated interaction phase to redesign what happens when the user activates a thumbnail.
- Separate "selection in grid" from "open for viewing":
  single click keeps lightweight selection behavior for fast triage,
  double click or Enter opens a focused viewer state.
- Introduce two explicit viewing modes:
  `detail view` for larger preview plus metadata and edit actions,
  `gallery view` for immersive browsing with most chrome hidden.
- In `detail view`, present the selected asset as the primary surface and move metadata/edit controls into a structured inspector rather than keeping the grid as the dominant surface.
- In `gallery view`, use a dark immersive canvas, arrow-key navigation, Esc to close, and a bottom filmstrip or strip-toggle for rapid adjacent browsing.
- Keep navigation continuous across both modes:
  next/previous actions,
  keyboard support,
  visible active-item context,
  and the ability to jump back to the grid without losing the current filter state.
- Preserve the current local edit flow inside `detail view`, but keep `gallery view` optimized for viewing rather than editing.
- Design the mode split using established photo-product patterns:
  Apple Photos emphasizes opening an asset into an enlarged view with optional full-screen and thumbnail navigation,
  Google Photos uses bottom filmstrip navigation for grouped browsing,
  Lightroom separates detail-oriented viewing from advanced actions such as compare and metadata inspection.
- Keep this phase renderer-focused at first:
  it may require new UI state and routing/state-machine structure,
  but it should not require widening package boundaries or bypassing existing IPC/application services.

### 4.3 UI Structure and Component Boundary Phase

- Add a dedicated engineering phase to split oversized renderer and UI-component files into clear, maintainable modules.
- Separate concerns across at least these layers:
  page-level containers in the desktop renderer,
  shared presentational components in `@chronopic/ui-components`,
  viewer-specific compositions,
  and low-level style primitives/utilities.
- Avoid single-file accumulation for page composition, overlay composition, and reusable controls; each major surface should have a clear ownership boundary and a file-local responsibility.
- Extract viewer-related pieces into focused modules such as:
  overlay shell,
  filmstrip,
  media preview,
  metadata inspector,
  and edit controls,
  so future interaction changes do not require editing one monolithic file.
- Extract renderer page logic into explicit sections or files for:
  shell layout,
  library actions,
  filter state handling,
  selection/viewer state,
  and keyboard interaction wiring,
  while keeping the existing IPC and data flow semantics intact.
- Keep package boundaries strict during the split:
  the desktop app should compose page/container logic,
  `@chronopic/ui-components` should expose only deliberate public UI building blocks,
  and no renderer file should reach into private files inside another package.
- Align exports with the new structure so each public component is exported intentionally rather than incidentally through one catch-all implementation file.
- Use this phase to improve modification cost and reasoning clarity, not to change product scope or behavior by default.

### 4.4 Real shadcn/ui Component Adoption Phase

- Add a dedicated phase to replace the current Tailwind-only lookalike primitives with actual `shadcn/ui`-style component implementations backed by the expected Radix primitives where applicable.
- Treat this as distinct from the earlier visual refactor:
  the goal here is to align interaction components with the real `shadcn/ui` composition model, accessibility behavior, and dependency stack rather than only matching the visual language.
- Start with the most visible interactive surfaces:
  `Select` in the filter toolbar,
  viewer overlays via `Dialog`/`Sheet`-style primitives,
  and any other controls whose current implementation still relies on raw DOM widgets or ad hoc overlay behavior.
- Introduce the minimal Radix dependency set required for the adopted `shadcn/ui` components, and keep those dependencies isolated to the UI package layer.
- Keep low-level visual tokens, utility merging, and public exports organized so the package still exposes a deliberate UI surface after the migration.
- Migrate incrementally:
  replace one interaction family at a time,
  validate behavior,
  then continue to adjacent controls instead of attempting a full UI rewrite in one pass.
- Preserve current product behavior unless a specific interaction improvement is part of the migration target.

### 4.5 Home Page Layout Restructure Phase

- Add a dedicated phase to restructure the renderer home page into a coherent layout with Header, Sidebar, and MainContent regions.
- Library configuration (add/remove library sources) is accessible from the Header's user dropdown and also from the Sidebar, and switches the main content area to a library settings page (not a dialog).
- Introduce a new `Avatar` component for the user_profile button and notification button.
- Introduce a `SearchInput` component for the header search bar.
- Header layout: logo on left, search + notification bell + user avatar on right (right-aligned).
- Introduce a `Sidebar` component with two sections:
  Library (All Photos, Favorites),
  Memories (list of user/AI-created memories, with a Create Memory action).
- Introduce a `RecentMemories` horizontal scroll section with a "See All Recent" link.
- Introduce a `GallerySection` combining the existing filter bar and photo grid under a unified section.
- Introduce a `PhotoCard` component with hover-revealed actions (favorite, delete, info).
- Introduce a `PageView` context for switching between home and library-settings views within the main content area.
- Preserve the existing viewer overlay, detail panel, and filter/toolbar behavior within the new layout shell.
- This phase is a renderer structural refactor; it must not change IPC handlers, domain types, or application-layer logic.

### 4.6 Favorite and Memory Phase

- Add `favorite: boolean` to the `Photo` domain interface and `favorite?: boolean` to `PhotoFilter`.
- Add `Memory` and `MemoryPhoto` domain interfaces representing user-created or AI-organized photo groupings.
- Update the SQLite schema: add `favorite` column to `photos` table, add `memories` table, add `memory_photos` junction table.
- Update `PhotoRow` and `mapPhotoRow` in the repository to include `favorite`.
- Update `listPhotos` to support filtering by `favorite`.
- Preserve `favorite` in `upsertPhotoRecord` so existing values are not overwritten on re-index.
- Add `updatePhotoFavorite(photoId, boolean)` to the database layer.
- Add memory CRUD to the database layer: `listMemories`, `createMemory`, `deleteMemory`, `addPhotoToMemory`, `removePhotoFromMemory`, `listPhotosByMemory`.
- Add `toggleFavorite` and memory methods to the application service.
- Add IPC handlers for favorite toggling and memory management.
- Wire favorite state through the renderer hook: `PhotoCard` hover action calls IPC to toggle, update local photo record.
- Update `FilterToolbar` to include a Favorites toggle backed by `filter.favorite`.
- Simplify `Sidebar` to only two sections: Library (All Photos, Favorites) and Memories. Remove placeholder albums and collections.
- Add a `CreateMemoryDialog` for creating a new memory with a name.
- Update the test plan: add verification for favorite toggle, memory creation, memory listing, and photo-membership queries.

### 5. Editing and History

- Support local tag edits and datetime correction in the database projection.
- Record edit history so the latest change can be rolled back safely.
- Do not write edits back into EXIF files in this implementation pass.

## Public Interfaces

- IPC surface will be grouped into `library`, `photos`, `edits`, and `system`.
- Domain types will include `Photo`, `PhotoRecord`, `Metadata`, `Semantic`, `IndexState`, `LibrarySource`, `EditHistory`, `PhotoFilter`, and `IndexerStats`.
- `services-indexer` will expose `scanLibrary`, `resumeIndexing`, `getIndexStats`, and `listSupportedMedia`.
- `services-ai-pipeline` will provide an `AIClient` abstraction and a disabled default implementation.

## Test Plan

- Verify schema creation and repository CRUD flows.
- Verify indexing for normal files, EXIF-less files, duplicates, and unsupported media.
- Verify thumbnail generation and cache reuse behavior.
- Verify filters, ordering, and pagination over persisted records.
- Verify tag edits, datetime edits, and rollback behavior.
- Verify IPC handlers do not expose raw filesystem access to the renderer.
- Verify the `shadcn/ui` refactor does not change renderer behavior or break existing IPC-driven flows.
- Verify major screens still work after the refactor: library management, scan action, media grid, detail panel, and edit actions.
- Verify the new thumbnail activation model:
  single click selects,
  double click or Enter opens detail view,
  Esc closes detail/gallery overlays,
  and arrow keys move between adjacent assets.
- Verify the gallery mode supports immersive browsing without breaking the current filter/query context.
- Verify detail view preserves tag editing, datetime editing, and rollback for the active asset.
- Verify the structural split does not change runtime behavior:
  the same key UI flows should remain functional after files are decomposed.
- Verify package exports remain deliberate and build/runtime resolution still matches the public package surface after the split.
- Verify adopted `shadcn/ui` components are genuinely backed by the expected primitives rather than raw DOM stand-ins for the same interaction.
- Verify `Select` keyboard behavior, focus handling, and overlay positioning remain correct after the migration.
- Verify viewer overlays continue to support dismissal, focus trapping, and keyboard controls after moving onto dialog-style primitives.
- Verify the home page layout renders with Header, Sidebar, and MainContent regions.
- Verify library configuration is accessible through the header dropdown or sidebar item, and switches the main content to the library settings page.
- Verify RecentMemories horizontal scroll and Gallery section with filter bar render correctly.
- Verify photo_card hover actions (favorite, delete, info) are registered and respond to interactions.
- Verify the page-view switch between home and library-settings does not lose viewer state or filter state.
- Verify favorite toggle persists to the database and survives a library re-scan.
- Verify memory creation, listing, and photo membership queries work end-to-end.
- Verify sidebar shows only Library (All Photos, Favorites) and Memories sections with no placeholders.
- Verify the database migration adds the `favorite` column and memory tables to existing app databases on next launch.

## Assumptions

- The repository has no existing implementation and can be structured freely.
- The first pass targets desktop only.
- Real AI providers, OCR, vector search, cloud sync, and EXIF writeback remain out of scope.
- File watching will not be shipped in the first pass; manual rescan is sufficient.
- The `shadcn/ui` phase is a renderer-only refactor and must not widen package boundaries or bypass existing application-layer APIs.
- The detail/gallery viewing phase should reuse the current photo list query model and active-record data flow instead of introducing a second parallel retrieval path unless runtime validation shows that the existing list payload is insufficient.
- The UI structure phase is a code-organization refactor first; it should preserve behavior unless a specific follow-up UX change is explicitly planned.
- The real `shadcn/ui` adoption phase should prefer a minimal, deliberate component set over importing a broad catalog that the product does not actually use.
- Favorite and Memory are local-only concepts; no cloud sync or sharing in this phase.
