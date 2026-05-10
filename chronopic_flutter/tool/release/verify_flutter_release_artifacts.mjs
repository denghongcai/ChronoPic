#!/usr/bin/env node
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const rootDir = path.resolve(new URL("../../../", import.meta.url).pathname);
const packageJson = JSON.parse(fs.readFileSync(path.join(rootDir, "package.json"), "utf8"));
const releaseVersion = process.env.CHRONOPIC_RELEASE_VERSION || packageJson.version;
const distDir = process.env.FLUTTER_RELEASE_DIST_DIR
  ? path.resolve(process.env.FLUTTER_RELEASE_DIST_DIR)
  : path.join(rootDir, "dist", "flutter-release");
const targets = process.argv.slice(2);
const selectedTargets = targets.length === 0 ? ["android"] : targets;

const expectedByTarget = {
  android: [
    "android/chronopic-flutter-android-release.apk",
    "android/chronopic-flutter-android-release.apk.sha256",
    "android/chronopic-flutter-android-release.aab",
    "android/chronopic-flutter-android-release.aab.sha256",
  ],
  linux: [
    `linux/chronopic-flutter-linux-x64-${releaseVersion}.tar.gz`,
    `linux/chronopic-flutter-linux-x64-${releaseVersion}.tar.gz.sha256`,
  ],
};

for (const target of selectedTargets) {
  if (!expectedByTarget[target]) {
    fail(`unknown release target: ${target}`);
  }
}

const expected = selectedTargets.flatMap((target) => expectedByTarget[target]);

function fail(message) {
  console.error(`[flutter-release-verify] ${message}`);
  process.exit(1);
}

function sha256(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

for (const relativePath of expected) {
  const filePath = path.join(distDir, relativePath);
  if (!fs.existsSync(filePath)) fail(`missing artifact: ${relativePath}`);
  if (!fs.statSync(filePath).isFile() || fs.statSync(filePath).size === 0) {
    fail(`empty artifact: ${relativePath}`);
  }
}

for (const artifact of expected.filter((item) => !item.endsWith(".sha256"))) {
  const filePath = path.join(distDir, artifact);
  const shaPath = `${filePath}.sha256`;
  const expectedHash = fs.readFileSync(shaPath, "utf8").trim().split(/\s+/)[0];
  const actualHash = sha256(filePath);
  if (actualHash !== expectedHash) {
    fail(`sha256 mismatch for ${artifact}`);
  }
}

if (selectedTargets.includes("linux")) {
  const archivePath = path.join(distDir, `linux/chronopic-flutter-linux-x64-${releaseVersion}.tar.gz`);
  const listing = execFileSync("tar", ["-tzf", archivePath], { encoding: "utf8" });
  if (!listing.split("\n").some((entry) => entry === "./chronopic" || entry === "chronopic")) {
    fail("Linux archive does not contain the chronopic executable");
  }
}

console.log(
  JSON.stringify(
    {
      ok: true,
      distDir,
      targets: selectedTargets,
      artifacts: expected,
    },
    null,
    2,
  ),
);
