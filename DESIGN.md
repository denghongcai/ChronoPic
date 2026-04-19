# ChronoPic UI/UX Redesign Guide

## Purpose

This document defines the next-stage visual and interaction redesign for ChronoPic.
It is intentionally product-facing rather than implementation-facing:
it explains what the interface should feel like,
how the browse surfaces should be organized,
and which UI decisions are considered in-bounds for the redesign phase.

The redesign should move ChronoPic away from a "tool panel with features attached" feeling
and toward a calm, editorial, collection-first photo workspace.

The reference direction for this phase is:

- spacious desktop-first composition
- strong visual hierarchy with clear hero content
- memory/collection cards that feel premium and cinematic
- lightweight navigation chrome
- browsing surfaces that feel like different lenses over the same library,
  not separate sub-products

## Product Intent

ChronoPic is not meant to feel like a generic admin dashboard.
It should feel like a local-first photo curation product:

- part library browser
- part memory workspace
- part spatial / temporal exploration tool

The product should communicate:

- calm over density
- curation over raw file management
- focus over clutter
- continuity across waterfall, map, and timeline

## Design Principles

### 1. Collection-First, Not Control-First

The first thing the user should feel is the presence of memories, collections, and images,
not buttons, filters, and chrome.

Implications:

- memory cards should be visually dominant near the top of the home screen
- browse controls should be present but not visually heavier than the content
- scanning / system management belongs in settings or secondary zones, not in the hero area

### 2. One Library, Multiple Lenses

`Waterfall`, `Map`, and `Timeline` are different views of the same result scope.
The UI must reinforce that these are perspective switches, not separate pages.

Implications:

- one shared browse header area
- one shared search / result-scope model
- consistent selected-photo context across all modes
- viewer entry should feel identical regardless of which mode opened it

### 3. Spacious Editorial Layout

The redesign should favor generous whitespace, strong content framing, and fewer hard boxes.
It should feel more like a media surface than an internal tool.

Implications:

- increase vertical rhythm between sections
- let featured memories breathe with larger cards
- reduce unnecessary borders and nested panel chrome
- use grouping and spacing before adding more separators

### 4. Quiet Navigation, Strong Content

Navigation should stay legible and always available, but visually recede behind the content.

Implications:

- sidebar should remain slim, stable, and quiet
- top bar should not feel heavier than the main canvas
- content titles and memory cards should drive emphasis, not nav components

### 5. Browsing Before Editing

The main product flow is browse, discover, select, then refine.
Editing controls should remain available but should not dominate the default screen state.

Implications:

- metadata and edit affordances belong in detail view, viewer, or focused panels
- home / browse views should prioritize scanning, grouping, and comparison
- destructive actions should stay visually subdued unless directly in context

### 6. Visual Consistency Across Browse Modes

Waterfall, map, and timeline should share common structure:

- browse title
- mode switch
- scope explanation
- selected-photo context
- result surface

Each mode can have a different body,
but the shell should feel consistent enough that the user never has to re-learn the page.

## Information Architecture

### Primary Regions

The redesigned desktop app should be read as four stable regions:

1. Sidebar
2. Featured Memories / Highlights
3. Browse Library shell
4. Focused viewer / detail surfaces when active

### Sidebar

Sidebar purpose:

- establish global orientation
- provide fast library pivots
- expose memories/collections list
- provide a low-emphasis create action

Sidebar should contain:

- app mark / product identity
- `All Photos`
- `Favorites`
- `Recent`
- `Settings`
- memories / collections list
- a low-emphasis `Create Memory` action anchored near the bottom

Sidebar should not contain:

- heavy stats blocks
- large management cards
- duplicate browse-mode controls

### Featured Memories / Highlights

This is the home hero surface.
It should make the product feel emotionally anchored in curation rather than file management.

Content:

- large cinematic memory cards
- title
- item count
- relative update time
- optional badge or source tag
- a trailing create-new tile/card

Behavior:

- cards should open memory detail
- this row should remain horizontally scannable and visually prominent

### Browse Library

This is the shared browse shell for library exploration.

It should contain:

- section title
- browse-mode switcher
- total result count
- search entry
- secondary filter action
- current-mode result surface

It should not contain:

- oversized system status tiles
- duplicated local explanations that belong elsewhere
- multiple competing toolbars stacked on top of each other

### Focused Viewer

Viewer remains the focused inspection surface.
It should stay mode-agnostic:

- waterfall can open it
- map can open it
- timeline can open it

The redesign phase does not change the viewer model fundamentally,
but visual integration should align it with the calmer main layout.

## Visual Direction

### Tone

Desired tone:

- refined
- soft
- warm-neutral
- photo-led
- premium but understated

Avoid:

- dashboard heaviness
- loud gradients everywhere
- overly dark enterprise chrome
- neon accents
- excessive card borders

### Layout Density

Target density:

- medium-low density
- large enough cards to create visual rhythm
- compact enough to browse at speed

Desktop priority should remain strong.
Do not over-optimize this phase for small-screen constraints at the cost of desktop quality.

### Shape Language

Preferred:

- rounded containers
- soft surfaces
- restrained shadows
- image cards with clear but not overly thick radii

Avoid:

- sharp utilitarian tables
- box-within-box nesting
- too many inset borders

### Typography

Typography should clearly separate:

- navigation labels
- section labels
- section titles
- card titles
- metadata text

Desired behavior:

- section titles are strong and editorial
- metadata remains quiet and compact
- small uppercase labels are used sparingly for structure

### Color

Recommended palette behavior:

- warm white / neutral base
- charcoal text
- soft gray support surfaces
- one restrained accent family for active states
- amber/gold can remain as a product accent if used sparingly

Color should support hierarchy,
not become the hierarchy.

## Interaction Principles

### 1. Search and Filtering Must Feel Lightweight

Search is primary.
Filtering is secondary.

Implications:

- search should stay visible near the browse shell
- secondary filters can collapse into a quieter control
- users should not face a wall of controls before seeing content

### 2. Selection Must Be Obvious but Not Heavy

Selecting a photo should be visually clear.
However, selection UI must not overpower browsing.

Implications:

- use a concise selected-state summary
- keep batch mode explicit
- avoid persistent loud selection chrome when not needed

### 3. Memory Actions Should Follow the Content

Memory creation and assignment should feel like curation actions,
not management chores.

Implications:

- memory cards are content-first
- `Add to Memory` stays close to photo/media actions
- create-memory entry should exist in sidebar and highlights row, but not dominate

### 4. Map and Timeline Need Immediate Context

Map and timeline are inherently secondary lenses.
They need stronger explanation than waterfall,
but that explanation should be integrated into the shell instead of appearing as random banners.

Implications:

- use a shared browse header zone
- explain current scope and current selection consistently
- avoid making map/timeline feel like prototype placeholders

## Screen-Level Redesign Targets

### Home / Library Surface

Target composition:

- left sidebar
- top highlight row with featured memories
- browse library section below
- quiet search and result count alignment on the right

The reference screenshots indicate a stronger top-down narrative:

- highlights first
- browse second
- controls embedded into browse rather than floating everywhere

### Memory Cards

Memory cards should become more cinematic and premium:

- edge-to-edge cover image
- overlaid title and metadata
- optional memory badge
- clear hover / click affordance

The create-new memory tile should visually belong to the row,
but remain clearly secondary to existing memories.

### Waterfall View

Waterfall should remain the fastest browse mode.
The redesign target is not "more UI",
but "cleaner framing".

Desired adjustments:

- stronger image rhythm
- less competing text
- clearer section spacing
- quieter support controls

### Map View

Map should visually feel part of the browse library shell.

Desired adjustments:

- map canvas and place list should read as one composed surface
- selected place context should be obvious
- list cards should feel visually aligned with the rest of the product

### Timeline View

Timeline should feel like a curated chronology,
not just gallery cards grouped by date.

Desired adjustments:

- stronger date headers
- more editorial spacing between groups
- clearer period labels
- selected-photo context integrated into the shell

## Component Expectations

### Components That Should Stay Shared

- browse mode switcher
- search input
- button / badge / icon button primitives
- memory card
- photo card
- selected-context callouts
- surface/panel primitives where still useful

### Components That Should Stay Renderer-Owned

- AMap loader and map lifecycle
- map viewport state
- timeline data orchestration
- shell-level composition of browse modes

## Technical Design Constraints

- Redesign must preserve strict package boundaries.
- Shared packages must not import renderer-only map SDK code.
- Design tokens and reusable UI components should stay in `@chronopic/ui-components`.
- App-specific page composition remains in the desktop renderer.
- Existing IPC, persistence, and indexing behavior must remain intact during redesign.

## Success Criteria

The redesign phase is successful when:

- the home screen feels collection-first instead of tool-first
- highlight memories feel premium and intentional
- browse library reads as one unified shell across waterfall, map, and timeline
- search/filter chrome becomes lighter and more coherent
- the product feels calmer, more editorial, and less like a generic dashboard
- implementation can proceed without blurring package boundaries

## Explicit Non-Goals

- no change to core persistence model in this phase
- no change to indexing architecture in this phase
- no new AI feature delivery in this phase
- no renderer-side shortcut to bypass existing application / IPC boundaries
- no full product rebrand or logo exercise
