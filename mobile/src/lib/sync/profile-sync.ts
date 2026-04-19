import type * as SQLite from 'expo-sqlite';

import {
  applyRemoteProfile,
  ensureProfileRow,
  setLocalAvatar,
  upsertLocalProfile,
  type LocalProfileRow,
} from '@/lib/db/profile-repo';
import { fetchProfile } from '@/lib/profile-api';
import { log } from '@/lib/log';

import {
  enqueueOutbox,
  enqueuePatchProfileMerged,
  flushOutbox,
  OUTBOX_OP,
} from './outbox';

const ONBOARDING_LEAVES = ['intro', 'you', 'look'] as const;

export function pathForOnboardingStep(step: number): string {
  const s = Math.max(0, Math.min(step, ONBOARDING_LEAVES.length - 1));
  const leaf = ONBOARDING_LEAVES[s];
  return `/(onboarding)/${leaf}`;
}

export async function pullProfile(database: SQLite.SQLiteDatabase, accessToken: string): Promise<void> {
  const pulledAt = new Date().toISOString();
  log.info('Profile pull start', {});
  const remote = await fetchProfile(accessToken);
  await applyRemoteProfile(database, remote);
  log.info('Profile pull done', { step: remote.onboarding_step, pulledAt });
}

export type ProfilePatch = Partial<
  Omit<LocalProfileRow, 'user_id' | 'dirty' | 'last_synced_at' | 'remote_updated_at'>
>;

export async function pushProfileUpdate(
  database: SQLite.SQLiteDatabase,
  partial: ProfilePatch,
): Promise<void> {
  await upsertLocalProfile(database, partial);
  await enqueuePatchProfileMerged(database, partial as Record<string, unknown>);
  await flushOutbox(database);
}

export async function pushAvatar(database: SQLite.SQLiteDatabase, localUri: string): Promise<void> {
  await setLocalAvatar(database, localUri);
  await enqueueOutbox(database, OUTBOX_OP.UPLOAD_AVATAR, 'avatar', {});
  log.info('Avatar outbox enqueued', { hasPhoto: true });
  await flushOutbox(database);
}

export async function pushCompleteOnboarding(database: SQLite.SQLiteDatabase): Promise<void> {
  const iso = new Date().toISOString();
  await upsertLocalProfile(database, { onboarding_completed_at: iso });
  await enqueueOutbox(database, OUTBOX_OP.COMPLETE_ONBOARDING, 'onboarding', {});
  log.info('Onboarding complete enqueued', {});
  await flushOutbox(database);
}

export async function initProfileDb(database: SQLite.SQLiteDatabase, userId: string): Promise<void> {
  await ensureProfileRow(database, userId);
}
