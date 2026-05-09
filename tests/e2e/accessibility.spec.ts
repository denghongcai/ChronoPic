import { expect, test, _electron as electron } from "@playwright/test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const FIXTURE_IMAGE_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGP8z8Dwn4GBgYGBgAEAGu0C/gfV1lQAAAAASUVORK5CYII=";

async function createFixtureLibrary(): Promise<string> {
  const fixtureDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-a11y-fixtures-"));
  const imageBuffer = Buffer.from(FIXTURE_IMAGE_BASE64, "base64");
  await fs.writeFile(path.join(fixtureDir, "keyboard-lake.png"), imageBuffer);
  await fs.writeFile(path.join(fixtureDir, "keyboard-city.png"), imageBuffer);
  return fixtureDir;
}

async function launchChronoPic(userDataDir: string) {
  const { VITE_DEV_SERVER_URL: _viteDevServerUrl, ...baseEnv } = process.env;
  return electron.launch({
    args: ["apps/desktop/dist/main/main.js"],
    env: {
      ...baseEnv,
      CHRONOPIC_USER_DATA_DIR: userDataDir,
      ELECTRON_DISABLE_SANDBOX: "1",
    },
  });
}

test.describe("ChronoPic accessibility and keyboard runtime", () => {
  test("supports keyboard activation, dialog focus return, and Escape viewer close", async () => {
    const userDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-a11y-userdata-"));
    const fixtureDir = await createFixtureLibrary();
    const electronApp = await launchChronoPic(userDataDir);
    const page = await electronApp.firstWindow();

    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole("button", { name: /add folder/i })).toBeVisible();

    await page.evaluate(async (libraryPath) => {
      const api = (window as any).chronoPic;
      await api.initialize();
      await api.addLibrarySource(libraryPath);
      await api.scanLibrary();
    }, fixtureDir);
    await page.reload({ waitUntil: "networkidle" });
    await expect(page.getByRole("button", { name: /create first memory/i })).toBeVisible({ timeout: 15_000 });

    const createFirstMemoryButton = page.getByRole("button", { name: /create first memory/i });
    await createFirstMemoryButton.click();
    await expect(page.getByPlaceholder(/e\.g\./i)).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(page.getByPlaceholder(/e\.g\./i)).not.toBeVisible();
    await expect(createFirstMemoryButton).toBeFocused();

    const photoCard = page.getByRole("button", { name: /keyboard-lake\.png/i }).first();
    await photoCard.focus();
    await page.keyboard.press(" ");
    await expect(photoCard).toHaveAttribute("aria-pressed", "true");
    await page.keyboard.press("Enter");
    await expect(page.getByRole("dialog", { name: /detail/i })).toBeVisible({ timeout: 10_000 });

    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog", { name: /detail/i })).not.toBeVisible();

    await photoCard.dblclick();
    const galleryDialog = page.getByRole("dialog", { name: /gallery/i });
    await expect(galleryDialog).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText("Gallery View", { exact: true })).toBeVisible();
    await expect(galleryDialog.getByText("keyboard-lake.png", { exact: true })).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog", { name: /gallery/i })).not.toBeVisible();

    await photoCard.focus();
    await page.keyboard.press("g");
    await expect(page.getByRole("dialog", { name: /gallery/i })).toBeVisible({ timeout: 10_000 });
    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog", { name: /gallery/i })).not.toBeVisible();

    await page.getByRole("button", { name: /select photos/i }).click();
    await expect(page.getByRole("button", { name: /select for batch actions/i }).first()).toBeVisible();

    await electronApp.close();
  });
});
