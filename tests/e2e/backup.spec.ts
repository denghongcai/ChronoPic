import { expect, test, _electron as electron } from "@playwright/test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const FIXTURE_IMAGE_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGP8z8Dwn4GBgYGBgAEAGu0C/gfV1lQAAAAASUVORK5CYII=";

async function createFixtureLibrary(): Promise<string> {
  const fixtureDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-backup-fixtures-"));
  const imageBuffer = Buffer.from(FIXTURE_IMAGE_BASE64, "base64");
  await fs.writeFile(path.join(fixtureDir, "backup-lake.png"), imageBuffer);
  await fs.writeFile(path.join(fixtureDir, "backup-city.png"), imageBuffer);
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

test.describe("ChronoPic backup and restore", () => {
  test("exports a local JSON backup and restores authored state into a clean data directory", async () => {
    const fixtureDir = await createFixtureLibrary();
    const sourceUserDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-backup-source-"));
    const targetUserDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-backup-target-"));
    const backupPath = path.join(await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-backup-file-")), "chronopic-backup.json");

    let electronApp = await launchChronoPic(sourceUserDataDir);
    let page = await electronApp.firstWindow();
    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });

    const exported = await page.evaluate(async ({ libraryPath, backupPath }) => {
      const api = (window as any).chronoPic;
      await api.initialize();
      await api.addLibrarySource(libraryPath);
      await api.scanLibrary();
      const photos = await api.listPhotos({ sortBy: "path", sortDirection: "asc" });
      const photoId = photos[0]?.photo.id;

      if (!photoId) {
        throw new Error("scan did not index any fixture photos");
      }

      const memory = await api.createMemory("Backup E2E", "Restored story");
      await api.addPhotoToMemory(memory.id, photoId);
      await api.updateMemory(memory.id, { coverPhotoId: photoId });
      await api.updatePhotoCaption(photoId, "Backup E2E caption");
      await api.updatePhotoTags(photoId, ["backup", "restore"]);
      await api.updatePhotoFavorite(photoId, true);
      await api.saveLocaleSettings({ locale: "zh-CN", aiOutputLocale: "zh-CN" });
      await api.saveMapSettings({ apiKey: "amap-backup-key", securityJsCode: "amap-security" });

      return {
        exported: await api.exportBackup(backupPath),
        preview: await api.previewBackupRestore(backupPath),
        memoryId: memory.id,
        photoId,
      };
    }, { libraryPath: fixtureDir, backupPath });

    expect(exported.exported?.path).toBe(backupPath);
    expect(exported.exported?.preview.photoCount).toBe(2);
    expect(exported.exported?.preview.memoryCount).toBe(1);
    expect(exported.preview?.preview.conflictCount).toBeGreaterThan(0);
    await expect.poll(async () => (await fs.stat(backupPath)).size).toBeGreaterThan(100);

    await electronApp.close();

    electronApp = await launchChronoPic(targetUserDataDir);
    page = await electronApp.firstWindow();
    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });

    const restored = await page.evaluate(async ({ backupPath, memoryId, photoId }) => {
      const api = (window as any).chronoPic;
      await api.initialize();
      const previewBeforeRestore = await api.previewBackupRestore(backupPath);
      const restoreResult = await api.restoreBackup(backupPath, { mode: "replace" });

      return {
        previewBeforeRestore,
        restoreResult,
        photos: await api.listPhotos({ sortBy: "path", sortDirection: "asc" }),
        record: await api.getPhoto(photoId),
        memory: await api.getMemory(memoryId),
        memoryPhotos: await api.listPhotosByMemory(memoryId),
        locale: await api.getLocaleSettings(),
        map: await api.getMapSettings(),
        snapshot: await api.getSnapshot(),
      };
    }, { backupPath, memoryId: exported.memoryId, photoId: exported.photoId });

    expect(restored.previewBeforeRestore?.preview.conflictCount).toBe(0);
    expect(restored.restoreResult?.result.restoredPhotoCount).toBe(2);
    expect(restored.photos).toHaveLength(2);
    expect(restored.snapshot.sources).toHaveLength(1);
    expect(restored.record?.semantic.caption).toBe("Backup E2E caption");
    expect(restored.record?.semantic.labels).toEqual(["backup", "restore"]);
    expect(restored.record?.photo.favorite).toBe(true);
    expect(restored.memory?.name).toBe("Backup E2E");
    expect(restored.memory?.description).toBe("Restored story");
    expect(restored.memory?.coverPhotoId).toBe(exported.photoId);
    expect(restored.memoryPhotos.map((record: any) => record.photo.id)).toContain(exported.photoId);
    expect(restored.locale).toEqual({ locale: "zh-CN", aiOutputLocale: "zh-CN" });
    expect(restored.map).toEqual({ apiKey: "amap-backup-key", securityJsCode: "amap-security" });

    await electronApp.close();
  });
});
