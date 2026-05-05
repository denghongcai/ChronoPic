# Agent Verification Script

This is a director script for code agents working on ChronoPic. It is not a rigid E2E test suite and it is not meant to replace `pnpm test`, `pnpm typecheck`, `pnpm build`, or `pnpm run e2e:runtime`.

Use this script after completing any `PLAN.md` phase, phase checklist item, or meaningful implementation slice. The goal is to make the agent deliberately inspect the product as a desktop app, choose the right Playwright checks for the change, and leave concrete evidence before marking work complete.

## When To Run

Run this script before marking a `PLAN.md` item complete and before adding a completion entry to `AGENTS.md`.

Run it again near the end of a larger phase if multiple slices were implemented.

If a change is docs-only and has no runtime/UI impact, record why runtime Playwright verification was skipped and still run the relevant static/documentation checks.

## Preflight

1. Read the current `PLAN.md` item being completed.
2. Read the latest relevant `AGENTS.md` entries.
3. Check `git status --short` and identify which files changed.
4. Map the change to affected user flows:
   - first-run setup
   - library source management
   - scan and browse
   - waterfall, map, or timeline browse mode
   - focused detail/gallery viewer
   - edit history and rollback
   - favorites
   - memory list/detail/authoring
   - AI queue, memory candidates, or notifications
   - settings, locale, AI config, or map config
5. Choose the scenes below that cover the affected flows. Always include Scene 1 and Scene 7 for user-facing runtime changes.

## Scene 1 - Launch And First Impression

Purpose: verify that the app launches as an Electron desktop app and that the first visible screen matches the current product state.

Agent actions:

- Build if the changed files affect runtime output:
  `pnpm build`
- Launch Electron through Playwright with a temporary `CHRONOPIC_USER_DATA_DIR`.
- Capture a screenshot of the first window.
- Inspect the main shell for obvious blank screens, broken CSS, missing preload bridge, console errors, or first-run copy that contradicts the current state.

Evidence to record:

- Whether Electron loaded production renderer assets successfully.
- Screenshot path or description.
- Any renderer console errors that are not known environment noise.

## Scene 2 - First-Run And Library Setup

Purpose: verify the local-first entry path.

Agent actions:

- Start from an empty temporary app data directory.
- Confirm the first-run panel explains local folder setup.
- Confirm the primary action is `Add Folder` when no source exists.
- Add a controlled fixture directory through the preload bridge or dialog automation.
- Confirm the state changes to a scan-ready path.

Evidence to record:

- Empty-state screenshot or notes.
- Source count after adding the fixture directory.
- Whether the UI copy distinguishes no-source from no-results.

## Scene 3 - Scan And Browse

Purpose: verify the core media ingestion loop.

Agent actions:

- Use a small fixture library with at least two supported images. Use deterministic local fixtures for repeatability; use `https://picsum.photos/` only when richer visual screenshots are needed.
- Run `scanLibrary` through the preload bridge or UI.
- Confirm indexed photo count, thumbnail presence, and browse visibility.
- Check the waterfall gallery first. If the change affects map or timeline, switch to those modes and verify their empty/ready state.

Evidence to record:

- Indexed count.
- Screenshot after scan.
- Notes on thumbnail, layout, and browse-mode state.

## Scene 4 - Focused Viewing

Purpose: verify that selecting and opening media still works after the change.

Agent actions:

- Select a photo.
- Open detail view.
- Switch to gallery view if the change touches viewer behavior.
- Verify next/previous navigation, escape/close behavior, and original-media loading.

Evidence to record:

- Detail/gallery screenshot or notes.
- Any broken keyboard or viewer-control behavior.

## Scene 5 - Editing, Favorites, And Rollback

Purpose: verify that user-visible edits flow through IPC and SQLite.

Agent actions:

- Edit caption.
- Edit tags.
- Toggle favorite.
- Edit datetime.
- Roll back the latest edit.
- Re-read the photo record through preload and confirm the rollback affected only the intended field.

Evidence to record:

- Before/after field values.
- Whether manual caption/tags/favorite state persisted.
- Whether rollback matched the intended latest edit.

## Scene 6 - Memories

Purpose: verify that memory authoring remains usable.

Agent actions:

- Create a memory.
- Add at least one scanned photo to it.
- Open memory detail.
- If the change affects memory editing, update title/description/cover or remove a photo.
- Confirm memory list, memory detail, and photo-to-memory relationship remain consistent.

Evidence to record:

- Memory id/name.
- Photo count in the memory.
- Screenshot or notes for memory list/detail.

## Scene 7 - Restart Persistence

Purpose: verify that runtime state survives a real Electron restart.

Agent actions:

- Close Electron.
- Re-launch with the same temporary `CHRONOPIC_USER_DATA_DIR`.
- Confirm sources, photos, edited fields, favorites, memories, and locale/settings touched by the scenario are still present.

Evidence to record:

- Persisted source count.
- Persisted photo count.
- Persisted memory count or memory detail.
- Persisted settings relevant to the change.

## Scene 8 - Settings, Locale, AI, And Map

Purpose: verify configuration surfaces that often fail without obvious compile errors.

Agent actions:

- Open Library Settings when the change touches settings or configuration.
- Switch UI locale if i18n is affected.
- Save AI settings only with safe placeholder/test values; confirm disabled or configured state is understandable.
- Save map settings only with safe placeholder/test values; confirm missing key states do not look like app failure.

Evidence to record:

- Locale before/after.
- Settings persistence after restart if settings were changed.
- Screenshot or notes for disabled optional capability states.

## Scene 9 - Notifications And AI Queue

Purpose: verify operational surfaces after AI, memory-candidate, or status-message changes.

Agent actions:

- Open Notifications.
- Verify queue counts and actions are visible and understandable.
- If AI is disabled, confirm the UI says so without blocking the rest of the app.
- If a memory-candidate path changed, generate or inspect candidates using deterministic disabled/test-provider behavior.

Evidence to record:

- Notification page screenshot or notes.
- Queue/candidate counts.
- Whether disabled-provider behavior is clear.

## Required Closeout

Before marking the plan item complete:

1. Run the normal verification commands appropriate to the change:
   - `pnpm test`
   - `pnpm typecheck`
   - `pnpm build`
   - `pnpm run e2e:runtime` when runtime behavior is affected
2. Run the selected Playwright scenes above manually or with temporary ad hoc Playwright code.
3. Record the evidence in `AGENTS.md`:
   - scenes run
   - commands run
   - screenshots or report paths if created
   - uncovered risks or skipped scenes with reasons
4. Update `PLAN.md` only when the corresponding implementation and verification have landed locally.

## Agent Notes

- Prefer temporary app data with `CHRONOPIC_USER_DATA_DIR` so verification does not mutate the user's real desktop state.
- Keep ad hoc Playwright snippets out of the repo unless they become stable tests.
- Do not mark a phase complete from screenshots alone. Screenshots are evidence of rendering, not persistence or data correctness.
- Do not mark a phase complete from tests alone. Tests are evidence for the paths they cover, not for the full product workflow.
- If Playwright finds a runtime bug, fix the root cause and rerun the affected scene plus the normal verification commands.
