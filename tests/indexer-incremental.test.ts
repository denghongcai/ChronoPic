import assert from "node:assert/strict";
import test from "node:test";

import { IndexerService } from "../packages/services-indexer/dist/index.js";
import type { LibrarySource, PhotoRecord } from "@chronopic/domain";

function makeExistingRecord(path: string, sourceUpdatedAt: number, size = 128): PhotoRecord {
  const now = Date.now();

  return {
    photo: {
      id: `photo-${path}`,
      path,
      hash: `hash-${path}`,
      size,
      mime: "image/jpeg",
      thumbnailPath: `${path}.thumb.jpg`,
      favorite: false,
      createdAt: now,
      updatedAt: now,
    },
    metadata: {
      photoId: `photo-${path}`,
      datetime: now,
      lat: null,
      lng: null,
      camera: null,
      confidence: 1,
      originalDatetimeText: null,
    },
    semantic: {
      photoId: `photo-${path}`,
      labels: [],
      caption: null,
      generatedLabels: [],
      generatedCaption: null,
      summary: null,
      embeddingRef: null,
      aiStatus: "disabled",
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    },
    indexState: {
      photoId: `photo-${path}`,
      indexed: true,
      aiProcessed: false,
      error: null,
      lastIndexedAt: now,
      duplicateOf: null,
      sourceUpdatedAt,
      missingAt: null,
    },
  };
}

test("IndexerService scanLibrary skips unchanged files, reprocesses modified files, and marks missing files", async () => {
  const source: LibrarySource = {
    id: "lib-1",
    path: "/library",
    isActive: true,
    createdAt: 1,
    updatedAt: 1,
    lastScanAt: null,
  };

  const unchangedPath = "/library/unchanged.jpg";
  const modifiedPath = "/library/modified.jpg";
  const newPath = "/library/new.jpg";
  const missingPath = "/library/missing.jpg";

  const existingByPath = new Map<string, PhotoRecord>([
    [unchangedPath, makeExistingRecord(unchangedPath, 1000, 128)],
    [modifiedPath, makeExistingRecord(modifiedPath, 1000, 128)],
    [missingPath, makeExistingRecord(missingPath, 1000, 128)],
  ]);

  const upsertedPaths: string[] = [];
  const missingMarked: string[][] = [];

  const fakeDb = {
    listTrackedPhotosInSource() {
      return Array.from(existingByPath.values()).map((record) => ({
        path: record.photo.path,
        size: record.photo.size,
        sourceUpdatedAt: record.indexState.sourceUpdatedAt,
        missingAt: record.indexState.missingAt,
      }));
    },
    markPhotosMissing(paths: string[]) {
      missingMarked.push(paths);
      return paths.length;
    },
    findPhotoByPath(path: string) {
      return existingByPath.get(path) ?? null;
    },
    findPrimaryPhotoIdByHash() {
      return null;
    },
    upsertPhotoRecord(record: PhotoRecord) {
      upsertedPaths.push(record.photo.path);
      existingByPath.set(record.photo.path, record);
    },
    getPhoto(photoId: string) {
      return Array.from(existingByPath.values()).find((record) => record.photo.id === photoId) ?? null;
    },
    touchLibraryScan() {},
  };

  const fakeMediaFiles = {
    async scanDirectory() {
      return [unchangedPath, modifiedPath, newPath];
    },
    async describeFile(filePath: string) {
      if (filePath === unchangedPath) {
        return { path: filePath, size: 128, mime: "image/jpeg", createdAt: 1000, updatedAt: 1000 };
      }
      if (filePath === modifiedPath) {
        return { path: filePath, size: 256, mime: "image/jpeg", createdAt: 1000, updatedAt: 2000 };
      }
      return { path: filePath, size: 64, mime: "image/jpeg", createdAt: 3000, updatedAt: 3000 };
    },
    async computeHash(filePath: string) {
      return `hash:${filePath}`;
    },
    async extractMetadata(_filePath: string, fallbackTimestamp: number) {
      return {
        datetime: fallbackTimestamp,
        lat: null,
        lng: null,
        camera: null,
        confidence: 1,
        originalDatetimeText: null,
      };
    },
    listSupportedMedia() {
      return ["image/jpeg"];
    },
  };

  const fakeThumbnails = {
    async generateThumbnail(filePath: string) {
      return `${filePath}.thumb.jpg`;
    },
  };

  const service = new IndexerService(fakeDb as never, fakeMediaFiles as never, fakeThumbnails as never, false, 2);
  const stats = await service.scanLibrary(source);

  assert.deepEqual(missingMarked, [[missingPath]]);
  assert.equal(stats.discovered, 3);
  assert.equal(stats.processed, 3);
  assert.equal(stats.imported, 2);
  assert.equal(stats.skipped, 1);
  assert.deepEqual(upsertedPaths.sort(), [modifiedPath, newPath].sort());
});

