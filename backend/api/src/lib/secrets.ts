import { getCacheTtlMs, getSecretFromVault } from '@/lib/keyvault';
import { logger } from '@/lib/logger';

export const SECRET_MAP: Record<string, string> = {
  SUPABASE_SERVICE_ROLE_KEY: 'supabase-service-role-key',
  SUPABASE_PUBLISHABLE_KEY: 'supabase-publishable-key',
};

let userProvidedKeys: Set<string> | null = null;

let refreshTimer: ReturnType<typeof setInterval> | null = null;

export function isKeyVaultEnabled(): boolean {
  return Boolean(process.env.AZURE_KEYVAULT_URL?.trim());
}

function isEnvProvided(key: string): boolean {
  return Boolean(process.env[key]?.trim());
}

function ensureUserProvidedKeysSnapshot(): Set<string> {
  if (!userProvidedKeys) {
    userProvidedKeys = new Set<string>();
    for (const envKey of Object.keys(SECRET_MAP)) {
      if (isEnvProvided(envKey)) {
        userProvidedKeys.add(envKey);
      }
    }
  }
  return userProvidedKeys;
}

export async function preloadAll(): Promise<void> {
  const provided = ensureUserProvidedKeysSnapshot();

  if (!isKeyVaultEnabled()) {
    return;
  }

  for (const [envKey, vaultName] of Object.entries(SECRET_MAP)) {
    if (provided.has(envKey)) {
      continue;
    }
    const value = await getSecretFromVault(vaultName);
    if (value) {
      process.env[envKey] = value;
    }
  }
}

async function refreshFromVault(): Promise<void> {
  if (!isKeyVaultEnabled()) {
    return;
  }
  const provided = ensureUserProvidedKeysSnapshot();
  for (const [envKey, vaultName] of Object.entries(SECRET_MAP)) {
    if (provided.has(envKey)) {
      continue;
    }
    const value = await getSecretFromVault(vaultName, { force: true });
    if (value) {
      process.env[envKey] = value;
    }
  }
}

export function startRefreshLoop(): void {
  if (refreshTimer !== null) {
    return;
  }
  const intervalMs = getCacheTtlMs();
  refreshTimer = setInterval(() => {
    void refreshFromVault().catch((err) => {
      const message = err instanceof Error ? err.message : String(err);
      logger.warn('Key Vault refresh failed', { message });
    });
  }, intervalMs);
}

export function stopRefreshLoop(): void {
  if (refreshTimer !== null) {
    clearInterval(refreshTimer);
    refreshTimer = null;
  }
}

export function resetSecretsModuleForTests(): void {
  stopRefreshLoop();
  userProvidedKeys = null;
}
