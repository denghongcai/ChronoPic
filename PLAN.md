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

## Assumptions

- The repository has no existing implementation and can be structured freely.
- The first pass targets desktop only.
- Real AI providers, OCR, vector search, cloud sync, and EXIF writeback remain out of scope.
- File watching will not be shipped in the first pass; manual rescan is sufficient.
- The `shadcn/ui` phase is a renderer-only refactor and must not widen package boundaries or bypass existing application-layer APIs.
- The detail/gallery viewing phase should reuse the current photo list query model and active-record data flow instead of introducing a second parallel retrieval path unless runtime validation shows that the existing list payload is insufficient.
- The UI structure phase is a code-organization refactor first; it should preserve behavior unless a specific follow-up UX change is explicitly planned.
