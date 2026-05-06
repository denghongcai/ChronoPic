import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";

const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8")) as {
  scripts?: Record<string, string>;
};

test("release packaging scripts are exposed at the repository root", () => {
  assert.match(packageJson.scripts?.["package:linux"] ?? "", /scripts\/package-linux\.mjs/);
  assert.match(packageJson.scripts?.["package:verify"] ?? "", /scripts\/verify-package\.mjs/);
  assert.match(packageJson.scripts?.["e2e:packaged"] ?? "", /packaged\.spec\.ts/);
  assert.match(packageJson.scripts?.["package:smoke"] ?? "", /package:verify/);
  assert.match(packageJson.scripts?.["package:smoke"] ?? "", /e2e:packaged/);
});

test("release packaging implementation files exist", () => {
  assert.equal(fs.existsSync("scripts/package-linux.mjs"), true);
  assert.equal(fs.existsSync("scripts/verify-package.mjs"), true);
  assert.equal(fs.existsSync("tests/e2e/packaged.spec.ts"), true);
});

test("tag release workflow publishes the verified Linux package", () => {
  assert.equal(fs.existsSync(".github/workflows/release.yml"), true);

  const workflow = fs.readFileSync(".github/workflows/release.yml", "utf8");
  assert.match(workflow, /tags:\s*\n\s*-\s+"v\*"/);
  assert.match(workflow, /contents:\s+write/);
  assert.match(workflow, /pnpm run package:linux/);
  assert.match(workflow, /pnpm run package:verify/);
  assert.match(workflow, /xvfb-run -a pnpm run e2e:packaged/);
  assert.match(workflow, /gh release (create|upload)/);
  assert.match(workflow, /sha256/);
});
