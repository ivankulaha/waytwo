# Feature: Authentication

## Overview

End users sign in or sign up on the Expo app using **Supabase Auth** (email/password and Apple). Sessions persist via **SecureStore**. The **Next.js** API under `backend/api` validates **Supabase JWTs** for protected `/api/v1/*` routes.

## Mobile

- **Client:** `mobile/lib/supabase.ts` — Supabase client + secure storage adapter; env `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (legacy `EXPO_PUBLIC_SUPABASE_ANON_KEY` optional), `EXPO_PUBLIC_API_URL`.
- **State:** `mobile/context/AuthContext.tsx` — session, `onAuthStateChange`, `needsNewPassword` flag after recovery deep link.
- **Navigation:** `mobile/app/_layout.tsx` — guards `(tabs)` vs `(auth)`, handles password-reset URLs with `exchangeCodeForSession`.
- **Flows:** `mobile/app/(auth)/` — email entry, password (login), signup, forgot password, new password after deep link.

## Backend

- **Env:** `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (legacy `SUPABASE_ANON_KEY` optional) — same publishable key as the mobile app for `createClient` + `auth.getUser(token)`.
- **Middleware:** `backend/api/src/middleware.ts` — CORS, JWT validation except `GET /api/v1/health`.
- **Routes:** e.g. `GET /api/v1/me` — uses `x-user-id` from middleware.

## Security notes

- Anon key only on mobile; service role server-side only.
- Generic authentication errors on the password step where appropriate.
- Apple: nonce hashing per Supabase OIDC expectations.

**Author:** Ivan Kulaha
