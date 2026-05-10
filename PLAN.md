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
7. `4.24 Packaged Desktop Release Readiness Phase`
8. `4.25 Maintenance Review and Platform Hygiene Phase`
9. Evaluate the remaining future product backlog below only after packaged-launch readiness and maintenance hygiene are verified.

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

### 4.24 Packaged Desktop Release Readiness Phase

- Add a dedicated release-readiness phase before new discovery or AI capabilities.
- The goal is not a public signed release yet; it is to prove ChronoPic can be packaged locally and launched from the packaged output rather than only from `apps/desktop/dist/main/main.js`.
- Start with the current Linux development environment and record macOS/Windows as follow-up packaging targets unless the local toolchain already supports them cleanly.
- Keep this phase focused on packaging, launch, and artifact verification rather than broad product behavior changes.

Implementation breakdown:

1. Packaging configuration
- Add the minimal Electron packaging toolchain needed for a local desktop artifact.
- Prefer a directory/unpacked artifact first so the app can be smoked without installer complexity.
- Keep package metadata explicit:
  app id,
  product name,
  files included,
  native module handling,
  renderer assets,
  preload output,
  and main-process entry.
- Ensure packaged output does not include dev-only test artifacts or local data directories.

2. Local packaging commands
- Add root scripts for:
  package build,
  local release artifact generation,
  and packaged smoke verification.
- Commands should be easy to run after the existing verification set and should not require manual path composition.
- Preserve the existing runtime scripts:
  `desktop:dev`,
  `desktop:start`,
  and E2E commands should continue to work.

3. Packaged runtime smoke test
- Add a smoke path that launches the packaged app with a temporary `CHRONOPIC_USER_DATA_DIR`.
- Verify:
  production renderer loads,
  preload bridge is available,
  SQLite opens,
  thumbnail generation works,
  backup/restore bridge remains available,
  and the app can close cleanly.
- Reuse the current fixture-media and Playwright Electron testing pattern where practical, but make sure it launches the packaged binary/artifact rather than the built main JS file.

4. Release artifact verification
- Add an artifact verification script that checks the local packaged output contains the expected main/preload/renderer assets and required native modules.
- For Linux, smoke the extracted/packaged executable directly.
- Record platform limitations explicitly:
  no signing/notarization yet,
  no auto-update yet,
  and macOS/Windows packaging can remain follow-up work unless verified locally.

5. Documentation and CI
- Update `README.md` with local packaging commands and packaged smoke verification.
- Add CI coverage where practical:
  at minimum package/verify the Linux artifact in CI,
  or document why full packaging is manual if CI constraints block it.
- Keep CI evidence aligned with what the README tells contributors to run.

6. Verification
- Use `docs/agent-verification-script.md` because this is a launch/distribution flow.
- Required scenes:
  Scene 1 - Launch And First Impression,
  Scene 2 - First-Run And Library Setup,
  Scene 3 - Scan And Browse,
  Scene 7 - Restart Persistence,
  Scene 8 - Settings, Locale, AI, And Map.
- Also run:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:backup`,
  and the new packaged smoke command.

Acceptance expectations:

- A local packaged desktop artifact can be produced from the repo.
- The packaged app can launch with isolated user data and exercise the preload/SQLite/thumbnail path.
- A verifier or smoke command checks packaged output rather than only source-build output.
- README and CI/local scripts document the supported packaging path and current platform limitations.
- No unrelated performance, OCR, vector search, person grouping, or sidecar writeback work is bundled into this phase.

Current status:

- Completed locally on 2026-05-06.
- Added a custom local Linux unpacked packaging path that stages only the desktop production build, package `dist` outputs, production dependencies, and Electron-rebuilt native modules before embedding them into Electron's Linux runtime.
- Added root scripts:
  `package:linux`,
  `package:verify`,
  `package:smoke`,
  and `e2e:packaged`.
- Added packaged artifact verification for:
  executable presence,
  main/preload/renderer assets,
  explicit ChronoPic package metadata,
  `better-sqlite3` and `sharp` native modules,
  executable mode,
  and exclusion of repo-local test/data artifacts.
- Added `tests/e2e/packaged.spec.ts` so the smoke path launches `dist/release/chronopic-linux-x64/chronopic` directly rather than `apps/desktop/dist/main/main.js`.
- Updated README and CI with the supported local/Linux packaging path and current release limitations:
  no signing,
  no notarization,
  no auto-update,
  and no verified macOS/Windows artifacts yet.
- Expanded the tag-triggered GitHub Release workflow to Linux, macOS, and Windows:
  tags matching `v*` build and verify each platform package on the matching runner,
  run packaged E2E,
  create platform-specific tar.gz archives and SHA-256 checksums,
  and publish or update the GitHub Release for the tag.
- Split project documentation by audience:
  `README.md` is user-facing,
  and `DEVELOPMENT.md` owns developer setup, verification, architecture, packaging, and release workflow details.
- Verified with:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:backup`,
  `pnpm run package:linux`,
  `pnpm run package:smoke`,
  and packaged director-script scenes 1, 2, 3, 7, and 8.

### 4.25 Maintenance Review and Platform Hygiene Phase ✅

- Treat installable installers as unnecessary for now; keep the release model focused on portable, unpacked desktop bundles.
- Review the current logic, release workflow, and platform packaging path after the first verified three-platform release.
- Keep this as a maintenance close-out rather than a new product feature phase.

Implementation breakdown:

1. Platform workflow hygiene
- Update GitHub official actions to current Node 24-compatible versions where available.
- Keep the release matrix behavior unchanged:
  Linux,
  macOS,
  and Windows still package, verify, smoke, archive, and upload assets independently.

2. Packaging script maintainability
- Remove repeated package-target normalization and release-folder naming logic from release helper scripts.
- Keep platform-specific runtime copy behavior explicit inside the packager.
- Preserve current artifact naming:
  `chronopic-<target>-<arch>`.

3. Documentation consistency
- Keep README wording aligned with the chosen portable-bundle release model.
- Keep developer-document references clickable where the document points to repo files.

4. Verification
- Run script syntax checks for package/release helpers.
- Run the packaging structure regression test.
- Run root tests and typecheck.
- Run Linux package and package verification because the shared target helper affects real packaging paths.

Current status:

- Completed locally on 2026-05-06.
- Added [scripts/package-targets.mjs](scripts/package-targets.mjs) as the shared package-target helper for:
  target normalization,
  target validation,
  and release folder naming.
- Updated [scripts/package-desktop.mjs](scripts/package-desktop.mjs),
  [scripts/verify-package.mjs](scripts/verify-package.mjs),
  and [scripts/archive-release-artifact.mjs](scripts/archive-release-artifact.mjs)
  to consume the shared helper instead of carrying duplicate logic.
- Updated [.github/workflows/ci.yml](.github/workflows/ci.yml)
  and [.github/workflows/release.yml](.github/workflows/release.yml)
  from `actions/checkout@v4` / `actions/setup-node@v4`
  to `actions/checkout@v5` / `actions/setup-node@v5`.
- Updated [tests/packaging.test.ts](tests/packaging.test.ts)
  to cover the shared package-target helper and Node 24-compatible workflow actions.
- Generalized the packaged E2E test name in [tests/e2e/packaged.spec.ts](tests/e2e/packaged.spec.ts)
  so it no longer describes the cross-platform packaged smoke as Linux-only.
- Updated [README.md](README.md) and [DEVELOPMENT.md](DEVELOPMENT.md)
  to describe releases as portable, unpacked desktop bundles rather than installers.
- Tightened [DEVELOPMENT.md](DEVELOPMENT.md) file references so repo-file pointers are clickable Markdown links.
- Verified with:
  `node --check scripts/package-targets.mjs && node --check scripts/package-desktop.mjs && node --check scripts/verify-package.mjs && node --check scripts/archive-release-artifact.mjs`,
  `node --experimental-strip-types --test tests/packaging.test.ts`,
  `pnpm run package:linux`,
  `pnpm run package:verify -- linux`,
  `pnpm test`,
  `pnpm typecheck`,
  and `git diff --check`.

### 4.26 AI Productization Tightening Phase ✅

- Do a smaller AI productization close-out before promoting larger AI features such as OCR, vector search, or person grouping.
- The goal is to make the existing AI-powered promise more visible, understandable, and recoverable in the product without changing the core local-first model.
- Keep this phase focused on UX/status/orchestration around already-planned AI enrichment, memory suggestions, candidate review, and settings.

Implementation breakdown:

1. AI setup clarity
- Add a clear AI readiness surface in Settings or Notifications:
  configured,
  incomplete,
  disabled,
  and failed states should be distinguishable.
- Show which settings are required for AI enrichment:
  API key,
  base URL,
  model,
  provider name,
  and AI output language.
- Avoid exposing secrets after save; only show presence/absence and safe metadata.
- Add a lightweight health-check action if the current provider abstraction supports it cleanly.
  If not, add the UI affordance and disabled-state copy first, then defer live provider probing.

2. AI enrichment queue visibility
- Make pending, processing, failed, and completed AI enrichment states visible from the existing Notifications or AI-related surfaces.
- Provide retry affordances for failed photo enrichment and failed memory enrichment where application APIs already support retry semantics.
- Keep user-authored fields visually distinct from AI-generated suggestions.
- Explain that generated content is reviewable and does not overwrite user edits.

3. Memory candidate guidance
- Tighten the suggested-memory review flow so users understand:
  why a memory candidate was suggested,
  which photos are included,
  confidence/reason metadata when available,
  and that accepting a candidate creates an editable Memory.
- Preserve the explicit accept/reject rule.
- Do not auto-create Memories from AI suggestions.

4. First-run and empty-state integration
- Add small AI-aware empty states in relevant surfaces:
  home,
  notifications,
  search/discovery,
  and memory suggestions.
- The empty states should point to the next concrete action:
  configure AI,
  scan library,
  run enrichment,
  review candidates,
  or retry failed work.
- Keep copy concise and user-facing; avoid developer or implementation terminology.

5. Verification
- Add or update unit tests around any new application-level AI status aggregation.
- Add E2E coverage only for visible UI state changes that can be exercised without real provider secrets.
- Use [docs/agent-verification-script.md](docs/agent-verification-script.md) because this is a user-facing product-flow refinement.
- Suggested manual scenes:
  Scene 1 - Launch And First Impression,
  Scene 3 - Scan And Browse,
  Scene 6 - Settings, Locale, AI, And Map,
  Scene 8 - Notifications And AI Queue,
  and Scene 7 - Restart Persistence if settings or queue state persistence changes.

Acceptance expectations:

- Users can tell whether AI is disabled, incomplete, configured, running, failed, or ready for review.
- AI setup and output-language state are visible without exposing secrets.
- Failed AI work has an obvious recovery path where retry APIs exist.
- Memory candidates explain enough context to support review without automatic acceptance.
- The README's AI-powered positioning is reflected in the product UI, while local-first and review-before-apply boundaries remain clear.
- No OCR, vector embedding search, face/person recognition, installer work, or large-library performance work is bundled into this phase.

Current status:

- Completed locally on 2026-05-07.
- Added `getAIReadiness()` in [packages/domain/src/index.ts](packages/domain/src/index.ts) with unit coverage in [tests/domain.test.ts](tests/domain.test.ts).
- Added an AI setup status card in [packages/ui-components/src/photo-home.tsx](packages/ui-components/src/photo-home.tsx) that distinguishes:
  configured,
  incomplete,
  and disabled settings.
- The setup card lists required AI fields safely:
  API key,
  base URL,
  model,
  provider name,
  and AI output language,
  using presence/missing badges instead of exposing saved secrets.
- Notifications now show missing AI setup fields and provide a direct `Configure AI` path back to Library Settings when the AI queue cannot run.
- Existing AI queue status badges remain visible for:
  disabled,
  pending,
  processing,
  failed,
  and completed items.
- Suggested Memories now explain that accepting a candidate creates an editable Memory, rejecting it leaves the library untouched, and each candidate shows source/confidence/photo-count context near the reason.
- Added an accessible name and title to the sidebar Notifications icon button in [packages/ui-components/src/sidebar.tsx](packages/ui-components/src/sidebar.tsx).
- Added [tests/e2e/ai-productization.spec.ts](tests/e2e/ai-productization.spec.ts) plus the root script:
  `pnpm run e2e:ai`.
- Added `e2e:ai` to CI and documented it in [DEVELOPMENT.md](DEVELOPMENT.md).
- Live provider health checking is intentionally deferred because the current provider abstraction does not expose a separate non-generating health probe; this phase adds readiness and recovery UI without adding a new provider API.
- Verified with:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run clean && pnpm run build:packages && node --experimental-strip-types --test tests/domain.test.ts tests/i18n.test.ts`,
  `pnpm run e2e:ai`,
  and `pnpm run e2e:accessibility`.

### 4.27 Flutter Rewrite Phase 0: Freeze Parity Contract ✅

- Start the Flutter rewrite line without scaffolding Flutter or Dart packages yet.
- Treat the current Electron app as the reference implementation until Flutter passes explicit parity gates.
- Keep this phase focused on migration safety, fixture definition, and acceptance boundaries.
- Do not change product runtime behavior in this phase.

Implementation breakdown:

1. Parity contract
- Define the user-visible workflows the Flutter rewrite must preserve:
  library setup,
  manual scan,
  browse/discovery,
  detail/gallery viewing,
  editing/rollback,
  favorites,
  memories,
  AI setup and queue,
  memory candidates,
  locale/settings,
  backup/preview/restore,
  accessibility,
  and desktop launch.
- Ground the contract in existing Electron tests and docs rather than inventing new semantics.

2. Reference fixture baseline
- Create a sanitized Electron backup fixture suitable for Dart parsing tests.
- Include expected derived counts and key authored/generated fields in a separate expected fixture.
- Keep fixture data deterministic and free of real user paths, real API keys, or real personal photos.

3. Refresh path
- Add a documented command or script that can refresh the Electron reference fixture from the current app behavior.
- Ensure the refresh path uses deterministic fixture media.

4. Handoff to Dart Phase 1
- Make the Phase 1 Dart domain/backup work point at the parity contract and fixtures.
- Do not start Dart model implementation until Phase 0 artifacts exist.

Current status:

- Completed locally on 2026-05-07.
- Added [docs/flutter-parity-contract.md](docs/flutter-parity-contract.md) as the Phase 0 parity contract.
- Linked Phase 0 from [docs/flutter-refactor-phases.md](docs/flutter-refactor-phases.md).
- Added sanitized Flutter parity fixtures under [tests/fixtures/flutter-parity/](tests/fixtures/flutter-parity/):
  [chronopic-backup-v1.json](tests/fixtures/flutter-parity/chronopic-backup-v1.json)
  and [chronopic-backup-v1.expected.json](tests/fixtures/flutter-parity/chronopic-backup-v1.expected.json).
- Added [scripts/write-flutter-parity-fixtures.mjs](scripts/write-flutter-parity-fixtures.mjs)
  and root script `pnpm run fixtures:flutter-parity` to refresh the fixture baseline.
- Added [tests/flutter-parity-fixtures.test.ts](tests/flutter-parity-fixtures.test.ts)
  to validate counts and migration-critical authored/generated fields.
- Verified with:
  `node --check scripts/write-flutter-parity-fixtures.mjs`,
  `node --experimental-strip-types --test tests/flutter-parity-fixtures.test.ts`,
  and `git diff --check`.

### 4.28 Flutter Rewrite Phase 1: Dart Domain And Backup Contract ✅

- Added the Flutter/Dart workspace under [chronopic_flutter/](chronopic_flutter/).
- Added [chronopic_domain](chronopic_flutter/packages/chronopic_domain/) with platform-neutral models for photos, metadata, semantic state, index state, library sources, edit history, memories, memory candidates, settings, filters, backups, and AI readiness.
- Added [chronopic_testkit](chronopic_flutter/packages/chronopic_testkit/) to load the committed parity fixtures from [tests/fixtures/flutter-parity/](tests/fixtures/flutter-parity/).
- Implemented Dart backup parsing, validation, preview counts, JSON re-emission, and fixture-backed compatibility tests.
- Verified with:
  `dart test packages/chronopic_domain`
  and `dart analyze packages/chronopic_domain packages/chronopic_testkit`.

### 4.29 Flutter Rewrite Phase 2: Drift Database And Repositories ✅

- Added [chronopic_database](chronopic_flutter/packages/chronopic_database/) with a repository facade for backup preview/restore/export, photo listing, caption/tag/favorite edits, memory CRUD, memory membership, and memory candidates.
- Added a Drift schema for `library_sources`, `photos`, `memories`, `memory_photos`, `edit_history`, and `memory_candidates`, plus generated Drift code.
- Kept the public app-facing database export focused on the repository facade; Drift internals are exposed only through [chronopic_database_testing.dart](chronopic_flutter/packages/chronopic_database/lib/chronopic_database_testing.dart) for package tests.
- Verified with:
  `dart run build_runner build`,
  `dart test test/repository_test.dart test/drift_database_test.dart`,
  and `dart analyze packages/chronopic_database`.
- Note: the Drift runtime test is run from `chronopic_flutter/packages/chronopic_database` so sqlite native asset hooks are available.

### 4.30 Flutter Rewrite Phase 3: Media Source Abstraction ✅

- Added [chronopic_media](chronopic_flutter/packages/chronopic_media/) with `MediaSourceAdapter`, media asset metadata, read results, permission state, stable IDs, supported-media filtering, and missing-asset handling.
- Implemented deterministic fixture media and a desktop directory adapter for recursive local media discovery.
- Verified with:
  `dart test packages/chronopic_media`
  and `dart analyze packages/chronopic_media`.

### 4.31 Flutter Rewrite Phase 4: Indexer And AI Pipeline ✅

- Added [chronopic_ai](chronopic_flutter/packages/chronopic_ai/) with disabled, fixture-success, and fixture-failure AI client implementations.
- Added [chronopic_app](chronopic_flutter/packages/chronopic_app/) with backup orchestration and an indexer service that consumes media adapters, skips unchanged assets, records missing assets, and writes AI state through the repository boundary.
- Verified with:
  `dart test packages/chronopic_ai packages/chronopic_app`
  and `dart analyze packages/chronopic_ai packages/chronopic_app`.

### 4.32 Flutter Rewrite Phase 5: Flutter Desktop MVP ✅

- Added [chronopic_ui](chronopic_flutter/packages/chronopic_ui/) with the first Flutter Material desktop MVP surface:
  first-run/library actions,
  scan action,
  search/filter controls,
  photo grid,
  favorites,
  memories,
  detail/edit surface,
  gallery surface,
  and backup/restore actions.
- Added the Linux Flutter app shell under [chronopic_flutter/apps/chronopic/](chronopic_flutter/apps/chronopic/).
- Queried the current Flutter stable toolchain and package resolver before finalizing dependencies:
  `flutter upgrade --verify-only` reports Flutter `3.41.9` stable is already current,
  and `flutter pub outdated` reports direct dependencies are up to date with the newest resolvable stable versions.
- Kept `test` at `1.30.0` because `1.31.1` is listed as latest but not resolvable under the current Flutter stable dependency graph.
- Verified with:
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  and `flutter build linux --debug`.

### 4.33 Flutter Rewrite Phase 5.5: Linux Desktop Feature Parity And E2E Gate

- Insert this phase before Android/iOS productization.
- Treat the current Electron desktop app as the reference behavior, but finish Linux Flutter desktop parity first.
- Keep this phase focused on real local-first desktop behavior rather than mobile permissions or packaging.

Implementation breakdown:

1. Real desktop library loop
- Add a Flutter Linux path-entry flow for registering a local library directory.
- Run manual scan through the Dart service layer and desktop media adapter.
- Preserve incremental scan semantics:
  imported assets are upserted,
  unchanged assets are skipped,
  unsupported files are ignored,
  and scan results remain visible in the catalog after multiple files are discovered.

2. Core parity actions
- Wire browse/search/favorite filtering to real service state.
- Wire detail selection to caption edit, tag edit, rollback, favorite toggle, and add-to-memory actions.
- Wire backup export, backup preview, and backup restore smoke actions to the Dart backup contract.

3. Linux parity E2E
- Add a deterministic Flutter test that creates a temporary local directory with supported and unsupported files.
- Drive the UI through add-library, scan, browse, search, favorite, edit, rollback, memory, and backup controls.
- Verify the exported backup preserves the same authored/generated fields that matter for Electron-to-Flutter migration.

4. Completion gate
- Do not start Phase 6 until this phase passes:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  and `flutter build linux --debug`.

Current status:

- Started locally on 2026-05-08.
- Implementation plan is tracked in [docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md](docs/superpowers/plans/2026-05-08-flutter-linux-desktop-parity-phase-5-5.md).
- Electron-vs-Flutter Linux parity gaps are tracked in [docs/flutter-linux-desktop-parity-matrix.md](docs/flutter-linux-desktop-parity-matrix.md).
- First executable Linux parity slice completed locally on 2026-05-08:
  repository upsert/edit-history/memory actions,
  app-service desktop directory scan,
  real Flutter path-entry/scan controls,
  caption/tag/favorite/rollback controls,
  memory actions,
  backup smoke actions,
  and temp-directory parity tests.
- Additional Linux parity work completed locally on 2026-05-08:
  UI-driven empty-to-scanned library flow by entering a real Linux directory path and clicking `Scan Library`,
  native folder-picker entry point for first-run library selection,
  generated thumbnail cache files for scanned local images,
  local image preview rendering in grid/detail,
  focused gallery dialog open/close,
  gallery adjacent navigation through toolbar buttons and keyboard arrows,
  gallery Escape close behavior,
  video placeholders in the browse grid,
  desktop date/time fields for datetime correction,
  invalid date/time input handling,
  rollback coverage for caption, tags, favorite, and datetime edits,
  UI-level caption/tag/favorite/memory/backup smoke coverage,
  visible tag/GPS/date/sort filter controls,
  repository coverage for AI status/date/sort filter semantics,
  Favorites navigation filtering coverage,
  and explicit JSON backup export/preview/restore through a Linux file path.
- Backup error coverage now includes malformed JSON handling in both service and Flutter UI tests.
- Flutter backup UI now includes native `file_selector` save/open picker entry points through `choose-backup-export-path` and `choose-backup-restore-path`.
- Flutter AI status panel now exposes secret-safe readiness, per-status AI queue counts, and memory candidate count.
- Flutter Linux desktop now creates a persistent default app service backed by the existing backup JSON contract under the local data directory, and service/UI tests verify that library state, caption/tag edits, favorite state, and memory membership reload in a fresh service or Flutter shell.
- Flutter memory lifecycle now covers detail editing, rename, description edit, set cover, remove selected photo from memory, and persistence through repository/service/UI parity tests.
- Flutter detail metadata now shows captured local date/time, local UTC offset, original date text, camera, GPS, MIME, and size; the Linux parity test verifies the visible metadata grid after datetime correction.
- Flutter browse grid now uses adaptive desktop column counts and has larger-library coverage from an 18-photo scanned Linux fixture directory plus widget-level wide/narrow layout assertions.
- Flutter detail keyboard parity now covers selected-photo shortcuts for favorite toggle, rollback, and gallery open.
- Flutter map and timeline browse modes now run from the same visible result set:
  map mode lists GPS-backed photos and coordinates,
  while timeline mode groups photos by local capture date.
- Flutter AI provider settings, failed-queue retry, and memory candidate accept/reject actions are now wired through repository/service/UI tests.
- Flutter gallery now has a dark fullscreen shell with counter, keyboard hint, filmstrip, button navigation, keyboard navigation, and Escape close coverage.
- Flutter desktop i18n now includes English/Simplified Chinese UI dictionaries, a visible locale switcher, and Chinese coverage for critical shell/import/backup/memory/browse text.
- Flutter manual scan status now distinguishes imported, updated, skipped, error, and missing counts.
- Flutter search/filter UX now exposes an active-filter summary for applied query, tag, GPS, AI status, date, favorite, memory, and sort state.
- Flutter caption/tag editing now includes visible validation for caption length, tag length, tag count, and duplicate-tag normalization.
- Flutter Linux parity E2E now asserts visible rollback state for caption, tags, favorite, and datetime edits.
- Flutter backup export E2E now compares exported JSON photos, memories, memoryPhotos, and settings against the live backup snapshot.
- Native folder/save/open picker behavior is treated as an accepted headless-test difference for Phase 5.5:
  the Flutter UI exposes `file_selector` entry points, while deterministic widget E2E drives typed Linux paths because native portal dialogs are not operable inside Flutter widget tests.
- Final Phase 5.5 verification passed locally on 2026-05-08 with:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  `dart test test/repository_test.dart test/drift_database_test.dart` from [chronopic_flutter/packages/chronopic_database/](chronopic_flutter/packages/chronopic_database/),
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  `flutter build linux --debug`,
  and `git diff --check`.
- Phase 5.5 is complete locally against the documented Linux desktop parity gate.
- Phase 6 Android/iOS productization may start only from this completed Linux desktop baseline.

### 4.34 Flutter Desktop UI Refine And Component Parity Phase

- Treat the current Electron desktop UI as the product-quality reference for the Flutter Linux desktop shell.
- Refine the Flutter UI before mobile work:
  the current Phase 5.5 surface is behavior-complete but still reads like a dense Material test harness.
- Split `chronopic_home.dart` into focused UI modules for:
  localization,
  theme,
  shell/sidebar/page routing,
  home browse,
  library controls,
  filters,
  grid/map/timeline browse,
  detail editing,
  gallery,
  memories,
  settings,
  AI status,
  and backup controls.
- Rebuild Flutter desktop information architecture around the Electron structure:
  persistent left sidebar,
  home page,
  memories page,
  memory detail page,
  settings page,
  notifications/AI work queue page,
  browse toolbar,
  and focused viewer.
- Preserve every Phase 5.5 behavior and stable test key unless the matching test is intentionally updated in the same slice.
- Keep this phase desktop-focused:
  no Android/iOS UI or media permission work until the Flutter desktop UI is product-quality.
- Design spec:
  [docs/superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md](docs/superpowers/specs/2026-05-08-flutter-desktop-ui-refine-design.md)
- Implementation plan:
  [docs/superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md](docs/superpowers/plans/2026-05-08-flutter-desktop-ui-refine.md)
- Current status:
  complete locally on 2026-05-08.
- Implementation result:
  `chronopic_home.dart` is now the service/state orchestration shell,
  and Flutter UI rendering is split across focused modules for shell,
  home,
  filters,
  browse,
  detail,
  gallery,
  memories,
  settings,
  localization,
  and theme.
- The default home surface now follows the Electron information architecture:
  persistent desktop sidebar,
  dedicated Memories,
  Memory Detail,
  Settings,
  and Notifications pages,
  compact library/search/filter controls,
  focused detail inspector,
  and fullscreen gallery dialog.
- Verification:
  `dart test packages/chronopic_domain packages/chronopic_media packages/chronopic_ai packages/chronopic_app`,
  `dart test test/repository_test.dart test/drift_database_test.dart` from [chronopic_flutter/packages/chronopic_database/](chronopic_flutter/packages/chronopic_database/),
  `dart analyze packages/chronopic_domain packages/chronopic_database packages/chronopic_media packages/chronopic_ai packages/chronopic_app packages/chronopic_testkit packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `flutter analyze packages/chronopic_ui apps/chronopic`,
  `flutter build linux --debug`,
  `flutter pub outdated`,
  Linux bundle screenshot smoke launch with
  `xvfb-run -a -s "-screen 0 1600x1200x24"` and `LIBGL_ALWAYS_SOFTWARE=1`,
  and `git diff --check`.
- Dependency audit:
  `flutter pub outdated` reports all direct dependencies are already at the newest resolvable versions;
  newer transitive/dev versions are not mutually compatible with the current resolved toolchain.
- Runtime screenshot evidence:
  `test-results/flutter-ui-refine-xvfb-window.png` captured the Linux debug bundle first-run desktop window at 1280x720.
  The screenshot is intentionally kept under the ignored `test-results/` directory.

### 4.35 Flutter Electron UI And Functional Parity Phase

- Continue desktop-first work before Phase 6 mobile productization.
- Treat Electron as the reference product surface and Flutter Linux desktop as the candidate implementation.
- Align UI and functionality through a repeated loop:
  capture Electron screenshots,
  capture Flutter screenshots,
  compare them in a parity matrix,
  fix concrete gaps,
  then rerun both sides' tests and screenshots.
- Required reference surfaces:
  empty first-run home,
  populated grid/waterfall browse,
  map or disabled-map state,
  timeline,
  detail inspector and editing,
  fullscreen gallery,
  favorites,
  memories list,
  memory detail,
  settings,
  notifications/AI queue,
  Chinese locale,
  and restart persistence.
- Add durable parity matrix:
  [docs/flutter-electron-ui-functional-parity.md](docs/flutter-electron-ui-functional-parity.md)
- Add acceptance spec:
  [docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md](docs/superpowers/specs/2026-05-08-flutter-electron-ui-functional-parity.md)
- Add implementation plan:
  [docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md](docs/superpowers/plans/2026-05-08-flutter-electron-ui-functional-parity.md)
- Current status:
  phase handoff completed on 2026-05-09 and pushed to
  `flutter-refactor-phases`.
  Capture harnesses are landed for Electron and Flutter.
  First shell/home/browse/detail alignment slice is implemented and screenshot-backed;
  gallery/detail/favorites/editing alignment task is implemented and screenshot-backed;
  memory list/detail alignment is partially implemented and screenshot-backed;
  notifications/settings alignment is partially implemented and screenshot-backed;
  map/timeline first-viewport alignment is partially implemented and screenshot-backed,
  including an Electron-like pale disabled-map canvas in the Flutter Map surface
  and an Electron-like light timeline card with selected-photo banner in the Flutter Timeline surface;
  Chinese locale first-viewport alignment is partially implemented and screenshot-backed;
  all 13 Flutter parity screenshots have been recaptured at the Electron reference size of 1440x920;
  no unexamined `Gap` rows remain in the parity matrix;
  all rows are either matched by behavior or closed as documented accepted
  renderer/fixture differences.
  The populated-grid, favorites, and restart-persistence Flutter surfaces now
  show an Electron-like selected-photo banner above the grid when a photo is selected.
  Detail capture now uses an immersive Electron-like focused dark viewer with
  a large media canvas, right-side metric-card inspector, AI insights,
  gallery strip, keyboard hint, and real add/close/gallery actions instead of
  a plain inline detail page or normal Flutter shell chrome.
  Gallery capture now uses a bordered dark media frame, metadata below the
  image instead of a large scrim, an Open Inspector action, and a separate
  framed gallery strip closer to Electron's viewer hierarchy.
  Populated browse, favorites, and restart-persistence surfaces now include a
  functional Electron-like discovery lens row where Map, Timeline, and Memory
  chips navigate to real app surfaces instead of acting as visual-only hints.
  Notifications now use an Electron-like outer container with separate AI queue
  and Memory candidates cards while preserving retry and memory-review actions.
  Notifications now also place the page title inside the white content card and
  use Electron-like blue/red/green/yellow semantic chips for AI queue,
  failed,
  ready,
  and memory candidate states.
  Settings now use Electron-like primary library actions, backup action grouping
  with `LOCAL JSON`, and an AI Enrichment readiness card with `PRESENT` pills
  while preserving path-based backup/restore and secret-safe AI editing.
  Settings now also keeps the first viewport focused on the Electron-like
  Library Settings card with Add Folder and Scan Library,
  moves manual path import into a lower panel,
  and uses Electron-like orange/white/blue/green action and status semantics
  for restore,
  language save,
  backup format,
  and AI readiness.
  Shared desktop shell chrome now moves notifications into the sidebar header,
  replaces the previous Notifications nav row with an Electron-like Recent row,
  adds a bottom Create Memory action,
  and hides the idle scan status bar so non-immersive pages start at the same
  top content position as Electron.
  Browse controls now use Electron's `Waterfall` label instead of `Grid`,
  including the Simplified Chinese `瀑布流` label,
  and the selected-photo banner now uses Electron's memory-membership copy.
  Focused detail capture now selects the same first fixture photo as Electron
  and exposes Electron-like add,
  close,
  previous,
  next,
  and Gallery top controls with dark/disabled/highlight states.
  Focused detail inspector status now reports file/index health as `HEALTHY`
  while keeping AI failure information in AI-specific fields,
  matching Electron's inspector semantics.
  Fullscreen gallery now removes the extra back/X controls,
  uses dark Detail View/Open Inspector actions,
  shows date plus time,
  uses Electron's `NOT IN ANY MEMORY` and `2 ITEMS` copy,
  and keeps the dark framed media/filmstrip hierarchy.
  Settings backup JSON path controls now live in a lower file-path panel so the
  first viewport matches Electron's backup card density while preserving
  path-based export/restore workflows.
  Browse media cards now use a lower-density desktop grid, larger cards,
  bottom gradient metadata, and improved missing-media fallback so populated,
  favorites, and restart-persistence evidence more closely matches Electron's
  media-card hierarchy.
  Global Flutter desktop brand chrome now matches Electron's `ChronoPic` /
  `Photo workspace` labels instead of identifying the rewrite as
  `ChronoPic Flutter`.
  Empty first-run now uses `Add Folder` as the primary folder-picker action
  while preserving the explicit path-based `Add Library` control below.
  Empty first-run now also removes the lower path-based library toolbar and
  full filter panel from the first viewport,
  keeps those operational controls available in Settings,
  and adds a `Create First Memory` CTA to the recent-memory empty state.
  Filter controls remain visible when an active filter/search returns zero
  photos,
  so filtered-empty states do not regress into onboarding.
  Populated grid,
  Favorites,
  and Restart Persistence now use Electron-like compact `Select` / `Filter`
  browse-toolbar affordances by default instead of rendering the full filter
  panel in the first viewport;
  the full filter panel remains available behind `Filter` and stays visible for
  active search/tag/GPS/AI/date/sort states.
  Map and Timeline screenshots were recaptured after the compact toolbar pass,
  so both now inherit reduced first-viewport toolbar density while preserving
  the disabled-map and timeline-card behavior already implemented.
  Browse media cards now use a taller card ratio,
  and photo/memory fallback surfaces now share an Electron-like edge treatment
  with top path/name text instead of a centered broken-image icon.
  Memories list now has an Electron-like `SUGGESTED MEMORIES` header,
  a real Generate/refresh affordance,
  title-card candidate treatment,
  `Adjust photos`,
  and candidate accept/reject actions aligned more closely with Electron.
  Memory list/detail/home cards now use framed media-style cover fallback
  treatment instead of centered icon-only gradient blocks.
  Memory detail now uses a read-first hero with compact actions and moves
  editable metadata controls into a lower management panel.
  Memory detail now also uses Electron-like updated timestamp formatting,
  a `STORY OUTLINE` section,
  and chapter-card metadata for month/day,
  mapped count,
  and AI readiness.
  Full Flutter-side verification for this phase has been rerun with
  `dart analyze packages/chronopic_app packages/chronopic_ui`,
  `flutter test packages/chronopic_ui apps/chronopic`,
  `bash tool/capture_flutter_parity.sh all`,
  and a `file` check confirming all 13 Flutter PNGs are 1440x920.
  Electron-side verification has also been rerun:
  `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:runtime`,
  `pnpm run e2e:backup`,
  `pnpm run e2e:ai`,
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`,
  `node scripts/capture-electron-parity.mjs`,
  and a `file` check confirming all 13 Electron PNGs are 1440x920.
  The Electron gate exposed and now covers a deterministic edit-history rollback
  fix for rapid same-millisecond edits.
- Next execution plan:
  keep Phase 6 mobile productization blocked until the pushed Flutter desktop
  parity branch is reviewed or merged.

### 4.36 Viewer Overlay Activation Parity Phase

- Continue desktop-first parity after code comparison found a missed interaction
  contract in Phase 5.7:
  primary photo-card activation and in-overlay Detail/Gallery switching were
  not consistently aligned to the Electron reference.
- Treat the expected desktop behavior as:
  single click selects,
  double-click or double-tap opens the focused Detail viewer overlay,
  Enter opens the same focused Detail/inspector overlay,
  `G` opens gallery for the selected photo,
  Gallery overlay `D` / `Detail View` returns to the focused Detail overlay,
  and `Escape` closes the active overlay while preserving selection.
- Electron comparison finding:
  `packages/ui-components/src/photo-card.tsx`
  correctly wires `onDoubleClick` to detail mode,
  while `packages/ui-components/src/photo-viewer-overlay.tsx`
  supports Detail and Gallery as two modes inside the same fullscreen Radix
  viewer overlay.
- Flutter comparison finding:
  `chronopic_flutter/packages/chronopic_ui/lib/src/browse/browse_surface.dart`
  previously wired photo cards only to selection,
  while `chronopic_flutter/packages/chronopic_ui/lib/src/gallery/gallery_dialog.dart`
  provides the fullscreen Gallery mode and now returns explicitly to focused
  Detail mode for `D` / `Detail View`.
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md](docs/superpowers/plans/2026-05-09-gallery-overlay-activation-parity.md)
- Required verification:
  Electron E2E must prove double-click opens Detail,
  the in-overlay Gallery button switches to Gallery,
  and `D` switches Gallery back to Detail;
  Flutter widget/parity tests must prove double-tap opens focused Detail,
  Gallery can be opened from that overlay,
  and `D` / `Detail View` returns to focused Detail;
  both sides must recapture and compare populated browse,
  Detail,
  and Gallery screenshots before closing the corrected matrix rows.
- Current status:
  corrected locally on 2026-05-09 after user review clarified the Electron
  reference interaction;
  correction commit `96ba222` restores Detail-first card activation and
  fixes Flutter Gallery-to-Detail switching.
- Local verification:
  Electron accessibility E2E now covers Enter-to-Detail,
  double-click-to-Detail,
  Detail-to-Gallery,
  Gallery `D`-to-Detail,
  selected-card `G`-to-Gallery,
  and Escape close;
  Flutter parity tests now cover card double-tap-to-focused-Detail,
  focused Detail-to-Gallery,
  Gallery `D`-to-focused-Detail,
  selected-photo `G`-to-Gallery,
  Enter-to-focused-Detail,
  and Escape close.
- Screenshot comparison:
  refreshed Electron and Flutter populated browse,
  Detail,
  and Gallery screenshots are 1440x920;
  side-by-side comparison artifacts are under
  `test-results/flutter-electron-parity/compare/`.

### 4.37 Full Feature UI Parity Review Phase

- Purpose:
  review every Electron-vs-Flutter desktop feature surface and UI state with
  code,
  tests,
  and refreshed screenshot evidence before further broad UI work.
- Method:
  review Electron reference code/runtime first,
  compare Flutter implementation,
  run or add focused tests for behavior,
  refresh screenshots,
  inspect side-by-side compare artifacts,
  and classify each finding as `Matched`,
  `Accepted Difference`,
  or `Gap`.
- Surfaces:
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
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-feature-ui-parity-review.md](docs/superpowers/plans/2026-05-09-feature-ui-parity-review.md)
- Detailed review report:
  [docs/flutter-electron-feature-ui-review.md](docs/flutter-electron-feature-ui-review.md)
- Current status:
  reviewed on 2026-05-09.
  Full Electron and Flutter screenshot evidence was refreshed,
  all 13 side-by-side compare artifacts were generated,
  and the detailed review found one confirmed parity gap:
  Flutter zh mode still contains app-owned English UI strings.
  Verification passed after the review:
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  `pnpm typecheck`,
  `pnpm build`,
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/linux_desktop_parity_test.dart packages/chronopic_ui/test/chronopic_home_test.dart`,
  and
  `git diff --check`.
- Follow-up:
  visible-string localization parity has been promoted to Phase 4.38.

### 4.38 Flutter Visible String Localization Parity Phase

- Purpose:
  close the confirmed Flutter Chinese-locale UI parity gap by removing
  app-owned English strings from zh mode while preserving source-authored user
  content.
- Reference finding:
  `FUI-001` in
  [docs/flutter-electron-feature-ui-review.md](docs/flutter-electron-feature-ui-review.md).
- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md](docs/superpowers/plans/2026-05-09-flutter-visible-string-localization-parity.md)
- Scope:
  selected-photo banners,
  active filter labels,
  status messages,
  Detail/Gallery controls,
  memory list/detail actions,
  settings actions,
  notifications,
  map controls,
  and timeline actions.
- Test requirement:
  add failing zh assertions before changing strings,
  then refresh the affected Flutter screenshots and compare artifacts.
- Current status:
  implemented and verified on 2026-05-09.
- Result:
  Flutter app-owned zh UI is localized across selected-photo banners,
  active filter labels,
  status messages,
  Detail/Gallery controls,
  memory actions,
  settings,
  notifications,
  map,
  and timeline surfaces.
  Source-authored filenames,
  captions,
  memory names,
  imported descriptions,
  and AI/fixture content remain untranslated.
- Verification:
  `dart analyze packages/chronopic_ui apps/chronopic`,
  `flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts accessibility.spec.ts`,
  and
  `git diff --check`
  all pass.

## Future Product Backlog

These are intentionally recorded as candidate directions rather than committed phases. They should be promoted into explicit numbered phases only after the current product risk is re-evaluated.

### 6. Flutter Mobile Productization

- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md](docs/superpowers/plans/2026-05-09-flutter-phase-6-mobile-productization.md)
- Scope:
  Android/iOS runner scaffolding,
  Android-first photo-library permissions,
  mobile-native onboarding,
  resumable scan UX,
  metadata-only backup/restore semantics,
  Android smoke verification,
  and iOS verification constraints.
- Current status:
  implemented and locally verified on 2026-05-09 through the Linux workstation
  gates that are available here.
  Android runners,
  photo/media permissions,
  photo-library media source,
  mobile scan orchestration,
  mobile onboarding,
  Android user-state toolchain,
  Android debug APK build,
  and Android emulator smoke are complete.
  Android smoke passed on `emulator-5554`
  (`Android SDK built for x86_64`,
  Android 16/API 36) for denied permission recovery,
  selected-photo limited access,
  full-access import,
  restart persistence,
  and metadata backup restore.
  iOS runner metadata and photo-library usage descriptions are scaffolded and
  statically reviewed,
  but iOS real-device verification requires macOS/Xcode.
- Execution order:
  start with Android tooling/readiness and platform scaffolding,
  then implement the mobile `MediaSourceAdapter`,
  then wire app-service scan progress,
  then adapt the UI,
  then run Android smoke.
- Constraint:
  iOS code/config can be prepared on this Linux workstation,
  but iOS real-device verification must be done from macOS/Xcode before the
  iOS exit gate can be closed.
- Verification evidence:
  Electron regression gates pass with `pnpm test`,
  `pnpm typecheck`,
  `pnpm build`,
  `pnpm run e2e:accessibility`,
  `pnpm run e2e:runtime`,
  and
  `pnpm run e2e:prepare && pnpm exec playwright test -c tests/e2e/playwright.config.ts i18n.spec.ts`.
  Flutter regression gates pass with Dart analyze,
  Dart package tests,
  Flutter UI/parity tests,
  `flutter build apk --debug`,
  and Android emulator smoke on `emulator-5554`.
- Remaining before Phase 7 cutover:
  complete Phase 6.5 mobile deep E2E verification;
  run the iOS build/run gate from macOS/Xcode;
  then handle release signing,
  mobile privacy disclosures,
  and migration/cutover packaging.

### 6.5 Flutter Mobile Deep E2E Verification

- Implementation plan:
  [docs/superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md](docs/superpowers/plans/2026-05-09-flutter-mobile-deep-e2e-verification.md)
- Scope:
  deepen mobile validation after Phase 6 by adding a repeatable Android
  emulator E2E runner,
  Flutter integration coverage for app-owned mobile workflows,
  stable mobile test hooks,
  durable screenshot/XML/backup evidence,
  and an explicit iOS macOS/Xcode verification gate.
- Current status:
  completed locally on 2026-05-10.
  The evidence matrix,
  stable mobile hooks,
  Android permission/import/restart/backup runner,
  app-owned Android integration workflow test,
  iOS macOS/Xcode evidence gate,
  and full closeout verification have landed locally.
- Execution order:
  first create the mobile E2E evidence matrix,
  then add stable mobile test hooks,
  then automate Android permission/import/restart/backup checks,
  then add app-owned integration tests for edit/favorite/memory/detail/gallery/search/settings flows,
  then record iOS requirements and close out the phase.
- Constraint:
  Android permission dialogs and selected-photo picker flows must be driven by
  `adb`/`uiautomator` because they are outside Flutter's widget tree.
  iOS remains pending until macOS/Xcode evidence exists.
- Exit gate:
  Android deep E2E is repeatable from a clean emulator state and covers denied,
  limited,
  full-access,
  restart persistence,
  metadata backup restore,
  and key app-owned workflows.
  iOS evidence is either completed from macOS/Xcode or explicitly recorded as
  pending with exact commands and required screenshots.
- Remaining before Phase 7 cutover:
  run iOS verification from macOS/Xcode when available before treating iOS as
  release-verified,
  then proceed to release signing,
  mobile privacy disclosures,
  and migration/cutover packaging.

### 6.6 Flutter Linux Desktop Parity Hardening

- Status:
  completed locally on 2026-05-10 after Phase 6.5.
- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md](docs/superpowers/plans/2026-05-10-flutter-linux-desktop-parity-hardening.md)
- Scope:
  refresh Electron and Flutter Linux parity evidence after Phase 6/6.5,
  inspect all 13 side-by-side compare artifacts,
  preserve or repair desktop parity before Phase 7 release work starts.
- Method:
  run Electron and Flutter Linux against the same parity fixtures,
  capture screenshot evidence for home/library,
  gallery/detail overlay,
  memory list/detail,
  search/filter/sort,
  settings,
  notifications,
  Chinese locale,
  and restart persistence,
  then fix only confirmed mismatches until the Flutter desktop app remains
  functionally and visually aligned with the Electron reference.
- Exit gate:
  all 13 Electron screenshots,
  all 13 Flutter Linux screenshots,
  and all 13 compare artifacts are refreshed;
  `docs/flutter-electron-ui-functional-parity.md` and
  `docs/flutter-electron-feature-ui-review.md` are updated with Phase 6.6
  findings;
  any confirmed gap has a focused test or documented coverage path;
  Electron and Flutter desktop parity verification commands pass.
- Result:
  no new product UI/function gap was found beyond existing accepted renderer
  differences.
  Two parity-harness gaps were closed:
  `P66-001` normalized Flutter capture locale for normal English surfaces,
  and `P66-002` isolated Playwright artifacts so E2E runs no longer delete
  parity screenshot evidence.

### 7. Flutter Release Readiness And Cutover

- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md](docs/superpowers/plans/2026-05-10-flutter-release-readiness-and-cutover.md)
- Status:
  complete on 2026-05-10.
- Scope:
  Android deep E2E runner hardening,
  Electron-backup migration compatibility,
  Flutter Android/Linux release artifacts,
  Flutter CI/release workflow promotion,
  and Flutter-only release documentation.
- Explicit release decision:
  Flutter is the release target.
  Electron is no longer released;
  it remains only as reference and migration source until cutover is complete.
- Planned execution order:
  1. Android deep E2E runner hardening:
     improve `adb`/`uiautomator` retry logging,
     assert required screenshot/XML/backup artifacts after every run,
     write summary JSON,
     and repeat the clean-emulator runner twice to catch flake before release
     work starts.
     Implementation status:
     helper,
     runner logging/summary hardening,
     two-run wrapper,
     and live two-run emulator evidence are complete.
     Evidence:
     `.tmp/mobile-e2e/android-repeat/20260510T044545Z/combined-summary.json`
     reports `passed`.
  2. Migration and cutover compatibility:
     verify Flutter backup import against a sanitized real Electron backup
     fixture,
     document the Electron-to-Flutter migration path,
     and decide whether direct old SQLite import is still needed after backup
     import coverage is proven.
     Implementation status:
     complete.
     Evidence:
     `pnpm run e2e:backup`,
     `node scripts/write-flutter-migration-fixtures.mjs`,
     and
     `cd chronopic_flutter && dart test packages/chronopic_app/test/electron_backup_import_test.dart`
     pass.
     Direct old SQLite import is not required for Phase 7 unless JSON backup
     export/restore fails on a real user backup.
  3. Release signing and Android distribution readiness:
     add secret-safe signing configuration,
     build release APK/AAB artifacts,
     record Play Store photo-permission/privacy disclosure text,
     and document the Android release checklist.
     Implementation status:
     complete for technical release verification.
     Current `applicationId` is still `com.example.chronopic`,
     so artifacts are not production-uploadable until the final id is chosen.
     Evidence:
     unsigned/missing-signing release build fails with a clear message,
     local signed release APK/AAB build passes,
     and
     `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs android linux`
     verifies APK/AAB/Linux sha256 files.
  4. Flutter Linux release artifact:
     build `chronopic-flutter-linux-x64-0.1.5.tar.gz`,
     create `.sha256`,
     and verify the archive contains the Flutter `chronopic` executable.
     Implementation status:
     complete locally.
     Evidence:
     `chronopic_flutter/tool/release/build_linux_release.sh`
     and
     `node chronopic_flutter/tool/release/verify_flutter_release_artifacts.mjs linux`
     pass.
  5. CI gate promotion:
     add or extend CI/manual workflows for Flutter analyze,
     Dart package tests,
     Flutter UI/parity tests,
     Android debug build,
     and optionally a manually triggered Android emulator E2E workflow.
     Implementation status:
     complete.
     CI now has a Flutter job,
     `.github/workflows/android-deep-e2e.yml` provides a manually triggered
     Android emulator deep E2E gate,
     Electron package verification is no longer a CI release gate,
     and Android deep E2E remains both a local and manual CI Phase 7 gate.
  6. Flutter release workflow:
     replace Electron tag-release assets with Flutter Android and Flutter Linux
     artifacts.
     Do not publish new Electron release assets.
     Implementation status:
     complete.
     Tag release workflow now uploads Flutter Android and Flutter Linux assets
     only.
     iOS remains blocked until macOS/Xcode signing and E2E evidence exist.
- Final Phase 7 gate:
  passed on 2026-05-10.
  Evidence:
  `pnpm test && pnpm typecheck && pnpm build`,
  Flutter analyze/package tests/widget tests,
  `flutter build apk --debug`,
  Android two-run E2E hardening,
  signed Android release build,
  Linux release build,
  combined Android/Linux artifact verification,
  and `git diff --check` all passed locally.
- Version rule:
  before adding or changing dependencies,
  GitHub Actions,
  Android SDK/Gradle/Flutter setup,
  or release tooling,
  check the latest stable version from official sources and record the selected
  version in `AGENTS.md`.
- iOS:
  keep the existing macOS/Xcode live verification gate blocked until real
  Apple-toolchain evidence exists.

### 8. Flutter Adaptive Import And Performance Hardening

- Implementation plan:
  [docs/superpowers/plans/2026-05-10-flutter-adaptive-import-performance.md](docs/superpowers/plans/2026-05-10-flutter-adaptive-import-performance.md)
- Status:
  completed locally on 2026-05-10.
- Scope:
  repair Flutter desktop adaptive layout,
  make the waterfall browse surface genuinely lazy,
  add Android photo-library scope selection before scanning,
  and reduce blocking mobile scan work.
- Root causes confirmed on 2026-05-10:
  1. Desktop/mobile browse pages are wrapped by shell-level
     `SingleChildScrollView` containers and centered max-width frames.
     On wide desktop this creates large dead space and prevents the browse page
     from owning its own viewport.
  2. The waterfall grid uses `GridView.builder`, but it is configured with
     `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside the
     shell-level scroll view.
     That means large result sets participate in one page layout instead of
     being virtualized by the viewport.
  3. Android scanning is currently hard-coded to the synthetic full-library
     path:
     `PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: true)`
     followed by `paths.first.getAssetListPaged(page: 0, size: 100000)`.
     The user cannot choose a specific album/folder-like scope.
  4. Mobile import reads original asset bytes for changed items and thumbnail
     generation decodes/resizes/writes synchronously on the scan path, which can
     make Android import slow and visibly stuck on larger libraries.
- Dependency/version note:
  `photo_manager` was checked against the pub.dev package API on 2026-05-10;
  latest stable is `3.9.0`, matching the current workspace dependency.
- Planned execution order:
  1. Responsive browse viewport:
     let the home/browse page own its scroll viewport,
     align desktop content to the available content area instead of centering
     a narrow column,
     and keep non-browse settings/memory pages scroll-safe.
  2. Lazy waterfall:
     replace the shrink-wrapped browse grid with a sliver grid,
     add incremental query limits and scroll-threshold loading,
     and reset pagination whenever filters, sort, favorites, memory scope, or
     library scope changes.
  3. Android scoped import:
     expose photo-library scopes from `photo_manager`,
     let the user select a concrete scope before scanning,
     and keep All Photos as an explicit choice instead of an invisible default.
  4. Scan responsiveness:
     page mobile asset discovery,
     avoid original-byte reads when thumbnail bytes are enough,
     move CPU-heavy thumbnail work away from synchronous UI-visible scan steps,
     and preserve progress reporting.
  5. Verification:
     run focused Flutter widget tests,
     Dart package tests,
     Flutter analyze,
     Android debug build,
     Android scoped-import E2E where emulator tooling is available,
     and desktop screenshot comparisons at 1366/1600/2048 widths.
- Completion criteria:
  completed on 2026-05-10 with passing code/tests and recorded screenshot/E2E
  evidence.
- Implementation completed on 2026-05-10:
  1. Browse pages now own their viewport instead of being wrapped by the global
     shell scroll frame.
     The home page uses a `CustomScrollView` and sliver grid,
     while non-browse pages keep local scroll behavior.
  2. Waterfall query/render volume is incremental:
     initial result limit is 20 photos,
     scroll-near-end and the fallback load-more control increase the limit by
     20,
     and search/filter/sort/favorites/memory changes reset pagination.
  3. Android import now exposes `PhotoLibraryScope` choices from
     `photo_manager`.
     The user selects `All Photos` or a concrete album/path-like scope before
     scanning,
     and the selected scope is persisted in the source path for that scan.
  4. Mobile asset discovery is paged in `PhotoManagerGateway` instead of
     requesting 100000 assets in one call.
     Disabled-AI scans prefer thumbnail bytes and avoid reading original bytes,
     while thumbnail decode/resize/write runs through `Isolate.run`.
  5. The Android deep E2E runner now validates the scoped-import sheet in both
     full-access and limited-access flows,
     including `03-scope.xml`,
     `04-scope.xml`,
     and artifact assertions for the selected `ChronoPicDeepE2E` scope.
- Verification evidence:
  `cd chronopic_flutter && flutter analyze`,
  `cd chronopic_flutter && dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_app/test packages/chronopic_media/test`,
  `cd chronopic_flutter && flutter test packages/chronopic_ui/test/chronopic_home_test.dart packages/chronopic_ui/test/linux_desktop_parity_test.dart`,
  `cd chronopic_flutter/apps/chronopic && flutter build linux --debug`,
  `ANDROID_DEVICE_ID=emulator-5554 MOBILE_E2E_RUN_ID=phase8-final-20260510T122821Z chronopic_flutter/tool/mobile_e2e/android_deep_e2e.sh`,
  and
  `node chronopic_flutter/tool/mobile_e2e/assert_android_deep_e2e_artifacts.mjs .tmp/mobile-e2e/android/phase8-final-20260510T122821Z`
  all passed.
- Screenshot evidence:
  `test-results/flutter-adaptive-phase8/1366-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/1600-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/2048-populated-grid.png`,
  `test-results/flutter-adaptive-phase8/1366-detail.png`,
  `test-results/flutter-adaptive-phase8/1600-detail.png`,
  and
  `test-results/flutter-adaptive-phase8/2048-detail.png`.

- Person / face grouping:
  add person-like memory grouping only after the app has a real person-recognition or clustering signal.
  Do not pretend to identify people from generic captions or tags.
- OCR and text-in-image search:
  useful for screenshots, documents, receipts, posters, and travel photos.
  Should feed the same discovery/search model rather than creating a separate OCR-only search surface.
- Vector / embedding search:
  useful once semantic search needs fuzzy matching beyond inspectable text fields.
  Must preserve local-first semantics and explain provider/storage tradeoffs clearly.
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
- A future Flutter rewrite is tracked separately in [docs/flutter-refactor-phases.md](docs/flutter-refactor-phases.md). Phase 0 is complete in [docs/flutter-parity-contract.md](docs/flutter-parity-contract.md), but Flutter/Dart implementation should start with Phase 1 domain/backup compatibility against the committed parity fixtures.
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
