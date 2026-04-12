import { createClient, type SupabaseClient } from '@supabase/supabase-js';

function resolveServiceRoleKey(): string | undefined {
  return (
    process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() ||
    process.env.SUPABASE_SECRET_KEY?.trim() ||
    undefined
  );
}

export function createSupabaseServiceClient(): SupabaseClient {
  const url = process.env.SUPABASE_URL?.trim();
  const serviceKey = resolveServiceRoleKey();
  if (!url || !serviceKey) {
    throw new Error(
      'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY (Dashboard → Settings → API Keys → Secret). Legacy SUPABASE_SECRET_KEY is accepted.',
    );
  }
  return createClient(url, serviceKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

/**
 * Resolves whether an auth user with this email exists.
 * Uses paginated admin listUsers (no native email filter in current Auth API).
 */
export async function isAuthEmailRegistered(email: string): Promise<boolean> {
  const admin = createSupabaseServiceClient();
  const target = email.trim().toLowerCase();
  let page = 1;
  const perPage = 1000;

  for (;;) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
    if (error) {
      throw new Error(error.message);
    }
    const found = data.users.some((u) => (u.email ?? '').toLowerCase() === target);
    if (found) {
      return true;
    }
    if (data.users.length < perPage) {
      return false;
    }
    page += 1;
  }
}
