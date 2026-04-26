import { expect, test, _electron as electron } from "@playwright/test";

test.describe("ChronoPic i18n smoke", () => {
  let electronApp: Awaited<ReturnType<typeof electron["launch"]>>;

  test.beforeAll(async () => {
    electronApp = await electron.launch({
      args: ["apps/desktop/dist/main/main.js"],
      env: {
        ...process.env,
        ELECTRON_DISABLE_SANDBOX: "1",
        VITE_DEV_SERVER_URL: "http://localhost:5173",
      },
    });
  });

  test.afterAll(async () => {
    await electronApp?.close();
  });

  test("switching to Chinese localizes sidebar, header search, and memory detail", async () => {
    const page = await electronApp.firstWindow();
    const memoryName = `测试记忆 ${Date.now()}`;
    await page.waitForLoadState("networkidle");

    await page.getByRole("button", { name: /settings|设置/i }).click();
    await expect(page.getByText(/Library Settings|资料库设置/)).toBeVisible({ timeout: 10_000 });

    await page.getByRole("combobox").first().click();
    await page.getByRole("option", { name: /Simplified Chinese|简体中文/ }).click();
    await page.getByRole("button", { name: /Save Language Settings|保存语言设置/ }).click();

    await expect(page.getByText("资料库", { exact: true })).toBeVisible({ timeout: 10_000 });
    await page.getByRole("button", { name: "全部照片" }).click();
    await expect(page.getByPlaceholder("搜索时刻、地点...")).toBeVisible();

    await page.getByRole("button", { name: "创建记忆" }).click();
    await page.getByPlaceholder("例如：2024 夏天、巴黎旅行").fill(memoryName);
    await page.getByRole("button", { name: "创建" }).click();
    await page.getByRole("button", { name: memoryName, exact: true }).click();

    await expect(page.getByText("记忆详情")).toBeVisible({ timeout: 10_000 });
  });
});
