import type {
  DiscoveryQuery,
  IndexerStats,
  LibrarySnapshot,
  Memory,
  AcceptMemoryCandidateInput,
  MemoryCandidate,
  MemoryCandidateInput,
  MemorySource,
  PhotoFilter,
  PhotoRecord,
  PlaceGroup,
  PlaceGroupQuery,
  SemanticQueueStats,
  TimelineGranularity,
  TimelineGroup,
  TimelineGroupQuery,
} from "@chronopic/domain";
import type { ChronoPicDatabase } from "@chronopic/infra-db";
import type { AIClient, MemoryAIContext, PhotoAIContext } from "@chronopic/services-ai-pipeline";
import type { IndexerService } from "@chronopic/services-indexer";

export class ChronoPicAppService {
  constructor(
    private readonly db: ChronoPicDatabase,
    private readonly indexer: IndexerService,
    private readonly aiClient: AIClient
  ) {}

  initialize(): LibrarySnapshot {
    return this.db.getSnapshot();
  }

  addLibrarySource(libraryPath: string) {
    return this.db.addLibrarySource(libraryPath);
  }

  listLibrarySources() {
    return this.db.listLibrarySources();
  }

  async scanLibrary(sourceId?: string): Promise<IndexerStats | IndexerStats[]> {
    if (!sourceId) {
      return this.indexer.resumeIndexing();
    }

    const source = this.db.getLibrarySource(sourceId);

    if (!source) {
      throw new Error(`Library source not found: ${sourceId}`);
    }

    return this.indexer.scanLibrary(source);
  }

  listPhotos(filter?: PhotoFilter): PhotoRecord[] {
    return this.db.listPhotos(filter);
  }

  listPhotosForDiscovery(query: DiscoveryQuery = {}): PhotoRecord[] {
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

    return this.db.listPhotos(filter);
  }

  getPhoto(photoId: string): PhotoRecord | null {
    return this.db.getPhoto(photoId);
  }

  updatePhotoTags(photoId: string, labels: string[]): PhotoRecord {
    return this.db.updatePhotoTags(photoId, labels);
  }

  updatePhotoCaption(photoId: string, caption: string | null): PhotoRecord {
    return this.db.updatePhotoCaption(photoId, caption);
  }

  async enrichPhotoSemantic(photoId: string, context?: PhotoAIContext): Promise<PhotoRecord> {
    if (!this.aiClient.isEnabled()) {
      throw new Error("AI enrichment is not configured");
    }

    const photo = this.db.getPhoto(photoId);
    if (!photo) {
      throw new Error(`Photo not found: ${photoId}`);
    }

    this.db.updatePhotoSemanticEnrichment(photoId, {
      aiStatus: "processing",
      aiError: null,
    });

    try {
      const analysis = await this.aiClient.analyzePhoto(photo, context);
      return this.db.updatePhotoSemanticEnrichment(photoId, {
        ...analysis,
        aiStatus: "completed",
        aiError: null,
      });
    } catch (error) {
      const message = error instanceof Error && error.message ? error.message : "Unknown AI enrichment error";
      return this.db.updatePhotoSemanticEnrichment(photoId, {
        aiStatus: "failed",
        aiError: message,
        aiProcessedAt: Date.now(),
      });
    }
  }

  getSemanticQueueStats(): SemanticQueueStats {
    return this.db.getSemanticQueueStats();
  }

  async enrichPendingSemantics(limit = 12, context?: PhotoAIContext): Promise<{
    processed: number;
    completed: number;
    failed: number;
    skipped: number;
  }> {
    if (!this.aiClient.isEnabled()) {
      throw new Error("AI enrichment is not configured");
    }

    const queue = this.db.listPhotos({
      aiStatus: ["disabled", "pending", "failed"],
      limit,
      offset: 0,
      sortBy: "updatedAt",
      sortDirection: "asc",
    });

    const summary = {
      processed: queue.length,
      completed: 0,
      failed: 0,
      skipped: 0,
    };

    for (const photo of queue) {
      const updated = await this.enrichPhotoSemantic(photo.photo.id, context);
      if (updated.semantic.aiStatus === "completed") {
        summary.completed += 1;
      } else if (updated.semantic.aiStatus === "failed") {
        summary.failed += 1;
      } else {
        summary.skipped += 1;
      }
    }

    return summary;
  }

  updatePhotoDatetime(photoId: string, datetime: number | null): PhotoRecord {
    return this.db.updatePhotoDatetime(photoId, datetime);
  }

  rollbackLatestEdit(photoId?: string): PhotoRecord | null {
    return this.db.rollbackLatestEdit(photoId);
  }

  getSnapshot(): LibrarySnapshot {
    return this.db.getSnapshot();
  }

  getCapabilities() {
    return {
      aiEnabled: this.aiClient.isEnabled(),
      supportedMedia: this.indexer.listSupportedMedia()
    };
  }

  // ─── Favorite ────────────────────────────────────────────────────────────────

  updatePhotoFavorite(photoId: string, favorite: boolean): PhotoRecord {
    return this.db.updatePhotoFavorite(photoId, favorite);
  }

  // ─── Memory ─────────────────────────────────────────────────────────────────

  listMemories(): Memory[] {
    return this.db.listMemories();
  }

  getMemory(memoryId: string): Memory | null {
    return this.db.getMemory(memoryId);
  }

  createMemory(name: string, description?: string, source?: MemorySource): Memory {
    return this.db.createMemory(name, description ?? null, source ?? "manual");
  }

  updateMemory(memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }): Memory {
    return this.db.updateMemory(memoryId, updates);
  }

  async enrichMemorySemantic(memoryId: string, context?: MemoryAIContext): Promise<Memory> {
    if (!this.aiClient.isEnabled()) {
      throw new Error("AI enrichment is not configured");
    }

    const memory = this.db.getMemory(memoryId);
    if (!memory) {
      throw new Error(`Memory not found: ${memoryId}`);
    }

    const photos = this.db.listPhotosByMemory(memoryId, {
      limit: 24,
      offset: 0,
      sortBy: "datetime",
      sortDirection: "desc",
    });

    if (photos.length === 0) {
      return this.db.updateMemorySemanticEnrichment(memoryId, {
        aiStatus: "failed",
        aiError: "Memory has no photos to analyze",
        aiProcessedAt: Date.now(),
      });
    }

    this.db.updateMemorySemanticEnrichment(memoryId, {
      aiStatus: "processing",
      aiError: null,
    });

    try {
      const analysis = await this.aiClient.analyzeMemory(memory, photos, context);
      return this.db.updateMemorySemanticEnrichment(memoryId, {
        ...analysis,
        aiStatus: "completed",
        aiError: null,
      });
    } catch (error) {
      const message = error instanceof Error && error.message ? error.message : "Unknown AI enrichment error";
      return this.db.updateMemorySemanticEnrichment(memoryId, {
        aiStatus: "failed",
        aiError: message,
        aiProcessedAt: Date.now(),
      });
    }
  }

  deleteMemory(memoryId: string): void {
    this.db.deleteMemory(memoryId);
  }

  addPhotoToMemory(memoryId: string, photoId: string): void {
    this.db.addPhotoToMemory(memoryId, photoId);
  }

  removePhotoFromMemory(memoryId: string, photoId: string): void {
    this.db.removePhotoFromMemory(memoryId, photoId);
  }

  listPhotosByMemory(memoryId: string, filter?: PhotoFilter): PhotoRecord[] {
    return this.db.listPhotosByMemory(memoryId, filter);
  }

  listMemoriesByPhoto(photoId: string): Memory[] {
    return this.db.listMemoriesByPhoto(photoId);
  }

  listMemoryCandidates(): MemoryCandidate[] {
    return this.db.listMemoryCandidates("pending");
  }

  generateMemoryCandidates(limit = 12): MemoryCandidate[] {
    const photos = this.db.listPhotos({
      limit: 600,
      offset: 0,
      sortBy: "datetime",
      sortDirection: "desc",
    });
    const existingPhotoSets = this.db
      .listMemories()
      .map((memory) => this.db.listPhotosByMemory(memory.id, { limit: 500, offset: 0 }).map((record) => record.photo.id).sort().join("|"))
      .filter(Boolean);
    const existingSignatures = new Set(existingPhotoSets);
    const candidates = buildMemoryCandidateInputs(photos)
      .filter((candidate) => !existingSignatures.has([...candidate.photoIds].sort().join("|")))
      .slice(0, limit);
    const saved: MemoryCandidate[] = [];

    for (const candidate of candidates) {
      const result = this.db.upsertMemoryCandidate(candidate);
      if (result) {
        saved.push(result);
      }
    }

    return this.db.listMemoryCandidates("pending").slice(0, limit);
  }

  acceptMemoryCandidate(candidateId: string, input: AcceptMemoryCandidateInput = {}): Memory {
    return this.db.acceptMemoryCandidate(candidateId, input);
  }

  rejectMemoryCandidate(candidateId: string): MemoryCandidate {
    return this.db.rejectMemoryCandidate(candidateId);
  }

  countMappablePhotos(filter?: PhotoFilter): number {
    return this.db.countMappablePhotos(filter);
  }

  listPlaceGroups(query?: PlaceGroupQuery): PlaceGroup[] {
    return this.db.listPlaceGroups(query);
  }

  listTimelineGroups(query: TimelineGroupQuery = {}): TimelineGroup[] {
    const { filter, granularity = "month", limitGroups } = query;
    const photos = this.db
      .listPhotos(filter)
      .filter((record) => record.metadata.datetime != null)
      .sort((left, right) => (right.metadata.datetime ?? 0) - (left.metadata.datetime ?? 0));

    const groups = new Map<string, TimelineGroup>();

    for (const record of photos) {
      const datetime = record.metadata.datetime;
      if (datetime == null) {
        continue;
      }

      const date = new Date(datetime);
      const key = toTimelineKey(date, granularity);
      const label = toTimelineLabel(date, granularity);
      const existing = groups.get(key);

      if (existing) {
        existing.photoIds.push(record.photo.id);
        existing.photoCount += 1;
        existing.fromDatetime = Math.min(existing.fromDatetime ?? datetime, datetime);
        existing.toDatetime = Math.max(existing.toDatetime ?? datetime, datetime);
        continue;
      }

      groups.set(key, {
        id: key,
        key,
        label,
        granularity,
        photoIds: [record.photo.id],
        photoCount: 1,
        coverPhotoId: record.photo.id,
        coverThumbnailPath: record.photo.thumbnailPath,
        fromDatetime: datetime,
        toDatetime: datetime,
      });
    }

    const ordered = Array.from(groups.values()).sort((left, right) => (right.toDatetime ?? 0) - (left.toDatetime ?? 0));
    return typeof limitGroups === "number" ? ordered.slice(0, limitGroups) : ordered;
  }
}

function buildMemoryCandidateInputs(photos: PhotoRecord[]): MemoryCandidateInput[] {
  const byPlace = new Map<string, PhotoRecord[]>();
  const byMonth = new Map<string, PhotoRecord[]>();
  const byLabel = new Map<string, PhotoRecord[]>();

  for (const record of photos) {
    if (record.metadata.lat != null && record.metadata.lng != null) {
      const key = `${record.metadata.lat.toFixed(1)},${record.metadata.lng.toFixed(1)}`;
      byPlace.set(key, [...(byPlace.get(key) ?? []), record]);
    }

    const datetime = record.metadata.datetime;
    if (datetime != null) {
      const date = new Date(datetime);
      const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
      byMonth.set(key, [...(byMonth.get(key) ?? []), record]);
    }

    const labels = new Set([...record.semantic.labels, ...record.semantic.generatedLabels]);
    for (const label of labels) {
      const normalized = label.trim().toLowerCase();
      if (normalized.length < 3) {
        continue;
      }
      byLabel.set(normalized, [...(byLabel.get(normalized) ?? []), record]);
    }
  }

  const candidates: MemoryCandidateInput[] = [];

  for (const [key, group] of byPlace) {
    const records = uniqueRecords(group);
    if (records.length < 3) {
      continue;
    }
    const [lat, lng] = key.split(",");
    candidates.push(makeCandidate({
      records,
      source: "place",
      title: `Around ${lat}, ${lng}`,
      reason: `These photos cluster around the same GPS area (${lat}, ${lng}).`,
      confidence: Math.min(0.92, 0.68 + records.length * 0.03),
      labels: ["place", "mapped"],
      signaturePrefix: `place:${key}`,
    }));
  }

  for (const [key, group] of byMonth) {
    const records = uniqueRecords(group);
    if (records.length < 4) {
      continue;
    }
    const [year, month] = key.split("-");
    const date = new Date(Number(year), Number(month) - 1, 1);
    const label = new Intl.DateTimeFormat("en", { month: "long", year: "numeric" }).format(date);
    candidates.push(makeCandidate({
      records,
      source: "time",
      title: label,
      reason: `These photos were captured in the same month and can form a timeline memory.`,
      confidence: Math.min(0.86, 0.58 + records.length * 0.025),
      labels: ["timeline", key],
      signaturePrefix: `time:${key}`,
    }));
  }

  for (const [label, group] of byLabel) {
    const records = uniqueRecords(group);
    if (records.length < 3) {
      continue;
    }
    candidates.push(makeCandidate({
      records,
      source: "semantic",
      title: titleCase(label),
      reason: `These photos share the "${label}" semantic label from manual or AI metadata.`,
      confidence: Math.min(0.9, 0.62 + records.length * 0.03),
      labels: [label, "semantic"],
      signaturePrefix: `semantic:${label}`,
    }));
  }

  return candidates.sort((left, right) => right.confidence - left.confidence || right.photoIds.length - left.photoIds.length);
}

function uniqueRecords(records: PhotoRecord[]): PhotoRecord[] {
  const seen = new Set<string>();
  const unique: PhotoRecord[] = [];
  for (const record of records) {
    if (seen.has(record.photo.id)) {
      continue;
    }
    seen.add(record.photo.id);
    unique.push(record);
  }
  return unique;
}

function makeCandidate({
  records,
  source,
  title,
  reason,
  confidence,
  labels,
  signaturePrefix,
}: {
  records: PhotoRecord[];
  source: MemoryCandidateInput["source"];
  title: string;
  reason: string;
  confidence: number;
  labels: string[];
  signaturePrefix: string;
}): MemoryCandidateInput {
  const sorted = [...records].sort((left, right) => {
    const leftTime = left.metadata.datetime ?? left.photo.updatedAt;
    const rightTime = right.metadata.datetime ?? right.photo.updatedAt;
    return leftTime - rightTime;
  });
  const photoIds = sorted.map((record) => record.photo.id);
  const cover = sorted.find((record) => record.photo.thumbnailPath != null) ?? sorted[0];

  return {
    signature: `${signaturePrefix}:${photoIds.slice().sort().join("|")}`,
    title,
    description: null,
    reason,
    confidence,
    source,
    photoIds,
    coverPhotoId: cover?.photo.id ?? photoIds[0] ?? null,
    generatedLabels: labels,
  };
}

function titleCase(value: string): string {
  return value
    .split(/[\s_-]+/)
    .filter(Boolean)
    .map((part) => `${part[0]?.toUpperCase() ?? ""}${part.slice(1)}`)
    .join(" ");
}

function toTimelineKey(date: Date, granularity: TimelineGranularity): string {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");

  if (granularity === "year") {
    return `${year}`;
  }

  if (granularity === "month") {
    return `${year}-${month}`;
  }

  return `${year}-${month}-${day}`;
}

function toTimelineLabel(date: Date, granularity: TimelineGranularity): string {
  if (granularity === "year") {
    return new Intl.DateTimeFormat("zh-CN", { year: "numeric" }).format(date);
  }

  if (granularity === "month") {
    return new Intl.DateTimeFormat("zh-CN", { year: "numeric", month: "long" }).format(date);
  }

  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "long",
    day: "numeric",
    weekday: "short",
  }).format(date);
}
