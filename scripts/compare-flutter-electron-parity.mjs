import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";

const repoRoot = path.resolve(new URL("..", import.meta.url).pathname);
const parityRoot = path.join(repoRoot, "test-results", "flutter-electron-parity");
const electronDir = path.join(parityRoot, "electron");
const flutterDir = path.join(parityRoot, "flutter");
const compareDir = path.join(parityRoot, "compare");

const expectedScreenshots = [
  "01-empty-home.png",
  "02-populated-grid.png",
  "03-map.png",
  "04-timeline.png",
  "05-detail.png",
  "06-gallery.png",
  "07-favorites.png",
  "08-memories-list.png",
  "09-memory-detail.png",
  "10-settings.png",
  "11-notifications.png",
  "12-zh-locale.png",
  "13-restart-persistence.png",
];

function runMontage(args) {
  const result = spawnSync("montage", args, {
    cwd: repoRoot,
    encoding: "utf8",
  });
  if (result.status !== 0) {
    throw new Error(
      [
        `montage failed with status ${result.status}`,
        result.stdout.trim(),
        result.stderr.trim(),
      ]
        .filter(Boolean)
        .join("\n"),
    );
  }
}

async function assertFileExists(filePath) {
  const stat = await fs.stat(filePath).catch(() => null);
  if (!stat?.isFile() || stat.size === 0) {
    throw new Error(`Missing or empty screenshot: ${path.relative(repoRoot, filePath)}`);
  }
}

async function main() {
  await fs.rm(compareDir, { recursive: true, force: true });
  await fs.mkdir(compareDir, { recursive: true });

  const compareFiles = [];
  for (const screenshotName of expectedScreenshots) {
    const electronPath = path.join(electronDir, screenshotName);
    const flutterPath = path.join(flutterDir, screenshotName);
    await assertFileExists(electronPath);
    await assertFileExists(flutterPath);

    const compareName = `${path.basename(screenshotName, ".png")}-compare.png`;
    const comparePath = path.join(compareDir, compareName);
    runMontage([
      electronPath,
      flutterPath,
      "-tile",
      "2x1",
      "-geometry",
      "+24+0",
      comparePath,
    ]);
    await assertFileExists(comparePath);
    compareFiles.push(comparePath);
  }

  const contactSheetPath = path.join(compareDir, "contact-sheet-phase-9.png");
  runMontage([
    ...compareFiles,
    "-tile",
    "1x",
    "-geometry",
    "+0+18",
    contactSheetPath,
  ]);
  await assertFileExists(contactSheetPath);

  console.log(
    `Generated ${compareFiles.length} parity compare screenshots in ${path.relative(
      repoRoot,
      compareDir,
    )}`,
  );
}

await main();
