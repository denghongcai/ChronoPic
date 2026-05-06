import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

import { normalizePackageTarget, packageFolderName } from "./package-targets.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, "..");

function commandForPlatform(command) {
  return process.platform === "win32" ? `${command}.exe` : command;
}

async function run(command, args) {
  await new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: rootDir,
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

async function sha256(filePath) {
  const hash = crypto.createHash("sha256");
  const handle = await fs.open(filePath, "r");

  try {
    for await (const chunk of handle.createReadStream()) {
      hash.update(chunk);
    }
  } finally {
    await handle.close();
  }

  return hash.digest("hex");
}

const target = normalizePackageTarget(process.argv[2]);
const tag = process.argv[3] ?? process.env.RELEASE_TAG;

if (!tag) {
  throw new Error("Missing release tag. Pass it as the second argument or set RELEASE_TAG.");
}

const folderName = packageFolderName(target);
const releaseDir = path.join(rootDir, "dist", "release");
const artifactDir = path.join(rootDir, "dist", "release-artifacts");
const artifactName = `${folderName}-${tag}.tar.gz`;
const artifactPath = path.join(artifactDir, artifactName);
const checksumPath = `${artifactPath}.sha256`;

await fs.mkdir(artifactDir, { recursive: true });
await fs.rm(artifactPath, { force: true });
await fs.rm(checksumPath, { force: true });
await run(commandForPlatform("tar"), [
  "-C",
  releaseDir,
  "-czf",
  artifactPath,
  folderName,
]);

const digest = await sha256(artifactPath);
await fs.writeFile(checksumPath, `${digest}  ${artifactName}\n`, "utf8");

console.log(JSON.stringify({
  target,
  artifact: path.relative(rootDir, artifactPath),
  checksum: path.relative(rootDir, checksumPath),
  sha256: digest,
}, null, 2));
