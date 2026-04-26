import assert from "node:assert/strict";
import test from "node:test";

import { ChronoPicAppService } from "@chronopic/application";
import type { Memory, PhotoRecord } from "@chronopic/domain";

function makePhotoRecord(): PhotoRecord {
  const now = Date.now();

  return {
    photo: {
      id: "photo-1",
      path: "/tmp/forest.jpg",
      hash: "hash-1",
      size: 123,
      mime: "image/jpeg",
      thumbnailPath: "/tmp/forest-thumb.jpg",
      favorite: false,
      createdAt: now,
      updatedAt: now,
    },
    metadata: {
      photoId: "photo-1",
      datetime: now,
      lat: 31.2,
      lng: 121.5,
      camera: "test-cam",
      confidence: 1,
      originalDatetimeText: null,
    },
    semantic: {
      photoId: "photo-1",
      labels: ["manual-tag"],
      caption: "Manual caption",
      generatedLabels: [],
      generatedCaption: null,
      summary: null,
      embeddingRef: null,
      aiStatus: "pending",
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    },
    indexState: {
      photoId: "photo-1",
      indexed: true,
      aiProcessed: false,
      error: null,
      lastIndexedAt: now,
      duplicateOf: null,
      sourceUpdatedAt: now,
      missingAt: null,
    },
  };
}

const stubIndexer = {
  listSupportedMedia: () => ["image/jpeg"],
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
};

function makeMemory(): Memory {
  const now = Date.now();

  return {
    id: "memory-1",
    name: "Weekend Trip",
    description: "Manual notes",
    coverPhotoId: null,
    coverThumbnailPath: null,
    photoCount: 2,
    generatedName: null,
    generatedDescription: null,
    generatedLabels: [],
    aiStatus: "pending",
    aiProvider: null,
    aiModel: null,
    aiProcessedAt: null,
    aiError: null,
    source: "manual",
    createdAt: now,
    updatedAt: now,
  };
}

test("ChronoPicAppService enrichPhotoSemantic keeps manual fields while storing generated AI fields", async () => {
  const original = makePhotoRecord();
  let stored = structuredClone(original);

  const fakeDb = {
    getPhoto(photoId: string) {
      return photoId === stored.photo.id ? structuredClone(stored) : null;
    },
    updatePhotoSemanticEnrichment(photoId: string, updates: Partial<PhotoRecord["semantic"]>) {
      assert.equal(photoId, stored.photo.id);

      stored = {
        ...stored,
        semantic: {
          ...stored.semantic,
          ...updates,
          generatedLabels: updates.generatedLabels ?? stored.semantic.generatedLabels,
          generatedCaption: updates.generatedCaption ?? stored.semantic.generatedCaption,
          summary: updates.summary ?? stored.semantic.summary,
          aiStatus: updates.aiStatus ?? stored.semantic.aiStatus,
          aiProvider: updates.aiProvider ?? stored.semantic.aiProvider,
          aiModel: updates.aiModel ?? stored.semantic.aiModel,
          aiProcessedAt: updates.aiProcessedAt ?? stored.semantic.aiProcessedAt,
          aiError: updates.aiError ?? stored.semantic.aiError,
        },
        indexState: {
          ...stored.indexState,
          aiProcessed: (updates.aiStatus ?? stored.semantic.aiStatus) === "completed",
        },
      };

      return structuredClone(stored);
    },
  };

  const service = new ChronoPicAppService(
    fakeDb as never,
    stubIndexer as never,
    {
      isEnabled: () => true,
      analyzePhoto: async () => ({
        generatedLabels: ["forest", "mist", "trees"],
        generatedCaption: "Misty forest path",
        summary: "A soft, misty forest scene with layered pine trees.",
        embeddingRef: null,
        aiProvider: "openai-compatible",
        aiModel: "qwen2.5-vl",
        aiProcessedAt: 123456789,
        aiError: null,
      }),
    }
  );

  const enriched = await service.enrichPhotoSemantic("photo-1");

  assert.deepEqual(enriched.semantic.labels, ["manual-tag"]);
  assert.equal(enriched.semantic.caption, "Manual caption");
  assert.deepEqual(enriched.semantic.generatedLabels, ["forest", "mist", "trees"]);
  assert.equal(enriched.semantic.generatedCaption, "Misty forest path");
  assert.equal(enriched.semantic.summary, "A soft, misty forest scene with layered pine trees.");
  assert.equal(enriched.semantic.aiStatus, "completed");
  assert.equal(enriched.indexState.aiProcessed, true);
});

test("ChronoPicAppService stores failed AI status without clearing existing generated outputs", async () => {
  const original = makePhotoRecord();
  let stored: PhotoRecord = {
    ...original,
    semantic: {
      ...original.semantic,
      generatedLabels: ["existing-generated"],
      generatedCaption: "Existing generated caption",
      summary: "Existing summary",
      aiStatus: "completed",
      aiProvider: "openai-compatible",
      aiModel: "older-model",
      aiProcessedAt: 111,
    },
    indexState: {
      ...original.indexState,
      aiProcessed: true,
    },
  };

  const fakeDb = {
    getPhoto(photoId: string) {
      return photoId === stored.photo.id ? structuredClone(stored) : null;
    },
    updatePhotoSemanticEnrichment(photoId: string, updates: Partial<PhotoRecord["semantic"]>) {
      assert.equal(photoId, stored.photo.id);

      stored = {
        ...stored,
        semantic: {
          ...stored.semantic,
          ...updates,
          generatedLabels: updates.generatedLabels ?? stored.semantic.generatedLabels,
          generatedCaption: updates.generatedCaption ?? stored.semantic.generatedCaption,
          summary: updates.summary ?? stored.semantic.summary,
          aiStatus: updates.aiStatus ?? stored.semantic.aiStatus,
          aiProvider: updates.aiProvider ?? stored.semantic.aiProvider,
          aiModel: updates.aiModel ?? stored.semantic.aiModel,
          aiProcessedAt: updates.aiProcessedAt ?? stored.semantic.aiProcessedAt,
          aiError: updates.aiError ?? stored.semantic.aiError,
        },
        indexState: {
          ...stored.indexState,
          aiProcessed: (updates.aiStatus ?? stored.semantic.aiStatus) === "completed",
        },
      };

      return structuredClone(stored);
    },
  };

  const service = new ChronoPicAppService(
    fakeDb as never,
    stubIndexer as never,
    {
      isEnabled: () => true,
      analyzePhoto: async () => {
        throw new Error("model offline");
      },
    }
  );

  const failed = await service.enrichPhotoSemantic("photo-1");

  assert.equal(failed.semantic.aiStatus, "failed");
  assert.equal(failed.semantic.aiError, "model offline");
  assert.deepEqual(failed.semantic.generatedLabels, ["existing-generated"]);
  assert.equal(failed.semantic.generatedCaption, "Existing generated caption");
  assert.equal(failed.semantic.summary, "Existing summary");
  assert.equal(failed.indexState.aiProcessed, false);
});

test("ChronoPicAppService enrichPendingSemantics processes pending and failed photos only", async () => {
  const makeRecord = (id: string, aiStatus: PhotoRecord["semantic"]["aiStatus"]): PhotoRecord => ({
    ...makePhotoRecord(),
    photo: {
      ...makePhotoRecord().photo,
      id,
      path: `/tmp/${id}.jpg`,
    },
    metadata: {
      ...makePhotoRecord().metadata,
      photoId: id,
    },
    semantic: {
      ...makePhotoRecord().semantic,
      photoId: id,
      aiStatus,
    },
    indexState: {
      ...makePhotoRecord().indexState,
      photoId: id,
      aiProcessed: aiStatus === "completed",
    },
  });

  const records = new Map<string, PhotoRecord>([
    ["disabled-1", makeRecord("disabled-1", "disabled")],
    ["pending-1", makeRecord("pending-1", "pending")],
    ["failed-1", makeRecord("failed-1", "failed")],
    ["completed-1", makeRecord("completed-1", "completed")],
  ]);

  const fakeDb = {
    listPhotos(filter?: { aiStatus?: string[] | string; limit?: number }) {
      const statuses = filter?.aiStatus
        ? Array.isArray(filter.aiStatus)
          ? filter.aiStatus
          : [filter.aiStatus]
        : [];

      return Array.from(records.values())
        .filter((record) => statuses.length === 0 || statuses.includes(record.semantic.aiStatus))
        .slice(0, filter?.limit ?? 999)
        .map((record) => structuredClone(record));
    },
    getPhoto(photoId: string) {
      return structuredClone(records.get(photoId) ?? null);
    },
    updatePhotoSemanticEnrichment(photoId: string, updates: Partial<PhotoRecord["semantic"]>) {
      const current = records.get(photoId);
      assert.ok(current);

      const next: PhotoRecord = {
        ...current,
        semantic: {
          ...current.semantic,
          ...updates,
          generatedLabels: updates.generatedLabels ?? current.semantic.generatedLabels,
          generatedCaption: updates.generatedCaption ?? current.semantic.generatedCaption,
          summary: updates.summary ?? current.semantic.summary,
          aiStatus: updates.aiStatus ?? current.semantic.aiStatus,
          aiProvider: updates.aiProvider ?? current.semantic.aiProvider,
          aiModel: updates.aiModel ?? current.semantic.aiModel,
          aiProcessedAt: updates.aiProcessedAt ?? current.semantic.aiProcessedAt,
          aiError: updates.aiError ?? current.semantic.aiError,
        },
        indexState: {
          ...current.indexState,
          aiProcessed: (updates.aiStatus ?? current.semantic.aiStatus) === "completed",
        },
      };

      records.set(photoId, next);
      return structuredClone(next);
    },
    getSemanticQueueStats() {
      return {
        disabled: 0,
        pending: 1,
        processing: 0,
        completed: 1,
        failed: 1,
      };
    },
  };

  const service = new ChronoPicAppService(
    fakeDb as never,
    stubIndexer as never,
    {
      isEnabled: () => true,
      analyzePhoto: async (photo) => {
        if (photo.photo.id === "failed-1") {
          throw new Error("retry failed");
        }

        return {
          generatedLabels: ["ai-tag"],
          generatedCaption: `caption-${photo.photo.id}`,
          summary: `summary-${photo.photo.id}`,
          embeddingRef: null,
          aiProvider: "openai-compatible",
          aiModel: "model-a",
          aiProcessedAt: 999,
          aiError: null,
        };
      },
    }
  );

  const summary = await service.enrichPendingSemantics(10);

  assert.deepEqual(summary, {
    processed: 3,
    completed: 2,
    failed: 1,
    skipped: 0,
  });
  assert.equal(records.get("disabled-1")?.semantic.aiStatus, "completed");
  assert.equal(records.get("pending-1")?.semantic.aiStatus, "completed");
  assert.equal(records.get("failed-1")?.semantic.aiStatus, "failed");
  assert.equal(records.get("completed-1")?.semantic.aiStatus, "completed");
});

test("ChronoPicAppService enrichMemorySemantic stores generated fields without overwriting manual title or description", async () => {
  let storedMemory = makeMemory();
  let receivedMemoryContext: unknown;
  const photoRecords = [makePhotoRecord(), { ...makePhotoRecord(), photo: { ...makePhotoRecord().photo, id: "photo-2", path: "/tmp/coast.jpg" } }];

  const fakeDb = {
    getMemory(memoryId: string) {
      return memoryId === storedMemory.id ? structuredClone(storedMemory) : null;
    },
    listPhotosByMemory(memoryId: string) {
      return memoryId === storedMemory.id ? photoRecords.map((photo) => structuredClone(photo)) : [];
    },
    updateMemorySemanticEnrichment(memoryId: string, updates: Partial<Memory>) {
      assert.equal(memoryId, storedMemory.id);
      storedMemory = {
        ...storedMemory,
        generatedName: updates.generatedName ?? storedMemory.generatedName,
        generatedDescription: updates.generatedDescription ?? storedMemory.generatedDescription,
        generatedLabels: updates.generatedLabels ?? storedMemory.generatedLabels,
        aiStatus: updates.aiStatus ?? storedMemory.aiStatus,
        aiProvider: updates.aiProvider ?? storedMemory.aiProvider,
        aiModel: updates.aiModel ?? storedMemory.aiModel,
        aiProcessedAt: updates.aiProcessedAt ?? storedMemory.aiProcessedAt,
        aiError: updates.aiError ?? storedMemory.aiError,
      };
      return structuredClone(storedMemory);
    },
  };

  const service = new ChronoPicAppService(
    fakeDb as never,
    stubIndexer as never,
    {
      isEnabled: () => true,
      analyzePhoto: async () => {
        throw new Error("unused");
      },
      analyzeMemory: async (_memory, _photos, context) => {
        receivedMemoryContext = context;
        return {
          generatedName: "Misty Coastal Weekend",
          generatedDescription: "A calm set of shoreline and travel photos with soft light and a reflective mood.",
          generatedLabels: ["coast", "weekend", "travel"],
          aiProvider: "openai-compatible",
          aiModel: "model-a",
          aiProcessedAt: 456,
          aiError: null,
        };
      },
    }
  );

  const enriched = await service.enrichMemorySemantic("memory-1", {
    name: "My edited title draft",
    description: "My edited description draft",
  });

  assert.equal(enriched.name, "Weekend Trip");
  assert.equal(enriched.description, "Manual notes");
  assert.deepEqual(receivedMemoryContext, {
    name: "My edited title draft",
    description: "My edited description draft",
  });
  assert.equal(enriched.generatedName, "Misty Coastal Weekend");
  assert.equal(
    enriched.generatedDescription,
    "A calm set of shoreline and travel photos with soft light and a reflective mood."
  );
  assert.deepEqual(enriched.generatedLabels, ["coast", "weekend", "travel"]);
  assert.equal(enriched.aiStatus, "completed");
});

test("ChronoPicAppService listPhotosForDiscovery maps discovery text to photo query filters", () => {
  let receivedFilter: Record<string, unknown> | undefined;
  const fakeDb = {
    listPhotos(filter?: Record<string, unknown>) {
      receivedFilter = filter;
      return [];
    },
  };

  const service = new ChronoPicAppService(fakeDb as never, stubIndexer as never, {
    isEnabled: () => false,
  } as never);

  service.listPhotosForDiscovery({
    text: "misty forest",
    memoryId: "memory-1",
    favorite: true,
    hasGps: true,
    sortBy: "updatedAt",
    sortDirection: "asc",
    limit: 24,
    offset: 12,
  });

  assert.deepEqual(receivedFilter, {
    query: "misty forest",
    favorite: true,
    memoryId: "memory-1",
    hasGps: true,
    sortBy: "updatedAt",
    sortDirection: "asc",
    limit: 24,
    offset: 12,
  });
});
