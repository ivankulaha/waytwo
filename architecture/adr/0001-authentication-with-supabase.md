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

## Related

- Plan: `.cursor/plans/waytwo_authentication_6500aa8d.plan.md`
- Feature: `architecture/features/authentication.md`

**Author:** Ivan Kulaha
