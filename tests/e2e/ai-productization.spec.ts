import { expect, test, _electron as electron } from "@playwright/test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

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

test.describe("ChronoPic AI productization UX", () => {
  test("shows AI setup readiness and routes disabled queue recovery to settings", async () => {
    const userDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-ai-product-userdata-"));
    const electronApp = await launchChronoPic(userDataDir);
    const page = await electronApp.firstWindow();

    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });

    await page.getByRole("button", { name: /settings/i }).click();
    await expect(page.getByRole("heading", { name: /ai enrichment/i })).toBeVisible();
    await expect(page.getByText("AI setup status")).toBeVisible();
    await expect(page.getByText("Incomplete").first()).toBeVisible();
    await expect(page.locator("span").filter({ hasText: /^API Key$/ })).toBeVisible();
    await expect(page.getByText("Missing").first()).toBeVisible();

    await page.getByPlaceholder(/model name/i).fill("vision-test-model");
    await page.getByPlaceholder(/model endpoint url/i).fill("https://models.example/v1");
    await expect(page.getByText("Incomplete").first()).toBeVisible();
    await expect(page.getByText(/AI stays disabled until every required setting/i)).toBeVisible();

    await page.getByRole("button", { name: /notifications/i }).click();
    await expect(page.getByText(/AI setup is missing/i)).toBeVisible();
    await page.getByRole("button", { name: /configure ai/i }).click();
    await expect(page.getByRole("heading", { name: /ai enrichment/i })).toBeVisible();

    await electronApp.close();
  });
});
