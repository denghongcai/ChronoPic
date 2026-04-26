import type {
  AISettings,
  AppCapabilities,
  DiscoveryQuery,
  LibrarySnapshot,
  Memory,
  AcceptMemoryCandidateInput,
  MemoryCandidate,
  MemorySource,
  MapSettings,
  PhotoFilter,
  PhotoRecord,
  PlaceGroup,
  PlaceGroupQuery,
  SemanticQueueStats,
  TimelineGroup,
  TimelineGroupQuery,
} from "@chronopic/domain";

export interface MemoryAIContext {
  name?: string | null;
  description?: string | null;
}

export interface ChronoPicBridge {
  initialize: () => Promise<{ snapshot: LibrarySnapshot; capabilities: AppCapabilities }>;
  debugLog: (message: string) => Promise<void>;
  getAISettings: () => Promise<AISettings>;
  saveAISettings: (settings: AISettings) => Promise<{ settings: AISettings; capabilities: AppCapabilities }>;
  getMapSettings: () => Promise<MapSettings>;
  saveMapSettings: (settings: MapSettings) => Promise<MapSettings>;
  pickLibraryDirectory: () => Promise<string | null>;
  addLibrarySource: (libraryPath: string) => Promise<unknown>;
  listLibrarySources: () => Promise<unknown>;
  scanLibrary: (sourceId?: string) => Promise<unknown>;
  listPhotosForDiscovery: (query?: DiscoveryQuery) => Promise<PhotoRecord[]>;
  listPhotos: (filter?: PhotoFilter) => Promise<PhotoRecord[]>;
  getSemanticQueueStats: () => Promise<SemanticQueueStats>;
  countMappablePhotos: (filter?: PhotoFilter) => Promise<number>;
  listPlaceGroups: (query?: PlaceGroupQuery) => Promise<PlaceGroup[]>;
  listTimelineGroups: (query?: TimelineGroupQuery) => Promise<TimelineGroup[]>;
  getPhoto: (photoId: string) => Promise<PhotoRecord | null>;
  updatePhotoTags: (photoId: string, labels: string[]) => Promise<PhotoRecord>;
  updatePhotoCaption: (photoId: string, caption: string | null) => Promise<PhotoRecord>;
  enrichPhotoSemantic: (photoId: string) => Promise<PhotoRecord>;
  enrichPendingSemantics: (limit?: number) => Promise<{ processed: number; completed: number; failed: number; skipped: number }>;
  updatePhotoDatetime: (photoId: string, datetime: number | null) => Promise<PhotoRecord>;
  updatePhotoFavorite: (photoId: string, favorite: boolean) => Promise<PhotoRecord>;
  rollbackLatestEdit: (photoId?: string) => Promise<PhotoRecord | null>;
  getSnapshot: () => Promise<LibrarySnapshot>;
  listMemories: () => Promise<Memory[]>;
  getMemory: (memoryId: string) => Promise<Memory | null>;
  enrichMemorySemantic: (memoryId: string, context?: MemoryAIContext) => Promise<Memory>;
  createMemory: (name: string, description?: string, source?: MemorySource) => Promise<Memory>;
  updateMemory: (memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }) => Promise<Memory>;
  deleteMemory: (memoryId: string) => Promise<void>;
  addPhotoToMemory: (memoryId: string, photoId: string) => Promise<void>;
  removePhotoFromMemory: (memoryId: string, photoId: string) => Promise<void>;
  listMemoriesByPhoto: (photoId: string) => Promise<Memory[]>;
  listPhotosByMemory: (memoryId: string, filter?: PhotoFilter) => Promise<PhotoRecord[]>;
  listMemoryCandidates: () => Promise<MemoryCandidate[]>;
  generateMemoryCandidates: (limit?: number) => Promise<MemoryCandidate[]>;
  acceptMemoryCandidate: (candidateId: string, input?: AcceptMemoryCandidateInput) => Promise<Memory>;
  rejectMemoryCandidate: (candidateId: string) => Promise<MemoryCandidate>;
}
