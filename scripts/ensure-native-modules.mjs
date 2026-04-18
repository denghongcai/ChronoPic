import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { spawnSync } from "node:child_process";

const require = createRequire(import.meta.url);

function resolvePackageJson(specifier, parentPaths = [process.cwd()]) {
  return require.resolve(`${specifier}/package.json`, {
    paths: parentPaths
  });
}

const electronPackageJsonPath = resolvePackageJson("electron");
const infraDbEntryPath = require.resolve("@chronopic/infra-db", {
  paths: [process.cwd()]
});
const infraDbRequire = createRequire(infraDbEntryPath);
const betterSqlitePackageJsonPath = infraDbRequire.resolve("better-sqlite3/package.json");
const electronRebuildEntryPath = require.resolve("@electron/rebuild", {
  paths: [process.cwd()]
});
const electronRebuildCliPath = path.join(path.dirname(electronRebuildEntryPath), "cli.js");

const electronPackage = JSON.parse(fs.readFileSync(electronPackageJsonPath, "utf8"));
const betterSqlitePackage = JSON.parse(fs.readFileSync(betterSqlitePackageJsonPath, "utf8"));

const betterSqliteDir = path.dirname(betterSqlitePackageJsonPath);
const markerDir = path.join(process.cwd(), "node_modules", ".cache", "chronopic");
const markerFile = path.join(
  markerDir,
  `native-${electronPackage.version}-better-sqlite3-${betterSqlitePackage.version}.json`
);
const bindingFile = path.join(betterSqliteDir, "build", "Release", "better_sqlite3.node");

if (fs.existsSync(bindingFile) && fs.existsSync(markerFile)) {
  process.exit(0);
}

fs.mkdirSync(markerDir, { recursive: true });

const rebuild = spawnSync(process.execPath, [electronRebuildCliPath, "-f", "-w", "better-sqlite3"], {
  cwd: process.cwd(),
  stdio: "inherit"
});

if (rebuild.status !== 0) {
  process.exit(rebuild.status ?? 1);
}

fs.writeFileSync(
  markerFile,
  JSON.stringify(
    {
      electronVersion: electronPackage.version,
      betterSqliteVersion: betterSqlitePackage.version,
      rebuiltAt: new Date().toISOString()
    },
    null,
    2
  )
);
