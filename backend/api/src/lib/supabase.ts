import { createClient } from '@supabase/supabase-js';

function resolvePublishableKey(): string | undefined {
  return (
    process.env.SUPABASE_PUBLISHABLE_KEY?.trim() || process.env.SUPABASE_ANON_KEY?.trim() || undefined
  );
}

export function createSupabaseBearerClient() {
  const url = process.env.SUPABASE_URL?.trim();
  const publishableKey = resolvePublishableKey();
  if (!url || !publishableKey) {
    throw new Error(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY (Dashboard → API Keys → Publishable). Legacy SUPABASE_ANON_KEY is still accepted. Copy .env.local.example to .env.local.',
    );
  }
  return createClient(url, publishableKey);
}
