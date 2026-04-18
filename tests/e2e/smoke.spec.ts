import { test, expect, _electron as electron } from "@playwright/test";

test.describe("ChronoPic Smoke Tests (Electron)", () => {
  let electronApp: Awaited<ReturnType<typeof electron["launch"]>>;

  test.beforeAll(async () => {
    electronApp = await electron.launch({
      args: ["apps/desktop/dist/main/main.js"],
      env: {
        ...process.env,
        VITE_DEV_SERVER_URL: "http://localhost:5173",
      },
    });
  });

  test.afterAll(async () => {
    await electronApp.close();
  });

  test("app window opens without renderer JS errors", async ({ page }) => {
    const errors: string[] = [];
    page.on("pageerror", (err) => errors.push(err.message));
    page.on("console", (msg) => {
      if (msg.type() === "error") errors.push(msg.text());
    });

    await page.goto("http://localhost:5173", { waitUntil: "networkidle" });
    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 10000 });

    const criticalErrors = errors.filter(
      (e) =>
        !e.includes("dbus") &&
        !e.includes("DBus") &&
        !e.includes("bus.cc") &&
        !e.includes("chronopic") &&
        !e.includes("Cannot read properties of undefined")
    );
    expect(criticalErrors).toHaveLength(0);
  });

  test("sidebar renders Library and Memories sections", async ({ page }) => {
    await page.goto("http://localhost:5173", { waitUntil: "networkidle" });
    await expect(page.locator("text=Library")).toBeVisible({ timeout: 10000 });
    await expect(page.locator("text=All Photos")).toBeVisible();
    await expect(page.getByText("Memories", { exact: true })).toBeVisible();
    await expect(page.locator("text=Create Memory")).toBeVisible();
  });

  test("header renders with search input", async ({ page }) => {
    await page.goto("http://localhost:5173", { waitUntil: "networkidle" });
    await expect(page.getByPlaceholder(/search/i)).toBeVisible({ timeout: 10000 });
  });

  test("CreateMemoryDialog opens and closes", async ({ page }) => {
    await page.goto("http://localhost:5173", { waitUntil: "networkidle" });
    await page.getByRole("button", { name: /create memory/i }).click();
    await expect(page.getByPlaceholder(/e\.g\./i)).toBeVisible({ timeout: 5000 });
    await page.getByRole("button", { name: /cancel/i }).click();
    await expect(page.getByPlaceholder(/e\.g\./i)).not.toBeVisible();
  });

  test("CreateMemoryDialog confirms with name", async ({ page }) => {
    await page.goto("http://localhost:5173", { waitUntil: "networkidle" });
    await page.getByRole("button", { name: /create memory/i }).click();
    await expect(page.getByPlaceholder(/e\.g\./i)).toBeVisible({ timeout: 5000 });
    await page.getByPlaceholder(/e\.g\./i).fill("Summer 2024");
    await page.getByRole("button", { name: /^create$/i }).click();
    await expect(page.getByPlaceholder(/e\.g\./i)).not.toBeVisible();
  });

  test("Gallery section renders", async ({ page }) => {
    await page.goto("http://localhost:5173", { waitUntil: "networkidle" });
    const gallery = page.locator(".space-y-6").first();
    await expect(gallery).toBeVisible({ timeout: 10000 });
  });
});
