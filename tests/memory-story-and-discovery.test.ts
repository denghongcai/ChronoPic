import assert from "node:assert/strict";
import test from "node:test";

import type { Memory, PhotoRecord, PlaceGroup } from "@chronopic/domain";
import { buildDiscoverySuggestions, buildMemoryStorySections } from "../packages/ui-components/dist/index.js";

function makePhotoRecord(overrides: {
  id: string;
  datetime?: number | null;
  favorite?: boolean;
  labels?: string[];
  generatedLabels?: string[];
  aiStatus?: PhotoRecord["semantic"]["aiStatus"];
  lat?: number | null;
  lng?: number | null;
}): PhotoRecord {
  const now = Date.UTC(2026, 3, 19, 12, 0, 0);

  return {
    photo: {
      id: overrides.id,
      path: `/tmp/${overrides.id}.jpg`,
      hash: `hash-${overrides.id}`,
      size: 123,
      mime: "image/jpeg",
      thumbnailPath: `/tmp/${overrides.id}-thumb.jpg`,
      favorite: overrides.favorite ?? false,
      createdAt: now,
      updatedAt: now,
    },
    metadata: {
      photoId: overrides.id,
      datetime: overrides.datetime ?? now,
      lat: overrides.lat ?? null,
      lng: overrides.lng ?? null,
      camera: null,
      confidence: 1,
      originalDatetimeText: null,
    },
    semantic: {
      photoId: overrides.id,
      labels: overrides.labels ?? [],
      caption: null,
      generatedLabels: overrides.generatedLabels ?? [],
      generatedCaption: null,
      summary: null,
      embeddingRef: null,
      aiStatus: overrides.aiStatus ?? "pending",
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    },
    indexState: {
      photoId: overrides.id,
      indexed: true,
      aiProcessed: overrides.aiStatus === "completed",
      error: null,
      lastIndexedAt: now,
      duplicateOf: null,
      sourceUpdatedAt: now,
      missingAt: null,
    },
  };
}

function makeMemory(): Memory {
  const now = Date.UTC(2026, 3, 19, 12, 0, 0);

  return {
    id: "memory-1",
    name: "Forest Weekend",
    description: "Pine trails and rainy light",
    coverPhotoId: null,
    coverThumbnailPath: null,
    photoCount: 3,
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

test("buildMemoryStorySections groups memory photos into chronological chapters", () => {
  const sections = buildMemoryStorySections([
    makePhotoRecord({ id: "may-1", datetime: Date.UTC(2026, 4, 1), labels: ["city"] }),
    makePhotoRecord({ id: "april-1", datetime: Date.UTC(2026, 3, 18), labels: ["forest"], lat: 31, lng: 121, aiStatus: "completed" }),
    makePhotoRecord({ id: "april-2", datetime: Date.UTC(2026, 3, 19), generatedLabels: ["forest"] }),
  ]);

  assert.equal(sections.length, 2);
  assert.equal(sections[0]?.monthKey, "2026-04");
  assert.equal(sections[0]?.photoCount, 2);
  assert.equal(sections[0]?.gpsCount, 1);
  assert.equal(sections[0]?.aiReadyCount, 1);
  assert.equal(sections[1]?.monthKey, "2026-05");
});

test("buildDiscoverySuggestions returns actionable pivots from the current browse scope", () => {
  const places: PlaceGroup[] = [
    {
      id: "place-1",
      centerLat: 31,
      centerLng: 121,
      photoCount: 2,
      representativePhotoId: "photo-1",
      representativeThumbnailPath: "/tmp/photo-1-thumb.jpg",
      fromDatetime: null,
      toDatetime: null,
    },
  ];

  const suggestions = buildDiscoverySuggestions({
    filter: {},
    memories: [makeMemory()],
    photos: [
      makePhotoRecord({ id: "photo-1", favorite: true, labels: ["forest"], lat: 31, lng: 121, aiStatus: "completed" }),
      makePhotoRecord({ id: "photo-2", generatedLabels: ["forest"], aiStatus: "pending" }),
    ],
    placeGroups: places,
  });

  assert(suggestions.some((suggestion) => suggestion.id === "filter:gps" && suggestion.patch?.hasGps === true));
  assert(suggestions.some((suggestion) => suggestion.id === "filter:favorites" && suggestion.patch?.favorite === true));
  assert(suggestions.some((suggestion) => suggestion.id === "mode:map" && suggestion.mode === "map"));
  assert(suggestions.some((suggestion) => suggestion.id === "tag:forest" && suggestion.patch?.tag === "forest"));
  assert(suggestions.some((suggestion) => suggestion.id === "memory:memory-1" && suggestion.memoryId === "memory-1"));
});
