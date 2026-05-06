import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { isPackageTarget, normalizePackageTarget, packageFolderName } from "./package-targets.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..");

function resolvePackagePaths(argv) {
  const args = argv.slice(2).filter((arg) => arg !== "--");
  const firstArg = args[0];
  const secondArg = args[1];
  const isTargetArg = isPackageTarget(firstArg);
  const target = normalizePackageTarget(isTargetArg ? firstArg : undefined);
  const packageDir = path.resolve(
    isTargetArg
      ? secondArg ?? path.join(rootDir, "dist", "release", packageFolderName(target))
      : firstArg ?? path.join(rootDir, "dist", "release", packageFolderName(target))
  );

  if (target === "macos") {
    return {
      target,
      packageDir,
      appDir: path.join(packageDir, "ChronoPic.app", "Contents", "Resources", "app"),
      executablePath: path.join(packageDir, "ChronoPic.app", "Contents", "MacOS", "ChronoPic"),
      executableLabel: "ChronoPic.app/Contents/MacOS/ChronoPic",
    };
  }

  if (target === "windows") {
    return {
      target,
      packageDir,
      appDir: path.join(packageDir, "resources", "app"),
      executablePath: path.join(packageDir, "chronopic.exe"),
      executableLabel: "chronopic.exe",
    };
  }

  return {
    target,
    packageDir,
    appDir: path.join(packageDir, "resources", "app"),
    executablePath: path.join(packageDir, "chronopic"),
    executableLabel: "chronopic",
  };
}

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function assertExists(filePath, label) {
  if (!(await pathExists(filePath))) {
    throw new Error(`Packaged artifact is missing ${label}`);
  }

  return filePath;
}

async function collectFiles(rootPath, predicate, results = []) {
  if (!(await pathExists(rootPath))) {
    return results;
  }

  const entries = await fs.readdir(rootPath, { withFileTypes: true });

  for (const entry of entries) {
    const entryPath = path.join(rootPath, entry.name);

    if (entry.isDirectory()) {
      await collectFiles(entryPath, predicate, results);
      continue;
    }

    if (predicate(entryPath)) {
      results.push(entryPath);
    }
  }

  return results;
}

async function assertAbsent(appDir, relativePath) {
  if (await pathExists(path.join(appDir, relativePath))) {
    throw new Error(`Packaged app should not include ${relativePath}`);
  }
}

const {
  target,
  packageDir,
  appDir,
  executablePath,
  executableLabel,
} = resolvePackagePaths(process.argv);

await assertExists(executablePath, executableLabel);
await assertExists(path.join(appDir, "package.json"), "app package.json");
await assertExists(path.join(appDir, "dist", "main", "main.js"), "app dist/main/main.js");
await assertExists(path.join(appDir, "dist", "preload", "index.cjs"), "app dist/preload/index.cjs");
await assertExists(path.join(appDir, "dist", "renderer", "index.html"), "app dist/renderer/index.html");
await assertExists(path.join(appDir, "node_modules"), "app node_modules");

const packageJson = JSON.parse(await fs.readFile(path.join(appDir, "package.json"), "utf8"));

if (packageJson.main !== "dist/main/main.js") {
  throw new Error(`Packaged app main entry must be dist/main/main.js, received ${String(packageJson.main)}`);
}

if (packageJson.chronopic?.appId !== "app.chronopic.desktop") {
  throw new Error("Packaged app metadata is missing chronopic.appId");
}

if (packageJson.chronopic?.platform !== target) {
  throw new Error(`Packaged app metadata platform must be ${target}, received ${String(packageJson.chronopic?.platform)}`);
}

if (target !== "windows") {
  const executableMode = (await fs.stat(executablePath)).mode;
  if ((executableMode & 0o111) === 0) {
    throw new Error(`Packaged ${executableLabel} is not executable`);
  }
}

const nativeModules = await collectFiles(path.join(appDir, "node_modules"), (filePath) => filePath.endsWith(".node"));
const betterSqlite = nativeModules.find((filePath) => path.basename(filePath) === "better_sqlite3.node");
const sharp = nativeModules.find((filePath) => path.basename(filePath).startsWith("sharp-"));

if (!betterSqlite) {
  throw new Error("Packaged app is missing better-sqlite3 native module");
}

if (!sharp) {
  throw new Error("Packaged app is missing sharp native module");
}

await assertAbsent(appDir, "tests");
await assertAbsent(appDir, "test-results");
await assertAbsent(appDir, "data");
await assertAbsent(appDir, "thumbs");

console.log(JSON.stringify({
  target,
  packageDir: path.relative(rootDir, packageDir),
  executable: path.relative(rootDir, executablePath),
  main: packageJson.main,
  appId: packageJson.chronopic.appId,
  nativeModules: {
    betterSqlite: path.relative(packageDir, betterSqlite),
    sharp: path.relative(packageDir, sharp),
  },
}, null, 2));
