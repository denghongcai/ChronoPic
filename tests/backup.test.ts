import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { ChronoPicAppService } from "@chronopic/application";
import type { ChronoPicBackup, UpsertPhotoPayload } from "@chronopic/domain";
import { ChronoPicDatabase } from "@chronopic/infra-db";

function tempDbPath(name: string): string {
  return path.join(fs.mkdtempSync(path.join(os.tmpdir(), `chronopic-${name}-`)), "chronopic.sqlite");
}

function createPhotoPayload(photoPath: string): UpsertPhotoPayload {
  const now = 1_715_000_000_000;
  return {
    photo: {
      id: "photo-1",
      path: photoPath,
      hash: "hash-1",
      size: 123,
      mime: "image/png",
      thumbnailPath: "/tmp/chronopic-thumb.png",
      favorite: false,
      createdAt: now,
      updatedAt: now,
    },
    metadata: {
      photoId: "photo-1",
      datetime: now,
      lat: 31.2,
      lng: 121.5,
      camera: "FixtureCam",
      confidence: 0.9,
      originalDatetimeText: "2024:05:01 10:00:00",
    },
    semantic: {
      photoId: "photo-1",
      labels: [],
      caption: null,
      generatedLabels: ["river"],
      generatedCaption: "Generated fixture caption",
      summary: "Generated fixture summary",
      embeddingRef: null,
      aiStatus: "completed",
      aiProvider: "fixture-provider",
      aiModel: "fixture-model",
      aiProcessedAt: now,
      aiError: null,
    },
    indexState: {
      photoId: "photo-1",
      indexed: true,
      aiProcessed: true,
      error: null,
      lastIndexedAt: now,
      duplicateOf: null,
      sourceUpdatedAt: now,
      missingAt: null,
    },
  };
}

function createService(db: ChronoPicDatabase): ChronoPicAppService {
  return new ChronoPicAppService(
    db,
    {
      listSupportedMedia: () => ["image/png"],
      resumeIndexing: async () => [],
      scanLibrary: async () => ({
        discovered: 0,
        processed: 0,
        imported: 0,
        duplicates: 0,
        errors: 0,
        skipped: 0,
        startedAt: Date.now(),
        finishedAt: Date.now(),
      }),
    } as never,
    {
      isEnabled: () => false,
      analyzePhoto: async () => {
        throw new Error("AI disabled");
      },
      analyzeMemory: async () => {
        throw new Error("AI disabled");
      },
    } as never
  );
}

test("backup export and restore preserves settings, edits, favorites, memories, and memberships", () => {
  const photoPath = path.join(os.tmpdir(), "chronopic-backup-photo.png");
  const sourceDb = new ChronoPicDatabase(tempDbPath("backup-source"));
  const sourceService = createService(sourceDb);
  sourceDb.addLibrarySource(path.dirname(photoPath));
  sourceDb.upsertPhotoRecord(createPhotoPayload(photoPath));

  sourceService.updatePhotoCaption("photo-1", "Manual caption");
  sourceService.updatePhotoTags("photo-1", ["family", "trip"]);
  sourceService.updatePhotoFavorite("photo-1", true);
  const memory = sourceService.createMemory("Backup Memory", "Durable story", "manual");
  sourceService.addPhotoToMemory(memory.id, "photo-1");
  sourceService.updateMemory(memory.id, { coverPhotoId: "photo-1" });

  const backup = sourceService.createBackup({
    ai: {
      apiKey: "secret-key",
      baseURL: "https://models.example.test/v1",
      model: "fixture-model",
      providerName: "fixture",
    },
    map: {
      apiKey: "amap-key",
      securityJsCode: "amap-security",
    },
    locale: {
      locale: "zh-CN",
      aiOutputLocale: "zh-CN",
    },
  });

  assert.equal(backup.schemaVersion, 1);
  assert.equal(backup.photos.length, 1);
  assert.equal(backup.memories.length, 1);
  assert.equal(backup.memoryPhotos.length, 1);
  assert.equal(backup.editHistory.length, 2);
  assert.equal(backup.settings.locale.locale, "zh-CN");

  const targetDb = new ChronoPicDatabase(tempDbPath("backup-target"));
  const targetService = createService(targetDb);
  const preview = targetService.previewBackupRestore(backup);
  assert.equal(preview.conflictCount, 0);
  assert.equal(preview.photoCount, 1);
  assert.equal(preview.memoryCount, 1);

  const result = targetService.restoreBackup(backup, { mode: "replace" });
  assert.equal(result.restoredPhotoCount, 1);
  assert.equal(result.restoredMemoryCount, 1);

  const restoredPhoto = targetService.getPhoto("photo-1");
  assert.equal(restoredPhoto?.semantic.caption, "Manual caption");
  assert.deepEqual(restoredPhoto?.semantic.labels, ["family", "trip"]);
  assert.equal(restoredPhoto?.photo.favorite, true);
  assert.equal(restoredPhoto?.semantic.generatedCaption, "Generated fixture caption");

  const restoredMemory = targetService.getMemory(memory.id);
  assert.equal(restoredMemory?.name, "Backup Memory");
  assert.equal(restoredMemory?.coverPhotoId, "photo-1");
  assert.deepEqual(
    targetService.listPhotosByMemory(memory.id).map((record) => record.photo.id),
    ["photo-1"]
  );
  assert.equal(targetDb.listEditHistory("photo-1").length, 2);

  sourceDb.close();
  targetDb.close();
});

test("rollbackLatestEdit uses insertion order for rapid edits with matching timestamps", () => {
  const photoPath = path.join(os.tmpdir(), "chronopic-rollback-photo.png");
  const db = new ChronoPicDatabase(tempDbPath("rollback-order"));
  const service = createService(db);
  const originalNow = Date.now;

  try {
    Date.now = () => 1_800_000_000_000;
    db.addLibrarySource(path.dirname(photoPath));
    db.upsertPhotoRecord(createPhotoPayload(photoPath));

    service.updatePhotoCaption("photo-1", "Rapid caption");
    service.updatePhotoTags("photo-1", ["runtime", "qa"]);
    service.updatePhotoDatetime("photo-1", 1_714_521_600_000);

    const afterDatetimeRollback = service.rollbackLatestEdit("photo-1");
    assert.equal(afterDatetimeRollback?.metadata.datetime, 1_715_000_000_000);
    assert.equal(afterDatetimeRollback?.semantic.caption, "Rapid caption");
    assert.deepEqual(afterDatetimeRollback?.semantic.labels, ["runtime", "qa"]);

    const afterLabelsRollback = service.rollbackLatestEdit("photo-1");
    assert.equal(afterLabelsRollback?.semantic.caption, "Rapid caption");
    assert.deepEqual(afterLabelsRollback?.semantic.labels, []);

    const afterCaptionRollback = service.rollbackLatestEdit("photo-1");
    assert.equal(afterCaptionRollback?.semantic.caption, null);
  } finally {
    Date.now = originalNow;
    db.close();
  }
});

test("backup restore preview reports conflicts against existing library state", () => {
  const photoPath = path.join(os.tmpdir(), "chronopic-backup-conflict.png");
  const backup: ChronoPicBackup = {
    app: "ChronoPic",
    schemaVersion: 1,
    exportedAt: 1_715_000_000_000,
    settings: {
      ai: { apiKey: "", baseURL: "", model: "", providerName: "openai-compatible" },
      map: { apiKey: "", securityJsCode: "" },
      locale: { locale: "en-US", aiOutputLocale: "follow-ui" },
    },
    librarySources: [],
    photos: [createPhotoPayload(photoPath)],
    memories: [],
    memoryPhotos: [],
    editHistory: [],
    memoryCandidates: [],
  };

  const db = new ChronoPicDatabase(tempDbPath("backup-conflict"));
  const service = createService(db);
  db.upsertPhotoRecord(createPhotoPayload(photoPath));

  const preview = service.previewBackupRestore(backup);
  assert.equal(preview.conflictCount, 1);
  assert.deepEqual(preview.conflicts.map((conflict) => conflict.kind), ["photo"]);
  assert.equal(preview.conflicts[0]?.path, photoPath);

  db.close();
});
