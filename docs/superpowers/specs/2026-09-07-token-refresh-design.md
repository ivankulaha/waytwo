# Design: Supabase access token refresh (native iOS)

Date: 2026-09-07
Author: Ivan Kulaha

## Problem

`PATCH /me/profile`, `POST /me/profile/complete`, and `GET /me/profile` all fail
uniformly once a session is more than ~1 hour old. Root cause (confirmed by
tracing the code, not guessed):

- The backend's Next.js middleware (`backend/api/src/middleware.ts`) verifies
  the bearer token via `supabase.auth.getUser(token)` on every `/api/v1/*`
  request and returns a bare `401` before any route handler runs if that
  fails. This is a content-agnostic failure, which is why PATCH, POST, and a
  plain GET all fail identically in the same batch.
- On the iOS side, `KeychainClient.Session` stores a raw `accessToken` +
  `refreshToken` string pair. `SyncCoordinator.sessionBecameActive()` reads
  `keychain.loadSession()?.accessToken` and passes that static string straight
  into `Outbox`/`ProfileSync`/`APIClient`.
- Nothing in the codebase calls `refreshSession`, `setSession`, or checks
  token expiry (confirmed via full-repo grep). Supabase access tokens expire
  after ~1 hour by default, so any session older than that fails every
  backend call until the user manually signs out and back in.

## Key finding: the SDK already does most of this

Inspecting `supabase-swift`'s `AuthClient.swift` (via
`~/Library/Developer/Xcode/DerivedData/.../SourcePackages/checkouts/supabase-swift`):

- `client.auth.session` (async getter): *"Returns the session, refreshing it
  if necessary."* Backed by an internal `SessionManager` (SDK-internal type,
  not to be confused with the one added below) with an `autoRefreshToken`
  config (default `true`) that starts a background refresh timer and also
  ticks on app foreground.
- `client.auth.setSession(accessToken:refreshToken:)`: decodes the JWT `exp`
  claim; if already expired, calls `refreshSession(refreshToken:)`
  automatically and stores the result in the SDK's internal session state.
  If not expired, it hydrates the SDK's internal state directly from the
  given tokens without a network call.
- `client.auth.refreshSession(refreshToken:)`: explicit forced refresh.
- `client.auth.onAuthStateChange`: emits a `.tokenRefreshed` event whenever
  the SDK refreshes in the background.

**Conclusion:** we do not need to reimplement expiry math, single-flight
refresh locking, or a background refresh timer. We need to (1) hydrate the
SDK's internal session from Keychain on cold launch (today nothing does this,
so the SDK has no internal session to refresh outside of the same-process
window right after sign-in/sign-up), and (2) always source our own
`APIClient` bearer token from the SDK's session getter instead of a static
Keychain string, and (3) keep Keychain's copy in sync so `resolveUserId` /
next cold launch still work.

## Decisions (confirmed with user)

1. **Refresh strategy:** both proactive (via the SDK's own `session` getter,
   which refreshes near/at expiry) and reactive (one retry after an actual
   401, as a safety net for server-side revocation the SDK's local `exp`
   check can't know about).
2. **Ownership:** a new dedicated `SessionManager` type, not `APIClient`
   itself and not `SyncCoordinator` alone. Both `APIClient` and
   `SyncCoordinator`/`Outbox`/`ProfileSync` depend on it for tokens.
3. **Refresh failure handling:** if the refresh token itself is dead
   (revoked/expired), force a full logout: clear Keychain + local profile
   state, reset to the signed-out `AppReducer.State()`, and surface a
   "session expired, please sign in again" message on the auth screen.

## Components

### `SupabaseClient` (existing file, additive changes)

New methods, each a thin wrapper so `SessionManager` never touches the
`Auth`/`Supabase` SDK types directly (keeps external systems routed through
`Core/` per the architecture rule):

```swift
func hydrateSession(accessToken: String, refreshToken: String) async throws -> SessionTokens
func currentAccessToken() async throws -> String
func forceRefresh() async throws -> SessionTokens
func onTokenRefreshed(_ handler: @escaping (SessionTokens) -> Void)
func onSignedOut(_ handler: @escaping () -> Void)
```

`hydrateSession` wraps `client.auth.setSession(accessToken:refreshToken:)`.
`currentAccessToken` wraps `try await client.auth.session.accessToken`.
`forceRefresh` wraps `client.auth.refreshSession(refreshToken:)`.
The two `on*` methods wrap `client.auth.onAuthStateChange` filtering for the
relevant `AuthChangeEvent` cases.

### `SessionManager` (new, `Core/Network/SessionManager.swift`, actor)

```swift
actor SessionManager {
    var onSessionInvalidated: (() -> Void)?

    init(supabase: SupabaseClient, keychain: KeychainClient, logger: AppLogger)

    /// Ensures the SDK has a live internal session from Keychain. No-op if
    /// already hydrated this process. Call once at app launch / after
    /// authentication, before any authenticated network call.
    func hydrateFromKeychainIfNeeded() async

    /// A token guaranteed valid at the time of return (SDK refreshes under
    /// the hood if near/at expiry). Throws if there is no session or the
    /// refresh token is dead; fires `onSessionInvalidated` in the latter
    /// case before throwing.
    func validAccessToken() async throws -> String

    /// One-shot forced refresh used only after a real 401 from our own
    /// backend. Throws (and fires `onSessionInvalidated`) if the refresh
    /// token is dead.
    func handleUnauthorized() async throws -> String
}
```

Internally, on init, calls `supabase.onTokenRefreshed { … }` to persist the
new `accessToken`/`refreshToken`/`userId` to Keychain (so `resolveUserId` and
the next cold launch see current tokens), and `supabase.onSignedOut { … }` to
fire `onSessionInvalidated`.

`hydrateFromKeychainIfNeeded`/`validAccessToken`/`handleUnauthorized` funnel
through the actor's serialized execution, so concurrent callers (outbox flush
+ profile pull firing at the same time) can't trigger overlapping SDK calls;
the actor gives us the "no duplicate refresh in flight" property for free
without hand-rolled locking.

### `APIClient` (existing file, signature change)

`fetchProfile`, `patchProfile`, `postProfileComplete` change from
`accessToken: String` to `sessionManager: SessionManager`. The private
`request<T,Body>` helper gains a `requiresAuth: Bool` path: when true, it asks
`sessionManager.validAccessToken()` for the bearer token; if the response is
specifically HTTP `401`, it calls `sessionManager.handleUnauthorized()` once
and retries the same request once with the new token. A second `401`
propagates as a thrown error (by then `onSessionInvalidated` has already
fired from inside `SessionManager`).

`checkEmailRegistered` is unaffected (no auth required).

### `Outbox` / `ProfileSync` / `SyncCoordinator`

Drop the `accessToken` parameter entirely:

- `Outbox.flush() async` (was `flush(accessToken: String?)`)
- `ProfileSync.pullProfile() async` (was `pullProfile(accessToken: String)`)
- `SyncCoordinator.sessionBecameActive()`: only checks
  `keychain.loadSession() != nil` to decide whether a sync attempt is worth
  making at all (cheap short-circuit for the fully-signed-out case); no
  longer reads or threads a token value.

Both `Outbox` and `ProfileSync` take a `SessionManager` in their initializer
instead of relying on a passed-in token.

### `AppContainer`

Constructs `SessionManager` after `supabase`/`keychain`/`logger`, wires
`sessionManager.onSessionInvalidated` to a new `AppContainer`-level closure
that `WayTwoApp` sets to call the existing `AppView.logout()` cleanup path
(minus the `signOut()` network call, since the session is already dead;
still clears Keychain + local DB + resets state and sets the new
`auth.sessionExpired` error key), and passes `sessionManager` into `api`,
`outbox`, `profileSync`.

### Cold launch (`WayTwoApp.RootContent`)

`routeAfterAuthentication()` calls
`await appContainer.sessionManager.hydrateFromKeychainIfNeeded()` before
`syncCoordinator.sessionBecameActive()`, so the SDK's session (and its
background auto-refresh timer) is live from process start rather than only
after an in-process sign-in/sign-up call.

## Error handling

- Individual outbox item failures (e.g. a genuine validation error from the
  backend): unchanged, log a warning and retry later.
- `SessionManager` reports the session as invalid (refresh token dead):
  `onSessionInvalidated` fires once, clears Keychain + local profile/outbox,
  resets `AppReducer.State()`, and sets `state.auth.errorKey =
  "auth.sessionExpired"` so the sign-in screen explains why the user landed
  there. New string added to `Localizable.xcstrings` in `en` and `uk`.
- `Outbox.flush()` stops processing remaining items early if
  `sessionManager.validAccessToken()` throws before the loop starts (no
  point retrying items one by one against a dead session).

## Testing

- `SessionManager` unit tests against a `TokenProviding`-style seam (a small
  protocol matching the `SupabaseClient` methods used) covering: valid token
  passthrough, forced refresh persisting new tokens to Keychain, and
  `onSessionInvalidated` firing exactly once when the refresh token is dead.
- `APIClient` 401-retry-once behavior via a stub `URLProtocol` (first
  response 401, second response 200 after a “refreshed” token is used;
  confirm the Authorization header changes between the two requests).
- `Outbox`/`ProfileSync` tests updated to the new no-token signatures.

## Out of scope

- Building a custom expiry/refresh clock (the SDK's `autoRefreshToken`
  already covers this).
- Multi-account / concurrent-session support.
- Changing the backend's 401 contract.
