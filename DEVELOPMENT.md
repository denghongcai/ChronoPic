# ChronoPic Development

This document is for contributors and code agents working on ChronoPic. The user-facing product overview lives in [README.md](README.md).

## Repository Status

- Current package version: `0.1.7`
- Latest verified release: `v0.1.7`
- Package manager: `pnpm@10.0.0`
- Runtime baseline: Node.js 24
- Planning source: [PLAN.md](PLAN.md)
- Execution log: [AGENTS.md](AGENTS.md)
- Manual verification script: [docs/agent-verification-script.md](docs/agent-verification-script.md)

## Setup

Install dependencies:

```sh
pnpm install
```

If Electron or native modules are partially installed, the desktop launch scripts run repair guards automatically. They can also be run directly:

```sh
pnpm --filter @chronopic/desktop run ensure:electron
pnpm --filter @chronopic/desktop run ensure:native
```

Native modules matter in this repo because `better-sqlite3` and `sharp` need the correct ABI for the current launch target. Root scripts switch between Node and Electron rebuilds where needed.

## Run From Source

Development mode:

```sh
pnpm desktop:dev
```

Production-style local launch:

```sh
pnpm desktop:start
```

Use `CHRONOPIC_USER_DATA_DIR` to isolate the database, thumbnails, settings, and debug log:

```sh
CHRONOPIC_USER_DATA_DIR=/tmp/chronopic-dev pnpm desktop:start
```

## Verification

Core checks:

```sh
pnpm test
pnpm typecheck
pnpm build
```

Runtime E2E checks:

```sh
pnpm run e2e:runtime
pnpm run e2e:accessibility
pnpm run e2e:ai
pnpm run e2e:backup
```

Packaged smoke:

```sh
pnpm run e2e:packaged
```

In headless Linux environments:

```sh
xvfb-run -a pnpm run e2e:packaged
```

What the main E2E suites cover:

- `e2e:runtime`: launches the built Electron app, indexes fixture media, writes edits/memories/settings, restarts, and verifies persistence through the preload bridge.
- `e2e:accessibility`: checks the keyboard/focus loop for first-run setup, create-memory dialog focus return, photo-card activation, viewer Escape close, and batch-select accessible labels.
- `e2e:ai`: checks AI setup readiness, safe required-field visibility, disabled queue recovery, and the Notifications-to-Settings path without requiring real provider secrets.
- `e2e:backup`: exports a JSON backup, previews conflicts, restores into a clean data directory, and verifies authored metadata, favorites, memories, memberships, locale, and map settings.
- `e2e:packaged`: launches the packaged executable or app bundle directly rather than [apps/desktop/dist/main/main.js](apps/desktop/dist/main/main.js).

For broader product validation after a phase or meaningful implementation slice, follow [docs/agent-verification-script.md](docs/agent-verification-script.md) and record evidence in [AGENTS.md](AGENTS.md).

## Local Packaging

Build an unpacked desktop artifact on the matching OS:

```sh
pnpm run package:linux
pnpm run package:macos
pnpm run package:windows
```

Artifacts are emitted under:

```text
dist/release/chronopic-<target>-<arch>
```

Verify package layout, metadata, native modules, and excluded local artifacts:

```sh
pnpm run package:verify -- linux
pnpm run package:verify -- macos
pnpm run package:verify -- windows
```

Release archive creation is handled by:

```sh
node scripts/archive-release-artifact.mjs <target> <tag>
```

Release artifacts use this naming pattern:

```text
chronopic-<target>-<arch>-<tag>.tar.gz
chronopic-<target>-<arch>-<tag>.tar.gz.sha256
```

## Releases

Pushing a version tag that starts with `v` runs [.github/workflows/release.yml](.github/workflows/release.yml):

```sh
git tag v0.1.7
git push origin v0.1.7
```

The release workflow:

- creates or updates the GitHub Release for the tag
- builds Linux on `ubuntu-latest`
- builds macOS on `macos-latest`
- builds Windows on `windows-latest`
- verifies each packaged artifact
- runs packaged E2E on each platform
- creates `tar.gz` archives
- uploads archives and `.sha256` checksum files

Current release limitations:

- artifacts are portable, unpacked desktop bundles rather than installers
- macOS artifacts are not notarized
- Windows artifacts are not signed
- auto-update is not implemented

## Architecture

ChronoPic keeps the Electron process boundary strict:

- renderer owns UI and interaction state
- preload exposes the typed desktop bridge
- main process owns IPC, local filesystem access, protocol handling, and runtime creation
- application package owns use cases
- infra packages own persistence, filesystem, image, and config concerns
- services packages own indexing and AI pipeline orchestration
- UI package owns shared React presentation components

Workspace packages compile only their own `src` directory and expose deliberate `dist` exports. The desktop app consumes workspace packages through package interfaces rather than source aliases.

## Project Layout

```text
apps/desktop/
  main/                 Electron main process
  preload/              preload bridge
  renderer/             React renderer

packages/
  application/          app-level use cases
  domain/               shared domain types and defaults
  i18n/                 typed locale dictionaries and helpers
  infra-config/         local settings persistence
  infra-db/             SQLite schema, migrations, and repositories
  infra-fs/             filesystem scanning and media metadata extraction
  infra-image/          image/native integration
  services-ai-pipeline/ optional AI provider and normalization pipeline
  services-indexer/     indexing orchestration
  shared-utils/         shared helpers
  ui-components/        shared React UI components

scripts/                build, native-module, packaging, and release helpers
tests/                  unit and E2E tests
.github/workflows/     CI and tag release workflows
```

## Main Commands

```sh
pnpm desktop:dev          # run the Electron app in development mode
pnpm desktop:start        # build and run the production-style desktop app
pnpm test                 # Node/unit tests
pnpm typecheck            # package and desktop TypeScript checks
pnpm build                # clean build for packages and desktop app
pnpm run e2e:runtime      # Electron runtime persistence smoke
pnpm run e2e:accessibility
pnpm run e2e:ai
pnpm run e2e:backup
pnpm run e2e:packaged
pnpm run package:linux
pnpm run package:macos
pnpm run package:windows
pnpm run package:verify -- <target>
```

## Planning And Agent Workflow

- `PRD.md` records the original product and architecture direction.
- [PLAN.md](PLAN.md) is the stable implementation plan and roadmap.
- [AGENTS.md](AGENTS.md) is the local execution record and must be updated after meaningful implementation or verification steps.
- [docs/agent-verification-script.md](docs/agent-verification-script.md) is the director script for manual product verification after completing plan items.

When implementation work changes a planned phase or checklist item, update both [PLAN.md](PLAN.md) and [AGENTS.md](AGENTS.md) before considering the work complete.
