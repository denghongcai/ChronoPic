import { _electron as electron, expect } from "@playwright/test";
import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const repoRoot = path.resolve(new URL("..", import.meta.url).pathname);
const outputDir = path.join(repoRoot, "test-results", "flutter-electron-parity", "electron");
const backupPath = path.join(repoRoot, "tests", "fixtures", "flutter-parity", "chronopic-backup-v1.json");

const screenshotNames = {
  emptyHome: "01-empty-home.png",
  populatedGrid: "02-populated-grid.png",
  map: "03-map.png",
  timeline: "04-timeline.png",
  detail: "05-detail.png",
  gallery: "06-gallery.png",
  favorites: "07-favorites.png",
  memoriesList: "08-memories-list.png",
  memoryDetail: "09-memory-detail.png",
  settings: "10-settings.png",
  notifications: "11-notifications.png",
  zhLocale: "12-zh-locale.png",
  restartPersistence: "13-restart-persistence.png",
};

function runDesktopGuard(scriptName) {
  const result = spawnSync(
    "pnpm",
    ["--filter", "@chronopic/desktop", "run", scriptName],
    {
      cwd: repoRoot,
      encoding: "utf8",
      stdio: "pipe",
    },
  );
  if (result.status !== 0) {
    throw new Error(
      [
        `Failed to run desktop guard: ${scriptName}`,
        result.stdout.trim(),
        result.stderr.trim(),
      ]
        .filter(Boolean)
        .join("\n"),
    );
  }
}

async function launchChronoPic(userDataDir) {
  const { VITE_DEV_SERVER_URL: _viteDevServerUrl, ...baseEnv } = process.env;
  return electron.launch({
    args: ["apps/desktop/dist/main/main.js"],
    cwd: repoRoot,
    env: {
      ...baseEnv,
      CHRONOPIC_USER_DATA_DIR: userDataDir,
      ELECTRON_DISABLE_SANDBOX: "1",
    },
  });
}

async function firstReadyWindow(electronApp) {
  const page = await electronApp.firstWindow();
  await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });
  await page.setViewportSize({ width: 1440, height: 920 });
  return page;
}

async function screenshot(page, name) {
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(outputDir, name), fullPage: false });
}

async function restoreFixture(page, locale = "en-US") {
  await page.evaluate(
    async ({ fixtureBackupPath, nextLocale }) => {
      const api = globalThis.chronoPic;
      await api.initialize();
      await api.restoreBackup(fixtureBackupPath, { mode: "replace" });
      await api.saveLocaleSettings({ locale: nextLocale, aiOutputLocale: nextLocale });
    },
    { fixtureBackupPath: backupPath, nextLocale: locale },
  );
}

async function openButton(page, pattern) {
  const button = page.getByRole("button", { name: pattern }).first();
  await expect(button).toBeVisible({ timeout: 10_000 });
  await button.click();
  await page.waitForTimeout(350);
}

async function openPhotoCard(page) {
  const card = page.getByRole("button", { name: /lake|backup|manual/i }).first();
  await expect(card).toBeVisible({ timeout: 10_000 });
  await card.press("Enter");
  await page.waitForTimeout(500);
}

async function closeDialogIfOpen(page) {
  await page.keyboard.press("Escape");
  await page.waitForTimeout(350);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(350);
}

async function main() {
  runDesktopGuard("ensure:electron");
  runDesktopGuard("ensure:native");

  await fs.rm(outputDir, { recursive: true, force: true });
  await fs.mkdir(outputDir, { recursive: true });

  const userDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-electron-parity-"));

  let electronApp = await launchChronoPic(userDataDir);
  let page = await firstReadyWindow(electronApp);
  await screenshot(page, screenshotNames.emptyHome);
  await restoreFixture(page, "en-US");
  await electronApp.close();

  electronApp = await launchChronoPic(userDataDir);
  page = await firstReadyWindow(electronApp);
  await screenshot(page, screenshotNames.populatedGrid);

  await openButton(page, /map/i);
  await screenshot(page, screenshotNames.map);

  await openButton(page, /timeline/i);
  await screenshot(page, screenshotNames.timeline);

  await openButton(page, /waterfall|grid/i).catch(async () => {
    await openButton(page, /waterfall/i);
  });
  await openPhotoCard(page);
  await screenshot(page, screenshotNames.detail);

  await openButton(page, /gallery/i);
  await screenshot(page, screenshotNames.gallery);
  await closeDialogIfOpen(page);

  await openButton(page, /favorites/i);
  await screenshot(page, screenshotNames.favorites);

  await openButton(page, /all photos/i);
  await openButton(page, /see all|view all/i);
  await screenshot(page, screenshotNames.memoriesList);

  await openButton(page, /fixture weekend/i);
  await screenshot(page, screenshotNames.memoryDetail);

  await openButton(page, /settings/i);
  await screenshot(page, screenshotNames.settings);

  await openButton(page, /notifications/i);
  await screenshot(page, screenshotNames.notifications);

  await page.evaluate(async () => {
    const api = globalThis.chronoPic;
    await api.saveLocaleSettings({ locale: "zh-CN", aiOutputLocale: "zh-CN" });
  });
  await electronApp.close();

  electronApp = await launchChronoPic(userDataDir);
  page = await firstReadyWindow(electronApp);
  await screenshot(page, screenshotNames.zhLocale);
  await screenshot(page, screenshotNames.restartPersistence);

  await electronApp.close();

  const files = await fs.readdir(outputDir);
  const missing = Object.values(screenshotNames).filter((name) => !files.includes(name));
  if (missing.length > 0) {
    throw new Error(`Missing Electron parity screenshots: ${missing.join(", ")}`);
  }

  console.log(`Captured Electron parity screenshots in ${path.relative(repoRoot, outputDir)}`);
}

await main();
