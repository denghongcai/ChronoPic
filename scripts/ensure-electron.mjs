import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { spawnSync } from "node:child_process";

const require = createRequire(import.meta.url);
const electronPackageJson = require.resolve("electron/package.json", {
  paths: [process.cwd()]
});
const electronDir = path.dirname(electronPackageJson);
const pathFile = path.join(electronDir, "path.txt");

if (fs.existsSync(pathFile)) {
  process.exit(0);
}

const result = spawnSync(process.execPath, [path.join(electronDir, "install.js")], {
  cwd: process.cwd(),
  stdio: "inherit"
});

if (result.status !== 0) {
  process.exit(result.status ?? 1);
}
