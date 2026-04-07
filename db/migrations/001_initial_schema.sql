-- Migration 001: initial schema
-- Tables: storage_sources, photos
-- Indexes: file_size, hash_partial, hash_full

CREATE TABLE IF NOT EXISTS storage_sources (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT    NOT NULL,
    type         TEXT    NOT NULL CHECK (type IN ('nas_smb', 'google_drive')),
    path         TEXT,                  -- local mount path (NAS); NULL for cloud
    credentials  TEXT,                  -- JSON blob for OAuth tokens etc.
    last_scanned TIMESTAMP
);

CREATE TABLE IF NOT EXISTS photos (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id    INTEGER NOT NULL REFERENCES storage_sources(id) ON DELETE CASCADE,
    file_path    TEXT    NOT NULL,
    file_name    TEXT    NOT NULL,
    file_size    INTEGER NOT NULL,
    created_at   TIMESTAMP,
    hash_partial TEXT,
    hash_full    TEXT,
    scanned_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (source_id, file_path)
);

-- Indexes for fast duplicate detection (group by size, then hash)
CREATE INDEX IF NOT EXISTS idx_photos_file_size    ON photos (file_size);
CREATE INDEX IF NOT EXISTS idx_photos_hash_partial ON photos (hash_partial);
CREATE INDEX IF NOT EXISTS idx_photos_hash_full    ON photos (hash_full);
