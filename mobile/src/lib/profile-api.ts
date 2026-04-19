import { log } from '@/lib/log';

function apiBase(): string {
  const base = process.env.EXPO_PUBLIC_API_URL?.trim();
  if (!base) {
    throw new Error('Missing EXPO_PUBLIC_API_URL');
  }
  return base.replace(/\/$/, '');
}

export type ProfileApiRow = {
  user_id: string;
  display_name: string | null;
  gender: 'male' | 'female' | 'other' | null;
  date_of_birth: string | null;
  photo_path: string | null;
  color_id: string | null;
  onboarding_step: number;
  onboarding_completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export class ProfileApiError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message);
    this.name = 'ProfileApiError';
  }
}

export async function fetchProfile(accessToken: string): Promise<ProfileApiRow> {
  const url = `${apiBase()}/me/profile`;
  const res = await fetch(url, {
    method: 'GET',
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    log.warn('fetchProfile HTTP error', { status: res.status });
    throw new ProfileApiError('http', res.status);
  }
  const data = (await res.json()) as ProfileApiRow;
  return data;
}

export async function patchProfile(
  accessToken: string,
  body: Record<string, unknown>,
): Promise<ProfileApiRow> {
  const url = `${apiBase()}/me/profile`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    log.warn('patchProfile HTTP error', { status: res.status });
    throw new ProfileApiError('http', res.status);
  }
  return (await res.json()) as ProfileApiRow;
}

export async function postProfileComplete(accessToken: string): Promise<ProfileApiRow> {
  const url = `${apiBase()}/me/profile/complete`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    log.warn('postProfileComplete HTTP error', { status: res.status });
    throw new ProfileApiError('http', res.status);
  }
  return (await res.json()) as ProfileApiRow;
}
