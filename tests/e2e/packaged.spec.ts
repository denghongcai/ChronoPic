import { expect, test, _electron as electron } from "@playwright/test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const FIXTURE_IMAGE_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGP8z8Dwn4GBgYGBgAEAGu0C/gfV1lQAAAAASUVORK5CYII=";

async function createFixtureLibrary(): Promise<string> {
  const fixtureDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-packaged-fixtures-"));
  const imageBuffer = Buffer.from(FIXTURE_IMAGE_BASE64, "base64");
  await fs.writeFile(path.join(fixtureDir, "packaged-lake.png"), imageBuffer);
  await fs.writeFile(path.join(fixtureDir, "packaged-city.png"), imageBuffer);
  return fixtureDir;
}

async function launchPackagedChronoPic(userDataDir: string) {
  const { VITE_DEV_SERVER_URL: _viteDevServerUrl, ...baseEnv } = process.env;
  const executablePath = process.env.CHRONOPIC_PACKAGED_APP_PATH ?? defaultPackagedExecutablePath();

  return electron.launch({
    executablePath,
    env: {
      ...baseEnv,
      CHRONOPIC_USER_DATA_DIR: userDataDir,
      ELECTRON_DISABLE_SANDBOX: "1",
    },
  });
}

function defaultPackagedExecutablePath(): string {
  const arch = process.arch;
  const target = process.env.CHRONOPIC_PACKAGED_TARGET ?? platformTarget();

  if (target === "macos") {
    return path.resolve(`dist/release/chronopic-macos-${arch}/ChronoPic.app/Contents/MacOS/ChronoPic`);
  }

  if (target === "windows") {
    return path.resolve(`dist/release/chronopic-windows-${arch}/chronopic.exe`);
  }

  return path.resolve(`dist/release/chronopic-linux-${arch}/chronopic`);
}

function platformTarget(): string {
  if (process.platform === "darwin") {
    return "macos";
  }

  if (process.platform === "win32") {
    return "windows";
  }

  return "linux";
}

test.describe("ChronoPic packaged desktop runtime", () => {
  test("launches the packaged executable and exercises preload, SQLite, thumbnails, and backup bridge", async () => {
    const userDataDir = await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-packaged-userdata-"));
    const fixtureDir = await createFixtureLibrary();
    const backupPath = path.join(await fs.mkdtemp(path.join(os.tmpdir(), "chronopic-packaged-backup-")), "backup.json");

    const electronApp = await launchPackagedChronoPic(userDataDir);
    const page = await electronApp.firstWindow();
    await expect(page.locator(".flex.h-screen")).toBeVisible({ timeout: 15_000 });

    const result = await page.evaluate(async ({ libraryPath, backupPath }) => {
      const api = (window as any).chronoPic;

      if (!api) {
        throw new Error("preload bridge is unavailable");
      }

      await api.initialize();
      await api.addLibrarySource(libraryPath);
      await api.scanLibrary();
      const photos = await api.listPhotos({ sortBy: "path", sortDirection: "asc" });
      const photoId = photos[0]?.photo.id;

      if (!photoId) {
        throw new Error("packaged scan did not index fixture media");
      }

      await api.updatePhotoCaption(photoId, "Packaged smoke caption");
      const exported = await api.exportBackup(backupPath);
      const preview = await api.previewBackupRestore(backupPath);

      return {
        photos,
        record: await api.getPhoto(photoId),
        exported,
        preview,
        snapshot: await api.getSnapshot(),
      };
    }, { libraryPath: fixtureDir, backupPath });

    expect(result.photos).toHaveLength(2);
    expect(result.photos.every((record: any) => record.photo.thumbnailPath)).toBe(true);
    expect(result.record?.semantic.caption).toBe("Packaged smoke caption");
    expect(result.snapshot.sources).toHaveLength(1);
    expect(result.exported?.preview.photoCount).toBe(2);
    expect(result.preview?.preview.conflictCount).toBeGreaterThan(0);
    await expect.poll(async () => (await fs.stat(backupPath)).size).toBeGreaterThan(100);

    await electronApp.close();
  });
});
