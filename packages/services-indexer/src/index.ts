import type { IndexerStats, LibrarySource, PhotoRecord } from "@chronopic/domain";
import { createId, ensureErrorMessage, runWithConcurrency } from "@chronopic/shared-utils";
import type { ChronoPicDatabase } from "@chronopic/infra-db";
import type { MediaFileService } from "@chronopic/infra-fs";
import type { ThumbnailService } from "@chronopic/infra-image";

export class IndexerService {
  constructor(
    private readonly db: ChronoPicDatabase,
    private readonly mediaFiles: MediaFileService,
    private readonly thumbnails: ThumbnailService,
    private readonly aiEnabled = false,
    private readonly concurrency = 4
  ) {}

  listSupportedMedia(): string[] {
    return this.mediaFiles.listSupportedMedia();
  }

  async scanLibrary(source: LibrarySource): Promise<IndexerStats> {
    const startedAt = Date.now();
    const files = await this.mediaFiles.scanDirectory(source.path);
    const stats: IndexerStats = {
      discovered: files.length,
      processed: 0,
      imported: 0,
      duplicates: 0,
      errors: 0,
      skipped: 0,
      startedAt,
      finishedAt: null
    };

    await runWithConcurrency(files, this.concurrency, async (filePath) => {
      try {
        const record = await this.indexFile(filePath);
        stats.processed += 1;
        stats.imported += 1;

        if (record.indexState.duplicateOf) {
          stats.duplicates += 1;
        }
      } catch {
        stats.processed += 1;
        stats.errors += 1;
      }
    });

    stats.finishedAt = Date.now();
    this.db.touchLibraryScan(source.id);
    return stats;
  }

  async resumeIndexing(): Promise<IndexerStats[]> {
    const sources = this.db.listLibrarySources().filter((source) => source.isActive);
    const results: IndexerStats[] = [];

    for (const source of sources) {
      results.push(await this.scanLibrary(source));
    }

    return results;
  }

  private async indexFile(filePath: string): Promise<PhotoRecord> {
    const existing = this.db.findPhotoByPath(filePath);
    const descriptor = await this.mediaFiles.describeFile(filePath);
    const hash = await this.mediaFiles.computeHash(filePath);
    const metadata = await this.mediaFiles.extractMetadata(filePath, descriptor.updatedAt);
    const duplicateOf = this.db.findPrimaryPhotoIdByHash(hash, existing?.photo.id);
    const photoId = existing?.photo.id ?? createId("photo");
    const thumbnailPath = await this.thumbnails.generateThumbnail(filePath, descriptor.mime, hash || filePath);
    const timestamp = Date.now();

    const record: PhotoRecord = {
      photo: {
        id: photoId,
        path: descriptor.path,
        hash,
        size: descriptor.size,
        mime: descriptor.mime,
        thumbnailPath,
        favorite: existing?.photo.favorite ?? false,
        createdAt: existing?.photo.createdAt ?? descriptor.createdAt,
        updatedAt: timestamp
      },
      metadata: {
        photoId,
        datetime: metadata.datetime,
        lat: metadata.lat,
        lng: metadata.lng,
        camera: metadata.camera,
        confidence: metadata.confidence,
        originalDatetimeText: metadata.originalDatetimeText
      },
      semantic: existing?.semantic ?? {
        photoId,
        labels: [],
        caption: null,
        generatedLabels: [],
        generatedCaption: null,
        summary: null,
        embeddingRef: null,
        aiStatus: this.aiEnabled ? "pending" : "disabled",
        aiProvider: null,
        aiModel: null,
        aiProcessedAt: null,
        aiError: null
      },
      indexState: {
        photoId,
        indexed: true,
        aiProcessed: false,
        error: null,
        lastIndexedAt: timestamp,
        duplicateOf
      }
    };

    this.db.upsertPhotoRecord(record);
    return this.db.getPhoto(photoId) as PhotoRecord;
  }

  async recordIndexingError(filePath: string, error: unknown): Promise<void> {
    const existing = this.db.findPhotoByPath(filePath);

    if (!existing) {
      return;
    }

    this.db.upsertPhotoRecord({
      ...existing,
      photo: {
        ...existing.photo,
        updatedAt: Date.now()
      },
      indexState: {
        ...existing.indexState,
        error: ensureErrorMessage(error),
        lastIndexedAt: Date.now()
      }
    });
  }
}
