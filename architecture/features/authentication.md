# Feature: Authentication

## Overview

End users sign in or sign up on the Expo app using **Supabase Auth** (email/password and Apple). Sessions persist via **SecureStore**. The **Next.js** API under `backend/api` validates **Supabase JWTs** for protected `/api/v1/*` routes.

## Mobile

- **Client:** `mobile/src/lib/supabase.ts` — Supabase client + secure storage adapter; env `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (legacy `EXPO_PUBLIC_SUPABASE_ANON_KEY` optional), `EXPO_PUBLIC_API_URL`.
- **Email branch:** `mobile/src/lib/auth-api.ts` — `POST …/auth/check-email` (no bearer) after the user submits email; routes to password (registered) or signup (not registered).
- **State:** `mobile/src/context/AuthContext.tsx` — session, `onAuthStateChange`, `needsNewPassword` flag after recovery deep link.
- **Navigation:** `mobile/src/app/_layout.tsx` — guards `(tabs)` vs `(auth)`, handles password-reset URLs with `exchangeCodeForSession`.
- **Flows:** `mobile/src/app/(auth)/` — email entry, optional Apple on iOS, API check, password (login) or signup (password only; email from params), forgot password, new password after deep link. Password validation minimum **6** characters (aligned with Supabase project settings).

## Backend

- **Env:** `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (legacy `SUPABASE_ANON_KEY` optional), and **`SUPABASE_SERVICE_ROLE_KEY`** (server-only secret JWT) for Auth Admin lookups on the check-email route.
- **Middleware:** `backend/api/src/middleware.ts` — CORS, JWT validation except `GET /api/v1/health` and **`POST /api/v1/auth/check-email`**.
- **Routes:** `GET /api/v1/me` — uses `x-user-id` from middleware. **`POST /api/v1/auth/check-email`** — public JSON `{ email }` → `{ registered: boolean }`; uses `backend/api/src/lib/supabase-admin.ts` and paginated `auth.admin.listUsers` until match or end of list (scale note: see [tech-debt](../tech-debt.md)).

## Security notes

- Publishable key only on mobile; **service role** only on the server, never in `EXPO_PUBLIC_*`.
- **Email step** intentionally discloses registration status via the API (enumeration tradeoff); generic errors remain appropriate on **password** sign-in failure.
- Apple: nonce hashing per Supabase OIDC expectations.
- Deferred hardening: [tech-debt.md](../tech-debt.md) (rate limits, CAPTCHA).

**Author:** Ivan Kulaha
