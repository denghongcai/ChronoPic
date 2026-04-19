import path from "node:path";
import { fileURLToPath } from "node:url";
import { pathToFileURL } from "node:url";

import { app, BrowserWindow, dialog, ipcMain, net, protocol } from "electron";
import type { OpenDialogOptions } from "electron";

import type { PhotoFilter, PlaceGroupQuery, TimelineGroupQuery } from "@chronopic/domain";

import { createRuntime } from "./runtime.js";

const ASSET_SCHEME = "chronopic-asset";

protocol.registerSchemesAsPrivileged([
  {
    scheme: ASSET_SCHEME,
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true
    }
  }
]);

app.disableHardwareAcceleration();

let mainWindow: BrowserWindow | null = null;
let handlersRegistered = false;
let runtimeHandle: Awaited<ReturnType<typeof createRuntime>> | null = null;
let assetProtocolRegistered = false;

const currentDir = path.dirname(fileURLToPath(import.meta.url));
const thumbsDir = path.join(app.getPath("userData"), "chronopic", "thumbs");

async function createMainWindow(): Promise<void> {
  runtimeHandle ??= await createRuntime();
  const isDev = process.env.VITE_DEV_SERVER_URL !== undefined;

  await registerAssetProtocol();

  mainWindow = new BrowserWindow({
    width: 1440,
    height: 920,
    minWidth: 1180,
    minHeight: 760,
    backgroundColor: "#11161a",
    webPreferences: {
      preload: path.join(currentDir, "../preload/index.cjs"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  if (isDev) {
    await mainWindow.loadURL(process.env.VITE_DEV_SERVER_URL as string);
  } else {
    await mainWindow.loadFile(path.join(currentDir, "../renderer/index.html"));
  }

  if (!handlersRegistered) {
    registerHandlers(runtimeHandle);
    handlersRegistered = true;
  }

  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

async function registerAssetProtocol(): Promise<void> {
  if (assetProtocolRegistered) {
    return;
  }

  assetProtocolRegistered = true;

  await protocol.handle(ASSET_SCHEME, async (request) => {
    const url = new URL(request.url);
    const host = url.hostname;

    const requestedPath = url.searchParams.get("path");

    if (!requestedPath) {
      return new Response("Missing path", { status: 400 });
    }

    const resolvedPath = path.resolve(requestedPath);

    if (host === "thumbs") {
      if (!isPathInside(thumbsDir, resolvedPath)) {
        return new Response("Forbidden", { status: 403 });
      }

      return net.fetch(pathToFileURL(resolvedPath).toString());
    }

    if (host === "media") {
      const libraryRoots = runtimeHandle?.appService.listLibrarySources().map((source) => path.resolve(source.path)) ?? [];
      const isAllowed = libraryRoots.some((rootPath) => isPathInside(rootPath, resolvedPath));

      if (!isAllowed) {
        return new Response("Forbidden", { status: 403 });
      }

      return net.fetch(pathToFileURL(resolvedPath).toString());
    }

    return new Response("Not found", { status: 404 });
  });
}

function isPathInside(rootPath: string, candidatePath: string): boolean {
  const relativePath = path.relative(rootPath, candidatePath);
  return relativePath !== "" && !relativePath.startsWith("..") && !path.isAbsolute(relativePath);
}

function registerHandlers(runtime: NonNullable<typeof runtimeHandle>) {
  ipcMain.handle("library:pickDirectory", async () => {
    const options: OpenDialogOptions = { properties: ["openDirectory"] };
    const result = mainWindow
      ? await dialog.showOpenDialog(mainWindow, options)
      : await dialog.showOpenDialog(options);

    return result.canceled ? null : result.filePaths[0] ?? null;
  });

  ipcMain.handle("system:initialize", async () => ({
    snapshot: runtime.appService.initialize(),
    capabilities: runtime.appService.getCapabilities()
  }));

  ipcMain.handle("library:add", async (_event, libraryPath: string) => runtime.appService.addLibrarySource(libraryPath));
  ipcMain.handle("library:list", async () => runtime.appService.listLibrarySources());
  ipcMain.handle("library:scan", async (_event, sourceId?: string) => runtime.appService.scanLibrary(sourceId));
  ipcMain.handle("photos:list", async (_event, filter?: PhotoFilter) => runtime.appService.listPhotos(filter));
  ipcMain.handle("photos:countMappable", async (_event, filter?: PhotoFilter) => runtime.appService.countMappablePhotos(filter));
  ipcMain.handle("photos:listPlaceGroups", async (_event, query?: PlaceGroupQuery) => runtime.appService.listPlaceGroups(query));
  ipcMain.handle("photos:listTimelineGroups", async (_event, query?: TimelineGroupQuery) =>
    runtime.appService.listTimelineGroups(query)
  );
  ipcMain.handle("photos:get", async (_event, photoId: string) => runtime.appService.getPhoto(photoId));
  ipcMain.handle("photos:updateTags", async (_event, photoId: string, labels: string[]) =>
    runtime.appService.updatePhotoTags(photoId, labels)
  );
  ipcMain.handle("photos:updateCaption", async (_event, photoId: string, caption: string | null) =>
    runtime.appService.updatePhotoCaption(photoId, caption)
  );
  ipcMain.handle("photos:updateDatetime", async (_event, photoId: string, datetime: number | null) =>
    runtime.appService.updatePhotoDatetime(photoId, datetime)
  );
  ipcMain.handle("photos:toggleFavorite", async (_event, photoId: string, favorite: boolean) =>
    runtime.appService.updatePhotoFavorite(photoId, favorite)
  );
  ipcMain.handle("photos:rollback", async (_event, photoId?: string) => runtime.appService.rollbackLatestEdit(photoId));
  ipcMain.handle("system:snapshot", async () => runtime.appService.getSnapshot());
  ipcMain.handle("memories:list", async () => runtime.appService.listMemories());
  ipcMain.handle("memories:get", async (_event, memoryId: string) => runtime.appService.getMemory(memoryId));
  ipcMain.handle("memories:create", async (_event, name: string, description?: string, source?: string) =>
    runtime.appService.createMemory(name, description, source as "manual" | "ai")
  );
  ipcMain.handle(
    "memories:update",
    async (_event, memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }) =>
      runtime.appService.updateMemory(memoryId, updates)
  );
  ipcMain.handle("memories:delete", async (_event, memoryId: string) => runtime.appService.deleteMemory(memoryId));
  ipcMain.handle("memories:addPhoto", async (_event, memoryId: string, photoId: string) =>
    runtime.appService.addPhotoToMemory(memoryId, photoId)
  );
  ipcMain.handle("memories:removePhoto", async (_event, memoryId: string, photoId: string) =>
    runtime.appService.removePhotoFromMemory(memoryId, photoId)
  );
  ipcMain.handle("memories:listByPhoto", async (_event, photoId: string) =>
    runtime.appService.listMemoriesByPhoto(photoId)
  );
  ipcMain.handle("memories:listPhotos", async (_event, memoryId: string, filter?: PhotoFilter) =>
    runtime.appService.listPhotosByMemory(memoryId, filter)
  );
}

app.whenReady().then(createMainWindow);

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    void createMainWindow();
  }
});

app.on("before-quit", () => {
  runtimeHandle?.close();
});
