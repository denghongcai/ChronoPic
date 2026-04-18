const { contextBridge, ipcRenderer } = require("electron");

import type { ChronoPicBridge } from "./bridge.js";

const api: ChronoPicBridge = {
  initialize: () => ipcRenderer.invoke("system:initialize"),
  pickLibraryDirectory: () => ipcRenderer.invoke("library:pickDirectory"),
  addLibrarySource: (libraryPath: string) => ipcRenderer.invoke("library:add", libraryPath),
  listLibrarySources: () => ipcRenderer.invoke("library:list"),
  scanLibrary: (sourceId?: string) => ipcRenderer.invoke("library:scan", sourceId),
  listPhotos: (filter) => ipcRenderer.invoke("photos:list", filter),
  getPhoto: (photoId: string) => ipcRenderer.invoke("photos:get", photoId),
  updatePhotoTags: (photoId: string, labels: string[]) => ipcRenderer.invoke("photos:updateTags", photoId, labels),
  updatePhotoDatetime: (photoId: string, datetime: number | null) =>
    ipcRenderer.invoke("photos:updateDatetime", photoId, datetime),
  rollbackLatestEdit: (photoId?: string) => ipcRenderer.invoke("photos:rollback", photoId),
  getSnapshot: () => ipcRenderer.invoke("system:snapshot")
};

contextBridge.exposeInMainWorld("chronoPic", api);
