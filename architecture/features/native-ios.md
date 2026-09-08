# Native iOS Architecture

**Author:** Ivan Kulaha  
**Status:** Phase 2 complete — parity with React Native app  
**Related ADR:** [ADR-0007 — Native iOS POC Migration from React Native](../adr/0007-native-ios-poc-migration-from-react-native.md)

---

## Overview

The `mobile-ios/WayTwo/` target is a native iOS reimplementation of the WayTwo mobile app using SwiftUI and a hand-rolled reducer pattern. It runs in parallel with the existing React Native app in `mobile/` and is not yet the production path. Promotion depends on passing the validation criteria in ADR-0007.

Phase 2 completed the following areas beyond the initial POC: full design token system, Apple Sign-In, complete auth flow state machine, Keychain session restore on launch, connectivity-gated profile sync, Settings tab with logout, and deep-link password reset via universal links.

---

## App Shell

```
mobile-ios/WayTwo/
├── App/
│   ├── WayTwoApp.swift       – SwiftUI entry point; `RootContent` with session restore, scene-phase pull, SwiftData profile restore, deep-link handler
│   ├── AppContainer.swift    – dependency graph (single struct, live singleton)
│   ├── AppReducer.swift      – root State, Action, reduce
│   ├── AppView.swift         – root view; derives active screen from state; navigation + binding helpers
│   ├── AppView+Auth.swift    – auth async side effects (email check, sign-in, sign-up, reset, Apple)
│   ├── AppView+Onboarding.swift – onboarding persistence + complete onboarding
│   ├── AppView+Session.swift – logout
│   └── Config.swift          – typed config values read from .xcconfig
├── Core/                     – shared infrastructure (no feature logic)
└── Features/                 – domain modules
```

`WayTwoApp` creates `AppContainer.live` and passes it down. On launch, a `.task` modifier checks `KeychainClient.loadSession()` and sets `isAuthenticated` without requiring a network round-trip. An `.onOpenURL` handler intercepts Supabase password-reset deep links and routes to the `newPassword` auth flow state.

`AppView` reads `AppReducer.State` and renders one of four exclusive branches:

| Condition | Rendered content |
|-----------|-----------------|
| `!isAuthenticated` | Auth flow (`NavigationStack` driven by `AuthReducer.State.flow`) |
| `!profileRoutingReady` | Loading placeholder (surface background + `ProgressView`) |
| `!hasCompletedOnboarding` | `NavigationStack` onboarding sequence |
| all above false | `TabView` with Home and Settings tabs |

Navigation state lives entirely in `AppReducer.State`; no imperative push calls exist in views. `hasCompletedOnboarding` is never written from a leftover local cache — see **Post-Auth Routing** below.

### Post-Auth Routing (backend is the source of truth)

Local SwiftData is a **per-user cache**, not the router. `WayTwoApp.RootContent.routeAfterAuthentication()` runs once per sign-in / cold launch whenever `isAuthenticated` becomes true:

1. Resolve the auth user id: prefer the id saved with the Keychain session (every sign-in since this change saves it via `SupabaseClient.SessionTokens.userId`); fall back to decoding the access token's `sub` claim with `JWTAccessToken.subject(_:)` for sessions saved before user id persistence existed (then re-persists it so future launches skip the decode). Unresolvable → treated as untrusted.
2. `DatabaseClient.prepareProfileForUser(_:)` binds the singleton `ProfileRecord` to that user id. If the cached row belongs to a different or unresolved user (including a leftover pre-migration `"local"` row), the row is wiped and a blank row is created — a deleted-and-re-registered account can never inherit the previous account's onboarding state.
3. `profileRoutingReady` is set `false` and `ProfileCompleteness.hasFinishedOnboarding` is applied against the (possibly blank) local row, so `AppView` shows the loading placeholder instead of flashing Home from stale data.
4. `SyncCoordinator.sessionBecameActive()` pulls `GET /api/v1/me/profile`, applying it via `DatabaseClient.applyRemoteProfile` (which also corrects `ProfileRecord.userId`).
5. `ProfileCompleteness` is applied again from the now-current row; onboarding draft fields (`name`, `gender`, `dateOfBirth`) are restored and `onboarding.step` resumes to `.look` if both required "you" fields are already present, otherwise `.intro`.
6. `profileRoutingReady = true`.

`ProfileCompleteness.hasFinishedOnboarding(displayName:gender:onboardingCompletedAt:)` is the single completeness rule: both trimmed `displayName` and `gender` non-empty **and** `onboardingCompletedAt` non-nil. A blank remote profile (e.g. after the auth user was deleted and re-registered) always resolves to "not finished".

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

`AppView` and `AppView+Auth` own async side-effect closures (sign-in, sign-up, reset, Apple). State mutations happen after awaiting results; errors surface as `errorKey` localization strings, never raw messages. Sign-in / sign-up / Apple set `isAuthenticated = true` and otherwise only persist the Keychain session — they do not pull or route; `WayTwoApp.RootContent`'s `isAuthenticated` observer owns the single post-auth routing pass described above.

### Apple Sign-In

`SignInView` surfaces an Apple Sign-In button. On success the view calls `onAppleSignIn(idToken:nonce:)`. `AppView` forwards the id-token and hashed nonce to `SupabaseClient.signInWithApple`, which calls `signInWithIdToken` via the Supabase SDK. The resulting session tokens are persisted to Keychain and `isAuthenticated` is set. The raw nonce is never logged.

---

## Session Lifecycle

| Event | Behavior |
|-------|----------|
| App cold launch | `.task` calls `KeychainClient.loadSession()`; non-nil result sets `isAuthenticated = true`, which triggers the Post-Auth Routing pass above |
| Successful sign-in (password or Apple) | `KeychainClient.saveSession(accessToken:refreshToken:userId:)` persists both tokens and the Supabase auth user id |
| Logout | `SupabaseClient.signOut()` → `AppContainer.clearLocalSession()` (deletes the Keychain session and wipes the local profile row) → `AppReducer.State` reset to default |
| Session invalidated (SDK fires `.signedOut`) | `WayTwoApp.RootContent` receives the event via `supabase.observeSessionInvalidated`; `handleSessionInvalidated()` calls `appContainer.clearLocalSession()`, resets `AppReducer.State`, and sets `appState.auth.errorKey = "auth.sessionExpired"` so the sign-in screen explains why the user landed there |
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
├── DatabaseClient     – SwiftData container; ProfileRecord cache
├── SupabaseClient     – Supabase SDK wrapper (fully wired, not stubbed)
├── APIClient          – REST client for backend profile operations
├── NetworkMonitor     – NWPathMonitor wrapper; publishes reachability state; fires `onBecameOnline` / `onStatusChange`
├── ProfileSync        – awaited network writes + `pullProfile`; holds `TokenSource`; persists cache only after success
└── SyncCoordinator    – sole owner of profile pull; checks `keychain.loadSession() != nil` to gate pull; triggered on foreground, network restore, session active, auth success
```

`AppContainer.live` is a static singleton assembled at app start. Dependencies are injected into features via the container reference passed through the view hierarchy.

---

## Storage

| Store | Type | Purpose |
|-------|------|---------|
| `ProfileRecord` | SwiftData `@Model` | Local profile cache for the current auth user (bound to `userId`; name, gender, DOB, photo, color, onboarding fields, `updatedAt`) |
| Keychain (`auth.token`) | `Security.framework` | Legacy single-token slot (backward compatibility) |
| Keychain (`auth.session`) | `Security.framework` | JSON-encoded `Session` struct with `accessToken`, `refreshToken`, and optional `userId` |

`DatabaseClient` owns the `ModelContainer` and exposes typed methods (`prepareProfileForUser`, `clearUserLocalState`, `upsertProfileFields(ProfilePatch)`, `getProfile`, `applyRemoteProfile`, `markOnboardingCompleted`). `prepareProfileForUser(_:)` is the only way the singleton profile row is created or rebound; it wipes the row whenever the current auth user id does not match the cached row's `userId`. If the on-disk store cannot open after the schema drop (the old `OutboxRecord` model), the store files are deleted and recreated. Profile field updates use `ProfilePatch` (typed properties) with `asDictionary()` only at the HTTP body boundary. Callers never access the model context directly. An `init(logger:inMemory:)` overload backs an in-memory `ModelContainer` for unit tests; production always uses the default on-disk store.

---

## Networking

Two distinct clients handle different backends:

- **`SupabaseClient`** — wraps the official `Supabase` Swift SDK. All auth operations are live: `signInWithPassword`, `signUp`, `signOut`, `resetPasswordForEmail`, `updatePassword`, `exchangeCodeForSession`, `signInWithIdToken` (Apple). Logs auth failures at `warn` with structured `AuthError` metadata (no tokens or credentials). Conforms to `TokenSource`: `currentAccessToken()` reads `client.auth.session.accessToken` (the SDK persists its session to its own Keychain entry, independent of `KeychainClient`, and auto-refreshes on read if at/near expiry); `forceRefresh()` calls `client.auth.refreshSession()` and is invoked only after a real 401 from the backend. `observeSessionInvalidated(_:)` subscribes to `client.auth.onAuthStateChange` filtered to `.signedOut`; the registration handle is retained in a class-backed `ListenerBox` for the app's process lifetime.
- **`APIClient`** — communicates with the WayTwo backend REST API (profile fetch and updates, plus unauthenticated `checkEmailRegistered`). Takes `tokenSource: TokenSource` on authenticated methods (`fetchProfile`, `patchProfile`, `postProfileComplete`). Every request uses a shared retry policy: up to 3 attempts with 0.5s / 1s / 2s delays on transport errors and 5xx. 4xx is not retried. On HTTP 401 the private `request` helper calls `tokenSource.forceRefresh()` once and retries that attempt; a second 401 propagates as a thrown error. Accepts an injectable `URLSession` (defaults to `.shared`) for unit testing.

Both clients are initialized from `Config.xcconfig`-backed values (`Config.apiURL`, `Config.supabaseURL`, `Config.supabasePublishableKey`). Secrets are not embedded in source.

`JWTAccessToken.subject(_:)` (`Core/Network/`) is a dependency-free helper that decodes only the `sub` claim from a JWT payload, used solely to recover the auth user id from a pre-migration Keychain session. It never logs the token or any claim.

---

## Sync

### Connectivity-gated writes

Profile mutations are sent to the backend immediately. There is no durable write queue. Onboarding Continue / Finish are disabled while `NetworkMonitor` reports offline. `ProfileSync` awaits `APIClient`, which applies the shared retry policy, and applies the remote profile only after success. Killing the app during a write drops that write.

`SyncCoordinator` only pulls — after app foreground (`scenePhase == .active`), when the network transitions from offline to online, after sign-in / Apple SSO, and after restoring a session on cold launch.

`markOnboardingCompleted()` writes `onboardingCompletedAt` locally after `POST /me/profile/complete` succeeds so a later pull failure does not send the user back through onboarding.

### ProfileSync

`ProfileSync` performs awaited writes and explicit pulls:

| Method | Direction | When called |
|--------|-----------|-------------|
| `pullProfile()` | Remote → local | `SyncCoordinator` session / foreground / online |
| `pushProfile(patch:)` | Network then local | Onboarding You save |
| `completeOnboarding(look:)` | Network then local | Onboarding Look finish (PATCH look fields, then POST complete) |

Write-path methods return `Result<Void, ProfileSyncError>`. After `APIClient` retries are exhausted, failures map to `error.saveFailed` and do not persist the patch.

---

## Design Tokens

Shared design values are defined in `Core/Design/` and must be used by all views. Raw numeric literals for spacing, sizing, radius, or color are not permitted.

### `Tokens` (spacing, radius, size)

| Namespace | Values |
|-----------|--------|
| `Tokens.Spacing` | `xs` (4), `md` (8), `lg` (12), `xl` (16), `x2l` (20), `x3l` (24), `x4l` (32) |
| `Tokens.Radius` | `md` (12), `lg` (16), `glassPanel` (26), `full` (28) |
| `Tokens.FontSize` | `sm` (13), `md` (14), `lg` (16), `xl` (17), `x2l` (24), `avatarInitial` (48) |
| `Tokens.Size` | `inputHeight` / `buttonHeight` (56), `avatar` (120), `glowRadius` (240), `cropCircle` (300), `swatchTap` (48), `swatchInner` (36) |

### Shared UI components (`Core/UI/`)

| Component | Purpose |
|-----------|---------|
| `ProfileAvatarView` | Displays an avatar circle (photo or color-keyed initial/icon) with optional name label below; accepts `colorId`, `photoPath`, `displayName`, `showsName`; used on Home and Onboarding Look |
| `GlassPanelBackground` | `ViewModifier`; applies `glassEffect(.regular.interactive())` on iOS 26+, frosted fill + stroke fallback on earlier OS; for rounded-rect panels |
| `GlassCircleBackground` | `ViewModifier`; same adaptive glass treatment for circular shapes |
| `AvatarCropView` | Full-screen crop: pinch-to-zoom, drag-to-pan, circular mask; confirm renders a clipped JPEG via `AvatarPhotoFileStore.saveJPEG` |
| `CameraPickerView` | `UIViewControllerRepresentable` over `UIImagePickerController` (`.camera`, front-facing) |
| `PrimaryButton` | Primary CTA with disabled/pressed states driven by tokens |
| `AppTextField` / `SecureInputField` | Styled form inputs |
| `FormScreenScrollContainer` | Scroll container enforcing vertical rhythm for form screens |

### Profile photo (crop)

- **`OnboardingLookView`** / **`ProfileEditView`** — Menu for **Camera** / **Photo Library**; library uses SwiftUI **`PhotosPicker`** (no `NSPhotoLibraryUsageDescription`); after selection or capture, **`fullScreenCover(item:)`** presents **`AvatarCropView`**.

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
| `glassBg` | Translucent panel fill |
| `glassBorder` | Stroke for glass panels and circles |
| `avatarGlassBg` | Avatar circle fill when no photo is set; lighter opacity than `glassBg` |
| `profileFallback` | Avatar placeholder color when `colorId` has no palette match |
| `profilePalette` | Named color swatches for avatar selection (coral, tangerine, amber, lemon, leaf, mint, sky, azure, purple, magenta, rose, crimson) |

### `Gradients`

| Name | Type | Usage |
|------|------|-------|
| `Gradients.auth` | `RadialGradient` | Auth screen background overlay |
| `Gradients.profileGlowStops(color:)` | `[Gradient.Stop]` | Dynamic glow behind the avatar on Home and Onboarding Look screens |

---

## Settings Tab

`SettingsView` is the second main tab (`AppReducer.Tab.settings`). It currently exposes:

- **Logout** — calls `logout()` on `AppView` (see `AppView+Session.swift`), which signs out via Supabase, calls `container.clearLocalSession()` (shared helper that deletes the Keychain session and wipes local state), and resets root state to `AppReducer.State()`.
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
| `debug` | Internal transitions (SwiftData writes, network status) |
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
| Profile sync (pull) | Done (post-auth, foreground, and on-reconnect via `NetworkMonitor.onBecameOnline`) |
| Token auto-refresh (401 retry) | Done (`APIClient` retries once with `forceRefresh()`; SDK auto-refreshes on `currentAccessToken()`; SDK-reported session invalidation clears local state and returns user to sign-in) |
| Offline write queue | Removed (connectivity-gated writes; in-flight retry only) |
| Backend-driven onboarding routing | Done (`ProfileCompleteness`; local cache scoped to auth `userId`, wiped on user switch / logout) |
| Push notifications | Out of scope |
| Android / cross-platform | Not applicable — iOS only |

The POC is considered complete when all validation criteria in ADR-0007 are met. Promotion to the primary app path requires a separate decision.
