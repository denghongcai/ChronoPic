import { defineConfig, devices } from "@playwright/test";
import path from "node:path";

const repoRoot = path.resolve(new URL("../..", import.meta.url).pathname);

export default defineConfig({
  testDir: ".",
  outputDir: path.join(repoRoot, "test-results", "playwright-artifacts"),
  fullyParallel: false,
  timeout: 30_000,
  use: {
    baseURL: "http://localhost:5173",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
