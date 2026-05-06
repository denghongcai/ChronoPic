import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..");
const packageDir = path.resolve(process.argv[2] ?? path.join(rootDir, "dist", "release", "chronopic-linux-x64"));
const appDir = path.join(packageDir, "resources", "app");

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function assertExists(relativePath) {
  const absolutePath = path.join(packageDir, relativePath);

  if (!(await pathExists(absolutePath))) {
    throw new Error(`Packaged artifact is missing ${relativePath}`);
  }

  return absolutePath;
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

async function assertAbsent(relativePath) {
  if (await pathExists(path.join(appDir, relativePath))) {
    throw new Error(`Packaged app should not include ${relativePath}`);
  }
}

const executablePath = await assertExists("chronopic");
await assertExists("resources/app/package.json");
await assertExists("resources/app/dist/main/main.js");
await assertExists("resources/app/dist/preload/index.cjs");
await assertExists("resources/app/dist/renderer/index.html");
await assertExists("resources/app/node_modules");

const packageJson = JSON.parse(await fs.readFile(path.join(appDir, "package.json"), "utf8"));

if (packageJson.main !== "dist/main/main.js") {
  throw new Error(`Packaged app main entry must be dist/main/main.js, received ${String(packageJson.main)}`);
}

if (packageJson.chronopic?.appId !== "app.chronopic.desktop") {
  throw new Error("Packaged app metadata is missing chronopic.appId");
}

const executableMode = (await fs.stat(executablePath)).mode;
if ((executableMode & 0o111) === 0) {
  throw new Error("Packaged chronopic executable is not executable");
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

await assertAbsent("tests");
await assertAbsent("test-results");
await assertAbsent("data");
await assertAbsent("thumbs");

console.log(JSON.stringify({
  packageDir: path.relative(rootDir, packageDir),
  executable: path.relative(rootDir, executablePath),
  main: packageJson.main,
  appId: packageJson.chronopic.appId,
  nativeModules: {
    betterSqlite: path.relative(packageDir, betterSqlite),
    sharp: path.relative(packageDir, sharp),
  },
}, null, 2));
