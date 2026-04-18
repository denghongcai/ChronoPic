export const SCHEMA_SQL = `
PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS library_sources (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  last_scan_at INTEGER
);

CREATE TABLE IF NOT EXISTS photos (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  hash TEXT,
  size INTEGER NOT NULL,
  mime TEXT NOT NULL,
  thumbnail_path TEXT,
  favorite INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS metadata (
  photo_id TEXT PRIMARY KEY REFERENCES photos(id) ON DELETE CASCADE,
  datetime INTEGER,
  lat REAL,
  lng REAL,
  camera TEXT,
  confidence REAL NOT NULL DEFAULT 0,
  original_datetime_text TEXT
);

CREATE TABLE IF NOT EXISTS semantic (
  photo_id TEXT PRIMARY KEY REFERENCES photos(id) ON DELETE CASCADE,
  labels TEXT NOT NULL DEFAULT '[]',
  caption TEXT,
  embedding_ref TEXT,
  ai_status TEXT NOT NULL DEFAULT 'disabled'
);

CREATE TABLE IF NOT EXISTS index_state (
  photo_id TEXT PRIMARY KEY REFERENCES photos(id) ON DELETE CASCADE,
  indexed INTEGER NOT NULL DEFAULT 0,
  ai_processed INTEGER NOT NULL DEFAULT 0,
  error TEXT,
  last_indexed_at INTEGER,
  duplicate_of TEXT REFERENCES photos(id)
);

CREATE TABLE IF NOT EXISTS edit_history (
  id TEXT PRIMARY KEY,
  photo_id TEXT NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
  field_name TEXT NOT NULL,
  previous_value TEXT,
  next_value TEXT,
  created_at INTEGER NOT NULL,
  rolled_back_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_library_sources_path ON library_sources(path);
CREATE INDEX IF NOT EXISTS idx_photos_hash ON photos(hash);
CREATE INDEX IF NOT EXISTS idx_metadata_datetime ON metadata(datetime);
CREATE INDEX IF NOT EXISTS idx_index_state_error ON index_state(error);
CREATE INDEX IF NOT EXISTS idx_index_state_duplicate ON index_state(duplicate_of);
CREATE INDEX IF NOT EXISTS idx_edit_history_photo_created ON edit_history(photo_id, created_at DESC);

CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  cover_photo_id TEXT REFERENCES photos(id) ON DELETE SET NULL,
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
`;
