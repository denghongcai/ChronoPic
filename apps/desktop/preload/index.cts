const { contextBridge, ipcRenderer } = require("electron");

import type { ChronoPicBridge } from "./bridge.js";

const api: ChronoPicBridge = {
  initialize: () => ipcRenderer.invoke("system:initialize"),
  debugLog: (message: string) => ipcRenderer.invoke("system:debugLog", message),
  getAISettings: () => ipcRenderer.invoke("system:getAISettings"),
  saveAISettings: (settings) => ipcRenderer.invoke("system:saveAISettings", settings),
  getMapSettings: () => ipcRenderer.invoke("system:getMapSettings"),
  saveMapSettings: (settings) => ipcRenderer.invoke("system:saveMapSettings", settings),
  pickLibraryDirectory: () => ipcRenderer.invoke("library:pickDirectory"),
  addLibrarySource: (libraryPath: string) => ipcRenderer.invoke("library:add", libraryPath),
  listLibrarySources: () => ipcRenderer.invoke("library:list"),
  scanLibrary: (sourceId?: string) => ipcRenderer.invoke("library:scan", sourceId),
  listPhotos: (filter) => ipcRenderer.invoke("photos:list", filter),
  getSemanticQueueStats: () => ipcRenderer.invoke("photos:getSemanticQueueStats"),
  countMappablePhotos: (filter) => ipcRenderer.invoke("photos:countMappable", filter),
  listPlaceGroups: (query) => ipcRenderer.invoke("photos:listPlaceGroups", query),
  listTimelineGroups: (query) => ipcRenderer.invoke("photos:listTimelineGroups", query),
  getPhoto: (photoId: string) => ipcRenderer.invoke("photos:get", photoId),
  updatePhotoTags: (photoId: string, labels: string[]) => ipcRenderer.invoke("photos:updateTags", photoId, labels),
  updatePhotoCaption: (photoId: string, caption: string | null) => ipcRenderer.invoke("photos:updateCaption", photoId, caption),
  enrichPhotoSemantic: (photoId: string) => ipcRenderer.invoke("photos:enrichSemantic", photoId),
  enrichPendingSemantics: async (limit?: number) => {
    const response = await ipcRenderer.invoke("photos:enrichPendingSemantics", limit);
    const parsed = typeof response === "string" ? JSON.parse(response) : response;
    if (parsed && typeof parsed === "object" && "ok" in parsed && parsed.ok === false) {
      throw new Error(typeof parsed.message === "string" ? parsed.message : "Failed to process pending AI metadata");
    }

    if (parsed && typeof parsed === "object" && "ok" in parsed) {
      const { ok: _ok, ...rest } = parsed;
      return rest;
    }

    return parsed;
  },
  updatePhotoDatetime: (photoId: string, datetime: number | null) =>
    ipcRenderer.invoke("photos:updateDatetime", photoId, datetime),
  updatePhotoFavorite: (photoId: string, favorite: boolean) => ipcRenderer.invoke("photos:toggleFavorite", photoId, favorite),
  rollbackLatestEdit: (photoId?: string) => ipcRenderer.invoke("photos:rollback", photoId),
  getSnapshot: () => ipcRenderer.invoke("system:snapshot"),
  listMemories: () => ipcRenderer.invoke("memories:list"),
  getMemory: (memoryId: string) => ipcRenderer.invoke("memories:get", memoryId),
  enrichMemorySemantic: (memoryId: string) => ipcRenderer.invoke("memories:enrichSemantic", memoryId),
  createMemory: (name: string, description?: string, source?: "manual" | "ai") =>
    ipcRenderer.invoke("memories:create", name, description, source),
  updateMemory: (memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }) =>
    ipcRenderer.invoke("memories:update", memoryId, updates),
  deleteMemory: (memoryId: string) => ipcRenderer.invoke("memories:delete", memoryId),
  addPhotoToMemory: (memoryId: string, photoId: string) => ipcRenderer.invoke("memories:addPhoto", memoryId, photoId),
  removePhotoFromMemory: (memoryId: string, photoId: string) =>
    ipcRenderer.invoke("memories:removePhoto", memoryId, photoId),
  listMemoriesByPhoto: (photoId: string) => ipcRenderer.invoke("memories:listByPhoto", photoId),
  listPhotosByMemory: (memoryId: string, filter) => ipcRenderer.invoke("memories:listPhotos", memoryId, filter),
};

contextBridge.exposeInMainWorld("chronoPic", api);
