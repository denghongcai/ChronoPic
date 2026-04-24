import assert from "node:assert/strict";
import test from "node:test";

import { ChronoPicAppService } from "@chronopic/application";
import type { Memory, MemoryCandidate, MemoryCandidateInput, PhotoRecord } from "@chronopic/domain";

function makePhoto(id: string, options: { label?: string; lat?: number; lng?: number; datetime?: number }): PhotoRecord {
  const now = Date.UTC(2026, 3, 19, 12, 0, 0);

  return {
    photo: {
      id,
      path: `/tmp/${id}.jpg`,
      hash: `hash-${id}`,
      size: 100,
      mime: "image/jpeg",
      thumbnailPath: `/tmp/${id}.thumb.jpg`,
      favorite: false,
      createdAt: now,
      updatedAt: now,
    },
    metadata: {
      photoId: id,
      datetime: options.datetime ?? now,
      lat: options.lat ?? null,
      lng: options.lng ?? null,
      camera: null,
      confidence: 1,
      originalDatetimeText: null,
    },
    semantic: {
      photoId: id,
      labels: options.label ? [options.label] : [],
      caption: null,
      generatedLabels: [],
      generatedCaption: null,
      summary: null,
      embeddingRef: null,
      aiStatus: "completed",
      aiProvider: "test",
      aiModel: "test",
      aiProcessedAt: now,
      aiError: null,
    },
    indexState: {
      photoId: id,
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

const stubAi = {
  isEnabled: () => false,
  analyzePhoto: async () => {
    throw new Error("not used");
  },
  analyzeMemory: async () => {
    throw new Error("not used");
  },
};

function makeMemory(): Memory {
  const now = Date.now();
  return {
    id: "memory-1",
    name: "Existing",
    description: null,
    coverPhotoId: null,
    coverThumbnailPath: null,
    photoCount: 0,
    generatedName: null,
    generatedDescription: null,
    generatedLabels: [],
    aiStatus: "disabled",
    aiProvider: null,
    aiModel: null,
    aiProcessedAt: null,
    aiError: null,
    source: "manual",
    createdAt: now,
    updatedAt: now,
  };
}

test("ChronoPicAppService generates reviewable memory candidates from place, time, and semantic signals", () => {
  const saved: MemoryCandidate[] = [];
  const photos = [
    makePhoto("p1", { label: "forest", lat: 31.21, lng: 121.51, datetime: Date.UTC(2026, 3, 18) }),
    makePhoto("p2", { label: "forest", lat: 31.22, lng: 121.52, datetime: Date.UTC(2026, 3, 19) }),
    makePhoto("p3", { label: "forest", lat: 31.23, lng: 121.53, datetime: Date.UTC(2026, 3, 20) }),
    makePhoto("p4", { label: "city", lat: 40.12, lng: 116.35, datetime: Date.UTC(2026, 3, 21) }),
  ];

  const fakeDb = {
    listPhotos() {
      return photos;
    },
    listMemories() {
      return [];
    },
    listPhotosByMemory() {
      return [];
    },
    upsertMemoryCandidate(input: MemoryCandidateInput): MemoryCandidate {
      const candidate: MemoryCandidate = {
        id: `candidate-${saved.length + 1}`,
        signature: input.signature,
        title: input.title,
        description: input.description ?? null,
        reason: input.reason,
        confidence: input.confidence,
        source: input.source,
        status: "pending",
        photoIds: input.photoIds,
        coverPhotoId: input.coverPhotoId ?? input.photoIds[0] ?? null,
        coverThumbnailPath: null,
        generatedLabels: input.generatedLabels ?? [],
        acceptedMemoryId: null,
        createdAt: 1,
        updatedAt: 1,
      };
      saved.push(candidate);
      return candidate;
    },
    listMemoryCandidates() {
      return saved;
    },
  };

  const service = new ChronoPicAppService(fakeDb as never, stubIndexer as never, stubAi as never);
  const candidates = service.generateMemoryCandidates();

  assert(candidates.some((candidate) => candidate.source === "place"));
  assert(candidates.some((candidate) => candidate.source === "time"));
  assert(candidates.some((candidate) => candidate.source === "semantic" && candidate.title === "Forest"));
  assert(candidates.every((candidate) => candidate.status === "pending"));
});

test("ChronoPicAppService accepts and rejects memory candidates through persistence boundary", () => {
  const accepted: Array<{ candidateId: string; name?: string; photoIds?: string[] }> = [];
  const rejected: string[] = [];

  const fakeDb = {
    acceptMemoryCandidate(candidateId: string, input: { name?: string; photoIds?: string[] }) {
      accepted.push({ candidateId, ...input });
      return makeMemory();
    },
    rejectMemoryCandidate(candidateId: string) {
      rejected.push(candidateId);
      return {
        id: candidateId,
        signature: "signature",
        title: "Candidate",
        description: null,
        reason: "Test",
        confidence: 0.8,
        source: "semantic",
        status: "rejected",
        photoIds: [],
        coverPhotoId: null,
        coverThumbnailPath: null,
        generatedLabels: [],
        acceptedMemoryId: null,
        createdAt: 1,
        updatedAt: 2,
      } satisfies MemoryCandidate;
    },
  };

  const service = new ChronoPicAppService(fakeDb as never, stubIndexer as never, stubAi as never);
  service.acceptMemoryCandidate("candidate-1", { name: "Accepted", photoIds: ["p1"] });
  service.rejectMemoryCandidate("candidate-2");

  assert.deepEqual(accepted, [{ candidateId: "candidate-1", name: "Accepted", photoIds: ["p1"] }]);
  assert.deepEqual(rejected, ["candidate-2"]);
});
