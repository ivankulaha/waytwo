import { log } from '@/lib/log';

function apiBase(): string {
  const base = process.env.EXPO_PUBLIC_API_URL?.trim();
  if (!base) {
    throw new Error('Missing EXPO_PUBLIC_API_URL');
  }
  return base.replace(/\/$/, '');
}

export class CheckEmailError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CheckEmailError';
  }
}

/**
 * Calls the public API to see if an email already has an Auth user.
 * Does not log the email address.
 */
export async function checkEmailRegistered(email: string): Promise<boolean> {
  const url = `${apiBase()}/auth/check-email`;
  let res: Response;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
  } catch (e: unknown) {
    log.warn('check-email request failed', {
      message: e instanceof Error ? e.message : String(e),
    });
    throw new CheckEmailError('network');
  }

  if (!res.ok) {
    log.warn('check-email HTTP error', { status: res.status });
    throw new CheckEmailError('http');
  }

  let data: unknown;
  try {
    data = await res.json();
  } catch {
    log.warn('check-email invalid JSON response', {});
    throw new CheckEmailError('parse');
  }

  if (
    !data ||
    typeof data !== 'object' ||
    !('registered' in data) ||
    typeof (data as { registered: unknown }).registered !== 'boolean'
  ) {
    log.warn('check-email unexpected response shape', {});
    throw new CheckEmailError('shape');
  }

  return (data as { registered: boolean }).registered;
}
