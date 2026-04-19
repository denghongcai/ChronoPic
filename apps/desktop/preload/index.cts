const { contextBridge, ipcRenderer } = require("electron");

import type { ChronoPicBridge } from "./bridge.js";

const api: ChronoPicBridge = {
  initialize: () => ipcRenderer.invoke("system:initialize"),
  pickLibraryDirectory: () => ipcRenderer.invoke("library:pickDirectory"),
  addLibrarySource: (libraryPath: string) => ipcRenderer.invoke("library:add", libraryPath),
  listLibrarySources: () => ipcRenderer.invoke("library:list"),
  scanLibrary: (sourceId?: string) => ipcRenderer.invoke("library:scan", sourceId),
  listPhotos: (filter) => ipcRenderer.invoke("photos:list", filter),
  countMappablePhotos: (filter) => ipcRenderer.invoke("photos:countMappable", filter),
  listPlaceGroups: (query) => ipcRenderer.invoke("photos:listPlaceGroups", query),
  listTimelineGroups: (query) => ipcRenderer.invoke("photos:listTimelineGroups", query),
  getPhoto: (photoId: string) => ipcRenderer.invoke("photos:get", photoId),
  updatePhotoTags: (photoId: string, labels: string[]) => ipcRenderer.invoke("photos:updateTags", photoId, labels),
  updatePhotoCaption: (photoId: string, caption: string | null) => ipcRenderer.invoke("photos:updateCaption", photoId, caption),
  updatePhotoDatetime: (photoId: string, datetime: number | null) =>
    ipcRenderer.invoke("photos:updateDatetime", photoId, datetime),
  updatePhotoFavorite: (photoId: string, favorite: boolean) => ipcRenderer.invoke("photos:toggleFavorite", photoId, favorite),
  rollbackLatestEdit: (photoId?: string) => ipcRenderer.invoke("photos:rollback", photoId),
  getSnapshot: () => ipcRenderer.invoke("system:snapshot"),
  listMemories: () => ipcRenderer.invoke("memories:list"),
  getMemory: (memoryId: string) => ipcRenderer.invoke("memories:get", memoryId),
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
