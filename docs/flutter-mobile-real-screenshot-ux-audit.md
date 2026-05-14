# Flutter Mobile Real-Screenshot UX Audit

## Source Screenshots

- `.tmp/diagnostics/mobile-import-screenshot.jpg`: Android import/home screenshot from 2026-05-11.
- `.tmp/screenshots/mobile-count-scroll-2026-05-12.jpg`: Android focused Detail screenshot from 2026-05-12.
- `.tmp/user-input/mobile-ui-refine.png`: user-provided mobile UI refine proposal.

## Confirmed UX Issues

1. Home information hierarchy is too dense after Phase 11 and Phase 12.
2. Scan/catalog/browse totals are now logically correct, but repeated count surfaces make the first viewport harder to scan.
3. Bottom navigation and browse controls need stronger bottom-safe spacing so content does not feel clipped by the persistent nav.
4. Focused Detail is functionally correct, but the top action cluster is visually heavy on phone widths.
5. Gallery is functionally correct, but mobile actions should be simplified around view, navigate, and inspect rather than desktop-like command grouping.

## Phase 13 Decisions

- Keep the catalog total visible in one primary home shortcut, not repeated in every nearby status surface.
- Let scan/status cards communicate activity or readiness instead of restating the same count.
- Add explicit bottom-safe browse spacing for phone layouts because the bottom navigation is persistent.
- Treat mobile Detail as media-first: topbar, media, primary actions, then inspector/editing entry.
- Treat mobile Gallery as view-first: counter, media, filmstrip, and a compact action row for navigation/inspector.

## Phase 13 Implementation Result

- The All Photos shortcut owns the primary catalog count, keyed by `mobile-dashboard-primary-count`.
- The scan card now says `Ready for local browsing` or `Indexing without blocking browsing`.
- Waterfall browse adds a keyed mobile bottom spacer below the final sliver.
- Focused Detail separates the mobile topbar from primary actions and Details/inspector entry.
- Mobile Gallery adds a compact action row while preserving the full-result counter.
- The app-owned mobile integration test now rejects repeated `indexed locally` count copy.

## Non-Goals

- No data model changes.
- No scan pipeline changes.
- No lazy-thumbnail cache changes.
- No Play Store submission work.
- No OCR, vector search, person recognition, cloud sync, AI thumbnail analysis, or EXIF writeback.
- No iOS live verification claim from this Linux workstation.
