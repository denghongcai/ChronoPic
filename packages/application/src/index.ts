import type { IndexerStats, LibrarySnapshot, Memory, MemorySource, PhotoFilter, PhotoRecord } from "@chronopic/domain";
import type { ChronoPicDatabase } from "@chronopic/infra-db";
import type { AIClient } from "@chronopic/services-ai-pipeline";
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

  getPhoto(photoId: string): PhotoRecord | null {
    return this.db.getPhoto(photoId);
  }

  updatePhotoTags(photoId: string, labels: string[]): PhotoRecord {
    return this.db.updatePhotoTags(photoId, labels);
  }

  updatePhotoCaption(photoId: string, caption: string | null): PhotoRecord {
    return this.db.updatePhotoCaption(photoId, caption);
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
}
