import * as SQLite from 'expo-sqlite';

import { log } from '@/lib/log';

import { CREATE_META, CREATE_OUTBOX, CREATE_OUTBOX_INDEX, CREATE_PROFILE, SCHEMA_VERSION } from './schema';

let db: SQLite.SQLiteDatabase | null = null;
let openedDbName: string | null = null;

function dbFileName(userId: string): string {
  return `waytwo-${userId}.db`;
}

async function ensureSchema(database: SQLite.SQLiteDatabase): Promise<void> {
  await database.execAsync(`
    ${CREATE_META}
    ${CREATE_PROFILE}
    ${CREATE_OUTBOX}
    ${CREATE_OUTBOX_INDEX}
  `);
  const row = await database.getFirstAsync<{ value: string }>(
    `SELECT value FROM meta WHERE key = 'schema_version'`,
  );
  const v = row ? Number.parseInt(row.value, 10) : 0;
  if (v < SCHEMA_VERSION) {
    log.debug('SQLite schema migrate', { from: v, to: SCHEMA_VERSION });
    await database.runAsync(
      `INSERT OR REPLACE INTO meta (key, value) VALUES ('schema_version', ?)`,
      String(SCHEMA_VERSION),
    );
  }
}

export async function openProfileDb(userId: string): Promise<SQLite.SQLiteDatabase> {
  if (db && openedDbName === dbFileName(userId)) {
    return db;
  }
  if (db) {
    await closeAndWipe();
  }
  const name = dbFileName(userId);
  log.debug('SQLite open', { name });
  const next = await SQLite.openDatabaseAsync(name);
  await ensureSchema(next);
  db = next;
  openedDbName = name;
  return next;
}

export function getOpenedDb(): SQLite.SQLiteDatabase | null {
  return db;
}

export async function closeAndWipe(): Promise<void> {
  if (db) {
    try {
      await db.closeAsync();
    } catch (e) {
      log.warn('SQLite close failed', { message: e instanceof Error ? e.message : String(e) });
    }
    db = null;
  }
  if (openedDbName) {
    try {
      await SQLite.deleteDatabaseAsync(openedDbName);
      log.debug('SQLite deleted', { name: openedDbName });
    } catch (e) {
      log.warn('SQLite deleteDatabase failed', { message: e instanceof Error ? e.message : String(e) });
    }
    openedDbName = null;
  }
}
