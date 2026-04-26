import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pathToFileURL } from "node:url";

import { app, BrowserWindow, dialog, ipcMain, net, protocol } from "electron";
import type { OpenDialogOptions } from "electron";

import type { AISettings, DiscoveryQuery, MapSettings, PhotoFilter, PlaceGroupQuery, TimelineGroupQuery } from "@chronopic/domain";
import { ChronoPicConfigStore } from "@chronopic/infra-config";

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
let configStore: ChronoPicConfigStore | null = null;

const currentDir = path.dirname(fileURLToPath(import.meta.url));
const thumbsDir = path.join(app.getPath("userData"), "chronopic", "thumbs");
const debugLogPath = path.join(app.getPath("userData"), "chronopic", "debug.log");

function appendDebugLog(message: string): void {
  try {
    fs.mkdirSync(path.dirname(debugLogPath), { recursive: true });
    fs.appendFileSync(debugLogPath, `[${new Date().toISOString()}] ${message}\n`, "utf8");
  } catch {
    // Ignore logging failures.
  }
}

async function createMainWindow(): Promise<void> {
  runtimeHandle ??= await createRuntime({ aiSettings: getConfigStore().getAISettings() });
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
    registerHandlers();
    handlersRegistered = true;
  }

  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

function getConfigStore(): ChronoPicConfigStore {
  configStore ??= new ChronoPicConfigStore(path.join(app.getPath("userData"), "chronopic", "settings.json"));
  return configStore;
}

function getRuntimeHandle(): NonNullable<typeof runtimeHandle> {
  if (!runtimeHandle) {
    throw new Error("Runtime is not initialized");
  }

  return runtimeHandle;
}

function toSerializable<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

async function rebuildRuntime(): Promise<NonNullable<typeof runtimeHandle>> {
  runtimeHandle?.close();
  runtimeHandle = await createRuntime({ aiSettings: getConfigStore().getAISettings() });
  return runtimeHandle;
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

function registerHandlers() {
  ipcMain.handle("library:pickDirectory", async () => {
    const options: OpenDialogOptions = { properties: ["openDirectory"] };
    const result = mainWindow
      ? await dialog.showOpenDialog(mainWindow, options)
      : await dialog.showOpenDialog(options);

    return result.canceled ? null : result.filePaths[0] ?? null;
  });

  ipcMain.handle("system:initialize", async () => ({
    snapshot: getRuntimeHandle().appService.initialize(),
    capabilities: getRuntimeHandle().appService.getCapabilities()
  }));
  ipcMain.handle("system:debugLog", async (_event, message: string) => {
    appendDebugLog(message);
  });
  ipcMain.handle("system:getAISettings", async () => getConfigStore().getAISettings());
  ipcMain.handle("system:saveAISettings", async (_event, settings: AISettings) => {
    const saved = getConfigStore().saveAISettings(settings);
    const runtime = await rebuildRuntime();
    return {
      settings: saved,
      capabilities: runtime.appService.getCapabilities(),
    };
  });
  ipcMain.handle("system:getMapSettings", async () => getConfigStore().getMapSettings());
  ipcMain.handle("system:saveMapSettings", async (_event, settings: MapSettings) => getConfigStore().saveMapSettings(settings));

  ipcMain.handle("library:add", async (_event, libraryPath: string) => getRuntimeHandle().appService.addLibrarySource(libraryPath));
  ipcMain.handle("library:list", async () => getRuntimeHandle().appService.listLibrarySources());
  ipcMain.handle("library:scan", async (_event, sourceId?: string) => getRuntimeHandle().appService.scanLibrary(sourceId));
  ipcMain.handle("photos:listForDiscovery", async (_event, query?: DiscoveryQuery) =>
    toSerializable(getRuntimeHandle().appService.listPhotosForDiscovery(query))
  );
  ipcMain.handle("photos:list", async (_event, filter?: PhotoFilter) => toSerializable(getRuntimeHandle().appService.listPhotos(filter)));
  ipcMain.handle("photos:getSemanticQueueStats", async () => toSerializable(getRuntimeHandle().appService.getSemanticQueueStats()));
  ipcMain.handle("photos:countMappable", async (_event, filter?: PhotoFilter) => getRuntimeHandle().appService.countMappablePhotos(filter));
  ipcMain.handle("photos:listPlaceGroups", async (_event, query?: PlaceGroupQuery) => toSerializable(getRuntimeHandle().appService.listPlaceGroups(query)));
  ipcMain.handle("photos:listTimelineGroups", async (_event, query?: TimelineGroupQuery) =>
    toSerializable(getRuntimeHandle().appService.listTimelineGroups(query))
  );
  ipcMain.handle("photos:get", async (_event, photoId: string) => toSerializable(getRuntimeHandle().appService.getPhoto(photoId)));
  ipcMain.handle("photos:updateTags", async (_event, photoId: string, labels: string[]) =>
    getRuntimeHandle().appService.updatePhotoTags(photoId, labels)
  );
  ipcMain.handle("photos:updateCaption", async (_event, photoId: string, caption: string | null) =>
    getRuntimeHandle().appService.updatePhotoCaption(photoId, caption)
  );
  ipcMain.handle("photos:enrichSemantic", async (_event, photoId: string) => getRuntimeHandle().appService.enrichPhotoSemantic(photoId));
  ipcMain.handle("photos:enrichPendingSemantics", async (_event, limit?: number) => {
    appendDebugLog(`photos:enrichPendingSemantics start limit=${String(limit ?? 12)}`);
    try {
      const summary = await getRuntimeHandle().appService.enrichPendingSemantics(limit);
      appendDebugLog(`photos:enrichPendingSemantics success processed=${summary.processed} completed=${summary.completed} failed=${summary.failed} skipped=${summary.skipped}`);
      return JSON.stringify({
        ok: true,
        processed: Number(summary.processed),
        completed: Number(summary.completed),
        failed: Number(summary.failed),
        skipped: Number(summary.skipped),
      });
    } catch (error) {
      appendDebugLog(
        `photos:enrichPendingSemantics error message=${
          error instanceof Error && error.message ? error.message : "unknown"
        }`
      );
      return JSON.stringify({
        ok: false,
        message: error instanceof Error && error.message ? error.message : "Failed to process pending AI metadata",
      });
    }
  });
  ipcMain.handle("photos:updateDatetime", async (_event, photoId: string, datetime: number | null) =>
    getRuntimeHandle().appService.updatePhotoDatetime(photoId, datetime)
  );
  ipcMain.handle("photos:toggleFavorite", async (_event, photoId: string, favorite: boolean) =>
    getRuntimeHandle().appService.updatePhotoFavorite(photoId, favorite)
  );
  ipcMain.handle("photos:rollback", async (_event, photoId?: string) => getRuntimeHandle().appService.rollbackLatestEdit(photoId));
  ipcMain.handle("system:snapshot", async () => getRuntimeHandle().appService.getSnapshot());
  ipcMain.handle("memories:list", async () => toSerializable(getRuntimeHandle().appService.listMemories()));
  ipcMain.handle("memories:get", async (_event, memoryId: string) => toSerializable(getRuntimeHandle().appService.getMemory(memoryId)));
  ipcMain.handle("memories:enrichSemantic", async (_event, memoryId: string, context?: { name?: string | null; description?: string | null }) =>
    getRuntimeHandle().appService.enrichMemorySemantic(memoryId, context)
  );
  ipcMain.handle("memories:create", async (_event, name: string, description?: string, source?: string) =>
    getRuntimeHandle().appService.createMemory(name, description, source as "manual" | "ai")
  );
  ipcMain.handle(
    "memories:update",
    async (_event, memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }) =>
      getRuntimeHandle().appService.updateMemory(memoryId, updates)
  );
  ipcMain.handle("memories:delete", async (_event, memoryId: string) => getRuntimeHandle().appService.deleteMemory(memoryId));
  ipcMain.handle("memories:addPhoto", async (_event, memoryId: string, photoId: string) =>
    getRuntimeHandle().appService.addPhotoToMemory(memoryId, photoId)
  );
  ipcMain.handle("memories:removePhoto", async (_event, memoryId: string, photoId: string) =>
    getRuntimeHandle().appService.removePhotoFromMemory(memoryId, photoId)
  );
  ipcMain.handle("memories:listByPhoto", async (_event, photoId: string) =>
    toSerializable(getRuntimeHandle().appService.listMemoriesByPhoto(photoId))
  );
  ipcMain.handle("memories:listPhotos", async (_event, memoryId: string, filter?: PhotoFilter) =>
    toSerializable(getRuntimeHandle().appService.listPhotosByMemory(memoryId, filter))
  );
  ipcMain.handle("memoryCandidates:list", async () => toSerializable(getRuntimeHandle().appService.listMemoryCandidates()));
  ipcMain.handle("memoryCandidates:generate", async (_event, limit?: number) =>
    toSerializable(getRuntimeHandle().appService.generateMemoryCandidates(limit))
  );
  ipcMain.handle(
    "memoryCandidates:accept",
    async (_event, candidateId: string, input?: { name?: string; description?: string | null; photoIds?: string[] }) =>
      toSerializable(getRuntimeHandle().appService.acceptMemoryCandidate(candidateId, input))
  );
  ipcMain.handle("memoryCandidates:reject", async (_event, candidateId: string) =>
    toSerializable(getRuntimeHandle().appService.rejectMemoryCandidate(candidateId))
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
