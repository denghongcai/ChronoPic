# ChronoPic UX Refine Research

- Date: 2026-05-06
- Phase: 4.18 UX Refine and Lazyweb Research
- Current-state screenshots: `references/current-01-empty-home.png` through `references/current-09-viewer.png`
- Fixture imagery: `fixture-library/*.jpg`, downloaded from https://picsum.photos/

## Lazyweb Status

The Lazyweb design skill is installed, but the Lazyweb MCP tools are not exposed as callable tools in this Codex runtime. This report uses the required Lazyweb phase structure, local current-state screenshots, and fallback web research sources. The capture details are recorded in `capture-notes.md`.

## Sources Reviewed

- Material Design empty states: https://m1.material.io/patterns/empty-states.html
- Material Design navigation: https://m1.material.io/patterns/navigation.html
- Apple HIG patterns landing page: https://developer.apple.com/design/human-interface-guidelines/patterns
- UserOnboard empty-state onboarding patterns: https://www.useronboard.com/onboarding-ux-patterns/empty-states/

## Current-State Findings

### P0 - First-run home is a dead end

Evidence: `references/current-01-empty-home.png`

The main canvas says there is no matching media, which reads like a failed filter state. For a brand-new local-first app, the first screen should drive the user toward adding a local folder and scanning it. This aligns with empty-state guidance that blank spaces should prevent confusion and can provide starter direction or educational content when no content exists.

Implementation direction:

- Add a first-run panel at the top of the home page.
- Show `Add Folder` when there are no registered sources.
- Show `Scan Library` when sources exist but no indexed media exists.
- Keep the copy short and framed around local-first indexing.

Status: implemented in Phase 4.20 follow-up.

### P1 - Navigation hierarchy is mostly right, but high-frequency actions need clearer context

Evidence: `references/current-02-populated-waterfall.png`, `references/current-08-settings.png`

The sidebar now matches a desktop content app structure: Library, Memories, Notifications, Settings. The remaining issue is contextual priority. Add/scan belongs in the first-run and settings contexts; memory creation belongs near memory surfaces. This matches navigation guidance to prioritize common tasks and group related tasks.

Implementation direction:

- Keep global navigation stable.
- Surface setup actions contextually rather than relying only on settings.
- Avoid adding another global action rail until repeated workflows justify it.

Status: partially implemented by the new first-run panel.

### P1 - Empty states should distinguish "no library", "not scanned", and "no filter result"

Evidence: `references/current-01-empty-home.png`, `references/current-03-timeline.png`, `references/current-04-map.png`

The app has multiple legitimate empty states, but they should not all use the same mental model. A missing library is onboarding. A source without indexed photos is operational. A filtered gallery/map/timeline result is query feedback.

Implementation direction:

- Home onboarding handles no-source and no-indexed-photo states.
- Gallery empty state can remain result-oriented.
- Timeline and map empty states should continue explaining missing metadata requirements.

Status: home onboarding implemented; deeper map/timeline refinement remains optional.

### P2 - Recent Memories can dominate an empty home

Evidence: `references/current-01-empty-home.png`

The recent memories section is useful after content exists, but it takes prominent space before a user has created memories. Once the first-run panel is visible, it gives the screen a clearer order: setup first, memories second, browse third.

Implementation direction:

- Keep recent memories visible but below the first-run prompt.
- Consider collapsing it later when there are no memories and no indexed photos.

Status: first-run ordering implemented; collapse behavior remains backlog.

### P2 - Settings remains card-heavy

Evidence: `references/current-08-settings.png`

Settings is functional and scannable, but it uses several nested surfaces. The app does not need a visual refactor immediately, but later polish should flatten settings sections into quieter full-width panels.

Implementation direction:

- Leave current settings structure for now.
- Revisit after runtime QA and first-run onboarding are stable.

Status: backlog.

## Adopted Change

The highest-impact refinement is the first-run/onboarding panel because it directly unblocks new users and makes the local-first model visible without a product tour.

## Backlog

- Collapse or down-rank Recent Memories when the app has no memories and no indexed photos.
- Add scan-result summary with indexed count, skipped count, and error count after a scan.
- Make the selected-photo blue banner quieter once memory actions are more discoverable.
- Flatten Library Settings into fewer nested cards.
- Add small visual cues for AI-disabled and map-disabled states without making them look like errors.
