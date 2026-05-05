import { expect, test, _electron as electron } from "@playwright/test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const FIXTURE_IMAGE_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGP8z8Dwn4GBgYGBgAEAGu0C/gfV1lQAAAAASUVORK5CYII=";

async function createFixtureLibrary(): Promise<string> {
  const fixtureDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-runtime-fixtures-"));
  const imageBuffer = Buffer.from(FIXTURE_IMAGE_BASE64, "base64");
  await fs.writeFile(path.join(fixtureDir, "lake-weekend.png"), imageBuffer);
  await fs.writeFile(path.join(fixtureDir, "city-walk.png"), imageBuffer);
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

test.describe("ChronoPic desktop runtime", () => {
  test("indexes local media and persists edits, memories, and settings across restart", async () => {
    const userDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-runtime-userdata-"));
    const fixtureDir = await createFixtureLibrary();

    let electronApp = await launchChronoPic(userDataDir);
    let page = await electronApp.firstWindow();
    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });

    const firstRun = await page.evaluate(async (libraryPath) => {
      const api = (window as any).chronoPic;
      await api.initialize();
      await api.addLibrarySource(libraryPath);
      await api.scanLibrary();
      const photos = await api.listPhotos({ sortBy: "path", sortDirection: "asc" });
      const photoId = photos[0]?.photo.id;

      if (!photoId) {
        throw new Error("scan did not index any fixture photos");
      }

      const memory = await api.createMemory("Runtime QA", "Persistence smoke");
      await api.addPhotoToMemory(memory.id, photoId);
      await api.updatePhotoCaption(photoId, "Runtime QA caption");
      await api.updatePhotoTags(photoId, ["runtime", "qa"]);
      await api.updatePhotoFavorite(photoId, true);
      await api.updatePhotoDatetime(photoId, 1_714_521_600_000);
      await api.rollbackLatestEdit(photoId);
      await api.saveLocaleSettings({ locale: "zh-CN", aiOutputLocale: "zh-CN" });

      return {
        memoryId: memory.id,
        photoId,
        photos,
        record: await api.getPhoto(photoId),
        memoryPhotos: await api.listPhotosByMemory(memory.id),
        locale: await api.getLocaleSettings(),
        snapshot: await api.getSnapshot(),
      };
    }, fixtureDir);

    expect(firstRun.photos).toHaveLength(2);
    expect(firstRun.snapshot.sources).toHaveLength(1);
    expect(firstRun.record?.semantic.caption).toBe("Runtime QA caption");
    expect(firstRun.record?.semantic.labels).toEqual(["runtime", "qa"]);
    expect(firstRun.record?.photo.favorite).toBe(true);
    expect(firstRun.record?.metadata.datetime).not.toBe(1_714_521_600_000);
    expect(firstRun.memoryPhotos.map((record) => record.photo.id)).toContain(firstRun.photoId);
    expect(firstRun.locale).toEqual({ locale: "zh-CN", aiOutputLocale: "zh-CN" });

    await electronApp.close();

    electronApp = await launchChronoPic(userDataDir);
    page = await electronApp.firstWindow();
    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });

    const afterRestart = await page.evaluate(async ({ memoryId, photoId }) => {
      const api = (window as any).chronoPic;
      await api.initialize();
      return {
        photos: await api.listPhotos({ sortBy: "path", sortDirection: "asc" }),
        record: await api.getPhoto(photoId),
        memory: await api.getMemory(memoryId),
        memoryPhotos: await api.listPhotosByMemory(memoryId),
        locale: await api.getLocaleSettings(),
        snapshot: await api.getSnapshot(),
      };
    }, { memoryId: firstRun.memoryId, photoId: firstRun.photoId });

    expect(afterRestart.photos).toHaveLength(2);
    expect(afterRestart.snapshot.sources).toHaveLength(1);
    expect(afterRestart.record?.semantic.caption).toBe("Runtime QA caption");
    expect(afterRestart.record?.semantic.labels).toEqual(["runtime", "qa"]);
    expect(afterRestart.record?.photo.favorite).toBe(true);
    expect(afterRestart.memory?.name).toBe("Runtime QA");
    expect(afterRestart.memoryPhotos.map((record) => record.photo.id)).toContain(firstRun.photoId);
    expect(afterRestart.locale).toEqual({ locale: "zh-CN", aiOutputLocale: "zh-CN" });

    await electronApp.close();
  });
});
