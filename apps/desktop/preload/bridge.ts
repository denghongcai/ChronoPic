import type { AppCapabilities, LibrarySnapshot, PhotoFilter, PhotoRecord } from "@chronopic/domain";

export interface ChronoPicBridge {
  initialize: () => Promise<{ snapshot: LibrarySnapshot; capabilities: AppCapabilities }>;
  pickLibraryDirectory: () => Promise<string | null>;
  addLibrarySource: (libraryPath: string) => Promise<unknown>;
  listLibrarySources: () => Promise<unknown>;
  scanLibrary: (sourceId?: string) => Promise<unknown>;
  listPhotos: (filter?: PhotoFilter) => Promise<PhotoRecord[]>;
  getPhoto: (photoId: string) => Promise<PhotoRecord | null>;
  updatePhotoTags: (photoId: string, labels: string[]) => Promise<PhotoRecord>;
  updatePhotoDatetime: (photoId: string, datetime: number | null) => Promise<PhotoRecord>;
  rollbackLatestEdit: (photoId?: string) => Promise<PhotoRecord | null>;
  getSnapshot: () => Promise<LibrarySnapshot>;
}
