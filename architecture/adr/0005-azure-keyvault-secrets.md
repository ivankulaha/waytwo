# ADR-0005: Azure Key Vault for backend secrets

## Status

Accepted

## Context

The API (`backend/api`) reads server secrets from `process.env` (e.g. `.env.local`). For deployments on Azure, we want optional integration with **Azure Key Vault** using **`DefaultAzureCredential`** so the same code can use managed identity in Azure and developer credentials locally (e.g. Azure CLI) without embedding secrets in configuration.

## Decision

1. Add **`@azure/keyvault-secrets`** and **`@azure/identity`**; authenticate with **`DefaultAzureCredential`** and read secrets via **`SecretClient`** when **`AZURE_KEYVAULT_URL`** is set.
2. **Environment variables take precedence**: if `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_PUBLISHABLE_KEY` is already set, Key Vault is not used for that variable.
3. Only **sensitive** keys are mapped from Key Vault: **`SUPABASE_SERVICE_ROLE_KEY`** → secret `supabase-service-role-key`, **`SUPABASE_PUBLISHABLE_KEY`** → `supabase-publishable-key` (mapping is code-defined in `src/lib/secrets.ts`).
4. **Instrumentation-time preload**: `instrumentation.ts` calls `preloadAll()` so values populate `process.env` before request handling; existing consumers (`middleware.ts`, `supabase.ts`, `supabase-admin.ts`) keep reading `process.env` unchanged.
5. **TTL cache**: in-memory cache with default **1 hour** (`AZURE_KV_CACHE_TTL_MS`, default `3600000`); a **`setInterval`** refresh runs at the same interval. Failed fetches log a warning and keep the last cached value when possible.
6. **Middleware** reads Supabase URL and keys **inside** the middleware function so values set at startup are visible per request.

## Alternatives considered

- **Secrets only from Key Vault (no env fallback):** worse local dev and non-Azure hosts; rejected.
- **Azure App Configuration or separate config service:** extra moving parts; Key Vault is sufficient for secret material.
- **Per-request Key Vault calls:** higher latency and cost; rejected in favor of preload + TTL refresh.

## Consequences

- Azure hosts must grant the app identity **Get** on the required secrets; secret names must match the mapped names or the map must be updated.
- Local use with Key Vault requires a working **`DefaultAzureCredential`** chain (e.g. `az login`).
- Rotated secrets are picked up within roughly one TTL unless the process is restarted.

## Related

- `backend/api/src/lib/keyvault.ts`
- `backend/api/src/lib/secrets.ts`
- `backend/api/instrumentation.ts`

**Author:** Ivan Kulaha
