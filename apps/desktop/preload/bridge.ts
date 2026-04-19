import type {
  AppCapabilities,
  LibrarySnapshot,
  Memory,
  MemorySource,
  PhotoFilter,
  PhotoRecord,
  PlaceGroup,
  PlaceGroupQuery,
  TimelineGroup,
  TimelineGroupQuery,
} from "@chronopic/domain";

export interface ChronoPicBridge {
  initialize: () => Promise<{ snapshot: LibrarySnapshot; capabilities: AppCapabilities }>;
  pickLibraryDirectory: () => Promise<string | null>;
  addLibrarySource: (libraryPath: string) => Promise<unknown>;
  listLibrarySources: () => Promise<unknown>;
  scanLibrary: (sourceId?: string) => Promise<unknown>;
  listPhotos: (filter?: PhotoFilter) => Promise<PhotoRecord[]>;
  countMappablePhotos: (filter?: PhotoFilter) => Promise<number>;
  listPlaceGroups: (query?: PlaceGroupQuery) => Promise<PlaceGroup[]>;
  listTimelineGroups: (query?: TimelineGroupQuery) => Promise<TimelineGroup[]>;
  getPhoto: (photoId: string) => Promise<PhotoRecord | null>;
  updatePhotoTags: (photoId: string, labels: string[]) => Promise<PhotoRecord>;
  updatePhotoCaption: (photoId: string, caption: string | null) => Promise<PhotoRecord>;
  updatePhotoDatetime: (photoId: string, datetime: number | null) => Promise<PhotoRecord>;
  updatePhotoFavorite: (photoId: string, favorite: boolean) => Promise<PhotoRecord>;
  rollbackLatestEdit: (photoId?: string) => Promise<PhotoRecord | null>;
  getSnapshot: () => Promise<LibrarySnapshot>;
  listMemories: () => Promise<Memory[]>;
  getMemory: (memoryId: string) => Promise<Memory | null>;
  createMemory: (name: string, description?: string, source?: MemorySource) => Promise<Memory>;
  updateMemory: (memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }) => Promise<Memory>;
  deleteMemory: (memoryId: string) => Promise<void>;
  addPhotoToMemory: (memoryId: string, photoId: string) => Promise<void>;
  removePhotoFromMemory: (memoryId: string, photoId: string) => Promise<void>;
  listMemoriesByPhoto: (photoId: string) => Promise<Memory[]>;
  listPhotosByMemory: (memoryId: string, filter?: PhotoFilter) => Promise<PhotoRecord[]>;
}
