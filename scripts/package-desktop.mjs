import fs from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..");
const desktopDir = path.join(rootDir, "apps", "desktop");
const desktopRequire = createRequire(path.join(desktopDir, "package.json"));

const appId = "app.chronopic.desktop";
const productName = "ChronoPic";

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

const targetByPlatform = new Map([
  ["linux", "linux"],
  ["darwin", "macos"],
  ["win32", "windows"],
]);

function normalizeTarget(input = targetByPlatform.get(process.platform)) {
  if (input === "darwin") {
    return "macos";
  }

  if (input === "win32") {
    return "windows";
  }

  if (input === "linux" || input === "macos" || input === "windows") {
    return input;
  }

  throw new Error(`Unsupported package target: ${String(input)}`);
}

function packageFolderName(target, arch = process.arch) {
  return `chronopic-${target}-${arch}`;
}

function commandForPlatform(command) {
  return process.platform === "win32" ? `${command}.cmd` : command;
}

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

async function copyBuiltWorkspacePackage(packageName, stagingAppDir) {
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
      shell: process.platform === "win32",
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

async function prepareStagingApp(target, stagingAppDir, workDir) {
  const desktopPackage = await readJson(path.join(desktopDir, "package.json"));

  await fs.rm(workDir, { recursive: true, force: true });
  await fs.mkdir(stagingAppDir, { recursive: true });
  await fs.cp(path.join(desktopDir, "dist"), path.join(stagingAppDir, "dist"), { recursive: true });

  for (const packageName of runtimeWorkspacePackages) {
    await copyBuiltWorkspacePackage(packageName, stagingAppDir);
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
      platform: target,
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

  await run(commandForPlatform("pnpm"), [
    "install",
    "--prod",
    "--ignore-workspace",
    "--no-frozen-lockfile",
    "--ignore-scripts=false",
  ], { cwd: stagingAppDir });
}

async function rebuildNativeModulesForElectron(stagingAppDir) {
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

async function copyLinuxRuntime(electronDistDir, stagingAppDir, outputDir) {
  if (!(await pathExists(path.join(electronDistDir, "electron")))) {
    throw new Error("Electron Linux binary is missing. Run the desktop ensure:electron guard first.");
  }

  await fs.cp(electronDistDir, outputDir, { recursive: true });
  await fs.rm(path.join(outputDir, "resources", "default_app.asar"), { force: true });
  await fs.cp(stagingAppDir, path.join(outputDir, "resources", "app"), { recursive: true });
  await fs.rename(path.join(outputDir, "electron"), path.join(outputDir, "chronopic"));
  await fs.chmod(path.join(outputDir, "chronopic"), 0o755);

  const chromeSandbox = path.join(outputDir, "chrome-sandbox");
  if (await pathExists(chromeSandbox)) {
    await fs.chmod(chromeSandbox, 0o755);
  }
}

async function copyWindowsRuntime(electronDistDir, stagingAppDir, outputDir) {
  if (!(await pathExists(path.join(electronDistDir, "electron.exe")))) {
    throw new Error("Electron Windows binary is missing. This package target must run on Windows.");
  }

  await fs.cp(electronDistDir, outputDir, { recursive: true });
  await fs.rm(path.join(outputDir, "resources", "default_app.asar"), { force: true });
  await fs.cp(stagingAppDir, path.join(outputDir, "resources", "app"), { recursive: true });
  await fs.rename(path.join(outputDir, "electron.exe"), path.join(outputDir, "chronopic.exe"));
}

async function copyMacosRuntime(electronDistDir, stagingAppDir, outputDir) {
  const sourceBundle = path.join(electronDistDir, "Electron.app");
  const targetBundle = path.join(outputDir, `${productName}.app`);

  if (!(await pathExists(sourceBundle))) {
    throw new Error("Electron macOS app bundle is missing. This package target must run on macOS.");
  }

  await fs.cp(sourceBundle, targetBundle, { recursive: true });

  const contentsDir = path.join(targetBundle, "Contents");
  const resourcesDir = path.join(contentsDir, "Resources");
  const macosDir = path.join(contentsDir, "MacOS");
  const plistPath = path.join(contentsDir, "Info.plist");

  await fs.rm(path.join(resourcesDir, "default_app.asar"), { force: true });
  await fs.cp(stagingAppDir, path.join(resourcesDir, "app"), { recursive: true });

  const electronExecutable = path.join(macosDir, "Electron");
  const chronopicExecutable = path.join(macosDir, productName);
  await fs.rename(electronExecutable, chronopicExecutable);
  await fs.chmod(chronopicExecutable, 0o755);

  let plist = await fs.readFile(plistPath, "utf8");
  plist = replacePlistValue(plist, "CFBundleExecutable", productName);
  plist = replacePlistValue(plist, "CFBundleName", productName);
  plist = replacePlistValue(plist, "CFBundleDisplayName", productName);
  plist = replacePlistValue(plist, "CFBundleIdentifier", appId);
  await fs.writeFile(plistPath, plist, "utf8");
}

function replacePlistValue(plist, key, value) {
  const pattern = new RegExp(`(<key>${key}</key>\\s*<string>)([^<]*)(</string>)`);
  return plist.replace(pattern, `$1${value}$3`);
}

async function copyElectronRuntime(target, stagingAppDir, outputDir) {
  const electronPackageJsonPath = desktopRequire.resolve("electron/package.json");
  const electronPackageDir = path.dirname(electronPackageJsonPath);
  const electronDistDir = path.join(electronPackageDir, "dist");

  await fs.rm(outputDir, { recursive: true, force: true });
  await fs.mkdir(outputDir, { recursive: true });

  if (target === "linux") {
    await copyLinuxRuntime(electronDistDir, stagingAppDir, outputDir);
    return;
  }

  if (target === "windows") {
    await copyWindowsRuntime(electronDistDir, stagingAppDir, outputDir);
    return;
  }

  await copyMacosRuntime(electronDistDir, stagingAppDir, outputDir);
}

export async function packageDesktop(inputTarget = process.argv[2]) {
  const target = normalizeTarget(inputTarget);
  const folderName = packageFolderName(target);
  const workDir = path.join(rootDir, "dist", "package-work", folderName);
  const stagingAppDir = path.join(workDir, "app");
  const outputDir = path.join(rootDir, "dist", "release", folderName);

  await prepareStagingApp(target, stagingAppDir, workDir);
  await rebuildNativeModulesForElectron(stagingAppDir);
  await copyElectronRuntime(target, stagingAppDir, outputDir);

  console.log(`Packaged ${productName} ${target} artifact: ${path.relative(rootDir, outputDir)}`);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  await packageDesktop();
}
