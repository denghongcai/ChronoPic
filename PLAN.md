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
- Add a `CreateMemoryDialog` for creating a new memory with a name. ✅
- Update the test plan: add verification for favorite toggle, memory creation, memory listing, and photo-membership queries.

### 4.7 Memory Productization Phase

- Promote `Memory` from a lightweight filter target into a first-class product object with its own list and detail experiences.
- Extend the `Memory` data model with presentational/product metadata needed for a real memory surface:
  `description`,
  `coverPhotoId`,
  and stable update timestamps suitable for sorting and preview cards.
- Introduce a dedicated `Memories` page in the main content area instead of using the photo gallery as the primary memory browser.
- Introduce a dedicated `Memory Detail` page:
  hero/summary block,
  cover image,
  title,
  description,
  item count,
  update time,
  and then the memory-scoped photo grid below it.
- Add reusable UI components for memory presentation:
  `MemoryCard`,
  `MemoryListSection`,
  and `MemoryDetailPage`.
- Update `RecentMemories` so it renders actual memory cards rather than recent photos.
- Keep memory selection and navigation distinct from photo filtering:
  the memory list page browses memories,
  the memory detail page browses photos within one memory,
  and the all-photos gallery remains a separate surface.
- Add memory-management actions required for a usable loop:
  create,
  rename/edit metadata,
  delete,
  set cover,
  add photo to memory,
  remove photo from memory.
- Expose an "Add to Memory" action from focused photo surfaces such as the viewer/detail inspector so memories are manageable from normal browsing flows.
- Preserve package boundaries:
  data-model/database/app/IPC changes belong in shared and main layers,
  page/view composition belongs in renderer/UI layers.

### 4.8 Geospatial Browse and Map View Phase

- Add a dedicated product phase to turn GPS metadata into a first-class browsing dimension rather than treating location as a passive metadata field.
- Extend the local data model with place-oriented projections derived from photo GPS metadata:
  normalized latitude/longitude buckets,
  place-group summaries,
  viewport query helpers,
  and optional cached reverse-geocode labels for higher-quality place cards later.
- Introduce a new browse-mode model for the library surface:
  `waterfall`,
  `map`,
  and `timeline`,
  replacing the current implicit single gallery mode.
- Keep the existing grid/waterfall implementation as the default browse mode, but move it under an explicit browse-mode shell so the library page can switch views without duplicating filter/query state.
- Add a dedicated `Map View` rendered with the Gaode / AMap JavaScript API 2.0.
- Use GPS-bearing photos to render map markers or clustered overlays and allow viewport-driven browsing:
  click a marker/cluster/place-group to narrow the visible photo shelf,
  and keep selection synchronized between map results and photo results.
- Add a place-aggregation layer above raw points:
  at minimum city/area or distance-bucket grouping for photos with nearby coordinates,
  so the product can show “place groups” instead of only unstructured individual markers.
- Preserve a clean separation between raw EXIF GPS data and map-rendering coordinates:
  coordinate normalization/conversion logic belongs in shared/application layers,
  while Gaode-specific map rendering stays in the renderer/UI layer.
- Keep map access key handling and loader wiring isolated to the desktop renderer config/runtime rather than leaking them into business packages.
- Make the phase resilient to missing GPS:
  photos without coordinates remain visible in waterfall/timeline views,
  while map view shows a clear zero-state and count of mappable photos.

Recommended execution order:

1. Build the shared browse shell first
- Introduce `BrowseMode` and the renderer/page shell that can switch among `waterfall`, `map`, and `timeline`.
- Do this before map/timeline implementation so later views plug into one stable state model instead of creating parallel shells.

2. Add the geospatial foundation second
- Add domain/application/database support for GPS-bounded queries, mappable-photo counts, and place-group aggregation.
- Do this before map rendering so the map consumes a stable product-facing query layer rather than reaching into raw photo records directly.

3. Integrate Gaode map rendering third
- Add the renderer-only AMap loader and `MapView` after the browse shell and geospatial query layer exist.
- This keeps SDK-specific concerns from driving the shape of the data model.

4. Add timeline view last
- Implement timeline after browse-shell and shared query/state semantics are stable.
- Timeline depends on the same multi-mode shell, but does not need to block map delivery.

Implementation breakdown:

1. Geospatial domain and query foundation
- Add explicit geospatial browse types to `@chronopic/domain`, such as:
  `BrowseMode`,
  `GeoBounds`,
  `PlaceGroup`,
  and map/timeline query DTOs that do not depend on any map SDK.
- Add database/application query methods for:
  listing GPS-bearing photos inside bounds,
  counting mappable photos,
  and grouping nearby photos into place buckets.
- Keep first-pass place aggregation local and deterministic:
  use coordinate rounding / distance buckets rather than server-side reverse geocoding.

2. Renderer browse shell
- Refactor the current library browse surface so the main photo shelf is driven by an explicit browse mode:
  `waterfall`,
  `map`,
  `timeline`.
- Preserve the current filter/query model and selected-photo state while switching modes.
- Add a top-level mode switcher to the library browse page rather than creating separate disconnected pages.

3. Gaode map integration
- Integrate AMap JavaScript API 2.0 in the desktop renderer with a dedicated loader utility.
- Source references:
  Gaode JS API 2.0 overview and React guidance,
  point-cluster documentation,
  and coordinate-conversion utilities are documented in the official JS API 2.0 docs.
- Keep the Gaode key in renderer configuration/env only.
- Add a renderer-only `MapView` component that owns:
  map lifecycle,
  marker/cluster rendering,
  viewport events,
  and marker selection interactions.

4. Map-to-photo interaction loop
- Clicking a place group or marker should update the adjacent photo result shelf / current selection.
- Selecting a photo in the shelf should reflect back onto the map as an active marker or highlighted group where possible.
- The focused viewer should still open through the existing viewer pipeline rather than a map-specific detail flow.

5. Zero/edge states
- Map view must clearly explain:
  no GPS photos in current scope,
  current filter removes all mappable photos,
  or map failed to initialize because the API key/config is missing.
- Waterfall/timeline remain usable even when map view has no content.

### 4.9 Timeline View and Multi-Browse Shell Phase

- Add a dedicated phase to complete the browse split so `Library > Browse` is no longer synonymous with only the waterfall grid.
- Introduce a shared browse shell for the library page with stable state across:
  current query,
  favorites/memory filters,
  selection,
  and active browse mode.
- Implement a `Timeline View` that groups photos by date hierarchy:
  year,
  month,
  day,
  and optionally time segments for dense captures.
- Make the three browse modes first-class peers:
  `Waterfall View` for visual scanning,
  `Map View` for geographic exploration,
  and `Timeline View` for temporal exploration.
- Ensure transitions between browse modes preserve the same underlying result scope where possible:
  the user should be able to start from a search/filter/memory context and switch among waterfall, map, and timeline without losing that context.
- Add explicit empty/loading states per mode so the shell can explain why a mode has no content:
  no photos,
  no GPS-bearing photos,
  or no photos in the active time bucket.
- Keep viewer/detail interactions mode-agnostic:
  opening a photo from waterfall, map, or timeline enters the same focused viewing flow.

Recommended sequencing note:

- Even though this phase defines the final multi-browse shell, implementation should start by introducing the browse shell contract before map/timeline surfaces land.
- In practice the delivery order should be:
  browse shell contract first,
  then geospatial foundation,
  then map view,
  then timeline view.
- This avoids building timeline or map-specific state models that later need to be reconciled.

Implementation breakdown:

1. Shared browse shell contract
- Introduce a stable renderer-side browse-shell state model with:
  active browse mode,
  current filter,
  current selection,
  and mode-local UI state such as map viewport or expanded timeline groups.
- Keep cross-mode state explicit so waterfall/map/timeline are peers instead of separate ad hoc pages.

2. Timeline projection and grouping
- Add timeline grouping utilities in shared/application layers to bucket visible photos by:
  year,
  month,
  and day.
- Keep the first implementation deterministic and local:
  use persisted `metadata.datetime` and existing fallback timestamps.

3. Timeline renderer
- Add a dedicated `TimelineView` to the UI package or renderer shell.
- Render grouped sections with:
  sticky period headers where appropriate,
  dense photo strips/cards,
  and empty states for sparse or missing timeline data.

4. Multi-mode transitions
- Switching among waterfall/map/timeline should preserve the same logical result scope whenever possible.
- Map mode may additionally constrain by viewport, but the base query/filter must remain understandable and reversible when returning to waterfall/timeline.

5. UX completion
- Add clear mode labels and onboarding copy so users understand why they would use each browse mode.
- Ensure the home/library information architecture still feels coherent after browse becomes a multi-mode surface rather than a single grid.

Current local implementation status:

- The shared browse shell is landed.
- The geospatial foundation and the first renderer-owned Gaode `Map View` are landed, including viewport-aware place-group refresh.
- The first `Timeline View` is also landed:
  timeline groups are projected from persisted `metadata.datetime`,
  exposed through the app/IPC bridge,
  and rendered as grouped monthly sections that reuse the existing selection, favorite, add-to-memory, and viewer flows.
- Remaining work in this area is now polish-oriented:
  richer cross-mode transition behavior,
  deeper timeline hierarchy if needed,
  and multi-browse UX refinement.

### 4.10 UI/UX Redesign Phase

- Add a dedicated redesign phase to bring the product closer to a calm, collection-first photo workspace rather than a dashboard-like tool surface.
- Use [DESIGN.md](./DESIGN.md) as the normative design-direction document for this phase.
- Treat this phase as a deliberate visual and interaction redesign,
  not a backend or product-scope expansion.

Design goals:

- make the home screen feel memory-first and editorial
- reduce dashboard-like chrome and control density
- unify the browse shell across `waterfall`, `map`, and `timeline`
- strengthen featured-memory presentation
- keep navigation quiet and content dominant

Primary redesign targets:

1. Sidebar redesign
- Simplify the sidebar into a quiet navigation rail with stable global destinations:
  `All Photos`,
  `Favorites`,
  `Recent`,
  `Settings`,
  and memory / collection links.
- Move the create-memory affordance into a low-emphasis anchored action near the bottom.
- Avoid heavy stats or management surfaces in the navigation column.

2. Highlights / Recent Memories redesign
- Redesign the top memory row into a more cinematic highlights strip with large featured cards.
- Each memory card should prioritize:
  cover imagery,
  title,
  media count,
  and relative update time.
- Keep a create-new tile in the row, but make it visually secondary to real memories.

3. Browse Library shell redesign
- Redesign the library section into a cleaner shared shell:
  title,
  browse-mode switcher,
  total result count,
  search input,
  and secondary filter action.
- Reduce the perception of stacked toolbars and nested panels.
- Make `waterfall`, `map`, and `timeline` feel like peers under one browse surface rather than independent sub-pages.

4. Waterfall / Map / Timeline visual alignment
- Align spacing, headings, contextual scope messaging, and selected-photo callouts across all three browse modes.
- Keep each mode’s specialized surface intact,
  but ensure the shell and supporting affordances read as one product language.

5. Visual-system refinement
- Move toward a spacious editorial layout with softer surfaces, quieter chrome, and stronger image-led hierarchy.
- Prefer spacing, grouping, and typography before adding more borders or panels.

Technical implementation approach:

1. Document-first redesign guardrails
- `DESIGN.md` defines the redesign principles, screen intent, and component expectations.
- Implementation should reference that document rather than improvising screen-by-screen style changes.

2. Preserve architecture boundaries
- Keep renderer-only concerns in `apps/desktop/renderer`, especially:
  page composition,
  browse shell orchestration,
  and AMap lifecycle.
- Keep reusable design-system and shared UI pieces in `@chronopic/ui-components`.
- Do not move business logic, persistence logic, or SDK-specific behavior into shared UI packages just to simplify styling.

3. Token and component refinement
- Evolve the existing `shadcn`-based component layer rather than replacing it wholesale.
- Refine shared components such as:
  sidebar items,
  memory cards,
  browse mode switcher,
  search input,
  selected-context callouts,
  and browse section framing.

4. Renderer shell restructuring where needed
- Allow the renderer home shell to be re-composed if needed to match the redesign direction,
  but preserve:
  existing page model,
  browse-mode model,
  viewer model,
  and current IPC-backed actions.

5. Validation expectations
- Keep `pnpm typecheck` and `pnpm build` green throughout redesign work.
- Validate that redesign changes do not regress:
  memory navigation,
  browse-mode switching,
  viewer opening,
  add-to-memory flows,
  and settings/library access.

Current local implementation status:

- `DESIGN.md` is landed and defines the redesign direction and constraints.
- The redesign pass is now landed across both the home/library shell and the primary browse experience:
  header chrome is quieter,
  the sidebar is moving toward a calmer navigation rail,
  recent memories are being reframed as a cinematic highlights row,
  the browse-library heading/search/switcher area has been restructured to match the new editorial layout direction,
  filters now default to a collapsed state,
  duplicate browse headings have been removed,
  and waterfall cards are now substantially more image-first.
- Core behavior remains unchanged:
  the redesign work is still limited to renderer/UI composition and presentation rather than business-logic expansion.

Current AI phase status:

- Semantic storage is now split between user-authored and AI-generated fields.
- A real `Vercel AI SDK` + OpenAI-compatible provider path is landed behind `services-ai-pipeline`.
- Desktop runtime supports single-photo manual enrichment from the viewer inspector.
- Batch enrichment orchestration is now also landed:
  pending/failed photos can be processed through a queue action,
  queue stats are exposed to the renderer,
  and the home shell now surfaces an AI queue action bar when enrichment work remains.
- Business/application and infra package test coverage has been expanded alongside the AI work.

### 4.11 AI and Semantic Enrichment Phase

- Promote the currently deferred AI layer into a real product capability instead of leaving semantic fields permanently disabled.
- Keep the existing package boundaries:
  provider integration belongs behind `services-ai-pipeline`,
  orchestration belongs in shared/application and main-process layers,
  and renderer/UI only consumes product-facing outputs and processing state.
- Add a real `AIClient` implementation contract for:
  caption generation,
  keyword/tag suggestion,
  and concise semantic summary generation for photos and memories.
- Extend the enrichment pipeline so photos can transition through explicit semantic states:
  `pending`,
  `processing`,
  `completed`,
  `failed`,
  `disabled`.
- Persist AI-generated outputs separately from user-authored edits where possible so:
  user captions/tags are not overwritten,
  AI outputs remain replaceable or re-runnable,
  and provenance is visible in the data model.
- Use enrichment outputs to strengthen downstream product surfaces:
  search,
  memory creation/support,
  browse hints,
  and future discovery features.
- Keep first-pass AI enrichment local-first in product semantics even if a remote provider is used:
  the product should behave as an indexed desktop library with enrichment status,
  not as an online-only query UI.

Implementation breakdown:

1. Semantic data-model completion
- Audit and extend `Semantic` / related persistence fields so the app can store:
  generated caption,
  generated tags,
  summary/scene description,
  enrichment timestamps,
  provider/model metadata,
  and last-error state.

2. Real AI provider integration behind the existing abstraction
- Replace the disabled default path with a real provider-backed implementation while keeping the `AIClient` boundary stable.
- Allow the provider to be configured via desktop/runtime config rather than leaking SDK concerns into renderer UI modules.
- Add a product-visible configuration surface in `Library Settings` so local desktop users can set:
  base URL,
  model,
  provider name,
  and API key without relying only on process environment variables.
- Persist those settings locally and reload the desktop runtime after save so AI capability can be enabled/disabled from the product surface itself.

3. Enrichment orchestration
- Add application/service flows to enqueue and process semantic enrichment for:
  newly indexed photos,
  manually re-run photos,
  and later memory-level synthesis where needed.
- Keep retry/error handling explicit and visible in persisted state.

4. Product-surface integration
- Surface AI-generated caption/tags/summary in photo detail and related browsing/search surfaces.
- Extend AI synthesis to the memory surface as non-destructive suggestions:
  generate memory title/summary/tags without overwriting user-authored name/description by default,
  and let the renderer explicitly apply those suggestions when desired.
- Keep user edits distinct from generated fields and avoid destructive overwrite semantics.

5. Validation expectations
- Keep `pnpm typecheck` and `pnpm build` green.
- Verify enrichment state transitions, storage semantics, and non-destructive coexistence with user edits.
- Add unit-test coverage for both business-logic and infrastructure packages that participate in the AI phase:
  at minimum the application/service orchestration layer and the relevant infra package surface should gain regression tests alongside the implementation.

Current landed scope:

- Photo-level AI enrichment is implemented with:
  generated caption/tags/summary,
  queue stats,
  batch processing,
  and search/filter integration.
- Memory-level AI synthesis is implemented as suggestion-only metadata:
  generated title,
  generated summary,
  and generated tags are stored separately from manual memory fields and can be applied explicitly from the UI.
- AI provider configuration is implemented in-product through `Library Settings`,
  backed by local persisted config and runtime reload on save rather than requiring env-only startup.
- Gaode map configuration is also implemented in-product through `Library Settings`,
  backed by local persisted config with renderer-side fallback to env vars for development setups.
- Map browse runtime polish continues to be allowed inside the redesign/search groundwork as long as it preserves the current shared browse shell and renderer-owned map integration boundaries.
- Shared browse/notification UI should tolerate temporarily unavailable queue state during hydration or hot reload rather than assuming AI queue stats are always present on first render.
- Dialog-driven product surfaces should keep Radix accessibility requirements satisfied and avoid effect dependencies on unstable callback props, especially around memory editing flows.
- `4.12` is now started with a shared discovery-query foundation and broader text-search coverage that includes linked memory metadata in addition to photo semantic fields.
- The renderer is now beginning to consume `DiscoveryQuery` as an explicit search-state model rather than treating free-text search as only a raw `PhotoFilter.query` mutation.

### 4.12 Search and Discovery Phase

- Expand search from path/tag filtering into a broader discovery system backed by time, location, memory, and semantic enrichment data.
- Preserve one shared browse context across waterfall/map/timeline while allowing richer search queries to drive all three views.
- Add stronger query capabilities such as:
  semantic text search,
  memory-aware search,
  place-aware search,
  and timeline-aware discovery pivots.
- Keep search semantics product-facing and stable:
  renderer/UI consumes query DTOs and result projections,
  while ranking/filter composition lives in shared/application layers.
- Use this phase to make map/timeline/waterfall feel like coordinated discovery lenses rather than separate browsing silos.

Implementation breakdown:

1. Unified discovery query contract
- Consolidate the current ad hoc browse/search filters into a clearer shared discovery query model.
- Keep one shared query context for:
  waterfall,
  map,
  timeline,
  favorites,
  memories,
  and semantic search.
- Preserve compatibility with the current `PhotoFilter`-driven list flow while making the search surface easier to evolve.

2. Semantic search expansion
- Make free-text search explicitly hit:
  generated caption,
  generated labels,
  summary,
  manual caption,
  manual labels,
  and relevant memory metadata.
- Keep query behavior stable and inspectable rather than introducing opaque ranking too early.

3. Place-aware and memory-aware discovery
- Allow discovery flows to pivot more naturally across:
  places,
  memories,
  and timeline groupings.
- Keep map/timeline views driven by the same query state rather than inventing separate search models per browse mode.
- The browse shell now includes direct discovery pivots so the current result scope can jump into:
  `Map View`,
  `Timeline`,
  `Browse Memories`,
  or the current memory detail page without rebuilding the query manually.

4. Discovery UX completion
- Improve the renderer search surface so users can understand:
  what is being searched,
  why a result matched,
  and what scope is currently active.
- Favor strong context/explanation over premature recommendation widgets.
- The renderer now also shares discovery-context messaging across waterfall, map, and timeline so current scope and semantic-search conditions are explained consistently instead of being reimplemented per browse mode.
- Discovery surfaces now expose match-source explanations for the selected photo and inspector so the user can see which fields or linked memory metadata caused the current result to match the active query.
- Discovery/runtime UX must degrade safely when the Electron preload bridge is unavailable, showing a clear desktop-bridge error state instead of crashing the renderer during initial hydration.

### 4.13 Memory Authoring and Storytelling Phase

- Turn memories from static containers into authoring surfaces that help users shape a narrative.
- Keep manual authoring as the source of truth:
  generated title/summary/tags remain suggestions until explicitly applied,
  and manual description editing stores Markdown source directly before rendering it in the detail view.
- Add a story outline derived from the memory's current photos so the detail page exposes:
  chronological chapters,
  chapter cover images,
  photo counts,
  GPS availability,
  and AI-readiness signals.
- Keep this pass deterministic and local:
  no new remote model call is required to view the story outline,
  and no new database ordering model is introduced before the product proves the authoring flow needs manual chapter editing.

Current landed scope:

- `MemoryDetailPage` now includes a `Story Outline` section between the memory hero and management controls.
- `buildMemoryStorySections()` groups memory photos into chronological chapters using photo datetime first and photo update time as fallback ordering.
- Each chapter has a representative thumbnail, date range, photo count, mapped-photo count, and AI-ready count.
- Clicking a chapter lead opens the existing focused detail viewer for that representative photo, preserving the current viewer/gallery flow instead of introducing a parallel story player before the chapter model needs dedicated playback controls.
- Regression coverage now verifies chapter grouping and section metrics.
- Memory descriptions now use a Markdown-source contract:
  the database stores the raw Markdown string,
  `@uiw/react-md-editor` edits that same Markdown string,
  and the read view renders Markdown instead of displaying source text or persisting HTML.
- Memory title and description editing now use direct-manipulation entry points:
  clicking the title opens the title editor,
  clicking the description surface opens the Markdown editor,
  and each editor exposes a magic action that reuses the existing memory AI suggestion pipeline to generate empty content or optimize existing drafts before the user explicitly saves.
- AI optimize actions now pass the current unsaved editor draft into the memory AI pipeline as prompt context, so optimizing a title or description refines the user's current text instead of regenerating only from the last saved memory data.

### 4.14 Advanced Discovery Phase

- Make discovery more action-oriented without reintroducing noisy explanatory chrome.
- Keep one shared browse query model across waterfall, map, and timeline.
- Add lightweight discovery pivots that can move the current scope toward:
  favorites,
  mapped photos,
  AI-ready / needs-AI subsets,
  top tags,
  map view,
  timeline view,
  and existing memories.
- Keep suggestions deterministic and inspectable:
  suggestions are derived from visible records, place groups, memories, and the current filter,
  not from opaque recommendation ranking.

Current landed scope:

- `DiscoveryLensStrip` now renders a compact `Discover` chip row under the browse controls.
- `buildDiscoverySuggestions()` derives actionable pivots from the current result scope.
- Suggestion actions patch the existing `PhotoFilter`, switch the existing `BrowseMode`, or open the existing memory detail route.
- Regression coverage verifies GPS, favorites, map, tag, and memory suggestions.

### 4.15 AI Memory Auto-Grouping Phase

- Add an explicit AI-assisted memory creation flow that can propose new memories from the local photo library.
- The product goal is to let ChronoPic discover coherent memory candidates without requiring the user to manually select every photo first.
- Candidate grouping should use available local signals in layers:
  GPS proximity and place clusters,
  timeline proximity,
  AI-generated captions/summaries/tags,
  manually edited captions/tags,
  and future face/person signals when a dedicated person-recognition pipeline exists.
- Similar people should be treated as a future-capable grouping dimension, but the first implementation must not pretend to recognize identities unless the underlying model/pipeline actually emits person clusters.
- Proposed memories must be reviewable before they become real memories:
  show candidate title,
  reason for grouping,
  confidence,
  representative cover,
  photo count,
  and included photos.
- Generated memories should preserve the current memory semantics:
  AI suggestions are non-destructive,
  user-created/accepted memories remain editable,
  and users can reject or adjust candidates before saving.
- The first implementation should avoid opaque magic:
  persist candidate/proposal state separately from accepted memories,
  expose why a group was suggested,
  and avoid silently adding photos to existing memories unless explicitly accepted.

Implementation breakdown:

1. Candidate model and persistence
- Add a memory-candidate projection distinct from accepted `Memory`.
- Track candidate source signals such as:
  `place`,
  `time`,
  `semantic`,
  `person`,
  and `mixed`.
- Store candidate confidence, reason text, representative photo, suggested title/description/tags, and ordered photo IDs.
- Keep rejected/accepted candidate state so the app does not repeatedly propose the same group.

2. Grouping service
- Add a business/service-layer generator that can create candidates from:
  place groups,
  timeline groups,
  semantic labels/summaries,
  and AI model synthesis.
- Start with deterministic pre-clustering from GPS/time/semantic tags before invoking the multimodal model for naming and explanation.
- Use the Vercel AI SDK provider already configured in `4.11` for candidate naming/summary, not a separate model integration path.

3. Review and accept UI
- Add a `Suggested Memories` surface under Memories.
- Each candidate should show:
  cover,
  title,
  grouping reason,
  confidence,
  and a preview strip.
- User actions:
  accept as memory,
  reject,
  edit title before accept,
  remove photos from candidate before accept,
  and open candidate detail.

4. Acceptance semantics
- Accepting a candidate creates a normal editable `Memory` and links its photos through the existing memory-photo relationship.
- Rejected candidates remain suppressed unless the underlying photo set materially changes.
- Existing memories should be considered during grouping so the generator avoids duplicating a user-curated memory unless explicitly requested.

Current landed scope:

- Added a persisted `memory_candidates` projection separate from accepted `memories`.
- Candidate records now store:
  stable signature,
  title,
  description,
  reason,
  confidence,
  source signal,
  status,
  photo IDs,
  cover photo,
  generated labels,
  and accepted-memory linkage.
- Added deterministic candidate generation in the application layer from:
  GPS/place proximity,
  month/time grouping,
  and manual/AI semantic labels.
- Existing accepted memories are considered during candidate generation so exact duplicate photo sets are not proposed again.
- Added IPC/preload/renderer wiring for:
  listing candidates,
  generating candidates,
  accepting a candidate as a real editable memory,
  and rejecting a candidate.
- Memories page now includes a `Suggested Memories` review panel with:
  generate action,
  editable candidate title,
  reason/confidence display,
  labels,
  cover,
  photo-count preview,
  per-candidate photo removal before acceptance,
  accept,
  and reject.
- Accepted candidates create normal `Memory` records with source `ai` and existing `memory_photos` links.
- Regression coverage now verifies:
  schema support for candidates,
  service-level candidate generation from place/time/semantic signals,
  and accept/reject persistence boundaries.

### 4.16 Memory Candidate Queue and Notifications Phase

- Close the feedback loop for AI memory candidates so users know when candidate memories are ready to review.
- Keep the same confirmation rule from `4.15`:
  automatic candidate generation may create pending suggestions,
  but it must never create accepted memories without user action.
- Trigger candidate refresh after user-driven library scans so newly indexed photos can surface as suggestions without requiring the user to discover the Generate button manually.
- Surface pending candidate count in:
  the sidebar notification badge,
  the Notifications page,
  and the Memories page.
- Keep candidate notifications separate from photo AI enrichment:
  photo AI queue handles metadata generation,
  memory candidate queue handles reviewable memory proposals.

Implementation breakdown:

1. Scan-triggered candidate refresh
- After `Scan Library` completes, generate or refresh memory candidates.
- Refresh candidate state in the renderer after scan, acceptance, rejection, and manual generation.
- The scan flow should report candidate availability in the status message without implying memories were automatically created.

2. Notification integration
- Include pending memory-candidate count in the sidebar notification badge.
- Add a Notifications card that explains how many suggested memories are waiting for review.
- Provide a direct action from Notifications to refresh/generate suggestions.

3. Memories page readiness
- Show a clear `X suggested memories ready` affordance above or inside the Suggested Memories surface.
- Preserve the existing review UI and explicit accept/reject semantics.

Current landed scope:

- `Scan Library` now refreshes memory candidates after the scan finishes.
- Scan completion status now tells the user whether suggested memories are ready.
- Sidebar notification badge now includes pending memory candidates in addition to the photo AI queue.
- Notifications page now has a dedicated `Memory Candidates` card with pending count and a refresh action.
- Memories page now displays `X suggested memories are ready for review` inside the Suggested Memories surface.
- Candidate generation still only creates pending review items; accepted memories are created only through explicit user acceptance.

Priority order from this point forward:

1. `4.18 UX Refine and Lazyweb Research Phase`
2. `4.19 Runtime QA and Release Readiness Phase`
3. `4.20 First-Run and Onboarding UX Phase`
4. `4.21 Guided Onboarding Completion Phase`
5. `4.22 Accessibility and Keyboard Audit Phase`
6. `4.23 Export, Backup, and Restore Phase`
7. Evaluate the remaining future product backlog below only after backup/restore is verified.

Recently completed product-expansion sequence:

1. `4.11 AI and Semantic Enrichment Phase` ✅
2. `4.12 Search and Discovery Phase` ✅
3. `4.13 Memory Authoring and Storytelling Phase` ✅
4. `4.14 Advanced Discovery Phase` ✅
5. `4.15 AI Memory Auto-Grouping Phase` ✅
6. `4.16 Memory Candidate Queue and Notifications Phase` ✅
7. `4.17 Internationalization and AI Output Locale Phase` ✅

### 4.17 Internationalization and AI Output Locale Phase ✅

- Add first-class i18n rather than continuing to hard-code UI strings in renderer and UI components. ✅
- Introduce `@chronopic/i18n` as a strict package-boundary friendly TypeScript package: ✅
  typed locale IDs,
  typed translation keys,
  English and Simplified Chinese resource files,
  fallback behavior,
  interpolation,
  and shared date/count formatting helpers.
- Persist language settings in desktop configuration: ✅
  `locale` controls the UI language,
  `aiOutputLocale` controls generated AI content language,
  and `aiOutputLocale` defaults to following the UI locale unless explicitly changed.
- Add a Language section to Library Settings so users can switch UI language and AI output language without restarting the app. ✅
- Wire React UI through an `I18nProvider` / `useI18n()` API owned by `@chronopic/ui-components`, while keeping persistence and runtime settings in the desktop app/config layers. ✅
- Translate the initial critical path first: ✅
  Sidebar,
  Header/Search,
  Library Settings language controls,
  Notifications,
  Memory list/detail,
  and the main browse mode controls.
- Extend AI semantic enrichment prompts to accept an output locale and require `generatedName`, `generatedDescription`, labels, captions, summaries, and memory suggestions to be emitted in that locale. ✅
- Keep AI suggestions non-destructive: ✅
  locale changes affect future generated suggestions only,
  and generated content remains suggestions until explicitly applied.
- Add lightweight E2E coverage for language switching: ✅
  switch to Simplified Chinese in settings,
  verify Sidebar key text changes,
  verify Header/Search key text changes,
  open Memory Detail,
  and verify Memory Detail key text changes.
- Add unit coverage for translation key completeness, interpolation, fallback behavior, and locale normalization. ✅

Current landed scope:

- `@chronopic/i18n` is a standalone workspace package with typed locales, typed keys, fallback interpolation, locale normalization, AI output-locale resolution, and date/count helpers.
- Desktop config now persists `locale` and `aiOutputLocale`; main/preload expose `system:getLocaleSettings` and `system:saveLocaleSettings`.
- The renderer is wrapped in `I18nProvider`, and Library Settings exposes UI language plus AI output language controls.
- The initial visible path is translated across Sidebar, browse mode switcher, search placeholder, memory creation, memory detail, and language/settings surfaces.
- Photo AI enrichment, pending AI queue enrichment, and memory AI enrichment now pass the resolved output locale into prompt construction.
- Unit coverage is added in `tests/i18n.test.ts`, and app-service tests verify photo and pending AI output-locale context is forwarded.
- Lightweight Electron E2E coverage is added in `tests/e2e/i18n.spec.ts`; it expects the dev renderer to be available on `http://localhost:5173`, matching the existing E2E smoke-test model.
- Follow-up coverage audit expanded translations beyond the initial path to include filter toolbar, photo cards, add-to-memory menu, viewer overlays, memory list/recent/detail/story/suggestions, metadata/edit controls, notifications, map, timeline, gallery, photo grid, detail panel, discovery helper text, transient app status/toast messages, and legacy exported fallback components.
- A stricter second audit explicitly covered browse toolbar controls such as `Select` / `Filter`, `TagInput` accessibility labels, AI settings placeholders, exported `HomeStats` fallback copy, and the remaining memory delete icon label.
- Memory story chapters now keep raw month/date range data and format titles/subtitles at render time with the active UI locale, so chapter dates no longer stay in English after switching to Chinese.
- The remaining renderer scan hits are technical constants/placeholders rather than untranslated user-facing UI copy:
  timeline translation keys,
  browse/router state ids,
  status severity ids,
  an AMap technical error code,
  and AI provider/model/API example placeholders.

### 4.18 UX Refine and Lazyweb Research Phase

- Add a dedicated UX refinement phase before runtime QA so the product can be evaluated visually and interactionally after the broad product-expansion sequence has landed.
- Use Lazyweb as the research source of record for this phase rather than relying only on internal taste or isolated screenshots.
- The goal is to identify concrete improvements for ChronoPic's current desktop UX:
  home/library shell,
  browse modes,
  memory list/detail,
  AI suggestions,
  notifications,
  settings,
  first-run states,
  and dense photo-management actions.
- This phase should produce research artifacts first, then a prioritized refinement plan, then scoped implementation work.
- Do not use this phase to add new product capabilities; it is about improving clarity, hierarchy, ergonomics, and visual consistency of existing surfaces.

Implementation breakdown:

1. Capture current product state
- Run the current desktop app or dev renderer and capture representative screens:
  empty library,
  populated library waterfall,
  map browse,
  timeline browse,
  memory list,
  memory detail,
  suggested memories,
  notifications,
  library/settings,
  and focused photo viewer.
- Save current-state screenshots under the Lazyweb research directory so external references can be compared against the actual product.
- If the app cannot be launched, record the blocker and use the best available built renderer screenshots, but do not skip the current-state section.

2. Lazyweb design research
- Use `lazyweb-design-research` for a desktop-focused research pass.
- Search for photo-library, memory/album, asset-management, AI suggestion, notification, and settings patterns across direct and adjacent products.
- Prioritize references from products with strong collection-management UX, such as:
  Apple Photos,
  Google Photos,
  Lightroom,
  Notion-style structured authoring,
  Linear-style calm operational surfaces,
  and other high-quality desktop/web collection tools.
- Save research output to:
  `.lazyweb/design-research/chronopic-ux-refine-YYYY-MM-DD/report.md`,
  `.lazyweb/design-research/chronopic-ux-refine-YYYY-MM-DD/report.html`,
  and referenced screenshots under that report's `references/` directory.
- The report must distinguish between:
  direct findings that should change ChronoPic,
  interesting but nonessential inspiration,
  and patterns that should be rejected because they conflict with ChronoPic's local-first desktop workflow.

3. UX audit and issue inventory
- Compare Lazyweb findings with ChronoPic's current surfaces.
- Produce a prioritized issue inventory covering:
  information hierarchy,
  action density,
  duplicated controls,
  unclear empty states,
  mode-switching discoverability,
  memory authoring ergonomics,
  AI affordance prominence,
  notification usefulness,
  and settings/configuration clarity.
- Classify each issue as:
  `must fix before runtime QA`,
  `should fix before onboarding`,
  or `backlog`.
- Keep findings grounded in screenshots, file paths, or specific app surfaces rather than generic UX preferences.

4. Scoped refinement implementation
- Implement only the top `must fix before runtime QA` items in this phase.
- Likely implementation areas are renderer/UI only:
  `packages/ui-components/src/*`,
  `apps/desktop/renderer/src/app/*`,
  `apps/desktop/renderer/src/styles.css`,
  and i18n keys if visible copy changes.
- Preserve existing app/service/IPC/data contracts unless the research uncovers a clear interaction bug that cannot be fixed at the presentation layer.
- Keep changes small enough that runtime QA can still follow immediately after this phase.

5. Validation and documentation
- Re-run:
  `pnpm typecheck`,
  `pnpm test`,
  and `pnpm build`.
- Update `DESIGN.md` if the research changes durable design guidance.
- Update `AGENTS.md` after the research pass and again after each meaningful implementation slice.

Acceptance expectations:

- Lazyweb research artifacts are saved locally and linked from `AGENTS.md`.
- A prioritized UX issue inventory exists before implementation starts.
- Top-priority refinements are implemented without widening business/package boundaries.
- `pnpm typecheck`, `pnpm test`, and `pnpm build` pass after implementation.
- Remaining UX ideas are either moved into `4.20 First-Run and Onboarding UX Phase` or left in the Future Product Backlog.

Current status:

- Landed first pass on 2026-05-06.
- Current-state screenshots, picsum-based fixture imagery, capture notes, and the UX report are saved under:
  `.lazyweb/design-research/chronopic-ux-refine-2026-05-06/`.
- Lazyweb MCP tools were not exposed as callable tools in the current Codex runtime, so the phase used the installed Lazyweb skill structure plus fallback web research sources and local current-state screenshots.
- The prioritized issue inventory identified first-run/empty-library guidance as the top `must fix before runtime QA` item.
- The top refinement has landed in the UI layer: home now shows a first-run panel with `Add Folder` when no sources exist and `Scan Library` when sources exist but no photos are indexed.
- Remaining lower-priority findings are tracked in the report backlog.

### 4.19 Runtime QA and Release Readiness Phase

- Add a dedicated quality and release-readiness phase before any new major product feature work.
- The product surface is now broad enough that typecheck/unit/build validation is not sufficient by itself:
  AI enrichment,
  memory candidates,
  map/timeline browse,
  Markdown memory authoring,
  i18n,
  and incremental scan behavior all depend on real Electron runtime paths.
- The phase goal is to prove the first usable desktop loop end to end with a real preload bridge, temporary app data, SQLite persistence, fixture media, and packaged/development launch paths.
- This phase should not add major product scope unless a runtime defect requires a targeted UX correction.

Implementation breakdown:

1. Real Electron integration harness
- Add an E2E harness that launches the Electron app with:
  a temporary user-data directory,
  a controlled fixture library,
  isolated SQLite/config/cache paths,
  and deterministic cleanup between tests.
- Cover preload-backed flows instead of relying only on a browser-rendered Vite page where `window.chronoPic` is unavailable.
- Keep the existing lightweight Playwright smoke tests, but treat the new Electron integration suite as the acceptance path for runtime behavior.

2. Fixture library and critical workflows
- Add small deterministic fixture media for integration tests:
  normal image,
  duplicate or same-content image if practical,
  image without GPS,
  GPS-bearing image if a stable fixture can be created,
  and an EXIF-light or timestamp-fallback case.
- Verify the critical first-user loop:
  add library source,
  scan library,
  browse imported photos,
  open detail/gallery viewer,
  favorite/unfavorite,
  create memory,
  add/remove photos from memory,
  edit caption/tags/datetime,
  rollback latest edit,
  switch locale,
  and reload the app to verify persisted state.

3. AI, memory-candidate, and configuration smoke coverage
- Use test doubles or disabled-provider paths for deterministic CI validation.
- Verify configuration persistence for:
  AI provider settings,
  AI output locale,
  UI locale,
  and Gaode/AMap settings.
- Verify queue and candidate surfaces do not crash when provider configuration is absent, disabled, or temporarily unavailable.

4. CI and verification commands
- Add a repository CI entrypoint once the test split is clear.
- Required CI baseline should include:
  `pnpm install`,
  `pnpm test`,
  `pnpm typecheck`,
  and `pnpm build`.
- Electron E2E may be a separate job or manually triggered job if native display/runtime setup makes it too expensive for the default path.
- Keep package-boundary validation intact: CI must continue to build packages through declared exports rather than source aliases.

5. README and developer handoff
- Add a root `README.md` that documents:
  product purpose,
  local setup,
  launch commands,
  verification commands,
  AI provider configuration,
  AMap configuration,
  data/storage behavior,
  and known out-of-scope items.
- Keep `PLAN.md`, `AGENTS.md`, and `DESIGN.md` as deeper implementation and design references rather than forcing new contributors to read them first.

Acceptance expectations:

- `pnpm test`, `pnpm typecheck`, and `pnpm build` remain green.
- A documented Electron integration command exists and verifies at least the core scan/browse/edit/memory/locale persistence loop.
- README gives a new developer a stable path to install, launch, configure, and verify the desktop app.
- Any runtime defects found during this phase are fixed narrowly and recorded in `AGENTS.md`.

Current status:

- Landed first pass on 2026-05-06.
- Added runtime path isolation through `CHRONOPIC_USER_DATA_DIR` so Electron QA can use a disposable database, settings file, thumbnail cache, and debug log.
- Fixed a production desktop launch defect by making Vite emit relative renderer asset paths for Electron `loadFile()`.
- Fixed new empty-database initialization by applying schema before migrations.
- Added an Electron-native thumbnail generator for the desktop main process so runtime scanning no longer depends on a Node-ABI `sharp` build inside Electron.
- Added `tests/e2e/runtime.spec.ts` plus `pnpm run e2e:runtime` to verify the core preload/IPC/SQLite loop:
  add source,
  scan fixtures,
  edit caption/tags/datetime,
  rollback,
  favorite,
  create memory,
  add photo to memory,
  persist locale,
  restart,
  and verify state is still present.
- Added `docs/agent-verification-script.md` as an agent-oriented Playwright director script for broader manual/agent confidence checks beyond the rigid E2E suite.
- The director script tells future agents to use Playwright after completed plan slices, choose scenes based on the affected flow, verify first-run onboarding, scan/browse, viewer, editing/favorites/rollback, memories, settings, notifications, and restart persistence as applicable, and record evidence in `AGENTS.md`.
- Added root `README.md` and `.github/workflows/ci.yml` with test, typecheck, build, and runtime E2E coverage.

### 4.20 First-Run and Onboarding UX Phase

- Add a focused onboarding phase after runtime QA rather than adding another broad feature surface immediately.
- The current product has enough capabilities that a first-time user needs a guided path through the local-first loop.
- Keep onboarding product-native and dismissible:
  it should help the user start using ChronoPic, not behave like a marketing landing page.

Recommended scope:

1. Empty-library first run
- Show a clear empty state for a new install with no registered library.
- Primary action should be adding a folder.
- Secondary actions should point to language/settings and optional AI/map configuration.

2. Guided scan and first results
- After adding a folder, guide the user to run `Scan Library`.
- During scan, show progress and explain that ChronoPic is indexing local files and generating thumbnails.
- After scan, route the user toward browse, favorites, and memory creation without adding blocking tutorial steps.

3. Optional capability setup
- Surface AI enrichment and map setup as optional enhancements.
- Make missing API keys understandable without making the product feel broken.
- Keep manual scan as the explicit sync model; do not reintroduce realtime file watching.

4. First memory workflow
- Help the user create or accept a first memory once enough photos exist.
- If AI memory candidates are available, show the review workflow.
- If no candidates exist, guide toward manual selection and memory creation.

Acceptance expectations:

- First-run state is understandable with zero photos, zero memories, no AI provider, and no map key.
- A new user can complete:
  add folder,
  scan,
  view photos,
  create or review a memory,
  and return to normal browsing.
- Existing users with libraries should not be interrupted by onboarding.

Current status:

- Landed first pass on 2026-05-06.
- The empty-library and registered-but-unscanned first-run states now have a product-native setup panel instead of a generic "no media matches filters" result.
- Existing users with indexed photos are not interrupted because the panel only appears when there are no sources or no indexed photos.
- Deeper guided memory onboarding is promoted to `4.21 Guided Onboarding Completion Phase`.

### 4.21 Guided Onboarding Completion Phase

- Complete the product-native onboarding path after the first successful scan.
- Keep the flow non-blocking and embedded in the home surface rather than adding modal tours or marketing-style pages.
- The goal is to help a new user move from indexed photos to the first meaningful library actions:
  browsing,
  selecting,
  favoriting,
  creating or reviewing a memory,
  and optionally configuring AI/map settings.

Implementation breakdown:

1. Post-scan next steps
- When indexed photos exist but no memories exist yet, replace the empty Recent Memories card with a compact next-step panel.
- The panel should explain that the library is ready and offer clear next actions.
- Do not show this panel for established users with memories.

2. First memory path
- Primary action should open the existing Create Memory dialog.
- Secondary action should enter photo selection mode so the user can choose photos for a memory.
- If memory candidates exist, provide a route to the Memories review surface.

3. Optional setup path
- Provide a low-priority route to Library Settings for optional AI/map/language configuration.
- Optional setup must not make missing AI or map keys look like a product failure.

4. Verification
- Use `docs/agent-verification-script.md` because this is a user-facing runtime flow.
- Required scenes:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 6 - Memories,
  Scene 7 - Restart Persistence.
- Also run:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  and `pnpm run e2e:runtime`.

Acceptance expectations:

- A new user with indexed photos and zero memories sees a clear next-step panel instead of another empty memory card.
- The user can create a first memory from the home surface.
- The user can enter selection mode from the onboarding panel.
- If memory suggestions exist, the user can navigate to review them.
- Existing users with memories continue to see Recent Memories rather than onboarding.

Current status:

- Landed on 2026-05-06.
- The home surface now shows a guided next-step panel when photos are indexed and no memories exist.
- The panel provides actions for creating the first memory, selecting photos, reviewing suggestions when available, and opening optional setup.
- Existing users with memories continue to see the Recent Memories surface.

### 4.22 Accessibility and Keyboard Audit Phase

- Audit and harden the keyboard/focus paths that became important after the onboarding, memory, viewer, and Radix dialog/select work.
- Keep the phase focused on accessibility and keyboard behavior rather than broad visual redesign or new product capability.

Implementation breakdown:

1. Keyboard activation
- Photo cards must support keyboard selection and keyboard detail opening.
- Enter should open focused detail view.
- Space should activate the card's lightweight selection path.

2. Focus management
- Create Memory dialog should focus the memory-name input when opened.
- Closing the dialog with Escape should restore focus to the triggering control.
- Viewer dialog should close with Escape and leave the app in a usable focused state.

3. Accessible names and states
- Icon-only or compact controls must expose explicit accessible names.
- Select-for-batch controls must expose both an accessible name and pressed state.
- Thumbnail filmstrip items should expose useful names and selected state.

4. Runtime coverage
- Add a Playwright runtime accessibility spec for the core keyboard/focus path:
  first-run setup,
  post-scan onboarding,
  create-memory dialog focus return,
  photo-card Space/Enter behavior,
  viewer Escape close,
  and batch-select accessible names.
- Add a root script for the accessibility spec and include it in CI.

5. Verification
- Use `docs/agent-verification-script.md` because this is a user-facing runtime flow.
- Required scenes:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 4 - Focused Viewing,
  Scene 6 - Memories,
  Scene 7 - Restart Persistence.
- Also run:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:runtime`,
  and `pnpm run e2e:accessibility`.

Acceptance expectations:

- Create Memory dialog keyboard focus is predictable and returns to the trigger after Escape.
- Photo cards can be selected and opened from the keyboard.
- Viewer can be closed with Escape after keyboard opening.
- Batch selection controls are discoverable by role/name and expose selected state.
- Accessibility runtime coverage is available locally and in CI.

Current status:

- Landed on 2026-05-06.
- Added keyboard and accessible-state improvements for photo cards, batch selection, and filmstrip items.
- Added focus return for the controlled Create Memory dialog.
- Added `tests/e2e/accessibility.spec.ts`, `pnpm run e2e:accessibility`, CI coverage, and README documentation.

### 4.23 Export, Backup, and Restore Phase

- Add a first durable data-safety loop before packaged release or large-library usage.
- Keep this phase focused on ChronoPic's local projection:
  metadata edits,
  favorites,
  memories,
  memory-photo membership,
  generated AI fields,
  memory candidates,
  library source records,
  and local settings.
- Do not copy original media files or write EXIF sidecars in this phase.
  Original media remains referenced by path, and thumbnails can be regenerated by scanning.

Implementation breakdown:

1. Backup format and service boundary
- Define a versioned ChronoPic JSON backup format.
- Include:
  app identity,
  schema version,
  export timestamp,
  local AI/map/locale settings,
  library source records,
  photo projections,
  metadata,
  semantic/generated fields,
  index state,
  edit history,
  memories,
  memory-photo membership,
  and memory candidates.
- Keep the backup APIs in application/database/config boundaries rather than making renderer code query SQLite directly.

2. Restore preview and conflict reporting
- Add a dry-run preview that reports:
  source count,
  photo count,
  memory count,
  membership count,
  edit-history count,
  memory-candidate count,
  settings presence,
  and conflicts with the current library state.
- Detect conflicts for existing source paths, photo ids/paths, memory ids, and memory-candidate ids/signatures.
- Use the preview result before destructive restore from the product UI.

3. Restore execution
- Support restoring a backup into an empty desktop data directory.
- Support a replace-mode restore that swaps the local ChronoPic projection for the backup contents.
- Preserve user-visible authored data:
  captions,
  tags,
  corrected datetimes,
  favorites,
  memory metadata,
  memory covers,
  memberships,
  edit history,
  and settings.
- Keep restore scoped to the local projection; media files are not copied and EXIF is not modified.

4. Desktop bridge and settings UI
- Add main-process file handling for export, preview, and restore.
- Add preload bridge methods for the same operations.
- Add a Library Settings section with:
  `Export Backup`,
  `Preview Restore`,
  and `Restore Backup`.
- Make the UI text explicit that the backup is local JSON and does not copy originals.

5. Verification
- Add a Node integration test for service/database export and restore semantics.
- Add Electron E2E coverage:
  create/edit/favorite/memory,
  export a backup file,
  preview it,
  restore into a clean user-data directory,
  and verify the restored state.
- Include the backup E2E in CI.
- Use `docs/agent-verification-script.md` because this is a user-facing data-safety flow.
- Required scenes:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 5 - Editing, Favorites, And Rollback,
  Scene 6 - Memories,
  Scene 7 - Restart Persistence,
  Scene 8 - Settings, Locale, AI, And Map.
- Also run:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:accessibility`,
  and the backup E2E command.

Acceptance expectations:

- A versioned JSON backup can be exported from the desktop runtime.
- Restore preview reports accurate counts and conflicts before restore.
- A backup can restore authored metadata, favorites, memories, memberships, edit history, generated fields, and settings into a fresh data directory.
- Library Settings exposes export, preview, and restore controls.
- CI and local verification include backup/restore coverage.

Current status:

- Landed on 2026-05-06.
- Added a versioned ChronoPic JSON backup format in the domain layer.
- Added application/database/config support for:
  export,
  dry-run restore preview,
  conflict reporting,
  replace-mode restore,
  and settings export/restore.
- Added desktop main/preload bridge methods for backup export, restore preview, and restore execution.
- Added Library Settings controls for `Export Backup`, `Preview Restore`, and `Restore Backup`.
- Added localized backup/restore UI and status copy in English and Simplified Chinese.
- Added `tests/backup.test.ts` for service/database backup semantics and conflict preview.
- Added `tests/e2e/backup.spec.ts`, `pnpm run e2e:backup`, CI coverage, and README documentation.
- Hardened local native-module verification scripts so Node unit tests and Electron E2E can deliberately rebuild `better-sqlite3` for the correct ABI before running.

## Future Product Backlog

These are intentionally recorded as candidate directions rather than committed phases. They should be promoted into explicit numbered phases only after the current product risk is re-evaluated.

- Person / face grouping:
  add person-like memory grouping only after the app has a real person-recognition or clustering signal.
  Do not pretend to identify people from generic captions or tags.
- OCR and text-in-image search:
  useful for screenshots, documents, receipts, posters, and travel photos.
  Should feed the same discovery/search model rather than creating a separate OCR-only search surface.
- Vector / embedding search:
  useful once semantic search needs fuzzy matching beyond inspectable text fields.
  Must preserve local-first semantics and explain provider/storage tradeoffs clearly.
- Packaged desktop release:
  add signing/notarization/release packaging only after runtime QA stabilizes launch, storage, and native module behavior.
- Large-library performance pass:
  measure scan throughput, query latency, thumbnail cache growth, and renderer responsiveness with larger fixture libraries.
  Deprioritized on 2026-05-06; keep this in backlog rather than promoting it as the next numbered phase.
- Import/export sidecar metadata:
  consider JSON sidecars before EXIF writeback.
  EXIF writeback remains out of scope until the app has stronger backup and rollback guarantees.

### 5. Editing and History ✅

- Support local tag edits and datetime correction in the database projection. ✅
- Record edit history so the latest change can be rolled back safely. ✅
- Do not write edits back into EXIF files in this implementation pass. ✅
- E2E smoke tests cover the EditControls UI elements but full edit/rollback flow requires integration test setup with real database.
- Tag editing UI upgraded to chip/tag format: `TagInput` component with removable chips, type-to-add interaction. ✅
- Caption (name) field added: editable via `UpdatePhotoCaption` in db/app/IPC layers, surfaced in `EditControls`. ✅

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
- Verify memory story sections group photos chronologically and expose deterministic metrics without requiring remote AI.
- Verify advanced discovery suggestions produce actionable filter, browse-mode, tag, GPS, favorites, and memory pivots from the current scope.
- Verify AI memory auto-grouping keeps candidates separate from accepted memories, records grouping reasons/confidence, and requires explicit user acceptance before creating editable memories.
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
- Verify memory cards render title, cover, photo count, and updated time.
- Verify memory navigation is page-based rather than only a gallery filter side effect.
- Verify the memory detail page supports remove-photo and edit-metadata actions without breaking viewer state.
- Verify `RecentMemories` displays memories rather than raw photo thumbnails.
- Verify business-logic and infra packages gain direct unit-test coverage as new phases land, rather than relying only on renderer smoke tests.
- Verify i18n dictionary completeness, interpolation, locale normalization, persisted language settings, AI output-locale threading, and the Chinese switch smoke path for Sidebar/Header/Memory Detail.

### E2E Test Plan (Playwright)

- `tests/e2e/smoke.spec.ts` — Playwright E2E suite runnable with `npx playwright test`.
- Tests launch the Electron app with the dev renderer and verify:
  1. App window opens without renderer JS errors.
  2. Sidebar renders Library and Memories sections with correct nav items.
  3. Header renders with functional search input.
  4. CreateMemoryDialog opens from sidebar and closes on Cancel.
  5. CreateMemoryDialog confirms with name and closes.
  6. Gallery section with filter toolbar renders.
- Prerequisites: `pnpm desktop:dev` running on `http://localhost:5173`.
- Known limitation: `window.chronoPic` IPC errors are expected in production-built renderer loaded outside Electron preload context — these are filtered out and do not indicate app defects.

## Assumptions

- The repository has no existing implementation and can be structured freely.
- The first pass targets desktop only.
- Real AI providers, OCR, vector search, cloud sync, and EXIF writeback remain out of scope.
- Realtime file watching is intentionally out of scope for this product line; manual `Scan Library` remains the explicit and permanent sync mechanism.
- Manual `Scan Library` still needs incremental scan semantics:
  newly added files should enter the normal ingest pipeline,
  missing files should be marked inactive or removed from the local projection,
  and modified files should be reprocessed based on `mtime` / `size` / `hash` change detection rather than forcing a full rebuild every time.
- Incremental manual-scan semantics are now landed in code:
  existing unchanged files are skipped,
  files missing from disk are marked unavailable and excluded from browse/snapshot queries,
  and changed files are reprocessed with fresh hash/metadata/thumbnail output.
- The `shadcn/ui` phase is a renderer-only refactor and must not widen package boundaries or bypass existing application-layer APIs.
- The detail/gallery viewing phase should reuse the current photo list query model and active-record data flow instead of introducing a second parallel retrieval path unless runtime validation shows that the existing list payload is insufficient.
- The UI structure phase is a code-organization refactor first; it should preserve behavior unless a specific follow-up UX change is explicitly planned.
- The real `shadcn/ui` adoption phase should prefer a minimal, deliberate component set over importing a broad catalog that the product does not actually use.
- Favorite and Memory are local-only concepts; no cloud sync or sharing in this phase.
- The memory productization phase should reuse the existing photo/memory persistence model where possible, but it is allowed to extend the schema if memory metadata is insufficient for a proper product surface.
