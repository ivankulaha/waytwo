# ADR-0006: Local-first profile and onboarding with expo-sqlite

## Status

Accepted

## Context

Onboarding must work with intermittent connectivity, resume from the last step after app restart, and queue writes until the network is available. Partner fields are deferred to a future pair-creation flow.

## Decision

- Use **expo-sqlite** as the on-device source of truth for the single-row `profile` mirror plus an **outbox** table for pending operations (`PATCH_PROFILE`, `UPLOAD_AVATAR`, `COMPLETE_ONBOARDING`).
- **Flush** the outbox on enqueue, after `ProfileProvider` mount pull (initial catch-up), app foreground (`AppState`), and when `NetInfo` reports connectivity.
- **Avatar uploads** go directly to Supabase Storage with the user JWT at the stable object key `{user_id}/avatar.jpg` (bucket `avatars`, public read). After a successful upload, call `PATCH /api/v1/me/profile` with `photo_path` so Postgres never points at a missing object.
- **Server** persists canonical state in `public.profiles` with RLS; mobile uses `GET`/`PATCH`/`POST …/profile/complete` via the existing Next.js API and bearer middleware.

## Consequences

- Positive: predictable offline behaviour, simple mental model (one DB file per user), no WatermelonDB learning curve.
- Negative: bespoke sync logic must stay correct (ordering, merge of PATCH payloads, retries); future multi-entity sync may need generalisation or a dedicated sync library.
- Operational: Supabase migration must be applied before the app can load profiles; Storage policies must exist for `avatars`.

## Author

Ivan Kulaha
