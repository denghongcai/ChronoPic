import type { IndexerStats, LibrarySnapshot, PhotoFilter, PhotoRecord } from "@chronopic/domain";
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
}
