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
pnpm run e2e:accessibility
pnpm run e2e:backup
```

`pnpm run e2e:runtime` launches the built Electron app with an isolated user-data directory, indexes fixture media, writes edits and memory data, restarts the app, and verifies persistence through the preload IPC bridge.

`pnpm run e2e:accessibility` launches the built Electron app and verifies the core keyboard/focus loop: first-run setup, post-scan onboarding, create-memory focus return, photo-card keyboard activation, viewer Escape close, and batch-select accessible names.

`pnpm run e2e:backup` launches the built Electron app, exports a local JSON backup, previews conflicts, restores into a clean user-data directory, and verifies authored metadata, favorites, memories, memberships, locale, and map settings.

For broader agent-led product validation, follow the director script in `docs/agent-verification-script.md`. It tells code agents how to use Playwright manually after completing plan items, including which product scenes to inspect and what evidence to record in `AGENTS.md`.

## Local Packaging

Build an unpacked Linux desktop artifact:

```sh
pnpm run package:linux
```

The local artifact is emitted at `dist/release/chronopic-linux-x64/chronopic`. Verify the artifact layout and native modules:

```sh
pnpm run package:verify
```

Run the packaged smoke test, which launches the packaged executable rather than `apps/desktop/dist/main/main.js`:

```sh
pnpm run package:smoke
```

In headless Linux environments, run the smoke command under Xvfb:

```sh
xvfb-run -a pnpm run package:smoke
```

Current packaging scope is local Linux unpacked output only. Signing, notarization, auto-update, installers, and macOS/Windows artifacts are follow-up release work.

## Tag Releases

Pushing a version tag that starts with `v` runs the release workflow:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The workflow builds the Linux package, verifies the packaged artifact, runs packaged E2E under Xvfb, archives `dist/release/chronopic-linux-x64`, writes a SHA-256 checksum, and publishes both files to the GitHub Release for the tag.

## Optional Integrations

AI enrichment is disabled unless all required settings are present in the app settings or environment:

- `CHRONOPIC_AI_API_KEY`
- `CHRONOPIC_AI_BASE_URL`
- `CHRONOPIC_AI_MODEL`
- `CHRONOPIC_AI_PROVIDER`

Map browsing uses Gaode/AMap Web JS API settings saved from the desktop settings page. Leaving the API key blank keeps map rendering disabled.

## Backup And Restore

Library Settings includes local JSON backup controls. Backups include ChronoPic's database projection and settings: library source records, photo metadata, authored captions/tags/datetime edits, favorites, memories, memory memberships, generated fields, memory candidates, AI settings, map settings, and locale settings. Original media files are referenced by path and are not copied into the backup.

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
