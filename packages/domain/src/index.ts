export type AIPipelineStatus = "disabled" | "pending" | "processing" | "completed" | "failed";

export interface Photo {
  id: string;
  path: string;
  hash: string | null;
  size: number;
  mime: string;
  thumbnailPath: string | null;
  favorite: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface Metadata {
  photoId: string;
  datetime: number | null;
  lat: number | null;
  lng: number | null;
  camera: string | null;
  confidence: number;
  originalDatetimeText: string | null;
}

export interface Semantic {
  photoId: string;
  labels: string[];
  caption: string | null;
  generatedLabels: string[];
  generatedCaption: string | null;
  summary: string | null;
  embeddingRef: string | null;
  aiStatus: AIPipelineStatus;
  aiProvider: string | null;
  aiModel: string | null;
  aiProcessedAt: number | null;
  aiError: string | null;
}

export interface SemanticQueueStats {
  disabled: number;
  pending: number;
  processing: number;
  completed: number;
  failed: number;
}

export interface IndexState {
  photoId: string;
  indexed: boolean;
  aiProcessed: boolean;
  error: string | null;
  lastIndexedAt: number | null;
  duplicateOf: string | null;
  sourceUpdatedAt: number | null;
  missingAt: number | null;
}

export interface LibrarySource {
  id: string;
  path: string;
  isActive: boolean;
  createdAt: number;
  updatedAt: number;
  lastScanAt: number | null;
}

export interface EditHistory {
  id: string;
  photoId: string;
  fieldName: "labels" | "datetime" | "caption";
  previousValue: string | null;
  nextValue: string | null;
  createdAt: number;
  rolledBackAt: number | null;
}

export type MemorySource = "manual" | "ai";

export type MemoryCandidateSource = "place" | "time" | "semantic" | "person" | "mixed";

export type MemoryCandidateStatus = "pending" | "accepted" | "rejected";

export interface Memory {
  id: string;
  name: string;
  description: string | null;
  coverPhotoId: string | null;
  coverThumbnailPath: string | null;
  photoCount: number;
  generatedName: string | null;
  generatedDescription: string | null;
  generatedLabels: string[];
  aiStatus: AIPipelineStatus;
  aiProvider: string | null;
  aiModel: string | null;
  aiProcessedAt: number | null;
  aiError: string | null;
  source: MemorySource;
  createdAt: number;
  updatedAt: number;
}

export interface MemoryPhoto {
  memoryId: string;
  photoId: string;
  addedAt: number;
}

export interface MemoryCandidate {
  id: string;
  signature: string;
  title: string;
  description: string | null;
  reason: string;
  confidence: number;
  source: MemoryCandidateSource;
  status: MemoryCandidateStatus;
  photoIds: string[];
  coverPhotoId: string | null;
  coverThumbnailPath: string | null;
  generatedLabels: string[];
  acceptedMemoryId: string | null;
  createdAt: number;
  updatedAt: number;
}

export interface MemoryCandidateInput {
  signature: string;
  title: string;
  description?: string | null;
  reason: string;
  confidence: number;
  source: MemoryCandidateSource;
  photoIds: string[];
  coverPhotoId?: string | null;
  generatedLabels?: string[];
}

export interface AcceptMemoryCandidateInput {
  name?: string;
  description?: string | null;
  photoIds?: string[];
}

export interface PhotoRecord {
  photo: Photo;
  metadata: Metadata;
  semantic: Semantic;
  indexState: IndexState;
}

export type BrowseMode = "waterfall" | "map" | "timeline";

export interface GeoBounds {
  north: number;
  south: number;
  east: number;
  west: number;
}

export interface PlaceGroup {
  id: string;
  centerLat: number;
  centerLng: number;
  photoCount: number;
  representativePhotoId: string | null;
  representativeThumbnailPath: string | null;
  fromDatetime: number | null;
  toDatetime: number | null;
}

export interface PlaceGroupQuery {
  bounds?: GeoBounds;
  filter?: PhotoFilter;
  limit?: number;
  precision?: number;
}

export type TimelineGranularity = "year" | "month" | "day";

export interface TimelineGroup {
  id: string;
  key: string;
  label: string;
  granularity: TimelineGranularity;
  photoIds: string[];
  photoCount: number;
  coverPhotoId: string | null;
  coverThumbnailPath: string | null;
  fromDatetime: number | null;
  toDatetime: number | null;
}

export interface TimelineGroupQuery {
  filter?: PhotoFilter;
  granularity?: TimelineGranularity;
  limitGroups?: number;
}

export interface DiscoveryQuery {
  text?: string;
  mimePrefix?: string;
  tag?: string;
  aiStatus?: AIPipelineStatus | AIPipelineStatus[];
  favorite?: boolean;
  memoryId?: string;
  indexed?: boolean;
  hasError?: boolean;
  hasGps?: boolean;
  fromDatetime?: number;
  toDatetime?: number;
  sortBy?: "datetime" | "updatedAt" | "path";
  sortDirection?: "asc" | "desc";
  limit?: number;
  offset?: number;
}

export interface PhotoFilter {
  query?: string;
  mimePrefix?: string;
  tag?: string;
  aiStatus?: AIPipelineStatus | AIPipelineStatus[];
  favorite?: boolean;
  memoryId?: string;
  indexed?: boolean;
  hasError?: boolean;
  hasGps?: boolean;
  fromDatetime?: number;
  toDatetime?: number;
  sortBy?: "datetime" | "updatedAt" | "path";
  sortDirection?: "asc" | "desc";
  limit?: number;
  offset?: number;
}

export type PhotoFilterPatch = {
  [Key in keyof PhotoFilter]?: PhotoFilter[Key] | undefined;
};

export type DiscoveryQueryPatch = {
  [Key in keyof DiscoveryQuery]?: DiscoveryQuery[Key] | undefined;
};

export interface IndexerStats {
  discovered: number;
  processed: number;
  imported: number;
  duplicates: number;
  errors: number;
  skipped: number;
  startedAt: number;
  finishedAt: number | null;
}

export interface LibrarySnapshot {
  sources: LibrarySource[];
  stats: {
    totalPhotos: number;
    indexedPhotos: number;
    erroredPhotos: number;
    duplicatePhotos: number;
  };
}

export interface AppCapabilities {
  aiEnabled: boolean;
  supportedMedia: string[];
}

export interface AISettings {
  apiKey: string;
  baseURL: string;
  model: string;
  providerName: string;
}

export type AISettingsField = keyof AISettings;

export type AIReadinessStatus = "configured" | "incomplete";

export interface AIReadiness {
  status: AIReadinessStatus;
  configured: boolean;
  missingFields: AISettingsField[];
  presentFields: AISettingsField[];
}

export interface MapSettings {
  apiKey: string;
  securityJsCode: string;
}

export type Locale = "en-US" | "zh-CN";
export type AIOutputLocale = Locale | "follow-ui";

export interface LocaleSettings {
  locale: Locale;
  aiOutputLocale: AIOutputLocale;
}

export interface ChronoPicBackupSettings {
  ai: AISettings;
  map: MapSettings;
  locale: LocaleSettings;
}

export interface ChronoPicBackup {
  app: "ChronoPic";
  schemaVersion: 1;
  exportedAt: number;
  settings: ChronoPicBackupSettings;
  librarySources: LibrarySource[];
  photos: UpsertPhotoPayload[];
  memories: Memory[];
  memoryPhotos: MemoryPhoto[];
  editHistory: EditHistory[];
  memoryCandidates: MemoryCandidate[];
}

export type BackupRestoreMode = "merge" | "replace";

export interface BackupRestoreOptions {
  mode?: BackupRestoreMode;
}

export interface BackupRestoreConflict {
  kind: "source" | "photo" | "memory" | "memoryCandidate";
  id: string;
  path?: string;
  reason: string;
}

export interface BackupRestorePreview {
  schemaVersion: 1;
  sourceCount: number;
  photoCount: number;
  memoryCount: number;
  memoryPhotoCount: number;
  editHistoryCount: number;
  memoryCandidateCount: number;
  settingsIncluded: boolean;
  conflictCount: number;
  conflicts: BackupRestoreConflict[];
}

export interface BackupRestoreResult extends BackupRestorePreview {
  restoredAt: number;
  restoredSourceCount: number;
  restoredPhotoCount: number;
  restoredMemoryCount: number;
  restoredMemoryPhotoCount: number;
  restoredEditHistoryCount: number;
  restoredMemoryCandidateCount: number;
}

export interface UpsertPhotoPayload {
  photo: Photo;
  metadata: Metadata;
  semantic: Semantic;
  indexState: IndexState;
}

export interface PhotoEditInput {
  photoId: string;
  labels?: string[];
  datetime?: number | null;
}

export function discoveryQueryToPhotoFilter(query: DiscoveryQuery = {}): PhotoFilter {
  const filter: PhotoFilter = {};

  if (query.text !== undefined) filter.query = query.text;
  if (query.mimePrefix !== undefined) filter.mimePrefix = query.mimePrefix;
  if (query.tag !== undefined) filter.tag = query.tag;
  if (query.aiStatus !== undefined) filter.aiStatus = query.aiStatus;
  if (query.favorite !== undefined) filter.favorite = query.favorite;
  if (query.memoryId !== undefined) filter.memoryId = query.memoryId;
  if (query.indexed !== undefined) filter.indexed = query.indexed;
  if (query.hasError !== undefined) filter.hasError = query.hasError;
  if (query.hasGps !== undefined) filter.hasGps = query.hasGps;
  if (query.fromDatetime !== undefined) filter.fromDatetime = query.fromDatetime;
  if (query.toDatetime !== undefined) filter.toDatetime = query.toDatetime;
  if (query.sortBy !== undefined) filter.sortBy = query.sortBy;
  if (query.sortDirection !== undefined) filter.sortDirection = query.sortDirection;
  if (query.limit !== undefined) filter.limit = query.limit;
  if (query.offset !== undefined) filter.offset = query.offset;

  return filter;
}

export function getAIReadiness(settings: AISettings): AIReadiness {
  const requiredFields: AISettingsField[] = ["apiKey", "baseURL", "model", "providerName"];
  const missingFields = requiredFields.filter((field) => !settings[field]?.trim());
  const presentFields = requiredFields.filter((field) => settings[field]?.trim());
  const configured = missingFields.length === 0;

  return {
    status: configured ? "configured" : "incomplete",
    configured,
    missingFields,
    presentFields,
  };
}

export function photoFilterToDiscoveryQuery(filter: PhotoFilter = {}): DiscoveryQuery {
  const query: DiscoveryQuery = {};

  if (filter.query !== undefined) query.text = filter.query;
  if (filter.mimePrefix !== undefined) query.mimePrefix = filter.mimePrefix;
  if (filter.tag !== undefined) query.tag = filter.tag;
  if (filter.aiStatus !== undefined) query.aiStatus = filter.aiStatus;
  if (filter.favorite !== undefined) query.favorite = filter.favorite;
  if (filter.memoryId !== undefined) query.memoryId = filter.memoryId;
  if (filter.indexed !== undefined) query.indexed = filter.indexed;
  if (filter.hasError !== undefined) query.hasError = filter.hasError;
  if (filter.hasGps !== undefined) query.hasGps = filter.hasGps;
  if (filter.fromDatetime !== undefined) query.fromDatetime = filter.fromDatetime;
  if (filter.toDatetime !== undefined) query.toDatetime = filter.toDatetime;
  if (filter.sortBy !== undefined) query.sortBy = filter.sortBy;
  if (filter.sortDirection !== undefined) query.sortDirection = filter.sortDirection;
  if (filter.limit !== undefined) query.limit = filter.limit;
  if (filter.offset !== undefined) query.offset = filter.offset;

  return query;
}

export const DEFAULT_FILTER: Required<Pick<PhotoFilter, "limit" | "offset" | "sortBy" | "sortDirection">> = {
  limit: 60,
  offset: 0,
  sortBy: "datetime",
  sortDirection: "desc"
};
