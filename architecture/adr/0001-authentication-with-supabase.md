# ADR-0001: Authentication with Supabase (mobile direct + API JWT validation)

## Status

Accepted

## Context

WayTwo needs email/password and Sign in with Apple, password reset via deep link, session persistence, and a versioned HTTP API that can authorize requests on behalf of the signed-in user. The stack is Expo (React Native) and a small Next.js App Router service under `backend/api`.

## Decision

1. **Mobile talks to Supabase Auth directly** using `@supabase/supabase-js` with a custom session storage adapter on **`expo-secure-store`** (not AsyncStorage).
2. **Backend does not proxy login.** Protected routes validate **`Authorization: Bearer <Supabase access token>`** in middleware via `@supabase/ssr` / `getUser`, then forward identity (e.g. `x-user-id`) to route handlers.
3. **API versioning** uses path prefixes: `/api/v1/*`. Breaking changes introduce `/api/v2`, etc.
4. **Security / UX:** Generic client-facing auth errors (e.g. invalid credentials) to avoid leaking whether an account exists. Client-side validation with Zod before calling Supabase. **Sign in with Apple** uses a hashed nonce with `signInWithIdToken`. Password reset uses **`exchangeCodeForSession`** on the deep link URL (PKCE-style flow); tokens are not logged or stored manually.
5. **No secret or service role key in the mobile app**; only the **Supabase publishable** key (`sb_publishable_...`, env `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY`) is exposed client-side. Legacy JWT **anon** keys remain supported via env fallback until fully migrated.

## Consequences

- Simpler auth pipeline on the server (no custom credential endpoints).
- RLS and Supabase project configuration remain mandatory for data safety.
- Mobile and API must stay aligned on Supabase project and JWT format.

## Amendment (2026-04-12)

1. **Email registration check:** After the user enters a valid email (email/password flow only), the mobile app calls **`POST /api/v1/auth/check-email`** on the Next.js API with JSON `{ "email": "<string>" }`. The handler uses a **server-only** Supabase client with the **secret (service_role) JWT** and the Auth Admin API to respond `{ "registered": boolean }`. Login and sign-up **still** use Supabase directly from the app; the API does not proxy passwords.
2. **Enumeration tradeoff:** This endpoint intentionally reveals whether an email has an Auth user. **Mitigations** (rate limiting, CAPTCHA) are deferred; see [`architecture/tech-debt.md`](../tech-debt.md).
3. **Error messaging:** Decision §4’s “generic errors” to avoid leaking account existence applies to the **password** step and similar; the **email** step no longer hides whether an account exists once the check-email call succeeds.

## Related

- Plan: `.cursor/plans/waytwo_authentication_6500aa8d.plan.md`
- Feature: `architecture/features/authentication.md`
- Technical debt: `architecture/tech-debt.md`

**Author:** Ivan Kulaha
