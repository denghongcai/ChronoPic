import path from "node:path";

import Database from "better-sqlite3";

import type {
  BackupRestoreConflict,
  BackupRestoreOptions,
  BackupRestorePreview,
  BackupRestoreResult,
  ChronoPicBackup,
  EditHistory,
  LibrarySource,
  LibrarySnapshot,
  Memory,
  AcceptMemoryCandidateInput,
  MemoryCandidate,
  MemoryCandidateInput,
  MemoryCandidateStatus,
  MemoryPhoto,
  Metadata,
  PlaceGroup,
  PlaceGroupQuery,
  PhotoFilter,
  PhotoRecord,
  Semantic,
  SemanticQueueStats,
  UpsertPhotoPayload
} from "@chronopic/domain";
import type { MemoryCandidateSource, MemorySource } from "@chronopic/domain";
import { DEFAULT_FILTER } from "@chronopic/domain";
import { createId, dedupeStrings, normalizeAbsolutePath, parseStringArray, serializeStringArray } from "@chronopic/shared-utils";

import { SCHEMA_SQL } from "./schema.js";

type SqliteConnection = InstanceType<typeof Database>;

interface PhotoRow {
  id: string;
  path: string;
  hash: string | null;
  size: number;
  mime: string;
  thumbnail_path: string | null;
  favorite: number;
  created_at: number;
  updated_at: number;
  datetime: number | null;
  lat: number | null;
  lng: number | null;
  camera: string | null;
  confidence: number;
  original_datetime_text: string | null;
  labels: string;
  caption: string | null;
  generated_labels: string;
  generated_caption: string | null;
  summary: string | null;
  embedding_ref: string | null;
  ai_status: Semantic["aiStatus"];
  ai_provider: string | null;
  ai_model: string | null;
  ai_processed_at: number | null;
  ai_error: string | null;
  indexed: number;
  ai_processed: number;
  error: string | null;
  last_indexed_at: number | null;
  duplicate_of: string | null;
  source_updated_at: number | null;
  missing_at: number | null;
}

interface MemoryCandidateRow {
  id: string;
  signature: string;
  title: string;
  description: string | null;
  reason: string;
  confidence: number;
  source: MemoryCandidateSource;
  status: MemoryCandidateStatus;
  photo_ids: string;
  cover_photo_id: string | null;
  cover_thumbnail_path: string | null;
  generated_labels: string;
  accepted_memory_id: string | null;
  created_at: number;
  updated_at: number;
}

function normalizeAIPipelineStatus(status: string | null | undefined): Semantic["aiStatus"] {
  if (status === "complete") {
    return "completed";
  }

  if (status === "error") {
    return "failed";
  }

  return (status as Semantic["aiStatus"]) ?? "disabled";
}

function mapPhotoRow(row: PhotoRow): PhotoRecord {
  return {
    photo: {
      id: row.id,
      path: row.path,
      hash: row.hash,
      size: row.size,
      mime: row.mime,
      thumbnailPath: row.thumbnail_path,
      favorite: Boolean(row.favorite),
      createdAt: row.created_at,
      updatedAt: row.updated_at
    },
    metadata: {
      photoId: row.id,
      datetime: row.datetime,
      lat: row.lat,
      lng: row.lng,
      camera: row.camera,
      confidence: row.confidence,
      originalDatetimeText: row.original_datetime_text
    },
    semantic: {
      photoId: row.id,
      labels: parseStringArray(row.labels),
      caption: row.caption,
      generatedLabels: parseStringArray(row.generated_labels),
      generatedCaption: row.generated_caption,
      summary: row.summary,
      embeddingRef: row.embedding_ref,
      aiStatus: normalizeAIPipelineStatus(row.ai_status),
      aiProvider: row.ai_provider,
      aiModel: row.ai_model,
      aiProcessedAt: row.ai_processed_at,
      aiError: row.ai_error
    },
    indexState: {
      photoId: row.id,
      indexed: Boolean(row.indexed),
      aiProcessed: Boolean(row.ai_processed),
      error: row.error,
      lastIndexedAt: row.last_indexed_at,
      duplicateOf: row.duplicate_of,
      sourceUpdatedAt: row.source_updated_at,
      missingAt: row.missing_at,
    }
  };
}

function mapMemoryCandidateRow(row: MemoryCandidateRow): MemoryCandidate {
  return {
    id: row.id,
    signature: row.signature,
    title: row.title,
    description: row.description,
    reason: row.reason,
    confidence: row.confidence,
    source: row.source,
    status: row.status,
    photoIds: parseStringArray(row.photo_ids),
    coverPhotoId: row.cover_photo_id,
    coverThumbnailPath: row.cover_thumbnail_path,
    generatedLabels: parseStringArray(row.generated_labels),
    acceptedMemoryId: row.accepted_memory_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function pushTextSearchClause(clauses: string[], params: unknown[], query: string) {
  clauses.push(
    `(
      p.path LIKE ?
      OR s.caption LIKE ?
      OR s.generated_caption LIKE ?
      OR s.summary LIKE ?
      OR s.labels LIKE ?
      OR s.generated_labels LIKE ?
      OR EXISTS (
        SELECT 1
        FROM memory_photos mp_search
        JOIN memories mem_search ON mem_search.id = mp_search.memory_id
        WHERE mp_search.photo_id = p.id
          AND (
            mem_search.name LIKE ?
            OR mem_search.description LIKE ?
            OR mem_search.generated_name LIKE ?
            OR mem_search.generated_description LIKE ?
            OR mem_search.generated_labels LIKE ?
          )
      )
    )`
  );

  params.push(query, query, query, query, query, query, query, query, query, query, query);
}

export class ChronoPicDatabase {
  private readonly db: SqliteConnection;

  constructor(databasePath: string) {
    this.db = new Database(databasePath);
    this.db.pragma("foreign_keys = ON");
    this.db.exec(SCHEMA_SQL);
    this.runMigrations();
  }

  private runMigrations(): void {
    this.db.exec(`
      PRAGMA journal_mode = WAL;

      CREATE TABLE IF NOT EXISTS memories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        cover_photo_id TEXT REFERENCES photos(id) ON DELETE SET NULL,
        generated_name TEXT,
        generated_description TEXT,
        generated_labels TEXT NOT NULL DEFAULT '[]',
        ai_status TEXT NOT NULL DEFAULT 'disabled',
        ai_provider TEXT,
        ai_model TEXT,
        ai_processed_at INTEGER,
        ai_error TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS memory_photos (
        memory_id TEXT NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
        photo_id TEXT NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (memory_id, photo_id)
      );

      CREATE INDEX IF NOT EXISTS idx_memory_photos_photo ON memory_photos(photo_id);

      CREATE TABLE IF NOT EXISTS memory_candidates (
        id TEXT PRIMARY KEY,
        signature TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        reason TEXT NOT NULL,
        confidence REAL NOT NULL,
        source TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        photo_ids TEXT NOT NULL DEFAULT '[]',
        cover_photo_id TEXT REFERENCES photos(id) ON DELETE SET NULL,
        generated_labels TEXT NOT NULL DEFAULT '[]',
        accepted_memory_id TEXT REFERENCES memories(id) ON DELETE SET NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_memory_candidates_status ON memory_candidates(status, updated_at DESC);
    `);

    // Migrate photos table: add favorite column if missing
    const columns: Array<{ name: string }> = this.db
      .prepare("PRAGMA table_info(photos)")
      .all() as Array<{ name: string }>;
    if (!columns.find((c) => c.name === "favorite")) {
      this.db.exec("ALTER TABLE photos ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0");
    }

    const memoryColumns: Array<{ name: string }> = this.db
      .prepare("PRAGMA table_info(memories)")
      .all() as Array<{ name: string }>;
    if (!memoryColumns.find((c) => c.name === "cover_photo_id")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN cover_photo_id TEXT REFERENCES photos(id) ON DELETE SET NULL");
    }
    if (!memoryColumns.find((c) => c.name === "generated_name")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN generated_name TEXT");
    }
    if (!memoryColumns.find((c) => c.name === "generated_description")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN generated_description TEXT");
    }
    if (!memoryColumns.find((c) => c.name === "generated_labels")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN generated_labels TEXT NOT NULL DEFAULT '[]'");
    }
    if (!memoryColumns.find((c) => c.name === "ai_status")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN ai_status TEXT NOT NULL DEFAULT 'disabled'");
    }
    if (!memoryColumns.find((c) => c.name === "ai_provider")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN ai_provider TEXT");
    }
    if (!memoryColumns.find((c) => c.name === "ai_model")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN ai_model TEXT");
    }
    if (!memoryColumns.find((c) => c.name === "ai_processed_at")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN ai_processed_at INTEGER");
    }
    if (!memoryColumns.find((c) => c.name === "ai_error")) {
      this.db.exec("ALTER TABLE memories ADD COLUMN ai_error TEXT");
    }

    const semanticColumns: Array<{ name: string }> = this.db
      .prepare("PRAGMA table_info(semantic)")
      .all() as Array<{ name: string }>;
    if (!semanticColumns.find((c) => c.name === "generated_labels")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN generated_labels TEXT NOT NULL DEFAULT '[]'");
    }
    if (!semanticColumns.find((c) => c.name === "generated_caption")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN generated_caption TEXT");
    }
    if (!semanticColumns.find((c) => c.name === "summary")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN summary TEXT");
    }
    if (!semanticColumns.find((c) => c.name === "ai_provider")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN ai_provider TEXT");
    }
    if (!semanticColumns.find((c) => c.name === "ai_model")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN ai_model TEXT");
    }
    if (!semanticColumns.find((c) => c.name === "ai_processed_at")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN ai_processed_at INTEGER");
    }
    if (!semanticColumns.find((c) => c.name === "ai_error")) {
      this.db.exec("ALTER TABLE semantic ADD COLUMN ai_error TEXT");
    }

    const indexStateColumns: Array<{ name: string }> = this.db
      .prepare("PRAGMA table_info(index_state)")
      .all() as Array<{ name: string }>;
    if (!indexStateColumns.find((c) => c.name === "source_updated_at")) {
      this.db.exec("ALTER TABLE index_state ADD COLUMN source_updated_at INTEGER");
    }
    if (!indexStateColumns.find((c) => c.name === "missing_at")) {
      this.db.exec("ALTER TABLE index_state ADD COLUMN missing_at INTEGER");
    }
  }

  close(): void {
    this.db.close();
  }

  addLibrarySource(libraryPath: string): LibrarySource {
    const normalizedPath = normalizeAbsolutePath(libraryPath);
    const existing = this.db
      .prepare("SELECT id, path, is_active, created_at, updated_at, last_scan_at FROM library_sources WHERE path = ?")
      .get(normalizedPath) as
      | {
          id: string;
          path: string;
          is_active: number;
          created_at: number;
          updated_at: number;
          last_scan_at: number | null;
        }
      | undefined;

    if (existing) {
      this.db.prepare("UPDATE library_sources SET is_active = 1, updated_at = ? WHERE id = ?").run(Date.now(), existing.id);
      return {
        id: existing.id,
        path: existing.path,
        isActive: true,
        createdAt: existing.created_at,
        updatedAt: Date.now(),
        lastScanAt: existing.last_scan_at
      };
    }

    const now = Date.now();
    const source: LibrarySource = {
      id: createId("lib"),
      path: normalizedPath,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastScanAt: null
    };

    this.db
      .prepare(
        "INSERT INTO library_sources (id, path, is_active, created_at, updated_at, last_scan_at) VALUES (?, ?, ?, ?, ?, ?)"
      )
      .run(source.id, source.path, 1, source.createdAt, source.updatedAt, source.lastScanAt);

    return source;
  }

  listLibrarySources(): LibrarySource[] {
    const rows = this.db
      .prepare("SELECT id, path, is_active, created_at, updated_at, last_scan_at FROM library_sources ORDER BY created_at ASC")
      .all() as Array<{
      id: string;
      path: string;
      is_active: number;
      created_at: number;
      updated_at: number;
      last_scan_at: number | null;
    }>;

    return rows.map((row) => ({
      id: row.id,
      path: row.path,
      isActive: Boolean(row.is_active),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      lastScanAt: row.last_scan_at
    }));
  }

  touchLibraryScan(sourceId: string): void {
    const now = Date.now();
    this.db.prepare("UPDATE library_sources SET updated_at = ?, last_scan_at = ? WHERE id = ?").run(now, now, sourceId);
  }

  getLibrarySource(sourceId: string): LibrarySource | null {
    const row = this.db
      .prepare("SELECT id, path, is_active, created_at, updated_at, last_scan_at FROM library_sources WHERE id = ?")
      .get(sourceId) as
      | {
          id: string;
          path: string;
          is_active: number;
          created_at: number;
          updated_at: number;
          last_scan_at: number | null;
        }
      | undefined;

    if (!row) {
      return null;
    }

    return {
      id: row.id,
      path: row.path,
      isActive: Boolean(row.is_active),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      lastScanAt: row.last_scan_at
    };
  }

  findPhotoByPath(photoPath: string): PhotoRecord | null {
    const row = this.db
      .prepare(
        `SELECT
          p.id, p.path, p.hash, p.size, p.mime, p.thumbnail_path, p.favorite, p.created_at, p.updated_at,
          m.datetime, m.lat, m.lng, m.camera, m.confidence, m.original_datetime_text,
          s.labels, s.caption, s.generated_labels, s.generated_caption, s.summary, s.embedding_ref, s.ai_status, s.ai_provider, s.ai_model, s.ai_processed_at, s.ai_error,
          i.indexed, i.ai_processed, i.error, i.last_indexed_at, i.duplicate_of, i.source_updated_at, i.missing_at
        FROM photos p
        JOIN metadata m ON m.photo_id = p.id
        JOIN semantic s ON s.photo_id = p.id
        JOIN index_state i ON i.photo_id = p.id
        WHERE p.path = ?`
      )
      .get(normalizeAbsolutePath(photoPath)) as PhotoRow | undefined;

    return row ? mapPhotoRow(row) : null;
  }

  findPrimaryPhotoIdByHash(hash: string, currentPhotoId?: string): string | null {
    const row = this.db
      .prepare(
        "SELECT p.id FROM photos p JOIN index_state i ON i.photo_id = p.id WHERE p.hash = ? AND i.duplicate_of IS NULL AND i.missing_at IS NULL ORDER BY p.created_at ASC"
      )
      .get(hash) as { id: string } | undefined;

    if (!row) {
      return null;
    }

    return row.id === currentPhotoId ? null : row.id;
  }

  listTrackedPhotosInSource(rootPath: string): Array<{
    path: string;
    size: number;
    sourceUpdatedAt: number | null;
    missingAt: number | null;
  }> {
    const normalizedRoot = normalizeAbsolutePath(rootPath);
    const nestedPattern = `${normalizedRoot}${path.sep}%`;

    const rows = this.db
      .prepare(
        `SELECT p.path, p.size, i.source_updated_at, i.missing_at
         FROM photos p
         JOIN index_state i ON i.photo_id = p.id
         WHERE p.path = ? OR p.path LIKE ?`
      )
      .all(normalizedRoot, nestedPattern) as Array<{
      path: string;
      size: number;
      source_updated_at: number | null;
      missing_at: number | null;
    }>;

    return rows.map((row) => ({
      path: row.path,
      size: row.size,
      sourceUpdatedAt: row.source_updated_at,
      missingAt: row.missing_at,
    }));
  }

  markPhotosMissing(photoPaths: string[]): number {
    if (photoPaths.length === 0) {
      return 0;
    }

    const now = Date.now();
    const normalizedPaths = photoPaths.map((photoPath) => normalizeAbsolutePath(photoPath));
    const placeholders = normalizedPaths.map(() => "?").join(", ");
    const updateIndexResult = this.db
      .prepare(
        `UPDATE index_state
         SET indexed = 0,
             error = 'Missing from disk',
             last_indexed_at = ?,
             missing_at = ?
         WHERE photo_id IN (
           SELECT id
           FROM photos
           WHERE path IN (${placeholders})
         )`
      )
      .run(now, now, ...normalizedPaths);

    this.db
      .prepare(
        `UPDATE photos
         SET updated_at = ?
         WHERE path IN (${placeholders})`
      )
      .run(now, ...normalizedPaths);

    return updateIndexResult.changes;
  }

  upsertPhotoRecord(payload: UpsertPhotoPayload): void {
    const transaction = this.db.transaction((input: UpsertPhotoPayload) => {
      this.db
        .prepare(
          `INSERT INTO photos (id, path, hash, size, mime, thumbnail_path, favorite, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             path = excluded.path,
             hash = excluded.hash,
             size = excluded.size,
             mime = excluded.mime,
             thumbnail_path = excluded.thumbnail_path,
             updated_at = excluded.updated_at`
        )
        .run(
          input.photo.id,
          normalizeAbsolutePath(input.photo.path),
          input.photo.hash,
          input.photo.size,
          input.photo.mime,
          input.photo.thumbnailPath,
          input.photo.favorite ? 1 : 0,
          input.photo.createdAt,
          input.photo.updatedAt
        );

      this.db
        .prepare(
          `INSERT INTO metadata (photo_id, datetime, lat, lng, camera, confidence, original_datetime_text)
           VALUES (?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(photo_id) DO UPDATE SET
             datetime = excluded.datetime,
             lat = excluded.lat,
             lng = excluded.lng,
             camera = excluded.camera,
             confidence = excluded.confidence,
             original_datetime_text = excluded.original_datetime_text`
        )
        .run(
          input.metadata.photoId,
          input.metadata.datetime,
          input.metadata.lat,
          input.metadata.lng,
          input.metadata.camera,
          input.metadata.confidence,
          input.metadata.originalDatetimeText
        );

      this.db
        .prepare(
          `INSERT INTO semantic (
             photo_id, labels, caption, generated_labels, generated_caption, summary, embedding_ref, ai_status,
             ai_provider, ai_model, ai_processed_at, ai_error
           )
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(photo_id) DO UPDATE SET
             labels = excluded.labels,
             caption = excluded.caption,
             generated_labels = excluded.generated_labels,
             generated_caption = excluded.generated_caption,
             summary = excluded.summary,
             embedding_ref = excluded.embedding_ref,
             ai_status = excluded.ai_status,
             ai_provider = excluded.ai_provider,
             ai_model = excluded.ai_model,
             ai_processed_at = excluded.ai_processed_at,
             ai_error = excluded.ai_error`
        )
        .run(
          input.semantic.photoId,
          serializeStringArray(dedupeStrings(input.semantic.labels)),
          input.semantic.caption,
          serializeStringArray(dedupeStrings(input.semantic.generatedLabels)),
          input.semantic.generatedCaption,
          input.semantic.summary,
          input.semantic.embeddingRef,
          normalizeAIPipelineStatus(input.semantic.aiStatus),
          input.semantic.aiProvider,
          input.semantic.aiModel,
          input.semantic.aiProcessedAt,
          input.semantic.aiError
        );

      this.db
        .prepare(
          `INSERT INTO index_state (photo_id, indexed, ai_processed, error, last_indexed_at, duplicate_of, source_updated_at, missing_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(photo_id) DO UPDATE SET
             indexed = excluded.indexed,
             ai_processed = excluded.ai_processed,
             error = excluded.error,
             last_indexed_at = excluded.last_indexed_at,
             duplicate_of = excluded.duplicate_of,
             source_updated_at = excluded.source_updated_at,
             missing_at = excluded.missing_at`
        )
        .run(
          input.indexState.photoId,
          input.indexState.indexed ? 1 : 0,
          input.indexState.aiProcessed ? 1 : 0,
          input.indexState.error,
          input.indexState.lastIndexedAt,
          input.indexState.duplicateOf,
          input.indexState.sourceUpdatedAt,
          input.indexState.missingAt
        );
    });

    transaction(payload);
  }

  listPhotos(filter: PhotoFilter = {}): PhotoRecord[] {
    const resolvedFilter = { ...DEFAULT_FILTER, ...filter };
    const clauses: string[] = ["i.missing_at IS NULL"];
    const params: unknown[] = [];

    if (resolvedFilter.query) {
      const query = `%${resolvedFilter.query}%`;
      pushTextSearchClause(clauses, params, query);
    }

    if (resolvedFilter.mimePrefix) {
      clauses.push("p.mime LIKE ?");
      params.push(`${resolvedFilter.mimePrefix}%`);
    }

    if (resolvedFilter.tag) {
      clauses.push("(s.labels LIKE ? OR s.generated_labels LIKE ?)");
      params.push(`%${resolvedFilter.tag}%`, `%${resolvedFilter.tag}%`);
    }

    if (resolvedFilter.aiStatus) {
      const statuses = Array.isArray(resolvedFilter.aiStatus) ? resolvedFilter.aiStatus : [resolvedFilter.aiStatus];
      if (statuses.length > 0) {
        clauses.push(`s.ai_status IN (${statuses.map(() => "?").join(", ")})`);
        params.push(...statuses.map((status) => normalizeAIPipelineStatus(status)));
      }
    }

    if (typeof resolvedFilter.favorite === "boolean") {
      clauses.push("p.favorite = ?");
      params.push(resolvedFilter.favorite ? 1 : 0);
    }

    if (resolvedFilter.memoryId) {
      clauses.push("mp.memory_id = ?");
      params.push(resolvedFilter.memoryId);
    }

    if (typeof resolvedFilter.indexed === "boolean") {
      clauses.push("i.indexed = ?");
      params.push(resolvedFilter.indexed ? 1 : 0);
    }

    if (resolvedFilter.hasError) {
      clauses.push("i.error IS NOT NULL");
    }

    if (resolvedFilter.hasGps) {
      clauses.push("m.lat IS NOT NULL AND m.lng IS NOT NULL");
    }

    if (resolvedFilter.fromDatetime) {
      clauses.push("m.datetime >= ?");
      params.push(resolvedFilter.fromDatetime);
    }

    if (resolvedFilter.toDatetime) {
      clauses.push("m.datetime <= ?");
      params.push(resolvedFilter.toDatetime);
    }

    const whereSql = clauses.length > 0 ? `WHERE ${clauses.join(" AND ")}` : "";
    const orderMap: Record<NonNullable<PhotoFilter["sortBy"]>, string> = {
      datetime: "m.datetime",
      updatedAt: "p.updated_at",
      path: "p.path"
    };
    const orderSql = `${orderMap[resolvedFilter.sortBy]} ${resolvedFilter.sortDirection.toUpperCase()}`;

    const rows = this.db
      .prepare(
        `SELECT
          p.id, p.path, p.hash, p.size, p.mime, p.thumbnail_path, p.favorite, p.created_at, p.updated_at,
          m.datetime, m.lat, m.lng, m.camera, m.confidence, m.original_datetime_text,
          s.labels, s.caption, s.generated_labels, s.generated_caption, s.summary, s.embedding_ref, s.ai_status, s.ai_provider, s.ai_model, s.ai_processed_at, s.ai_error,
          i.indexed, i.ai_processed, i.error, i.last_indexed_at, i.duplicate_of, i.source_updated_at, i.missing_at
        FROM photos p
        JOIN metadata m ON m.photo_id = p.id
        JOIN semantic s ON s.photo_id = p.id
        JOIN index_state i ON i.photo_id = p.id
        ${resolvedFilter.memoryId ? "LEFT JOIN memory_photos mp ON mp.photo_id = p.id" : ""}
        ${whereSql}
        ORDER BY ${orderSql}
        LIMIT ? OFFSET ?`
      )
      .all(...params, resolvedFilter.limit, resolvedFilter.offset) as PhotoRow[];

    return rows.map(mapPhotoRow);
  }

  private listAllPhotoPayloads(): UpsertPhotoPayload[] {
    const rows = this.db
      .prepare(
        `SELECT
          p.id, p.path, p.hash, p.size, p.mime, p.thumbnail_path, p.favorite, p.created_at, p.updated_at,
          m.datetime, m.lat, m.lng, m.camera, m.confidence, m.original_datetime_text,
          s.labels, s.caption, s.generated_labels, s.generated_caption, s.summary, s.embedding_ref, s.ai_status, s.ai_provider, s.ai_model, s.ai_processed_at, s.ai_error,
          i.indexed, i.ai_processed, i.error, i.last_indexed_at, i.duplicate_of, i.source_updated_at, i.missing_at
        FROM photos p
        JOIN metadata m ON m.photo_id = p.id
        JOIN semantic s ON s.photo_id = p.id
        JOIN index_state i ON i.photo_id = p.id
        ORDER BY p.path ASC`
      )
      .all() as PhotoRow[];

    return rows.map((row) => {
      const record = mapPhotoRow(row);
      return {
        photo: record.photo,
        metadata: record.metadata,
        semantic: record.semantic,
        indexState: record.indexState,
      };
    });
  }

  getPhoto(photoId: string): PhotoRecord | null {
    const row = this.db
      .prepare(
        `SELECT
          p.id, p.path, p.hash, p.size, p.mime, p.thumbnail_path, p.favorite, p.created_at, p.updated_at,
          m.datetime, m.lat, m.lng, m.camera, m.confidence, m.original_datetime_text,
          s.labels, s.caption, s.generated_labels, s.generated_caption, s.summary, s.embedding_ref, s.ai_status, s.ai_provider, s.ai_model, s.ai_processed_at, s.ai_error,
          i.indexed, i.ai_processed, i.error, i.last_indexed_at, i.duplicate_of, i.source_updated_at, i.missing_at
        FROM photos p
        JOIN metadata m ON m.photo_id = p.id
        JOIN semantic s ON s.photo_id = p.id
        JOIN index_state i ON i.photo_id = p.id
        WHERE p.id = ?`
      )
      .get(photoId) as PhotoRow | undefined;

    return row ? mapPhotoRow(row) : null;
  }

  updatePhotoTags(photoId: string, labels: string[]): PhotoRecord {
    const existing = this.getPhoto(photoId);

    if (!existing) {
      throw new Error(`Photo not found: ${photoId}`);
    }

    const nextLabels = dedupeStrings(labels);
    const now = Date.now();

    const transaction = this.db.transaction(() => {
      this.db.prepare("UPDATE semantic SET labels = ? WHERE photo_id = ?").run(serializeStringArray(nextLabels), photoId);
      this.db.prepare("UPDATE photos SET updated_at = ? WHERE id = ?").run(now, photoId);
      this.db
        .prepare(
          "INSERT INTO edit_history (id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at) VALUES (?, ?, ?, ?, ?, ?, NULL)"
        )
        .run(
          createId("edit"),
          photoId,
          "labels",
          serializeStringArray(existing.semantic.labels),
          serializeStringArray(nextLabels),
          now
        );
    });

    transaction();
    return this.getPhoto(photoId) as PhotoRecord;
  }

  updatePhotoCaption(photoId: string, caption: string | null): PhotoRecord {
    const existing = this.getPhoto(photoId);

    if (!existing) {
      throw new Error(`Photo not found: ${photoId}`);
    }

    const now = Date.now();

    const transaction = this.db.transaction(() => {
      this.db.prepare("UPDATE semantic SET caption = ? WHERE photo_id = ?").run(caption, photoId);
      this.db.prepare("UPDATE photos SET updated_at = ? WHERE id = ?").run(now, photoId);
      this.db
        .prepare(
          "INSERT INTO edit_history (id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at) VALUES (?, ?, ?, ?, ?, ?, NULL)"
        )
        .run(createId("edit"), photoId, "caption", existing.semantic.caption, caption, now);
    });

    transaction();
    return this.getPhoto(photoId) as PhotoRecord;
  }

  updatePhotoSemanticEnrichment(
    photoId: string,
    updates: Partial<
      Pick<
        Semantic,
        "generatedLabels" | "generatedCaption" | "summary" | "embeddingRef" | "aiStatus" | "aiProvider" | "aiModel" | "aiProcessedAt" | "aiError"
      >
    >
  ): PhotoRecord {
    const existing = this.getPhoto(photoId);

    if (!existing) {
      throw new Error(`Photo not found: ${photoId}`);
    }

    const nextSemantic: Semantic = {
      ...existing.semantic,
      ...updates,
      generatedLabels: updates.generatedLabels ? dedupeStrings(updates.generatedLabels) : existing.semantic.generatedLabels,
      aiStatus: updates.aiStatus ? normalizeAIPipelineStatus(updates.aiStatus) : existing.semantic.aiStatus
    };
    const aiProcessed = nextSemantic.aiStatus === "completed";
    const now = Date.now();

    const transaction = this.db.transaction(() => {
      this.db
        .prepare(
          `UPDATE semantic
           SET generated_labels = ?,
               generated_caption = ?,
               summary = ?,
               embedding_ref = ?,
               ai_status = ?,
               ai_provider = ?,
               ai_model = ?,
               ai_processed_at = ?,
               ai_error = ?
           WHERE photo_id = ?`
        )
        .run(
          serializeStringArray(nextSemantic.generatedLabels),
          nextSemantic.generatedCaption,
          nextSemantic.summary,
          nextSemantic.embeddingRef,
          nextSemantic.aiStatus,
          nextSemantic.aiProvider,
          nextSemantic.aiModel,
          nextSemantic.aiProcessedAt,
          nextSemantic.aiError,
          photoId
        );

      this.db.prepare("UPDATE index_state SET ai_processed = ? WHERE photo_id = ?").run(aiProcessed ? 1 : 0, photoId);
      this.db.prepare("UPDATE photos SET updated_at = ? WHERE id = ?").run(now, photoId);
    });

    transaction();
    return this.getPhoto(photoId) as PhotoRecord;
  }

  updatePhotoDatetime(photoId: string, datetime: number | null): PhotoRecord {
    const existing = this.getPhoto(photoId);

    if (!existing) {
      throw new Error(`Photo not found: ${photoId}`);
    }

    const now = Date.now();

    const transaction = this.db.transaction(() => {
      this.db.prepare("UPDATE metadata SET datetime = ? WHERE photo_id = ?").run(datetime, photoId);
      this.db.prepare("UPDATE photos SET updated_at = ? WHERE id = ?").run(now, photoId);
      this.db
        .prepare(
          "INSERT INTO edit_history (id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at) VALUES (?, ?, ?, ?, ?, ?, NULL)"
        )
        .run(
          createId("edit"),
          photoId,
          "datetime",
          existing.metadata.datetime === null ? null : String(existing.metadata.datetime),
          datetime === null ? null : String(datetime),
          now
        );
    });

    transaction();
    return this.getPhoto(photoId) as PhotoRecord;
  }

  rollbackLatestEdit(photoId?: string): PhotoRecord | null {
    const row = this.db
      .prepare(
        `SELECT id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at
         FROM edit_history
         WHERE rolled_back_at IS NULL ${photoId ? "AND photo_id = ?" : ""}
         ORDER BY created_at DESC, rowid DESC
         LIMIT 1`
      )
      .get(...(photoId ? [photoId] : [])) as
      | {
          id: string;
          photo_id: string;
          field_name: EditHistory["fieldName"];
          previous_value: string | null;
          next_value: string | null;
          created_at: number;
          rolled_back_at: number | null;
        }
      | undefined;

    if (!row) {
      return null;
    }

    const transaction = this.db.transaction(() => {
      if (row.field_name === "labels") {
        this.db.prepare("UPDATE semantic SET labels = ? WHERE photo_id = ?").run(row.previous_value ?? "[]", row.photo_id);
      } else if (row.field_name === "caption") {
        this.db.prepare("UPDATE semantic SET caption = ? WHERE photo_id = ?").run(row.previous_value, row.photo_id);
      } else if (row.field_name === "datetime") {
        this.db
          .prepare("UPDATE metadata SET datetime = ? WHERE photo_id = ?")
          .run(row.previous_value ? Number(row.previous_value) : null, row.photo_id);
      }

      const now = Date.now();
      this.db.prepare("UPDATE photos SET updated_at = ? WHERE id = ?").run(now, row.photo_id);
      this.db.prepare("UPDATE edit_history SET rolled_back_at = ? WHERE id = ?").run(now, row.id);
    });

    transaction();
    return this.getPhoto(row.photo_id);
  }

  listEditHistory(photoId: string): EditHistory[] {
    const rows = this.db
      .prepare(
        "SELECT id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at FROM edit_history WHERE photo_id = ? ORDER BY created_at DESC, rowid DESC"
      )
      .all(photoId) as Array<{
      id: string;
      photo_id: string;
      field_name: EditHistory["fieldName"];
      previous_value: string | null;
      next_value: string | null;
      created_at: number;
      rolled_back_at: number | null;
    }>;

    return rows.map((row) => ({
      id: row.id,
      photoId: row.photo_id,
      fieldName: row.field_name,
      previousValue: row.previous_value,
      nextValue: row.next_value,
      createdAt: row.created_at,
      rolledBackAt: row.rolled_back_at
    }));
  }

  getSnapshot(): LibrarySnapshot {
    const sources = this.listLibrarySources();
    const stats = this.db
      .prepare(
        `SELECT
          COUNT(CASE WHEN missing_at IS NULL THEN 1 END) AS totalPhotos,
          SUM(CASE WHEN indexed = 1 AND missing_at IS NULL THEN 1 ELSE 0 END) AS indexedPhotos,
          SUM(CASE WHEN error IS NOT NULL AND missing_at IS NULL THEN 1 ELSE 0 END) AS erroredPhotos,
          SUM(CASE WHEN duplicate_of IS NOT NULL AND missing_at IS NULL THEN 1 ELSE 0 END) AS duplicatePhotos
        FROM index_state`
      )
      .get() as {
      totalPhotos: number | null;
      indexedPhotos: number | null;
      erroredPhotos: number | null;
      duplicatePhotos: number | null;
    };

    return {
      sources,
      stats: {
        totalPhotos: stats.totalPhotos ?? 0,
        indexedPhotos: stats.indexedPhotos ?? 0,
        erroredPhotos: stats.erroredPhotos ?? 0,
        duplicatePhotos: stats.duplicatePhotos ?? 0
      }
    };
  }

  exportBackup(settings: ChronoPicBackup["settings"]): ChronoPicBackup {
    return {
      app: "ChronoPic",
      schemaVersion: 1,
      exportedAt: Date.now(),
      settings,
      librarySources: this.listLibrarySources(),
      photos: this.listAllPhotoPayloads(),
      memories: this.listMemories(),
      memoryPhotos: this.listMemoryPhotos(),
      editHistory: this.listAllEditHistory(),
      memoryCandidates: this.listAllMemoryCandidates(),
    };
  }

  previewBackupRestore(backup: ChronoPicBackup): BackupRestorePreview {
    this.assertSupportedBackup(backup);

    const conflicts: BackupRestoreConflict[] = [];

    for (const source of backup.librarySources) {
      const existing = this.listLibrarySources().find((candidate) => candidate.id === source.id || candidate.path === source.path);
      if (existing) {
        conflicts.push({
          kind: "source",
          id: source.id,
          path: source.path,
          reason: existing.id === source.id ? "source id already exists" : "source path already exists",
        });
      }
    }

    for (const payload of backup.photos) {
      const existing = this.findPhotoConflict(payload.photo.id, payload.photo.path);
      if (existing) {
        conflicts.push({
          kind: "photo",
          id: payload.photo.id,
          path: payload.photo.path,
          reason: existing.id === payload.photo.id ? "photo id already exists" : "photo path already exists",
        });
      }
    }

    for (const memory of backup.memories) {
      if (this.getMemory(memory.id)) {
        conflicts.push({
          kind: "memory",
          id: memory.id,
          reason: "memory id already exists",
        });
      }
    }

    for (const candidate of backup.memoryCandidates) {
      const existing = this.findMemoryCandidateConflict(candidate.id, candidate.signature);
      if (existing) {
        conflicts.push({
          kind: "memoryCandidate",
          id: candidate.id,
          reason: existing.id === candidate.id ? "memory candidate id already exists" : "memory candidate signature already exists",
        });
      }
    }

    return {
      schemaVersion: backup.schemaVersion,
      sourceCount: backup.librarySources.length,
      photoCount: backup.photos.length,
      memoryCount: backup.memories.length,
      memoryPhotoCount: backup.memoryPhotos.length,
      editHistoryCount: backup.editHistory.length,
      memoryCandidateCount: backup.memoryCandidates.length,
      settingsIncluded: Boolean(backup.settings),
      conflictCount: conflicts.length,
      conflicts,
    };
  }

  restoreBackup(backup: ChronoPicBackup, options: BackupRestoreOptions = {}): BackupRestoreResult {
    this.assertSupportedBackup(backup);
    const mode = options.mode ?? "merge";
    const preview = this.previewBackupRestore(backup);

    const transaction = this.db.transaction(() => {
      if (mode === "replace") {
        this.clearRestorableData();
      }

      this.restoreLibrarySources(backup.librarySources);
      this.restorePhotos(backup.photos);
      this.restoreEditHistory(backup.editHistory);
      this.restoreMemories(backup.memories);
      this.restoreMemoryPhotos(backup.memoryPhotos);
      this.restoreMemoryCandidates(backup.memoryCandidates);
    });

    transaction();

    return {
      ...preview,
      restoredAt: Date.now(),
      restoredSourceCount: backup.librarySources.length,
      restoredPhotoCount: backup.photos.length,
      restoredMemoryCount: backup.memories.length,
      restoredMemoryPhotoCount: backup.memoryPhotos.length,
      restoredEditHistoryCount: backup.editHistory.length,
      restoredMemoryCandidateCount: backup.memoryCandidates.length,
    };
  }

  listMemoryPhotos(): MemoryPhoto[] {
    const rows = this.db
      .prepare("SELECT memory_id, photo_id, added_at FROM memory_photos ORDER BY memory_id ASC, added_at ASC")
      .all() as Array<{ memory_id: string; photo_id: string; added_at: number }>;

    return rows.map((row) => ({
      memoryId: row.memory_id,
      photoId: row.photo_id,
      addedAt: row.added_at,
    }));
  }

  private listAllEditHistory(): EditHistory[] {
    const rows = this.db
      .prepare(
        `SELECT id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at
         FROM edit_history
         ORDER BY created_at ASC`
      )
      .all() as Array<{
      id: string;
      photo_id: string;
      field_name: EditHistory["fieldName"];
      previous_value: string | null;
      next_value: string | null;
      created_at: number;
      rolled_back_at: number | null;
    }>;

    return rows.map((row) => ({
      id: row.id,
      photoId: row.photo_id,
      fieldName: row.field_name,
      previousValue: row.previous_value,
      nextValue: row.next_value,
      createdAt: row.created_at,
      rolledBackAt: row.rolled_back_at,
    }));
  }

  private listAllMemoryCandidates(): MemoryCandidate[] {
    const rows = this.db
      .prepare(
        `SELECT
          c.id,
          c.signature,
          c.title,
          c.description,
          c.reason,
          c.confidence,
          c.source,
          c.status,
          c.photo_ids,
          c.cover_photo_id,
          (
            SELECT p.thumbnail_path
            FROM photos p
            WHERE p.id = c.cover_photo_id
          ) AS cover_thumbnail_path,
          c.generated_labels,
          c.accepted_memory_id,
          c.created_at,
          c.updated_at
        FROM memory_candidates c
        ORDER BY c.updated_at DESC, c.created_at DESC`
      )
      .all() as MemoryCandidateRow[];

    return rows.map(mapMemoryCandidateRow);
  }

  private assertSupportedBackup(backup: ChronoPicBackup): void {
    if (backup.app !== "ChronoPic" || backup.schemaVersion !== 1) {
      throw new Error("Unsupported ChronoPic backup format");
    }
  }

  private findPhotoConflict(photoId: string, photoPath: string): { id: string; path: string } | null {
    const row = this.db
      .prepare("SELECT id, path FROM photos WHERE id = ? OR path = ? LIMIT 1")
      .get(photoId, photoPath) as { id: string; path: string } | undefined;
    return row ?? null;
  }

  private findMemoryCandidateConflict(candidateId: string, signature: string): { id: string; signature: string } | null {
    const row = this.db
      .prepare("SELECT id, signature FROM memory_candidates WHERE id = ? OR signature = ? LIMIT 1")
      .get(candidateId, signature) as { id: string; signature: string } | undefined;
    return row ?? null;
  }

  private clearRestorableData(): void {
    this.db.prepare("DELETE FROM memory_candidates").run();
    this.db.prepare("DELETE FROM memory_photos").run();
    this.db.prepare("DELETE FROM memories").run();
    this.db.prepare("DELETE FROM edit_history").run();
    this.db.prepare("DELETE FROM index_state").run();
    this.db.prepare("DELETE FROM semantic").run();
    this.db.prepare("DELETE FROM metadata").run();
    this.db.prepare("DELETE FROM photos").run();
    this.db.prepare("DELETE FROM library_sources").run();
  }

  private restoreLibrarySources(sources: LibrarySource[]): void {
    const insertSource = this.db.prepare(
      `INSERT OR REPLACE INTO library_sources (id, path, is_active, created_at, updated_at, last_scan_at)
       VALUES (?, ?, ?, ?, ?, ?)`
    );

    for (const source of sources) {
      insertSource.run(source.id, source.path, source.isActive ? 1 : 0, source.createdAt, source.updatedAt, source.lastScanAt);
    }
  }

  private restorePhotos(photos: UpsertPhotoPayload[]): void {
    const insertPhoto = this.db.prepare(
      `INSERT OR REPLACE INTO photos (id, path, hash, size, mime, thumbnail_path, favorite, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    );
    const insertMetadata = this.db.prepare(
      `INSERT OR REPLACE INTO metadata (photo_id, datetime, lat, lng, camera, confidence, original_datetime_text)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    );
    const insertSemantic = this.db.prepare(
      `INSERT OR REPLACE INTO semantic (
         photo_id, labels, caption, generated_labels, generated_caption, summary, embedding_ref,
         ai_status, ai_provider, ai_model, ai_processed_at, ai_error
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    );
    const insertIndexState = this.db.prepare(
      `INSERT OR REPLACE INTO index_state (
         photo_id, indexed, ai_processed, error, last_indexed_at, duplicate_of, source_updated_at, missing_at
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    );

    for (const payload of photos) {
      insertPhoto.run(
        payload.photo.id,
        payload.photo.path,
        payload.photo.hash,
        payload.photo.size,
        payload.photo.mime,
        payload.photo.thumbnailPath,
        payload.photo.favorite ? 1 : 0,
        payload.photo.createdAt,
        payload.photo.updatedAt
      );
      insertMetadata.run(
        payload.metadata.photoId,
        payload.metadata.datetime,
        payload.metadata.lat,
        payload.metadata.lng,
        payload.metadata.camera,
        payload.metadata.confidence,
        payload.metadata.originalDatetimeText
      );
      insertSemantic.run(
        payload.semantic.photoId,
        serializeStringArray(payload.semantic.labels),
        payload.semantic.caption,
        serializeStringArray(payload.semantic.generatedLabels),
        payload.semantic.generatedCaption,
        payload.semantic.summary,
        payload.semantic.embeddingRef,
        payload.semantic.aiStatus,
        payload.semantic.aiProvider,
        payload.semantic.aiModel,
        payload.semantic.aiProcessedAt,
        payload.semantic.aiError
      );
      insertIndexState.run(
        payload.indexState.photoId,
        payload.indexState.indexed ? 1 : 0,
        payload.indexState.aiProcessed ? 1 : 0,
        payload.indexState.error,
        payload.indexState.lastIndexedAt,
        payload.indexState.duplicateOf,
        payload.indexState.sourceUpdatedAt,
        payload.indexState.missingAt
      );
    }
  }

  private restoreEditHistory(history: EditHistory[]): void {
    const insertEdit = this.db.prepare(
      `INSERT OR REPLACE INTO edit_history (id, photo_id, field_name, previous_value, next_value, created_at, rolled_back_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    );

    for (const edit of history) {
      insertEdit.run(
        edit.id,
        edit.photoId,
        edit.fieldName,
        edit.previousValue,
        edit.nextValue,
        edit.createdAt,
        edit.rolledBackAt
      );
    }
  }

  private restoreMemories(memories: Memory[]): void {
    const insertMemory = this.db.prepare(
      `INSERT OR REPLACE INTO memories (
         id, name, description, cover_photo_id, generated_name, generated_description, generated_labels,
         ai_status, ai_provider, ai_model, ai_processed_at, ai_error, source, created_at, updated_at
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    );

    for (const memory of memories) {
      insertMemory.run(
        memory.id,
        memory.name,
        memory.description,
        memory.coverPhotoId,
        memory.generatedName,
        memory.generatedDescription,
        serializeStringArray(memory.generatedLabels),
        memory.aiStatus,
        memory.aiProvider,
        memory.aiModel,
        memory.aiProcessedAt,
        memory.aiError,
        memory.source,
        memory.createdAt,
        memory.updatedAt
      );
    }
  }

  private restoreMemoryPhotos(memoryPhotos: MemoryPhoto[]): void {
    const insertMemoryPhoto = this.db.prepare(
      "INSERT OR REPLACE INTO memory_photos (memory_id, photo_id, added_at) VALUES (?, ?, ?)"
    );

    for (const memoryPhoto of memoryPhotos) {
      insertMemoryPhoto.run(memoryPhoto.memoryId, memoryPhoto.photoId, memoryPhoto.addedAt);
    }
  }

  private restoreMemoryCandidates(candidates: MemoryCandidate[]): void {
    const insertCandidate = this.db.prepare(
      `INSERT OR REPLACE INTO memory_candidates (
         id, signature, title, description, reason, confidence, source, status, photo_ids,
         cover_photo_id, generated_labels, accepted_memory_id, created_at, updated_at
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    );

    for (const candidate of candidates) {
      insertCandidate.run(
        candidate.id,
        candidate.signature,
        candidate.title,
        candidate.description,
        candidate.reason,
        candidate.confidence,
        candidate.source,
        candidate.status,
        serializeStringArray(candidate.photoIds),
        candidate.coverPhotoId,
        serializeStringArray(candidate.generatedLabels),
        candidate.acceptedMemoryId,
        candidate.createdAt,
        candidate.updatedAt
      );
    }
  }

  // ─── Favorite ────────────────────────────────────────────────────────────────

  updatePhotoFavorite(photoId: string, favorite: boolean): PhotoRecord {
    const now = Date.now();
    this.db.prepare("UPDATE photos SET favorite = ?, updated_at = ? WHERE id = ?").run(favorite ? 1 : 0, now, photoId);
    return this.getPhoto(photoId) as PhotoRecord;
  }

  getSemanticQueueStats(): SemanticQueueStats {
    const rows = this.db
      .prepare(
        `SELECT s.ai_status AS ai_status, COUNT(*) AS total
         FROM semantic s
         GROUP BY s.ai_status`
      )
      .all() as Array<{ ai_status: string; total: number }>;

    const stats: SemanticQueueStats = {
      disabled: 0,
      pending: 0,
      processing: 0,
      completed: 0,
      failed: 0,
    };

    for (const row of rows) {
      const status = normalizeAIPipelineStatus(row.ai_status);
      stats[status] += row.total;
    }

    return stats;
  }

  recoverInterruptedAIProcessing(): {
    photoCount: number;
    memoryCount: number;
  } {
    const now = Date.now();
    const photoResult = this.db
      .prepare(
        `UPDATE semantic
         SET ai_status = 'pending',
             ai_error = COALESCE(ai_error, 'Recovered after app restart'),
             ai_processed_at = COALESCE(ai_processed_at, ?)
         WHERE ai_status = 'processing'`
      )
      .run(now);

    const memoryResult = this.db
      .prepare(
        `UPDATE memories
         SET ai_status = 'pending',
             ai_error = COALESCE(ai_error, 'Recovered after app restart'),
             ai_processed_at = COALESCE(ai_processed_at, ?)
         WHERE ai_status = 'processing'`
      )
      .run(now);

    return {
      photoCount: photoResult.changes,
      memoryCount: memoryResult.changes,
    };
  }

  // ─── Memory ─────────────────────────────────────────────────────────────────

  listMemories(): Memory[] {
    const rows = this.db
      .prepare(
        `SELECT
          m.id,
          m.name,
          m.description,
          m.cover_photo_id,
          m.generated_name,
          m.generated_description,
          m.generated_labels,
          m.ai_status,
          m.ai_provider,
          m.ai_model,
          m.ai_processed_at,
          m.ai_error,
          m.source,
          m.created_at,
          m.updated_at,
          (
            SELECT COUNT(*)
            FROM memory_photos mp_count
            WHERE mp_count.memory_id = m.id
          ) AS photo_count,
          (
            SELECT p.thumbnail_path
            FROM photos p
            WHERE p.id = COALESCE(
              m.cover_photo_id,
              (
                SELECT mp_cover.photo_id
                FROM memory_photos mp_cover
                WHERE mp_cover.memory_id = m.id
                ORDER BY mp_cover.added_at DESC
                LIMIT 1
              )
            )
          ) AS cover_thumbnail_path
        FROM memories m
        ORDER BY m.updated_at DESC, m.created_at DESC`
      )
      .all() as Array<{
      id: string;
      name: string;
      description: string | null;
      cover_photo_id: string | null;
      generated_name: string | null;
      generated_description: string | null;
      generated_labels: string;
      ai_status: Semantic["aiStatus"];
      ai_provider: string | null;
      ai_model: string | null;
      ai_processed_at: number | null;
      ai_error: string | null;
      cover_thumbnail_path: string | null;
      photo_count: number;
      source: MemorySource;
      created_at: number;
      updated_at: number;
    }>;

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      description: row.description,
      coverPhotoId: row.cover_photo_id,
      coverThumbnailPath: row.cover_thumbnail_path,
      photoCount: row.photo_count,
      generatedName: row.generated_name,
      generatedDescription: row.generated_description,
      generatedLabels: parseStringArray(row.generated_labels),
      aiStatus: normalizeAIPipelineStatus(row.ai_status),
      aiProvider: row.ai_provider,
      aiModel: row.ai_model,
      aiProcessedAt: row.ai_processed_at,
      aiError: row.ai_error,
      source: row.source,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
  }

  createMemory(name: string, description: string | null, source: MemorySource = "manual"): Memory {
    const now = Date.now();
    const memory: Memory = {
      id: createId("mem"),
      name,
      description,
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
      source,
      createdAt: now,
      updatedAt: now,
    };
    this.db
      .prepare(
        "INSERT INTO memories (id, name, description, cover_photo_id, source, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
      )
      .run(memory.id, memory.name, memory.description, memory.coverPhotoId, memory.source, memory.createdAt, memory.updatedAt);
    return memory;
  }

  getMemory(memoryId: string): Memory | null {
    return this.listMemories().find((memory) => memory.id === memoryId) ?? null;
  }

  updateMemory(memoryId: string, updates: { name?: string; description?: string | null; coverPhotoId?: string | null }): Memory {
    const current = this.getMemory(memoryId);

    if (!current) {
      throw new Error(`Memory not found: ${memoryId}`);
    }

    const next = {
      name: updates.name ?? current.name,
      description: updates.description === undefined ? current.description : updates.description,
      coverPhotoId: updates.coverPhotoId === undefined ? current.coverPhotoId : updates.coverPhotoId,
      updatedAt: Date.now(),
    };

    this.db
      .prepare(
        `UPDATE memories
         SET name = ?, description = ?, cover_photo_id = ?, updated_at = ?
         WHERE id = ?`
      )
      .run(next.name, next.description, next.coverPhotoId, next.updatedAt, memoryId);

    return this.getMemory(memoryId) as Memory;
  }

  updateMemorySemanticEnrichment(
    memoryId: string,
    updates: Partial<
      Pick<
        Memory,
        "generatedName" | "generatedDescription" | "generatedLabels" | "aiStatus" | "aiProvider" | "aiModel" | "aiProcessedAt" | "aiError"
      >
    >
  ): Memory {
    const current = this.getMemory(memoryId);

    if (!current) {
      throw new Error(`Memory not found: ${memoryId}`);
    }

    const next = {
      generatedName: updates.generatedName ?? current.generatedName,
      generatedDescription: updates.generatedDescription ?? current.generatedDescription,
      generatedLabels: updates.generatedLabels ?? current.generatedLabels,
      aiStatus: updates.aiStatus ?? current.aiStatus,
      aiProvider: updates.aiProvider ?? current.aiProvider,
      aiModel: updates.aiModel ?? current.aiModel,
      aiProcessedAt: updates.aiProcessedAt ?? current.aiProcessedAt,
      aiError: updates.aiError ?? current.aiError,
    };

    this.db
      .prepare(
        `UPDATE memories
         SET generated_name = ?,
             generated_description = ?,
             generated_labels = ?,
             ai_status = ?,
             ai_provider = ?,
             ai_model = ?,
             ai_processed_at = ?,
             ai_error = ?,
             updated_at = ?
         WHERE id = ?`
      )
      .run(
        next.generatedName,
        next.generatedDescription,
        serializeStringArray(next.generatedLabels),
        next.aiStatus,
        next.aiProvider,
        next.aiModel,
        next.aiProcessedAt,
        next.aiError,
        Date.now(),
        memoryId
      );

    return this.getMemory(memoryId) as Memory;
  }

  deleteMemory(memoryId: string): void {
    this.db.prepare("DELETE FROM memories WHERE id = ?").run(memoryId);
  }

  addPhotoToMemory(memoryId: string, photoId: string): void {
    const now = Date.now();
    this.db
      .prepare(
        "INSERT OR IGNORE INTO memory_photos (memory_id, photo_id, added_at) VALUES (?, ?, ?)"
      )
      .run(memoryId, photoId, now);
    this.db.prepare("UPDATE memories SET updated_at = ? WHERE id = ?").run(now, memoryId);
  }

  removePhotoFromMemory(memoryId: string, photoId: string): void {
    this.db.prepare("DELETE FROM memory_photos WHERE memory_id = ? AND photo_id = ?").run(memoryId, photoId);
    this.db
      .prepare(
        `UPDATE memories
         SET cover_photo_id = CASE WHEN cover_photo_id = ? THEN NULL ELSE cover_photo_id END,
             updated_at = ?
         WHERE id = ?`
      )
      .run(photoId, Date.now(), memoryId);
  }

  listMemoriesByPhoto(photoId: string): Memory[] {
    const rows = this.db
      .prepare(
        `SELECT
          m.id,
          m.name,
          m.description,
          m.cover_photo_id,
          m.generated_name,
          m.generated_description,
          m.generated_labels,
          m.ai_status,
          m.ai_provider,
          m.ai_model,
          m.ai_processed_at,
          m.ai_error,
          m.source,
          m.created_at,
          m.updated_at,
          (
            SELECT COUNT(*)
            FROM memory_photos mp_count
            WHERE mp_count.memory_id = m.id
          ) AS photo_count,
          (
            SELECT p.thumbnail_path
            FROM photos p
            WHERE p.id = COALESCE(
              m.cover_photo_id,
              (
                SELECT mp_cover.photo_id
                FROM memory_photos mp_cover
                WHERE mp_cover.memory_id = m.id
                ORDER BY mp_cover.added_at DESC
                LIMIT 1
              )
            )
          ) AS cover_thumbnail_path
        FROM memories m
        JOIN memory_photos mp ON mp.memory_id = m.id
        WHERE mp.photo_id = ?
        ORDER BY m.updated_at DESC, m.created_at DESC`
      )
      .all(photoId) as Array<{
      id: string;
      name: string;
      description: string | null;
      cover_photo_id: string | null;
      generated_name: string | null;
      generated_description: string | null;
      generated_labels: string;
      ai_status: Semantic["aiStatus"];
      ai_provider: string | null;
      ai_model: string | null;
      ai_processed_at: number | null;
      ai_error: string | null;
      cover_thumbnail_path: string | null;
      photo_count: number;
      source: MemorySource;
      created_at: number;
      updated_at: number;
    }>;

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      description: row.description,
      coverPhotoId: row.cover_photo_id,
      coverThumbnailPath: row.cover_thumbnail_path,
      photoCount: row.photo_count,
      generatedName: row.generated_name,
      generatedDescription: row.generated_description,
      generatedLabels: parseStringArray(row.generated_labels),
      aiStatus: normalizeAIPipelineStatus(row.ai_status),
      aiProvider: row.ai_provider,
      aiModel: row.ai_model,
      aiProcessedAt: row.ai_processed_at,
      aiError: row.ai_error,
      source: row.source,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
  }

  listPhotosByMemory(memoryId: string, filter: PhotoFilter = {}): PhotoRecord[] {
    return this.listPhotos({ ...filter, memoryId });
  }

  listMemoryCandidates(status: MemoryCandidateStatus = "pending"): MemoryCandidate[] {
    const rows = this.db
      .prepare(
        `SELECT
          c.id,
          c.signature,
          c.title,
          c.description,
          c.reason,
          c.confidence,
          c.source,
          c.status,
          c.photo_ids,
          c.cover_photo_id,
          p.thumbnail_path AS cover_thumbnail_path,
          c.generated_labels,
          c.accepted_memory_id,
          c.created_at,
          c.updated_at
        FROM memory_candidates c
        LEFT JOIN photos p ON p.id = c.cover_photo_id
        WHERE c.status = ?
        ORDER BY c.confidence DESC, c.updated_at DESC`
      )
      .all(status) as MemoryCandidateRow[];

    return rows.map(mapMemoryCandidateRow);
  }

  upsertMemoryCandidate(input: MemoryCandidateInput): MemoryCandidate | null {
    const existing = this.db
      .prepare(
        `SELECT
          c.id,
          c.signature,
          c.title,
          c.description,
          c.reason,
          c.confidence,
          c.source,
          c.status,
          c.photo_ids,
          c.cover_photo_id,
          p.thumbnail_path AS cover_thumbnail_path,
          c.generated_labels,
          c.accepted_memory_id,
          c.created_at,
          c.updated_at
        FROM memory_candidates c
        LEFT JOIN photos p ON p.id = c.cover_photo_id
        WHERE c.signature = ?`
      )
      .get(input.signature) as MemoryCandidateRow | undefined;

    const now = Date.now();
    const normalizedPhotoIds = dedupeStrings(input.photoIds).sort();

    if (existing) {
      if (existing.status !== "pending") {
        return null;
      }

      this.db
        .prepare(
          `UPDATE memory_candidates
           SET title = ?,
               description = ?,
               reason = ?,
               confidence = ?,
               source = ?,
               photo_ids = ?,
               cover_photo_id = ?,
               generated_labels = ?,
               updated_at = ?
           WHERE id = ?`
        )
        .run(
          input.title,
          input.description ?? null,
          input.reason,
          input.confidence,
          input.source,
          serializeStringArray(normalizedPhotoIds),
          input.coverPhotoId ?? normalizedPhotoIds[0] ?? null,
          serializeStringArray(input.generatedLabels ?? []),
          now,
          existing.id
        );

      return this.getMemoryCandidate(existing.id);
    }

    const id = createId("mc");
    this.db
      .prepare(
        `INSERT INTO memory_candidates (
          id,
          signature,
          title,
          description,
          reason,
          confidence,
          source,
          status,
          photo_ids,
          cover_photo_id,
          generated_labels,
          accepted_memory_id,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?, NULL, ?, ?)`
      )
      .run(
        id,
        input.signature,
        input.title,
        input.description ?? null,
        input.reason,
        input.confidence,
        input.source,
        serializeStringArray(normalizedPhotoIds),
        input.coverPhotoId ?? normalizedPhotoIds[0] ?? null,
        serializeStringArray(input.generatedLabels ?? []),
        now,
        now
      );

    return this.getMemoryCandidate(id);
  }

  getMemoryCandidate(candidateId: string): MemoryCandidate | null {
    const row = this.db
      .prepare(
        `SELECT
          c.id,
          c.signature,
          c.title,
          c.description,
          c.reason,
          c.confidence,
          c.source,
          c.status,
          c.photo_ids,
          c.cover_photo_id,
          p.thumbnail_path AS cover_thumbnail_path,
          c.generated_labels,
          c.accepted_memory_id,
          c.created_at,
          c.updated_at
        FROM memory_candidates c
        LEFT JOIN photos p ON p.id = c.cover_photo_id
        WHERE c.id = ?`
      )
      .get(candidateId) as MemoryCandidateRow | undefined;

    return row ? mapMemoryCandidateRow(row) : null;
  }

  rejectMemoryCandidate(candidateId: string): MemoryCandidate {
    const now = Date.now();
    this.db.prepare("UPDATE memory_candidates SET status = 'rejected', updated_at = ? WHERE id = ?").run(now, candidateId);
    const candidate = this.getMemoryCandidate(candidateId);
    if (!candidate) {
      throw new Error(`Memory candidate not found: ${candidateId}`);
    }
    return candidate;
  }

  acceptMemoryCandidate(candidateId: string, input: AcceptMemoryCandidateInput = {}): Memory {
    const candidate = this.getMemoryCandidate(candidateId);
    if (!candidate) {
      throw new Error(`Memory candidate not found: ${candidateId}`);
    }
    if (candidate.status !== "pending") {
      throw new Error(`Memory candidate is not pending: ${candidateId}`);
    }

    const photoIds = dedupeStrings(input.photoIds ?? candidate.photoIds).filter((photoId) => candidate.photoIds.includes(photoId));
    if (photoIds.length === 0) {
      throw new Error("Cannot accept an empty memory candidate");
    }

    const memory = this.createMemory(input.name?.trim() || candidate.title, input.description ?? candidate.description, "ai");
    const addPhoto = this.db.prepare("INSERT OR IGNORE INTO memory_photos (memory_id, photo_id, added_at) VALUES (?, ?, ?)");
    const now = Date.now();
    const transaction = this.db.transaction(() => {
      for (const photoId of photoIds) {
        addPhoto.run(memory.id, photoId, now);
      }
      this.db
        .prepare("UPDATE memories SET cover_photo_id = ?, updated_at = ? WHERE id = ?")
        .run(photoIds.includes(candidate.coverPhotoId ?? "") ? candidate.coverPhotoId : photoIds[0], now, memory.id);
      this.db
        .prepare("UPDATE memory_candidates SET status = 'accepted', accepted_memory_id = ?, updated_at = ? WHERE id = ?")
        .run(memory.id, now, candidateId);
    });
    transaction();

    return this.getMemory(memory.id) as Memory;
  }

  countMappablePhotos(filter: PhotoFilter = {}): number {
    const resolvedFilter = { ...DEFAULT_FILTER, ...filter };
    const clauses: string[] = ["m.lat IS NOT NULL", "m.lng IS NOT NULL", "i.missing_at IS NULL"];
    const params: unknown[] = [];

    if (resolvedFilter.query) {
      pushTextSearchClause(clauses, params, `%${resolvedFilter.query}%`);
    }

    if (resolvedFilter.mimePrefix) {
      clauses.push("p.mime LIKE ?");
      params.push(`${resolvedFilter.mimePrefix}%`);
    }

    if (resolvedFilter.tag) {
      clauses.push("(s.labels LIKE ? OR s.generated_labels LIKE ?)");
      params.push(`%${resolvedFilter.tag}%`, `%${resolvedFilter.tag}%`);
    }

    if (resolvedFilter.aiStatus) {
      const statuses = Array.isArray(resolvedFilter.aiStatus) ? resolvedFilter.aiStatus : [resolvedFilter.aiStatus];
      if (statuses.length > 0) {
        clauses.push(`s.ai_status IN (${statuses.map(() => "?").join(", ")})`);
        params.push(...statuses.map((status) => normalizeAIPipelineStatus(status)));
      }
    }

    if (typeof resolvedFilter.favorite === "boolean") {
      clauses.push("p.favorite = ?");
      params.push(resolvedFilter.favorite ? 1 : 0);
    }

    if (resolvedFilter.memoryId) {
      clauses.push("mp.memory_id = ?");
      params.push(resolvedFilter.memoryId);
    }

    if (typeof resolvedFilter.indexed === "boolean") {
      clauses.push("i.indexed = ?");
      params.push(resolvedFilter.indexed ? 1 : 0);
    }

    if (resolvedFilter.hasError) {
      clauses.push("i.error IS NOT NULL");
    }

    if (resolvedFilter.fromDatetime) {
      clauses.push("m.datetime >= ?");
      params.push(resolvedFilter.fromDatetime);
    }

    if (resolvedFilter.toDatetime) {
      clauses.push("m.datetime <= ?");
      params.push(resolvedFilter.toDatetime);
    }

    const row = this.db
      .prepare(
        `SELECT COUNT(*) AS total
         FROM photos p
         JOIN metadata m ON m.photo_id = p.id
         JOIN semantic s ON s.photo_id = p.id
         JOIN index_state i ON i.photo_id = p.id
         ${resolvedFilter.memoryId ? "LEFT JOIN memory_photos mp ON mp.photo_id = p.id" : ""}
         WHERE ${clauses.join(" AND ")}`
      )
      .get(...params) as { total: number };

    return row.total;
  }

  listPlaceGroups(query: PlaceGroupQuery = {}): PlaceGroup[] {
    const resolvedFilter = { ...DEFAULT_FILTER, ...(query.filter ?? {}) };
    const precision = Math.min(Math.max(query.precision ?? 2, 0), 6);
    const limit = query.limit ?? 200;
    const clauses: string[] = ["m.lat IS NOT NULL", "m.lng IS NOT NULL", "i.missing_at IS NULL"];
    const params: unknown[] = [];

    if (resolvedFilter.query) {
      pushTextSearchClause(clauses, params, `%${resolvedFilter.query}%`);
    }

    if (resolvedFilter.mimePrefix) {
      clauses.push("p.mime LIKE ?");
      params.push(`${resolvedFilter.mimePrefix}%`);
    }

    if (resolvedFilter.tag) {
      clauses.push("(s.labels LIKE ? OR s.generated_labels LIKE ?)");
      params.push(`%${resolvedFilter.tag}%`, `%${resolvedFilter.tag}%`);
    }

    if (typeof resolvedFilter.favorite === "boolean") {
      clauses.push("p.favorite = ?");
      params.push(resolvedFilter.favorite ? 1 : 0);
    }

    if (resolvedFilter.memoryId) {
      clauses.push("mp.memory_id = ?");
      params.push(resolvedFilter.memoryId);
    }

    if (typeof resolvedFilter.indexed === "boolean") {
      clauses.push("i.indexed = ?");
      params.push(resolvedFilter.indexed ? 1 : 0);
    }

    if (resolvedFilter.hasError) {
      clauses.push("i.error IS NOT NULL");
    }

    if (resolvedFilter.fromDatetime) {
      clauses.push("m.datetime >= ?");
      params.push(resolvedFilter.fromDatetime);
    }

    if (resolvedFilter.toDatetime) {
      clauses.push("m.datetime <= ?");
      params.push(resolvedFilter.toDatetime);
    }

    if (query.bounds) {
      clauses.push("m.lat BETWEEN ? AND ?");
      clauses.push("m.lng BETWEEN ? AND ?");
      params.push(query.bounds.south, query.bounds.north, query.bounds.west, query.bounds.east);
    }

    const rows = this.db
      .prepare(
        `SELECT
          ROUND(m.lat, ${precision}) AS bucket_lat,
          ROUND(m.lng, ${precision}) AS bucket_lng,
          COUNT(*) AS photo_count,
          MIN(m.datetime) AS from_datetime,
          MAX(m.datetime) AS to_datetime,
          MAX(p.id) AS representative_photo_id,
          MAX(p.thumbnail_path) AS representative_thumbnail_path
        FROM photos p
        JOIN metadata m ON m.photo_id = p.id
        JOIN semantic s ON s.photo_id = p.id
        JOIN index_state i ON i.photo_id = p.id
        ${resolvedFilter.memoryId ? "LEFT JOIN memory_photos mp ON mp.photo_id = p.id" : ""}
        WHERE ${clauses.join(" AND ")}
        GROUP BY bucket_lat, bucket_lng
        ORDER BY photo_count DESC, to_datetime DESC
        LIMIT ?`
      )
      .all(...params, limit) as Array<{
      bucket_lat: number;
      bucket_lng: number;
      photo_count: number;
      from_datetime: number | null;
      to_datetime: number | null;
      representative_photo_id: string | null;
      representative_thumbnail_path: string | null;
    }>;

    return rows.map((row) => ({
      id: `${row.bucket_lat},${row.bucket_lng}`,
      centerLat: row.bucket_lat,
      centerLng: row.bucket_lng,
      photoCount: row.photo_count,
      representativePhotoId: row.representative_photo_id,
      representativeThumbnailPath: row.representative_thumbnail_path,
      fromDatetime: row.from_datetime,
      toDatetime: row.to_datetime,
    }));
  }
}

export { SCHEMA_SQL } from "./schema.js";
