# ChronoPic

ChronoPic is a local-first desktop photo workspace. It indexes user-selected folders, stores metadata in a local SQLite database, generates thumbnails, supports browse/filter/detail viewing, and lets users build Memories from selected photos. AI enrichment and map rendering are optional layers; the core desktop loop works without cloud services or API keys.

## Requirements

- Node.js 24
- pnpm 10
- Native build tooling supported by `better-sqlite3` and `sharp`

## Setup

```sh
pnpm install
```

If Electron or native modules are partially installed, the desktop launch scripts run local repair guards automatically:

```sh
pnpm --filter @chronopic/desktop run ensure:electron
pnpm --filter @chronopic/desktop run ensure:native
```

## Run

Development:

```sh
pnpm desktop:dev
```

Production-style desktop launch:

```sh
pnpm desktop:start
```

Use `CHRONOPIC_USER_DATA_DIR` to isolate the database, thumbnails, settings, and debug log:

```sh
CHRONOPIC_USER_DATA_DIR=/tmp/chronopic-dev pnpm desktop:start
```

## Verification

```sh
pnpm test
pnpm typecheck
pnpm build
pnpm run e2e:runtime
```

`pnpm run e2e:runtime` launches the built Electron app with an isolated user-data directory, indexes fixture media, writes edits and memory data, restarts the app, and verifies persistence through the preload IPC bridge.

For broader agent-led product validation, follow the director script in `docs/agent-verification-script.md`. It tells code agents how to use Playwright manually after completing plan items, including which product scenes to inspect and what evidence to record in `AGENTS.md`.

## Optional Integrations

AI enrichment is disabled unless all required settings are present in the app settings or environment:

- `CHRONOPIC_AI_API_KEY`
- `CHRONOPIC_AI_BASE_URL`
- `CHRONOPIC_AI_MODEL`
- `CHRONOPIC_AI_PROVIDER`

Map browsing uses Gaode/AMap Web JS API settings saved from the desktop settings page. Leaving the API key blank keeps map rendering disabled.

## Project Layout

- `apps/desktop`: Electron main/preload/renderer app
- `packages/domain`: shared domain types and defaults
- `packages/infra-db`: SQLite schema, migrations, and repositories
- `packages/infra-fs`: filesystem scanning and media metadata extraction
- `packages/services-indexer`: indexing orchestration
- `packages/services-ai-pipeline`: optional AI enrichment client
- `packages/ui-components`: shared React UI components
- `tests`: unit and E2E tests

## Planning

- `PLAN.md` is the stable product and implementation plan.
- `AGENTS.md` is the local execution log and must be updated after meaningful implementation or verification steps.
