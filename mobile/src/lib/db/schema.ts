export const SCHEMA_VERSION = 1;

export const CREATE_META = `
CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);
`;

export const CREATE_PROFILE = `
CREATE TABLE IF NOT EXISTS profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  user_id TEXT NOT NULL,
  display_name TEXT,
  gender TEXT,
  date_of_birth TEXT,
  photo_path TEXT,
  color_id TEXT,
  onboarding_step INTEGER NOT NULL DEFAULT 0,
  onboarding_completed_at TEXT,
  photo_local_uri TEXT,
  photo_pending INTEGER NOT NULL DEFAULT 0,
  dirty INTEGER NOT NULL DEFAULT 0,
  last_synced_at TEXT,
  remote_updated_at TEXT
);
`;

export const CREATE_OUTBOX = `
CREATE TABLE IF NOT EXISTS outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  op TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error_at TEXT,
  last_error_message TEXT
);
`;

export const CREATE_OUTBOX_INDEX = `
CREATE INDEX IF NOT EXISTS idx_outbox_created ON outbox (created_at ASC);
`;
