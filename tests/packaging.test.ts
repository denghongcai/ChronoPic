import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";

const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8")) as {
  scripts?: Record<string, string>;
};

test("release packaging scripts are exposed at the repository root", () => {
  assert.match(packageJson.scripts?.["package:linux"] ?? "", /scripts\/package-desktop\.mjs linux/);
  assert.match(packageJson.scripts?.["package:macos"] ?? "", /scripts\/package-desktop\.mjs macos/);
  assert.match(packageJson.scripts?.["package:windows"] ?? "", /scripts\/package-desktop\.mjs windows/);
  assert.match(packageJson.scripts?.["package:verify"] ?? "", /scripts\/verify-package\.mjs/);
  assert.match(packageJson.scripts?.["e2e:packaged"] ?? "", /packaged\.spec\.ts/);
  assert.match(packageJson.scripts?.["package:smoke"] ?? "", /package:verify/);
  assert.match(packageJson.scripts?.["package:smoke"] ?? "", /e2e:packaged/);
});

test("release packaging implementation files exist", () => {
  assert.equal(fs.existsSync("scripts/package-desktop.mjs"), true);
  assert.equal(fs.existsSync("scripts/package-linux.mjs"), true);
  assert.equal(fs.existsSync("scripts/package-targets.mjs"), true);
  assert.equal(fs.existsSync("scripts/archive-release-artifact.mjs"), true);
  assert.equal(fs.existsSync("scripts/verify-package.mjs"), true);
  assert.equal(fs.existsSync("tests/e2e/packaged.spec.ts"), true);
});

test("tag release workflow publishes verified Linux, macOS, and Windows packages", () => {
  assert.equal(fs.existsSync(".github/workflows/release.yml"), true);

  const workflow = fs.readFileSync(".github/workflows/release.yml", "utf8");
  assert.match(workflow, /tags:\s*\n\s*-\s+"v\*"/);
  assert.match(workflow, /contents:\s+write/);
  assert.match(workflow, /target:\s+linux/);
  assert.match(workflow, /target:\s+macos/);
  assert.match(workflow, /target:\s+windows/);
  assert.match(workflow, /os:\s+ubuntu-latest/);
  assert.match(workflow, /os:\s+macos-latest/);
  assert.match(workflow, /os:\s+windows-latest/);
  assert.match(workflow, /pnpm run package:\$\{\{ matrix\.target \}\}/);
  assert.match(workflow, /pnpm run package:verify -- \$\{\{ matrix\.target \}\}/);
  assert.match(workflow, /CHRONOPIC_PACKAGED_TARGET: \$\{\{ matrix\.target \}\}/);
  assert.match(workflow, /scripts\/archive-release-artifact\.mjs \$\{\{ matrix\.target \}\}/);
  assert.match(workflow, /gh release upload/);
  assert.match(workflow, /sha256/);
});

test("CI and release workflows use Node 24 compatible official actions", () => {
  const ciWorkflow = fs.readFileSync(".github/workflows/ci.yml", "utf8");
  const releaseWorkflow = fs.readFileSync(".github/workflows/release.yml", "utf8");

  for (const workflow of [ciWorkflow, releaseWorkflow]) {
    assert.match(workflow, /actions\/checkout@v5/);
    assert.match(workflow, /actions\/setup-node@v5/);
    assert.match(workflow, /node-version:\s+24/);
    assert.match(workflow, /corepack enable pnpm/);
    assert.doesNotMatch(workflow, /pnpm\/action-setup/);
    assert.doesNotMatch(workflow, /cache:\s+pnpm/);
  }
});
