import fs from "node:fs/promises";
import path from "node:path";

const rootDir = process.cwd();

const targets = [
  "apps/desktop/dist",
  "packages/application/dist",
  "packages/domain/dist",
  "packages/infra-db/dist",
  "packages/infra-fs/dist",
  "packages/infra-image/dist",
  "packages/services-ai-pipeline/dist",
  "packages/services-indexer/dist",
  "packages/shared-utils/dist",
  "packages/ui-components/dist"
];

const staleGlobs = [
  "packages/application/src/index.d.ts",
  "packages/application/src/index.d.ts.map",
  "packages/application/src/index.js",
  "packages/application/src/index.js.map",
  "packages/domain/src/index.d.ts",
  "packages/domain/src/index.d.ts.map",
  "packages/domain/src/index.js",
  "packages/domain/src/index.js.map",
  "packages/infra-db/src/index.d.ts",
  "packages/infra-db/src/index.d.ts.map",
  "packages/infra-db/src/index.js",
  "packages/infra-db/src/index.js.map",
  "packages/infra-db/src/schema.d.ts",
  "packages/infra-db/src/schema.d.ts.map",
  "packages/infra-db/src/schema.js",
  "packages/infra-db/src/schema.js.map",
  "packages/infra-fs/src/index.d.ts",
  "packages/infra-fs/src/index.d.ts.map",
  "packages/infra-fs/src/index.js",
  "packages/infra-fs/src/index.js.map",
  "packages/infra-image/src/index.d.ts",
  "packages/infra-image/src/index.d.ts.map",
  "packages/infra-image/src/index.js",
  "packages/infra-image/src/index.js.map",
  "packages/services-ai-pipeline/src/index.d.ts",
  "packages/services-ai-pipeline/src/index.d.ts.map",
  "packages/services-ai-pipeline/src/index.js",
  "packages/services-ai-pipeline/src/index.js.map",
  "packages/services-indexer/src/index.d.ts",
  "packages/services-indexer/src/index.d.ts.map",
  "packages/services-indexer/src/index.js",
  "packages/services-indexer/src/index.js.map",
  "packages/shared-utils/src/index.d.ts",
  "packages/shared-utils/src/index.d.ts.map",
  "packages/shared-utils/src/index.js",
  "packages/shared-utils/src/index.js.map"
];

await Promise.all(
  targets.map(async (target) => {
    await fs.rm(path.join(rootDir, target), { recursive: true, force: true });
  })
);

await Promise.all(
  staleGlobs.map(async (target) => {
    await fs.rm(path.join(rootDir, target), { force: true });
  })
);
