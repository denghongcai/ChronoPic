import type { AppCapabilities, LibrarySnapshot, Memory, MemorySource, PhotoFilter, PhotoRecord } from "@chronopic/domain";

export interface ChronoPicBridge {
  initialize: () => Promise<{ snapshot: LibrarySnapshot; capabilities: AppCapabilities }>;
  pickLibraryDirectory: () => Promise<string | null>;
  addLibrarySource: (libraryPath: string) => Promise<unknown>;
  listLibrarySources: () => Promise<unknown>;
  scanLibrary: (sourceId?: string) => Promise<unknown>;
  listPhotos: (filter?: PhotoFilter) => Promise<PhotoRecord[]>;
  getPhoto: (photoId: string) => Promise<PhotoRecord | null>;
  updatePhotoTags: (photoId: string, labels: string[]) => Promise<PhotoRecord>;
  updatePhotoCaption: (photoId: string, caption: string | null) => Promise<PhotoRecord>;
  updatePhotoDatetime: (photoId: string, datetime: number | null) => Promise<PhotoRecord>;
  updatePhotoFavorite: (photoId: string, favorite: boolean) => Promise<PhotoRecord>;
  rollbackLatestEdit: (photoId?: string) => Promise<PhotoRecord | null>;
  getSnapshot: () => Promise<LibrarySnapshot>;
  listMemories: () => Promise<Memory[]>;
  createMemory: (name: string, description?: string, source?: MemorySource) => Promise<Memory>;
  deleteMemory: (memoryId: string) => Promise<void>;
  addPhotoToMemory: (memoryId: string, photoId: string) => Promise<void>;
  removePhotoFromMemory: (memoryId: string, photoId: string) => Promise<void>;
  listPhotosByMemory: (memoryId: string, filter?: PhotoFilter) => Promise<PhotoRecord[]>;
}
