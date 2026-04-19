import type * as SQLite from 'expo-sqlite';

import { expectedAvatarObjectPath } from '@/lib/avatar-path';
import type { ProfileApiRow } from '@/lib/profile-api';
import { log } from '@/lib/log';

export type LocalProfileRow = {
  user_id: string;
  display_name: string | null;
  gender: 'male' | 'female' | 'other' | null;
  date_of_birth: string | null;
  photo_path: string | null;
  color_id: string | null;
  onboarding_step: number;
  onboarding_completed_at: string | null;
  photo_local_uri: string | null;
  photo_pending: number;
  dirty: number;
  last_synced_at: string | null;
  remote_updated_at: string | null;
};

function mapRow(r: Record<string, unknown>): LocalProfileRow {
  return {
    user_id: String(r.user_id),
    display_name: r.display_name == null ? null : String(r.display_name),
    gender: (r.gender as LocalProfileRow['gender']) ?? null,
    date_of_birth: r.date_of_birth == null ? null : String(r.date_of_birth),
    photo_path: r.photo_path == null ? null : String(r.photo_path),
    color_id: r.color_id == null ? null : String(r.color_id),
    onboarding_step: Number(r.onboarding_step ?? 0),
    onboarding_completed_at: r.onboarding_completed_at == null ? null : String(r.onboarding_completed_at),
    photo_local_uri: r.photo_local_uri == null ? null : String(r.photo_local_uri),
    photo_pending: Number(r.photo_pending ?? 0),
    dirty: Number(r.dirty ?? 0),
    last_synced_at: r.last_synced_at == null ? null : String(r.last_synced_at),
    remote_updated_at: r.remote_updated_at == null ? null : String(r.remote_updated_at),
  };
}

export async function ensureProfileRow(database: SQLite.SQLiteDatabase, userId: string): Promise<void> {
  await database.runAsync(
    `INSERT OR IGNORE INTO profile (id, user_id, onboarding_step, photo_pending, dirty)
     VALUES (1, ?, 0, 0, 0)`,
    userId,
  );
}

export async function getProfile(database: SQLite.SQLiteDatabase): Promise<LocalProfileRow | null> {
  const r = await database.getFirstAsync<Record<string, unknown>>('SELECT * FROM profile WHERE id = 1');
  if (!r) return null;
  return mapRow(r);
}

export async function applyRemoteProfile(
  database: SQLite.SQLiteDatabase,
  remote: ProfileApiRow,
): Promise<void> {
  const local = await getProfile(database);
  const pending = local?.photo_pending === 1;
  const remotePath = remote.photo_path;
  const expected = expectedAvatarObjectPath(remote.user_id);
  const clearPending = Boolean(pending && remotePath === expected);
  await database.runAsync(
    `UPDATE profile SET
      display_name = ?,
      gender = ?,
      date_of_birth = ?,
      photo_path = ?,
      color_id = ?,
      onboarding_step = ?,
      onboarding_completed_at = ?,
      remote_updated_at = ?,
      dirty = 0,
      photo_local_uri = CASE WHEN ? THEN NULL ELSE photo_local_uri END,
      photo_pending = CASE WHEN ? THEN 0 ELSE photo_pending END,
      last_synced_at = ?
    WHERE id = 1`,
    remote.display_name,
    remote.gender,
    remote.date_of_birth,
    remote.photo_path,
    remote.color_id,
    remote.onboarding_step,
    remote.onboarding_completed_at,
    remote.updated_at,
    clearPending ? 1 : 0,
    clearPending ? 1 : 0,
    new Date().toISOString(),
  );
  log.debug('applyRemoteProfile', { step: remote.onboarding_step, clearPending: Boolean(clearPending) });
}

export async function upsertLocalProfile(
  database: SQLite.SQLiteDatabase,
  partial: Partial<
    Omit<LocalProfileRow, 'user_id' | 'dirty' | 'last_synced_at' | 'remote_updated_at'>
  > & { user_id?: string },
): Promise<void> {
  const keys = Object.keys(partial).filter((k) => k !== 'user_id');
  if (keys.length === 0) return;
  const setParts: string[] = [];
  const values: unknown[] = [];
  for (const k of keys) {
    const v = partial[k as keyof typeof partial];
    if (v === undefined) continue;
    setParts.push(`${k} = ?`);
    values.push(v ?? null);
  }
  if (setParts.length === 0) return;
  setParts.push('dirty = 1');
  await database.runAsync(
    `UPDATE profile SET ${setParts.join(', ')} WHERE id = 1`,
    ...(values as (string | number | null)[]),
  );
  log.debug('upsertLocalProfile', { keys });
}

export async function setLocalAvatar(
  database: SQLite.SQLiteDatabase,
  localUri: string,
): Promise<void> {
  await database.runAsync(
    `UPDATE profile SET photo_local_uri = ?, photo_pending = 1, dirty = 1 WHERE id = 1`,
    localUri,
  );
  log.info('Local avatar set', { hasPhoto: true });
}

export async function clearLocalAvatarPending(database: SQLite.SQLiteDatabase): Promise<void> {
  await database.runAsync(
    `UPDATE profile SET photo_local_uri = NULL, photo_pending = 0, dirty = 1 WHERE id = 1`,
  );
}
