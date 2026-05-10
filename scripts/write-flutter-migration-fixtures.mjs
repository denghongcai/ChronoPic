import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const FIXTURE_DIR = path.join("tests", "fixtures", "flutter-migration");
const BACKUP_PATH = path.join(FIXTURE_DIR, "electron-backup-v1.json");
const EXPECTED_PATH = path.join(FIXTURE_DIR, "electron-backup-v1.expected.json");
const FIXED_TIME = 1_715_500_000_000;

function findLatestElectronBackup() {
  const explicit = process.env.ELECTRON_BACKUP_SOURCE;
  if (explicit) {
    if (!fs.existsSync(explicit)) {
      throw new Error(`ELECTRON_BACKUP_SOURCE does not exist: ${explicit}`);
    }
    return explicit;
  }

  const candidates = fs
    .readdirSync(os.tmpdir(), { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name.startsWith("chronopic-backup-file-"))
    .map((entry) => path.join(os.tmpdir(), entry.name, "chronopic-backup.json"))
    .filter((filePath) => fs.existsSync(filePath))
    .sort((left, right) => fs.statSync(right).mtimeMs - fs.statSync(left).mtimeMs);

  if (candidates.length === 0) {
    throw new Error(
      "No Electron backup file found. Run `pnpm run e2e:backup` first or set ELECTRON_BACKUP_SOURCE.",
    );
  }
  return candidates[0];
}

function slugFromPath(filePath, fallback) {
  const baseName = path.basename(filePath || fallback, path.extname(filePath || fallback));
  return (
    baseName
      .replace(/^backup[-_]?/i, "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "") || fallback
  );
}

function fractionalTime(offset) {
  return FIXED_TIME + offset + 0.3997;
}

function stableThumbnailPath(photoId) {
  return `/fixture/electron-backup/thumbs/${photoId}.jpg`;
}

function sanitizeBackup(rawBackup) {
  const sortedPhotos = [...rawBackup.photos].sort((left, right) =>
    String(left.photo.path).localeCompare(String(right.photo.path)),
  );
  const photoIdMap = new Map();

  const photos = sortedPhotos.map((record, index) => {
    const slug = slugFromPath(record.photo.path, `photo-${index + 1}`);
    const photoId = `electron-photo-${slug}`;
    photoIdMap.set(record.photo.id, photoId);
    const photoPath = `/fixture/electron-backup/library/${path.basename(record.photo.path)}`;
    const thumbnailPath = stableThumbnailPath(photoId);
    const createdAt = fractionalTime((index + 1) * 1_000);
    const updatedAt = FIXED_TIME + (index + 1) * 10_000;

    return {
      photo: {
        ...record.photo,
        id: photoId,
        path: photoPath,
        thumbnailPath,
        createdAt,
        updatedAt,
      },
      metadata: {
        ...record.metadata,
        photoId,
        datetime: createdAt,
      },
      semantic: {
        ...record.semantic,
        photoId,
      },
      indexState: {
        ...record.indexState,
        photoId,
        lastIndexedAt: updatedAt,
        sourceUpdatedAt: createdAt,
        missingAt: null,
      },
    };
  });

  const memories = rawBackup.memories.map((memory, index) => {
    const memoryId = index === 0 ? "electron-memory-backup-e2e" : `electron-memory-${index + 1}`;
    const coverPhotoId = memory.coverPhotoId ? photoIdMap.get(memory.coverPhotoId) : null;
    return {
      ...memory,
      id: memoryId,
      coverPhotoId,
      coverThumbnailPath: coverPhotoId ? stableThumbnailPath(coverPhotoId) : null,
      createdAt: FIXED_TIME + 50_000 + index,
      updatedAt: FIXED_TIME + 60_000 + index,
    };
  });
  const memoryIdMap = new Map(rawBackup.memories.map((memory, index) => [memory.id, memories[index].id]));

  const memoryPhotos = rawBackup.memoryPhotos.map((membership, index) => ({
    ...membership,
    memoryId: memoryIdMap.get(membership.memoryId),
    photoId: photoIdMap.get(membership.photoId),
    addedAt: FIXED_TIME + 70_000 + index,
  }));

  const editHistory = rawBackup.editHistory.map((edit, index) => {
    const photoId = photoIdMap.get(edit.photoId);
    const slug = photoId?.replace(/^electron-photo-/, "") || `photo-${index + 1}`;
    return {
      ...edit,
      id: `electron-edit-${edit.fieldName}-${slug}`,
      photoId,
      createdAt: FIXED_TIME + 80_000 + index,
      rolledBackAt: null,
    };
  });

  return {
    app: "ChronoPic",
    schemaVersion: 1,
    exportedAt: FIXED_TIME,
    settings: {
      ai: {
        apiKey: "",
        baseURL: "",
        model: "",
        providerName: rawBackup.settings?.ai?.providerName || "openai-compatible",
      },
      map: {
        apiKey: "fixture-amap-key",
        securityJsCode: "fixture-amap-security",
      },
      locale: rawBackup.settings.locale,
    },
    librarySources: [
      {
        id: "source-electron-backup",
        path: "/fixture/electron-backup/library",
        isActive: true,
        createdAt: FIXED_TIME,
        updatedAt: FIXED_TIME + 10_000,
        lastScanAt: FIXED_TIME + 20_000,
      },
    ],
    photos,
    memories,
    memoryPhotos,
    editHistory,
    memoryCandidates: rawBackup.memoryCandidates ?? [],
  };
}

function buildExpected(backup) {
  const favoritePhotoIds = backup.photos
    .filter((record) => record.photo.favorite)
    .map((record) => record.photo.id);
  const authored = backup.photos.find((record) => record.semantic.caption);
  return {
    schemaVersion: backup.schemaVersion,
    source: {
      sanitizedFromElectronE2E: true,
    },
    counts: {
      sourceCount: backup.librarySources.length,
      photoCount: backup.photos.length,
      memoryCount: backup.memories.length,
      memoryPhotoCount: backup.memoryPhotos.length,
      editHistoryCount: backup.editHistory.length,
      memoryCandidateCount: backup.memoryCandidates.length,
    },
    keyFields: {
      locale: backup.settings.locale.locale,
      aiOutputLocale: backup.settings.locale.aiOutputLocale,
      mapApiKey: backup.settings.map.apiKey,
      favoritePhotoIds,
      authoredPhotoId: authored?.photo.id ?? null,
      authoredCaption: authored?.semantic.caption ?? null,
      authoredLabels: authored?.semantic.labels ?? [],
      memoryId: backup.memories[0]?.id ?? null,
      memoryName: backup.memories[0]?.name ?? null,
      memoryDescription: backup.memories[0]?.description ?? null,
      memoryPhotoIds: backup.memoryPhotos.map((membership) => membership.photoId),
      photoAiStatusById: Object.fromEntries(
        backup.photos.map((record) => [record.photo.id, record.semantic.aiStatus]),
      ),
      photoGeneratedLabelsById: Object.fromEntries(
        backup.photos.map((record) => [record.photo.id, record.semantic.generatedLabels]),
      ),
      photoDatetimeById: Object.fromEntries(
        backup.photos.map((record) => [record.photo.id, Math.trunc(record.metadata.datetime)]),
      ),
      directSqliteImportRequiredForPhase7: false,
    },
  };
}

function assertSanitized(contents) {
  const forbidden = [os.tmpdir(), os.homedir()].filter(Boolean);
  for (const value of forbidden) {
    if (value && contents.includes(value)) {
      throw new Error(`Sanitized migration fixture still contains local path: ${value}`);
    }
  }
  if (contents.includes('"amap-backup-key"') || contents.includes('"amap-security"')) {
    throw new Error("Sanitized migration fixture still contains Electron E2E secret placeholders");
  }
}

const sourcePath = findLatestElectronBackup();
const rawBackup = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const backup = sanitizeBackup(rawBackup);
const expected = buildExpected(backup);
const backupJson = `${JSON.stringify(backup, null, 2)}\n`;
const expectedJson = `${JSON.stringify(expected, null, 2)}\n`;

assertSanitized(backupJson);
assertSanitized(expectedJson);

fs.mkdirSync(FIXTURE_DIR, { recursive: true });
fs.writeFileSync(BACKUP_PATH, backupJson, "utf8");
fs.writeFileSync(EXPECTED_PATH, expectedJson, "utf8");

console.log(`Read ${sourcePath}`);
console.log(`Wrote ${BACKUP_PATH}`);
console.log(`Wrote ${EXPECTED_PATH}`);
