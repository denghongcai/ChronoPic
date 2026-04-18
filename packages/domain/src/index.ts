export type AIPipelineStatus = "disabled" | "pending" | "processing" | "complete" | "error";

export interface Photo {
  id: string;
  path: string;
  hash: string | null;
  size: number;
  mime: string;
  thumbnailPath: string | null;
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
  embeddingRef: string | null;
  aiStatus: AIPipelineStatus;
}

export interface IndexState {
  photoId: string;
  indexed: boolean;
  aiProcessed: boolean;
  error: string | null;
  lastIndexedAt: number | null;
  duplicateOf: string | null;
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
  fieldName: "labels" | "datetime";
  previousValue: string | null;
  nextValue: string | null;
  createdAt: number;
  rolledBackAt: number | null;
}

export interface PhotoRecord {
  photo: Photo;
  metadata: Metadata;
  semantic: Semantic;
  indexState: IndexState;
}

export interface PhotoFilter {
  query?: string;
  mimePrefix?: string;
  tag?: string;
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

export const DEFAULT_FILTER: Required<Pick<PhotoFilter, "limit" | "offset" | "sortBy" | "sortDirection">> = {
  limit: 60,
  offset: 0,
  sortBy: "datetime",
  sortDirection: "desc"
};
