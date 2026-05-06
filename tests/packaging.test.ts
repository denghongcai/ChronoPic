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
