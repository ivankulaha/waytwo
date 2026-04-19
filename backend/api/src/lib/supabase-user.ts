import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Supabase client scoped to the caller's JWT (RLS as that user).
 */
export function createSupabaseUserClient(request: Request): SupabaseClient {
  const url = process.env.SUPABASE_URL?.trim();
  const publishableKey =
    process.env.SUPABASE_PUBLISHABLE_KEY?.trim() || process.env.SUPABASE_ANON_KEY?.trim();
  const auth = request.headers.get('authorization');
  if (!url || !publishableKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY');
  }
  if (!auth?.startsWith('Bearer ')) {
    throw new Error('Missing Authorization');
  }
  return createClient(url, publishableKey, {
    global: { headers: { Authorization: auth } },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
