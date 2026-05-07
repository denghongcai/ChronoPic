import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";

import type { ChronoPicBackup } from "@chronopic/domain";

interface FlutterParityExpected {
  schemaVersion: number;
  counts: {
    sourceCount: number;
    photoCount: number;
    memoryCount: number;
    memoryPhotoCount: number;
    editHistoryCount: number;
    memoryCandidateCount: number;
  };
  keyFields: {
    locale: string;
    aiOutputLocale: string;
    favoritePhotoIds: string[];
    memoryIds: string[];
    memoryCandidateIds: string[];
    authoredCaptionPhotoIds: string[];
    generatedSemanticPhotoIds: string[];
    failedAIPhotoIds: string[];
    gpsPhotoIds: string[];
  };
}

const backup = JSON.parse(
  fs.readFileSync("tests/fixtures/flutter-parity/chronopic-backup-v1.json", "utf8")
) as ChronoPicBackup;

const expected = JSON.parse(
  fs.readFileSync("tests/fixtures/flutter-parity/chronopic-backup-v1.expected.json", "utf8")
) as FlutterParityExpected;

test("Flutter parity fixture matches the expected ChronoPic backup shape", () => {
  assert.equal(backup.app, "ChronoPic");
  assert.equal(backup.schemaVersion, expected.schemaVersion);
  assert.equal(backup.librarySources.length, expected.counts.sourceCount);
  assert.equal(backup.photos.length, expected.counts.photoCount);
  assert.equal(backup.memories.length, expected.counts.memoryCount);
  assert.equal(backup.memoryPhotos.length, expected.counts.memoryPhotoCount);
  assert.equal(backup.editHistory.length, expected.counts.editHistoryCount);
  assert.equal(backup.memoryCandidates.length, expected.counts.memoryCandidateCount);
  assert.equal(backup.settings.locale.locale, expected.keyFields.locale);
  assert.equal(backup.settings.locale.aiOutputLocale, expected.keyFields.aiOutputLocale);
});

test("Flutter parity fixture preserves migration-critical authored and generated fields", () => {
  assert.deepEqual(
    backup.photos.filter((record) => record.photo.favorite).map((record) => record.photo.id),
    expected.keyFields.favoritePhotoIds
  );
  assert.deepEqual(
    backup.memories.map((memory) => memory.id),
    expected.keyFields.memoryIds
  );
  assert.deepEqual(
    backup.memoryCandidates.map((candidate) => candidate.id),
    expected.keyFields.memoryCandidateIds
  );
  assert.deepEqual(
    backup.photos.filter((record) => record.semantic.caption).map((record) => record.photo.id),
    expected.keyFields.authoredCaptionPhotoIds
  );
  assert.deepEqual(
    backup.photos.filter((record) => record.semantic.generatedCaption).map((record) => record.photo.id),
    expected.keyFields.generatedSemanticPhotoIds
  );
  assert.deepEqual(
    backup.photos.filter((record) => record.semantic.aiStatus === "failed").map((record) => record.photo.id),
    expected.keyFields.failedAIPhotoIds
  );
  assert.deepEqual(
    backup.photos.filter((record) => record.metadata.lat !== null && record.metadata.lng !== null).map((record) => record.photo.id),
    expected.keyFields.gpsPhotoIds
  );
});
