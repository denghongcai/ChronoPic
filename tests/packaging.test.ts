import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";

const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8")) as {
  scripts?: Record<string, string>;
};

test("legacy desktop packaging scripts remain exposed at the repository root", () => {
  assert.match(packageJson.scripts?.["package:linux"] ?? "", /scripts\/package-desktop\.mjs linux/);
  assert.match(packageJson.scripts?.["package:macos"] ?? "", /scripts\/package-desktop\.mjs macos/);
  assert.match(packageJson.scripts?.["package:windows"] ?? "", /scripts\/package-desktop\.mjs windows/);
  assert.match(packageJson.scripts?.["package:verify"] ?? "", /scripts\/verify-package\.mjs/);
  assert.match(packageJson.scripts?.["e2e:packaged"] ?? "", /packaged\.spec\.ts/);
  assert.match(packageJson.scripts?.["package:smoke"] ?? "", /package:verify/);
  assert.match(packageJson.scripts?.["package:smoke"] ?? "", /e2e:packaged/);
});

test("legacy desktop packaging implementation files exist", () => {
  assert.equal(fs.existsSync("scripts/package-desktop.mjs"), true);
  assert.equal(fs.existsSync("scripts/package-linux.mjs"), true);
  assert.equal(fs.existsSync("scripts/package-targets.mjs"), true);
  assert.equal(fs.existsSync("scripts/archive-release-artifact.mjs"), true);
  assert.equal(fs.existsSync("scripts/verify-package.mjs"), true);
  assert.equal(fs.existsSync("tests/e2e/packaged.spec.ts"), true);
});

test("tag release workflow publishes verified Flutter Android and Linux artifacts only", () => {
  assert.equal(fs.existsSync(".github/workflows/release.yml"), true);

  const workflow = fs.readFileSync(".github/workflows/release.yml", "utf8");
  assert.match(workflow, /tags:\s*\n\s*-\s+"v\*"/);
  assert.match(workflow, /contents:\s+write/);
  assert.match(workflow, /flutter-android:/);
  assert.match(workflow, /flutter-linux:/);
  assert.match(workflow, /actions\/setup-java@v5/);
  assert.match(workflow, /CHRONOPIC_ANDROID_KEYSTORE_BASE64/);
  assert.match(workflow, /build_android_release\.sh/);
  assert.match(workflow, /verify_flutter_release_artifacts\.mjs android/);
  assert.match(workflow, /build_linux_release\.sh/);
  assert.match(workflow, /verify_flutter_release_artifacts\.mjs linux/);
  assert.match(workflow, /dist\/flutter-release\/android\/\*/);
  assert.match(workflow, /dist\/flutter-release\/linux\/\*/);
  assert.match(workflow, /gh release upload/);
  assert.doesNotMatch(workflow, /target:\s+macos/);
  assert.doesNotMatch(workflow, /target:\s+windows/);
  assert.doesNotMatch(workflow, /macos-latest/);
  assert.doesNotMatch(workflow, /windows-latest/);
  assert.doesNotMatch(workflow, /pnpm run package:\$\{\{ matrix\.target \}\}/);
  assert.doesNotMatch(workflow, /scripts\/archive-release-artifact\.mjs \$\{\{ matrix\.target \}\}/);
});

test("CI and release workflows use current official setup actions", () => {
  const ciWorkflow = fs.readFileSync(".github/workflows/ci.yml", "utf8");
  const releaseWorkflow = fs.readFileSync(".github/workflows/release.yml", "utf8");

  for (const workflow of [ciWorkflow, releaseWorkflow]) {
    assert.match(workflow, /actions\/checkout@v6/);
    assert.match(workflow, /actions\/setup-node@v6/);
    assert.match(workflow, /node-version:\s+24/);
    assert.doesNotMatch(workflow, /corepack enable pnpm/);
    assert.doesNotMatch(workflow, /pnpm\/action-setup@v4/);
    assert.doesNotMatch(workflow, /actions\/checkout@v5/);
    assert.doesNotMatch(workflow, /actions\/setup-node@v5/);
  }

  assert.match(ciWorkflow, /pnpm\/action-setup@v6/);
  assert.match(ciWorkflow, /version:\s+10\.0\.0/);
  assert.match(ciWorkflow, /cache:\s+pnpm/);
  assert.match(ciWorkflow, /actions\/setup-java@v5/);
  assert.match(ciWorkflow, /flutter build apk --debug/);

  assert.match(releaseWorkflow, /actions\/setup-java@v5/);
  assert.match(releaseWorkflow, /build_android_release\.sh/);
  assert.match(releaseWorkflow, /build_linux_release\.sh/);
  assert.doesNotMatch(releaseWorkflow, /pnpm\/action-setup/);
  assert.doesNotMatch(releaseWorkflow, /cache:\s+pnpm/);
});

test("manual Android deep E2E workflow runs the hardened two-run gate", () => {
  assert.equal(fs.existsSync(".github/workflows/android-deep-e2e.yml"), true);

  const workflow = fs.readFileSync(".github/workflows/android-deep-e2e.yml", "utf8");
  assert.match(workflow, /workflow_dispatch:/);
  assert.match(workflow, /default:\s+"36"/);
  assert.match(workflow, /actions\/checkout@v6/);
  assert.match(workflow, /actions\/setup-node@v6/);
  assert.match(workflow, /actions\/setup-java@v5/);
  assert.match(workflow, /reactivecircus\/android-emulator-runner@v2\.37\.0/);
  assert.match(workflow, /actions\/upload-artifact@v7\.0\.1/);
  assert.match(workflow, /ANDROID_DEVICE_ID=emulator-5554/);
  assert.match(workflow, /run_android_deep_e2e_twice\.sh/);
  assert.match(workflow, /\.tmp\/mobile-e2e\/android-repeat\//);
});
