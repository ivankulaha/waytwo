import type * as SQLite from 'expo-sqlite';

import { readAsStringAsync } from 'expo-file-system';

import { expectedAvatarObjectPath } from '@/lib/avatar-path';
import { applyRemoteProfile, getProfile } from '@/lib/db/profile-repo';
import { patchProfile, postProfileComplete } from '@/lib/profile-api';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';

export const OUTBOX_OP = {
  PATCH_PROFILE: 'PATCH_PROFILE',
  UPLOAD_AVATAR: 'UPLOAD_AVATAR',
  COMPLETE_ONBOARDING: 'COMPLETE_ONBOARDING',
} as const;

export type OutboxRow = {
  id: number;
  op: string;
  entity_id: string;
  payload_json: string;
  created_at: string;
  attempts: number;
  last_error_at: string | null;
  last_error_message: string | null;
};

let flushing = false;

export async function enqueueOutbox(
  database: SQLite.SQLiteDatabase,
  op: string,
  entityId: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await database.runAsync('DELETE FROM outbox WHERE op = ? AND entity_id = ?', op, entityId);
  await database.runAsync(
    `INSERT INTO outbox (op, entity_id, payload_json, created_at) VALUES (?, ?, ?, ?)`,
    op,
    entityId,
    JSON.stringify(payload),
    new Date().toISOString(),
  );
  log.debug('outbox enqueue', { op, entityId });
}

export async function enqueuePatchProfileMerged(
  database: SQLite.SQLiteDatabase,
  partial: Record<string, unknown>,
): Promise<void> {
  const existing = await database.getFirstAsync<{ payload_json: string }>(
    `SELECT payload_json FROM outbox WHERE op = ? AND entity_id = ?`,
    OUTBOX_OP.PATCH_PROFILE,
    'profile',
  );
  const prev = existing ? (JSON.parse(existing.payload_json) as Record<string, unknown>) : {};
  const merged = { ...prev, ...partial };
  await enqueueOutbox(database, OUTBOX_OP.PATCH_PROFILE, 'profile', merged);
}

async function getAccessToken(): Promise<string | null> {
  const { data, error } = await supabase.auth.getSession();
  if (error) {
    log.warn('outbox getSession failed', { message: error.message });
    return null;
  }
  return data.session?.access_token ?? null;
}

async function processUploadAvatar(database: SQLite.SQLiteDatabase): Promise<void> {
  const token = await getAccessToken();
  if (!token) {
    throw new Error('No session');
  }
  const {
    data: { user },
    error: userErr,
  } = await supabase.auth.getUser(token);
  if (userErr || !user) {
    throw new Error('No user');
  }
  const local = await getProfile(database);
  const uri = local?.photo_local_uri;
  if (!uri) {
    log.debug('outbox UPLOAD_AVATAR skip no local uri', {});
    return;
  }
  log.info('Avatar upload start', { hasPhoto: true });
  const base64 = await readAsStringAsync(uri, { encoding: 'base64' });
  const raw = atob(base64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i += 1) {
    bytes[i] = raw.charCodeAt(i);
  }
  const path = expectedAvatarObjectPath(user.id);
  const { error: upErr } = await supabase.storage.from('avatars').upload(path, bytes.buffer, {
    upsert: true,
    contentType: 'image/jpeg',
  });
  if (upErr) {
    log.warn('Avatar storage upload failed', { message: upErr.message });
    throw new Error(upErr.message);
  }
  const updated = await patchProfile(token, { photo_path: path });
  log.info('Avatar upload committed', { hasPhoto: true });
  await applyRemoteProfile(database, updated);
}

async function processPatchProfile(database: SQLite.SQLiteDatabase, payload: Record<string, unknown>): Promise<void> {
  const token = await getAccessToken();
  if (!token) throw new Error('No session');
  const remote = await patchProfile(token, payload);
  await applyRemoteProfile(database, remote);
}

async function processComplete(database: SQLite.SQLiteDatabase): Promise<void> {
  const token = await getAccessToken();
  if (!token) throw new Error('No session');
  const remote = await postProfileComplete(token);
  await applyRemoteProfile(database, remote);
}

export async function flushOutbox(database: SQLite.SQLiteDatabase): Promise<void> {
  if (flushing) {
    log.debug('outbox flush skip re-entrant', {});
    return;
  }
  flushing = true;
  const started = Date.now();
  let processed = 0;
  let failed = 0;
  try {
    for (;;) {
      const row = await database.getFirstAsync<OutboxRow>(
        'SELECT * FROM outbox ORDER BY id ASC LIMIT 1',
      );
      if (!row) break;
      log.debug('outbox flush item', { op: row.op, id: row.id, attempts: row.attempts });
      try {
        if (row.op === OUTBOX_OP.UPLOAD_AVATAR) {
          await processUploadAvatar(database);
        } else if (row.op === OUTBOX_OP.PATCH_PROFILE) {
          const payload = JSON.parse(row.payload_json) as Record<string, unknown>;
          await processPatchProfile(database, payload);
        } else if (row.op === OUTBOX_OP.COMPLETE_ONBOARDING) {
          await processComplete(database);
        } else {
          log.warn('outbox unknown op', { op: row.op });
        }
        await database.runAsync('DELETE FROM outbox WHERE id = ?', row.id);
        processed += 1;
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        failed += 1;
        log.warn('outbox item failed', { op: row.op, attempts: row.attempts + 1, message });
        await database.runAsync(
          `UPDATE outbox SET attempts = attempts + 1, last_error_at = ?, last_error_message = ? WHERE id = ?`,
          new Date().toISOString(),
          message.slice(0, 500),
          row.id,
        );
        break;
      }
    }
  } finally {
    flushing = false;
    log.debug('outbox flush done', {
      processed,
      failed,
      durationMs: Date.now() - started,
    });
  }
}
