import fs from "node:fs";
import path from "node:path";

const FIXTURE_DIR = path.join("tests", "fixtures", "flutter-parity");
const BACKUP_PATH = path.join(FIXTURE_DIR, "chronopic-backup-v1.json");
const EXPECTED_PATH = path.join(FIXTURE_DIR, "chronopic-backup-v1.expected.json");

const now = 1_715_000_000_000;
const later = now + 60_000;

const backup = {
  app: "ChronoPic",
  schemaVersion: 1,
  exportedAt: now,
  settings: {
    ai: {
      apiKey: "fixture-api-key",
      baseURL: "https://models.example.test/v1",
      model: "fixture-vision-model",
      providerName: "fixture-provider",
    },
    map: {
      apiKey: "fixture-amap-key",
      securityJsCode: "fixture-amap-security",
    },
    locale: {
      locale: "zh-CN",
      aiOutputLocale: "zh-CN",
    },
  },
  librarySources: [
    {
      id: "source-fixture-library",
      path: "/fixture/chronopic/library",
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastScanAt: later,
    },
  ],
  photos: [
    {
      photo: {
        id: "photo-lake",
        path: "/fixture/chronopic/library/backup-lake.png",
        hash: "hash-lake",
        size: 128,
        mime: "image/png",
        thumbnailPath: "/fixture/chronopic/thumbs/photo-lake.png",
        favorite: true,
        createdAt: now,
        updatedAt: later,
      },
      metadata: {
        photoId: "photo-lake",
        datetime: now,
        lat: 31.2304,
        lng: 121.4737,
        camera: "FixtureCam 1",
        confidence: 0.92,
        originalDatetimeText: "2024:05:06 10:00:00",
      },
      semantic: {
        photoId: "photo-lake",
        labels: ["backup", "lake"],
        caption: "Manual lake caption",
        generatedLabels: ["water", "travel"],
        generatedCaption: "Generated lake caption",
        summary: "A generated summary for the lake fixture.",
        embeddingRef: null,
        aiStatus: "completed",
        aiProvider: "fixture-provider",
        aiModel: "fixture-vision-model",
        aiProcessedAt: later,
        aiError: null,
      },
      indexState: {
        photoId: "photo-lake",
        indexed: true,
        aiProcessed: true,
        error: null,
        lastIndexedAt: later,
        duplicateOf: null,
        sourceUpdatedAt: now,
        missingAt: null,
      },
    },
    {
      photo: {
        id: "photo-city",
        path: "/fixture/chronopic/library/backup-city.png",
        hash: "hash-city",
        size: 128,
        mime: "image/png",
        thumbnailPath: "/fixture/chronopic/thumbs/photo-city.png",
        favorite: false,
        createdAt: now,
        updatedAt: later,
      },
      metadata: {
        photoId: "photo-city",
        datetime: now + 3_600_000,
        lat: null,
        lng: null,
        camera: "FixtureCam 1",
        confidence: 0.7,
        originalDatetimeText: null,
      },
      semantic: {
        photoId: "photo-city",
        labels: ["city"],
        caption: null,
        generatedLabels: ["street", "architecture"],
        generatedCaption: "Generated city caption",
        summary: "A generated summary for the city fixture.",
        embeddingRef: null,
        aiStatus: "failed",
        aiProvider: "fixture-provider",
        aiModel: "fixture-vision-model",
        aiProcessedAt: null,
        aiError: "fixture transient failure",
      },
      indexState: {
        photoId: "photo-city",
        indexed: true,
        aiProcessed: false,
        error: null,
        lastIndexedAt: later,
        duplicateOf: null,
        sourceUpdatedAt: now,
        missingAt: null,
      },
    },
  ],
  memories: [
    {
      id: "memory-weekend",
      name: "Fixture Weekend",
      description: "A portable memory used for Flutter parity tests.",
      coverPhotoId: "photo-lake",
      coverThumbnailPath: "/fixture/chronopic/thumbs/photo-lake.png",
      photoCount: 1,
      generatedName: "Generated Weekend",
      generatedDescription: "Generated memory description.",
      generatedLabels: ["weekend", "travel"],
      aiStatus: "completed",
      aiProvider: "fixture-provider",
      aiModel: "fixture-vision-model",
      aiProcessedAt: later,
      aiError: null,
      source: "manual",
      createdAt: now,
      updatedAt: later,
    },
  ],
  memoryPhotos: [
    {
      memoryId: "memory-weekend",
      photoId: "photo-lake",
      addedAt: later,
    },
  ],
  editHistory: [
    {
      id: "edit-caption-lake",
      photoId: "photo-lake",
      fieldName: "caption",
      previousValue: null,
      nextValue: "Manual lake caption",
      createdAt: later,
      rolledBackAt: null,
    },
    {
      id: "edit-tags-lake",
      photoId: "photo-lake",
      fieldName: "labels",
      previousValue: "[]",
      nextValue: "[\"backup\",\"lake\"]",
      createdAt: later + 1,
      rolledBackAt: null,
    },
  ],
  memoryCandidates: [
    {
      id: "candidate-city-lake",
      signature: "fixture:mixed:city-lake",
      title: "Fixture Trip",
      description: "Candidate generated from place and semantic fixture signals.",
      reason: "The fixture photos share a close import window and travel labels.",
      confidence: 0.81,
      source: "mixed",
      status: "pending",
      photoIds: ["photo-lake", "photo-city"],
      coverPhotoId: "photo-lake",
      coverThumbnailPath: "/fixture/chronopic/thumbs/photo-lake.png",
      generatedLabels: ["travel", "city"],
      acceptedMemoryId: null,
      createdAt: later,
      updatedAt: later,
    },
  ],
};

const expected = {
  schemaVersion: 1,
  counts: {
    sourceCount: backup.librarySources.length,
    photoCount: backup.photos.length,
    memoryCount: backup.memories.length,
    memoryPhotoCount: backup.memoryPhotos.length,
    editHistoryCount: backup.editHistory.length,
    memoryCandidateCount: backup.memoryCandidates.length,
  },
  keyFields: {
    locale: "zh-CN",
    aiOutputLocale: "zh-CN",
    favoritePhotoIds: ["photo-lake"],
    memoryIds: ["memory-weekend"],
    memoryCandidateIds: ["candidate-city-lake"],
    authoredCaptionPhotoIds: ["photo-lake"],
    generatedSemanticPhotoIds: ["photo-lake", "photo-city"],
    failedAIPhotoIds: ["photo-city"],
    gpsPhotoIds: ["photo-lake"],
  },
};

fs.mkdirSync(FIXTURE_DIR, { recursive: true });
fs.writeFileSync(BACKUP_PATH, `${JSON.stringify(backup, null, 2)}\n`, "utf8");
fs.writeFileSync(EXPECTED_PATH, `${JSON.stringify(expected, null, 2)}\n`, "utf8");

console.log(`Wrote ${BACKUP_PATH}`);
console.log(`Wrote ${EXPECTED_PATH}`);
