import assert from "node:assert/strict";
import test from "node:test";

import type { Memory, PhotoRecord } from "@chronopic/domain";
import { getDiscoveryMatchSummary } from "../packages/ui-components/dist/index.js";

function makePhotoRecord(): PhotoRecord {
  const now = Date.now();

  return {
    photo: {
      id: "photo-1",
      path: "/tmp/forest-dawn.jpg",
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
      labels: ["pines", "morning"],
      caption: "Forest dawn walk",
      generatedLabels: ["mist", "trees"],
      generatedCaption: "A misty pine forest at dawn",
      summary: "Soft morning mist over a pine forest path.",
      embeddingRef: null,
      aiStatus: "completed",
      aiProvider: "openai-compatible",
      aiModel: "test-model",
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

function makeMemory(): Memory {
  const now = Date.now();

  return {
    id: "memory-1",
    name: "Forest Escape",
    description: "Weekend cabin and pine trails",
    coverPhotoId: null,
    coverThumbnailPath: null,
    photoCount: 2,
    generatedName: "Misty Forest Story",
    generatedDescription: "A quiet forest trip filled with misty mornings.",
    generatedLabels: ["forest", "mist"],
    aiStatus: "completed",
    aiProvider: "openai-compatible",
    aiModel: "test-model",
    aiProcessedAt: now,
    aiError: null,
    source: "manual",
    createdAt: now,
    updatedAt: now,
  };
}

test("getDiscoveryMatchSummary explains which selected-photo fields matched the active query", () => {
  const summary = getDiscoveryMatchSummary(makePhotoRecord(), [makeMemory()], "mist");

  assert(summary);
  assert.deepEqual(summary.labels, ["AI Caption", "AI Summary", "AI Tags", "AI Memory Title", "AI Memory Summary", "AI Memory Tags"]);
  assert.equal(
    summary.description,
    "Matched in AI Caption, AI Summary, AI Tags, AI Memory Title, AI Memory Summary, AI Memory Tags."
  );
});
