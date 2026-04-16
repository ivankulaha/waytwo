import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';

import { logger } from '@/lib/logger';

const DEFAULT_CACHE_TTL_MS = 3_600_000;

type CacheEntry = { value: string; fetchedAt: number };

const cache = new Map<string, CacheEntry>();

let client: SecretClient | null = null;

function getVaultUrl(): string | undefined {
  return process.env.AZURE_KEYVAULT_URL?.trim();
}

export function getCacheTtlMs(): number {
  const raw = process.env.AZURE_KV_CACHE_TTL_MS?.trim();
  if (!raw) {
    return DEFAULT_CACHE_TTL_MS;
  }
  const n = Number.parseInt(raw, 10);
  if (!Number.isFinite(n) || n <= 0) {
    return DEFAULT_CACHE_TTL_MS;
  }
  return n;
}

function getClient(): SecretClient | null {
  const url = getVaultUrl();
  if (!url) {
    return null;
  }
  if (!client) {
    client = new SecretClient(url, new DefaultAzureCredential());
  }
  return client;
}

export function resetKeyVaultClientForTests(): void {
  client = null;
  cache.clear();
}

export async function getSecretFromVault(
  secretName: string,
  options?: { force?: boolean },
): Promise<string | undefined> {
  const ttlMs = getCacheTtlMs();
  const now = Date.now();
  const cached = cache.get(secretName);

  if (!options?.force && cached && now - cached.fetchedAt < ttlMs) {
    return cached.value;
  }

  const c = getClient();
  if (!c) {
    return cached?.value;
  }

  try {
    const bundle = await c.getSecret(secretName);
    const value = bundle.value?.trim();
    if (!value) {
      logger.warn('Key Vault secret empty or missing value', { secretName });
      return cached?.value;
    }
    cache.set(secretName, { value, fetchedAt: Date.now() });
    return value;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    logger.warn('Key Vault getSecret failed', { secretName, message });
    return cached?.value;
  }
}
