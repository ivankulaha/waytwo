# Feature: Onboarding (mobile + API)

## Overview

After authentication, new users complete a three-step onboarding (intro, profile fields, avatar + color). Data is written to **expo-sqlite** first and replicated to **Supabase** via the Next.js API. Users resume at `onboarding_step` until `onboarding_completed_at` is set.

**ADR:** [ADR-0006 — Local-first profile with expo-sqlite](../adr/0006-local-first-profile-with-expo-sqlite.md).

The same `GET`/`PATCH` profile API and SQLite mirror support **settings and profile edits** after onboarding; this doc focuses on the first-run flow.

## Mobile

- **Routes:** `mobile/src/app/(onboarding)/` — `intro`, `you`, `look`; stack layout exports `ErrorBoundary`.
- **Shell / UI:** `mobile/src/components/onboarding/*` — intro uses `AuthShell` with Skia **`<RadialBlob>`** (`RadialBlobPalette.onboardingIntro` in `gradients.ts`); form steps use solid black. Shared tokens in `theme.ts` (`OnboardingPalette`).
- **Look step:** Photo pick uses `expo-image-picker` (native gallery), then `react-native-image-crop-picker.openCropper` with `cropperCircleOverlay`. On iOS, `InteractionManager.runAfterInteractions` plus a delay and a `requestAnimationFrame` tick after the picker resolves reduce presenting the cropper while `PHPickerViewController` is still dismissing. Cropper toolbar/actions use dark styling with white labels where supported. Expo config plugin: `with-rn-image-crop-picker` in `mobile/app.json`. Selected profile color drives a single large radial-gradient halo via `react-native-svg`, absolutely centered on the avatar slot so the glow does not expand onboarding layout height (only the avatar circle reserves vertical space).
- **State:** `mobile/src/context/ProfileContext.tsx` — opens `waytwo-{userId}.db`, pulls `GET /api/v1/me/profile`, exposes `updateProfile`, `pushAvatarFromPicker`, `completeOnboarding`, `refreshFromDb`. Wipes DB on sign-out via `closeAndWipe()` in `mobile/src/lib/db/client.ts`.
- **Sync:** `mobile/src/lib/sync/outbox.ts` (FIFO flush, merged PATCH payloads), `mobile/src/lib/sync/profile-sync.ts` (`pullProfile`, `pushProfileUpdate`, `pushAvatar`, `pushCompleteOnboarding`, `pathForOnboardingStep`).
- **Navigation:** `mobile/src/app/_layout.tsx` — waits for `ProfileProvider.ready` when a session exists; redirects incomplete users to `/(onboarding)/…`; `mobile/src/app/index.tsx` uses the same completion check.
- **Logging:** `log.info` / `log.debug` / `log.warn` on main onboarding and outbox steps (no PII).

## Backend

- **Migrations:** `backend/api/supabase/migrations/20250418120000_profiles_and_avatars.sql` — `public.profiles`, RLS, `avatars` bucket + Storage policies, `updated_at` trigger.
- **API:** `GET` + `PATCH` `backend/api/src/app/api/v1/me/profile/route.ts`, `POST` `…/profile/complete/route.ts`. JWT-bound Supabase client: `backend/api/src/lib/supabase-user.ts`.
- **Validation:** Zod on `PATCH` body; `photo_path` must equal `{user_id}/avatar.jpg`.
- **Logging:** `logger.info` entry/exit and domain steps; `logger.warn` on upstream errors.

## Requirements source

- [requirements/onboarding.md](../../requirements/onboarding.md)

## Figma

- **File (MCP-accessible):** [WayTwo (Copy)](https://www.figma.com/design/NIofouu7Ph9yhZs118YH9j/WayTwo--Copy-) (`NIofouu7Ph9yhZs118YH9j`).
- **Onboarding v2:** [section `326:5994`](https://www.figma.com/design/NIofouu7Ph9yhZs118YH9j/WayTwo--Copy-?node-id=326-5994). Details: `.cursor/rules/figma-design-context.mdc`.

## Author

Ivan Kulaha
