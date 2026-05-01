# Native iOS Architecture

**Author:** Ivan Kulaha  
**Status:** Phase 2 complete — parity with React Native app  
**Related ADR:** [ADR-0007 — Native iOS POC Migration from React Native](../adr/0007-native-ios-poc-migration-from-react-native.md)

---

## Overview

The `mobile-ios/WayTwo/` target is a native iOS reimplementation of the WayTwo mobile app using SwiftUI and a hand-rolled reducer pattern. It runs in parallel with the existing React Native app in `mobile/` and is not yet the production path. Promotion depends on passing the validation criteria in ADR-0007.

Phase 2 completed the following areas beyond the initial POC: full design token system, Apple Sign-In, complete auth flow state machine, Keychain session restore on launch, profile/outbox sync semantics, Settings tab with logout, and deep-link password reset via universal links.

---

## App Shell

```
mobile-ios/WayTwo/
├── App/
│   ├── WayTwoApp.swift       – SwiftUI entry point; session restore + deep-link handler
│   ├── AppContainer.swift    – dependency graph (single struct, live singleton)
│   ├── AppReducer.swift      – root State, Action, reduce
│   ├── AppView.swift         – root view; derives active screen from state
│   └── Config.swift          – typed config values read from .xcconfig
├── Core/                     – shared infrastructure (no feature logic)
└── Features/                 – domain modules
```

`WayTwoApp` creates `AppContainer.live` and passes it down. On launch, a `.task` modifier checks `KeychainClient.loadSession()` and sets `isAuthenticated` without requiring a network round-trip. An `.onOpenURL` handler intercepts Supabase password-reset deep links and routes to the `newPassword` auth flow state.

`AppView` reads `AppReducer.State` and renders one of three exclusive branches:

| Condition | Rendered content |
|-----------|-----------------|
| `!isAuthenticated` | Auth flow (`NavigationStack` driven by `AuthReducer.State.flow`) |
| `!hasCompletedOnboarding` | `NavigationStack` onboarding sequence |
| both true | `TabView` with Home and Settings tabs |

Navigation state lives entirely in `AppReducer.State`; no imperative push calls exist in views.

---

## Feature Modules

Each feature lives under `Features/<Domain>/` and contains:

- **`<Domain>Reducer.swift`** — `State`, `Action`, `reduce` function (pure)
- **`<Domain>View.swift`** (+ sub-views) — SwiftUI views that accept `@Binding<State>` and closure callbacks

Views dispatch mutations by writing to bound state or calling action closures. They do not reference Core clients directly.

### Implemented modules

| Module | Reducer | Views |
|--------|---------|-------|
| Auth | `AuthReducer` | `SignInView`, `SignUpView`, `SignInPasswordView`, `ForgotPasswordView`, `NewPasswordView` |
| Onboarding | `OnboardingReducer` | `OnboardingIntroView`, `OnboardingYouView`, `OnboardingLookView` |
| Profile | `ProfileReducer` | `ProfileView`, `ProfileEditView` |
| Home | `HomeReducer` | `HomeView` |
| Settings | `SettingsReducer` | `SettingsView` |

---

## Auth Flow State Machine

`AuthReducer.State.flow` drives the entire unauthenticated experience as an enum with six states:

| State | Screen | Transition |
|-------|--------|------------|
| `.email` | `SignInView` | Email check → `.password` (existing) or `.signup` (new) |
| `.password` | `SignInPasswordView` | Supabase password sign-in → authenticated; or `.forgot` |
| `.signup` | `SignUpView` | Supabase sign-up → back to `.email` |
| `.forgot` | `ForgotPasswordView` | Reset email sent → `.emailSent` |
| `.emailSent` | Inline confirmation screen | Manual navigation back to `.email` |
| `.newPassword` | `NewPasswordView` | Deep-link restore → Supabase `updatePassword` → `.email` |

`AppView.authFlow` owns all async side-effect closures (sign-in, sign-up, reset, Apple). State mutations happen after awaiting results; errors surface as `errorKey` localization strings, never raw messages.

### Apple Sign-In

`SignInView` surfaces an Apple Sign-In button. On success the view calls `onAppleSignIn(idToken:nonce:)`. `AppView` forwards the id-token and hashed nonce to `SupabaseClient.signInWithApple`, which calls `signInWithIdToken` via the Supabase SDK. The resulting session tokens are persisted to Keychain and `isAuthenticated` is set. The raw nonce is never logged.

---

## Session Lifecycle

| Event | Behavior |
|-------|----------|
| App cold launch | `.task` calls `KeychainClient.loadSession()`; non-nil result sets `isAuthenticated = true` without a network call |
| Successful sign-in (password or Apple) | `KeychainClient.saveSession(accessToken:refreshToken:)` persists both tokens |
| Logout | `SupabaseClient.signOut()` → `KeychainClient.deleteSession()` → `AppReducer.State` reset to default |
| Deep-link password reset | `WayTwoApp.onOpenURL` extracts `code` query param → `SupabaseClient.exchangeCodeForSession(url:)` → `auth.flow = .newPassword` |

Keychain items are stored with `kSecAttrAccessibleAfterFirstUnlock`, allowing background access after device unlock.

---

## Core Infrastructure

All external system access is routed through typed client structs/classes in `Core/`. Views and reducers never call frameworks directly.

### Dependency graph

```
AppContainer
├── AppLogger          – wraps os.Logger; structured key=value metadata; never logs secrets or PII
├── KeychainClient     – session token persistence via Security.framework (token + session accounts)
├── DatabaseClient     – SwiftData container; ProfileRecord + OutboxRecord models
├── SupabaseClient     – Supabase SDK wrapper (fully wired, not stubbed)
├── APIClient          – REST client for backend profile operations
├── NetworkMonitor     – NWPathMonitor wrapper; publishes reachability state
├── Outbox             – local write queue using DatabaseClient
└── ProfileSync        – bidirectional sync (push + pull) using DatabaseClient + APIClient + Outbox
```

`AppContainer.live` is a static singleton assembled at app start. Dependencies are injected into features via the container reference passed through the view hierarchy.

---

## Storage

| Store | Type | Purpose |
|-------|------|---------|
| `ProfileRecord` | SwiftData `@Model` | Local profile cache (name, email, avatarLocalPath, updatedAt) |
| `OutboxRecord` | SwiftData `@Model` | Pending write operations queued for remote sync |
| Keychain (`auth.token`) | `Security.framework` | Legacy single-token slot (backward compatibility) |
| Keychain (`auth.session`) | `Security.framework` | JSON-encoded `Session` struct with `accessToken` + `refreshToken` |

`DatabaseClient` owns the `ModelContainer` and exposes typed methods (`upsertProfile`, `fetchProfile`, `enqueueOutbox`, `fetchOutbox`, `deleteOutbox`). Callers never access the model context directly.

---

## Networking

Two distinct clients handle different backends:

- **`SupabaseClient`** — wraps the official `Supabase` Swift SDK. All auth operations are live: `signInWithPassword`, `signUp`, `signOut`, `resetPasswordForEmail`, `updatePassword`, `exchangeCodeForSession`, `signInWithIdToken` (Apple). Logs auth failures at `warn` with structured `AuthError` metadata (no tokens or credentials).
- **`APIClient`** — communicates with the WayTwo backend REST API (profile fetch and updates).

Both clients are initialized from `Config.xcconfig`-backed values (`Config.apiURL`, `Config.supabaseURL`, `Config.supabasePublishableKey`). Secrets are not embedded in source.

---

## Sync

### Outbox pattern

Profile mutations are written locally first, then enqueued in `OutboxRecord` with a typed operation. `Outbox.flush()` processes the queue and deletes records on delivery. Missing avatar files are discarded with a warning log rather than blocking the queue.

Supported outbox operations:

| Operation | Trigger |
|-----------|---------|
| `.patchProfile` | Any profile field edit |
| `.uploadAvatar` | Avatar photo selected |
| `.completeOnboarding` | User finishes onboarding step 3 |

### ProfileSync

`ProfileSync` exposes four methods covering both directions:

| Method | Direction | When called |
|--------|-----------|-------------|
| `pullProfile(accessToken:)` | Remote → local | After onboarding completion; on reconnect |
| `pushProfile(partial:accessToken:)` | Local → remote | Profile edit saved |
| `pushAvatar(localURI:accessToken:)` | Local → remote | Avatar selected |
| `pushCompleteOnboarding(accessToken:)` | Local → remote, then pull | Onboarding step 3 complete |

`pushCompleteOnboarding` enqueues the operation, flushes the outbox, then immediately pulls the remote profile to reconcile any server-side onboarding mutations.

Failures in all sync methods are logged as warnings and do not crash the app.

---

## Design Tokens

Shared design values are defined in `Core/Design/` and must be used by all views. Raw numeric literals for spacing, sizing, radius, or color are not permitted.

### `Tokens` (spacing, radius, size)

| Namespace | Values |
|-----------|--------|
| `Tokens.Spacing` | `xs` (4), `md` (8), `lg` (12), `xl` (16), `x2l` (20), `x3l` (24), `x4l` (32) |
| `Tokens.Radius` | `md` (12), `lg` (16), `full` (28) |
| `Tokens.Size` | `inputHeight` / `buttonHeight` (56), `avatar` (120), `swatchTap` (48), `swatchInner` (36) |

### `AppColors` (semantic colors)

Dark-first color system. All values are static `Color` properties:

| Token | Purpose |
|-------|---------|
| `surface` / `surfaceElevated` | Page backgrounds |
| `textPrimary` / `textSecondary` | Body and secondary text |
| `inputBackground` / `inputBorder` | Form fields |
| `buttonBackground` / `buttonText` | Primary CTA |
| `error` | Inline validation and error states |
| `homeBackground` / `settingsBackground` | Screen-specific backgrounds |
| `profileFallback` | Avatar placeholder color |
| `profilePalette` | Named color swatches for avatar selection (purple, blue, teal, green, orange, pink) |

### `Gradients`

| Name | Type | Usage |
|------|------|-------|
| `Gradients.auth` | `RadialGradient` | Auth screen background overlay |
| `Gradients.homeGlow(color:)` | `RadialGradient` | Dynamic glow behind avatar on Home screen |

---

## Settings Tab

`SettingsView` is the second main tab (`AppReducer.Tab.settings`). It currently exposes:

- **Logout** — calls `AppView.logout()`, which signs out via Supabase, deletes the Keychain session, and resets root state to `AppReducer.State()`.
- **Error display** — shows a localized error message if `SettingsReducer.State.errorKey` is set (e.g. if sign-out fails).

---

## Localization

User-facing strings are stored in `Resources/Localizable.xcstrings` (Xcode String Catalog format) with both `en` and `uk` locales.

Key grouping convention mirrors the React Native app:

| Prefix | Domain |
|--------|--------|
| `auth.*` | Sign-in, sign-up, password reset, Apple sign-in, email confirmation |
| `onboarding.*` | Onboarding steps |
| `tabs.*` | Tab bar labels |
| `profile.*` | Profile view and edit |
| `home.*` | Home screen |
| `settings.*` | Settings screen and logout |
| `validation.*` | Field validation messages |
| `error.*` | Generic error titles |

SwiftUI views must use `String(localized:)` or `LocalizedStringKey`; hardcoded display text is not permitted outside `#Preview` blocks.

---

## Logging

`AppLogger` wraps `os.Logger` with subsystem `com.ivankulaha.WayTwo`. All log calls use structured `key=value` metadata strings. Log level conventions:

| Level | When |
|-------|------|
| `debug` | Internal transitions (outbox enqueue, SwiftData writes) |
| `info` | Action boundaries (sync success, profile save, sign-in ok) |
| `warn` | Retryable or recoverable failures (sync pull failed, avatar missing) |
| `error` | User-visible or fatal failures |

`print()` is not used anywhere in production code. Secrets, tokens, auth codes, deep-link URLs, and PII must not appear in any log call at any level.

---

## Migration Status

| Area | Status |
|------|--------|
| App shell + root state | Done |
| Auth screens | Done (all 6 flow states, Supabase fully wired) |
| Apple Sign-In | Done |
| Keychain session restore | Done |
| Deep-link password reset | Done |
| Onboarding screens | Done (3-step flow) |
| Profile view + edit | Done (local SwiftData, push sync) |
| Home screen | Done (scaffold) |
| Settings tab + logout | Done |
| Design token system | Done (Tokens, AppColors, Gradients) |
| Supabase Auth integration | Done (all methods live, SDK integrated) |
| Profile sync (push) | Done |
| Profile sync (pull) | Done (post-onboarding; on-reconnect hook TBD) |
| Offline outbox flush on reconnect | Partial (flush logic present; NetworkMonitor trigger not wired) |
| Push notifications | Out of scope |
| Android / cross-platform | Not applicable — iOS only |

The POC is considered complete when all validation criteria in ADR-0007 are met. Promotion to the primary app path requires a separate decision.
