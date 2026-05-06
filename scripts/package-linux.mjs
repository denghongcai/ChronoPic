import fs from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..");
const desktopDir = path.join(rootDir, "apps", "desktop");
const workDir = path.join(rootDir, "dist", "package-work", "linux-x64");
const stagingAppDir = path.join(workDir, "app");
const outputDir = path.join(rootDir, "dist", "release", "chronopic-linux-x64");
const appResourceDir = path.join(outputDir, "resources", "app");
const desktopRequire = createRequire(path.join(desktopDir, "package.json"));

const appId = "app.chronopic.desktop";
const productName = "ChronoPic";
const executableName = "chronopic";

const runtimeWorkspacePackages = [
  "@chronopic/application",
  "@chronopic/domain",
  "@chronopic/i18n",
  "@chronopic/infra-config",
  "@chronopic/infra-db",
  "@chronopic/infra-fs",
  "@chronopic/infra-image",
  "@chronopic/services-ai-pipeline",
  "@chronopic/services-indexer",
  "@chronopic/shared-utils",
];

function workspaceFolderName(packageName) {
  return packageName.replace("@chronopic/", "");
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

async function writeJson(filePath, value) {
  await fs.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

function rewriteWorkspaceDependencies(dependencies, basePrefix) {
  if (!dependencies) {
    return undefined;
  }

  const rewritten = {};

  for (const [name, range] of Object.entries(dependencies)) {
    rewritten[name] = typeof range === "string" && range.startsWith("workspace:")
      ? `file:${basePrefix}${workspaceFolderName(name)}`
      : range;
  }

  return rewritten;
}

async function copyBuiltWorkspacePackage(packageName) {
  const folderName = workspaceFolderName(packageName);
  const sourceDir = path.join(rootDir, "packages", folderName);
  const targetDir = path.join(stagingAppDir, "packages", folderName);
  const sourcePackageJson = await readJson(path.join(sourceDir, "package.json"));

  if (!(await pathExists(path.join(sourceDir, "dist")))) {
    throw new Error(`Missing built package output for ${packageName}. Run pnpm build first.`);
  }

  await fs.mkdir(targetDir, { recursive: true });
  await fs.cp(path.join(sourceDir, "dist"), path.join(targetDir, "dist"), { recursive: true });
  await writeJson(path.join(targetDir, "package.json"), {
    name: sourcePackageJson.name,
    version: sourcePackageJson.version,
    type: sourcePackageJson.type,
    main: sourcePackageJson.main,
    types: sourcePackageJson.types,
    exports: sourcePackageJson.exports,
    dependencies: rewriteWorkspaceDependencies(sourcePackageJson.dependencies, "../"),
    optionalDependencies: rewriteWorkspaceDependencies(sourcePackageJson.optionalDependencies, "../"),
  });
}

async function run(command, args, options = {}) {
  await new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: options.cwd ?? rootDir,
      env: {
        ...process.env,
        ...options.env,
      },
      stdio: "inherit",
    });

    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(`${command} ${args.join(" ")} exited with ${code ?? "unknown status"}`));
    });
  });
}

async function prepareStagingApp() {
  const desktopPackage = await readJson(path.join(desktopDir, "package.json"));

  await fs.rm(workDir, { recursive: true, force: true });
  await fs.mkdir(stagingAppDir, { recursive: true });
  await fs.cp(path.join(desktopDir, "dist"), path.join(stagingAppDir, "dist"), { recursive: true });

  for (const packageName of runtimeWorkspacePackages) {
    await copyBuiltWorkspacePackage(packageName);
  }

  await writeJson(path.join(stagingAppDir, "package.json"), {
    name: "chronopic",
    version: desktopPackage.version,
    private: true,
    type: "module",
    productName,
    main: desktopPackage.main,
    chronopic: {
      appId,
      productName,
      platform: "linux",
      arch: process.arch,
      entry: desktopPackage.main,
      packagedAt: new Date().toISOString(),
    },
    dependencies: Object.fromEntries(
      runtimeWorkspacePackages.map((packageName) => [
        packageName,
        `file:./packages/${workspaceFolderName(packageName)}`,
      ])
    ),
    pnpm: {
      onlyBuiltDependencies: [
        "better-sqlite3",
        "sharp",
      ],
    },
  });

  await run("pnpm", [
    "install",
    "--prod",
    "--ignore-workspace",
    "--no-frozen-lockfile",
    "--ignore-scripts=false",
  ], { cwd: stagingAppDir });
}

async function rebuildNativeModulesForElectron() {
  const electronPackageJsonPath = desktopRequire.resolve("electron/package.json");
  const electronPackage = await readJson(electronPackageJsonPath);
  const rebuildEntryPath = desktopRequire.resolve("@electron/rebuild");
  const rebuildCliPath = path.join(path.dirname(rebuildEntryPath), "cli.js");

  await run(process.execPath, [
    rebuildCliPath,
    "--version",
    electronPackage.version,
    "--module-dir",
    stagingAppDir,
    "--force",
    "--which-module",
    "better-sqlite3,sharp",
  ]);
}

async function copyElectronRuntime() {
  const electronPackageJsonPath = desktopRequire.resolve("electron/package.json");
  const electronPackageDir = path.dirname(electronPackageJsonPath);
  const electronDistDir = path.join(electronPackageDir, "dist");

  if (!(await pathExists(path.join(electronDistDir, "electron")))) {
    throw new Error("Electron binary is missing. Run the desktop ensure:electron guard first.");
  }

  await fs.rm(outputDir, { recursive: true, force: true });
  await fs.mkdir(outputDir, { recursive: true });
  await fs.cp(electronDistDir, outputDir, { recursive: true });
  await fs.rm(path.join(outputDir, "resources", "default_app.asar"), { force: true });
  await fs.rm(appResourceDir, { recursive: true, force: true });
  await fs.mkdir(path.dirname(appResourceDir), { recursive: true });
  await fs.cp(stagingAppDir, appResourceDir, { recursive: true });

  const electronBinary = path.join(outputDir, "electron");
  const appBinary = path.join(outputDir, executableName);
  await fs.rm(appBinary, { force: true });
  await fs.rename(electronBinary, appBinary);
  await fs.chmod(appBinary, 0o755);

  const chromeSandbox = path.join(outputDir, "chrome-sandbox");
  if (await pathExists(chromeSandbox)) {
    await fs.chmod(chromeSandbox, 0o755);
  }
}

await prepareStagingApp();
await rebuildNativeModulesForElectron();
await copyElectronRuntime();

console.log(`Packaged ${productName} Linux artifact: ${path.relative(rootDir, outputDir)}`);
