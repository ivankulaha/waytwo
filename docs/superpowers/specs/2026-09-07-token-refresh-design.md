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

## Key finding: `client.auth` is already a complete, self-persisting session manager

Inspecting `supabase-swift`'s source (via
`~/Library/Developer/Xcode/DerivedData/.../SourcePackages/checkouts/supabase-swift`):

- `client.auth` (`Auth.AuthClient`) is itself an `actor`, constructed once
  inside our `SupabaseClient` wrapper's `client: Supabase.SupabaseClient` and
  held for the app's whole process lifetime.
- Its default local storage is `KeychainLocalStorage` — **its own Keychain
  entry, entirely separate from our hand-rolled `KeychainClient`**:
  ```
  public static let defaultLocalStorage: any AuthLocalStorage = KeychainLocalStorage()
  ```
  This means the SDK persists and restores its session across app launches
  on its own; no manual "hydrate from our Keychain" step is needed.
- `client.auth.session` (async getter) is backed by the SDK-internal
  `SessionManager` (an SDK-private type, not the one originally proposed
  below):
  ```swift
  func session() async throws -> Session {
    guard let currentSession = sessionStorage.get() else { throw AuthError.sessionMissing }
    if !currentSession.isExpired { return currentSession }
    return try await refreshSession(currentSession.refreshToken)
  }
  ```
  i.e. every read is proactive: expired sessions are refreshed transparently.
  Concurrent refreshes are single-flighted via an internal `inFlightRefreshTask`.
- `AuthClient.init` subscribes to `didBecomeActive`/`willResignActive` and
  starts/stops a periodic auto-refresh timer, so a foregrounded app also
  refreshes ahead of expiry without anything reading `session` first.
- When the SDK's own API layer gets back an error indicating the session/JWT
  is genuinely dead (revoked, user deleted, etc.), it clears its stored
  session and emits `.signedOut` via `client.auth.onAuthStateChange`, no
  custom detection needed:
  ```swift
  } else if let errorCode, sessionCleanupErrorCodes.contains(errorCode) {
    await sessionManager.remove()
    eventEmitter.emit(.signedOut, session: nil)
    return .sessionMissing
  }
  ```

**Conclusion:** the SDK already does everything a hand-rolled `SessionManager`
would: persistence, on-demand refresh, single-flight locking, background
auto-refresh, and an invalidation signal. Introducing a separate
`SessionManager` type would just re-wrap `SupabaseClient` with no new
behavior. **`SupabaseClient` (our existing wrapper) is the right and only
place for this** — extend it with a few small methods and have `APIClient`
depend on it directly instead of a raw token string.

## Decisions (confirmed with user)

1. **Refresh strategy:** both proactive (via the SDK's own `session` getter,
   which refreshes near/at expiry) and reactive (one retry after an actual
   401, as a safety net for server-side revocation the SDK's local `exp`
   check can't know about).
2. **Ownership:** originally scoped as a new dedicated `SessionManager` type.
   Revised after tracing the SDK: `SupabaseClient` (our existing wrapper
   around `client.auth`) already owns everything a `SessionManager` would,
   so it takes on this responsibility directly rather than through a new
   pass-through type. `APIClient` and `SyncCoordinator`/`Outbox`/`ProfileSync`
   depend on `SupabaseClient` for tokens.
3. **Refresh failure handling:** if the refresh token itself is dead
   (revoked/expired), force a full logout: clear Keychain + local profile
   state, reset to the signed-out `AppReducer.State()`, and surface a
   "session expired, please sign in again" message on the auth screen.

## Components

### `SupabaseClient` (existing file, additive changes — no new type)

Three small additions, each a thin wrapper so callers never touch
`Auth`/`Supabase` SDK types directly (keeps external systems routed through
`Core/` per the architecture rule):

```swift
/// A token guaranteed valid at the time of return (the SDK refreshes under
/// the hood if the persisted session is at/near expiry). Throws
/// `AuthError.sessionMissing` if there is no session at all.
func currentAccessToken() async throws -> String

/// One-shot forced refresh, used only after a real 401 from our own backend
/// (the SDK's on-demand refresh in `currentAccessToken` already covers plain
/// local expiry; this covers server-side revocation).
func forceRefresh() async throws -> String

/// Registers a handler fired when the SDK detects the session is genuinely
/// dead (revoked/deleted, not just locally expired) and clears itself.
/// Wraps `client.auth.onAuthStateChange`, filtered to `.signedOut`.
func observeSessionInvalidated(_ handler: @escaping () -> Void)
```

`currentAccessToken` wraps `try await client.auth.session.accessToken`.
`forceRefresh` wraps `try await client.auth.refreshSession().accessToken`.
No hydration step is needed: the SDK's `KeychainLocalStorage` already
persists and restores its own session across launches independently of our
`KeychainClient`.

### `APIClient` (existing file, signature change)

`fetchProfile`, `patchProfile`, `postProfileComplete` change from
`accessToken: String` to `supabase: SupabaseClient`. The private
`request<T,Body>` helper gains a `requiresAuth: Bool` path: when true, it asks
`supabase.currentAccessToken()` for the bearer token; if the response is
specifically HTTP `401`, it calls `supabase.forceRefresh()` once and retries
the same request once with the new token. A second `401` propagates as a
thrown error (by then the SDK has already emitted `.signedOut` internally,
see `observeSessionInvalidated` below).

`checkEmailRegistered` is unaffected (no auth required).

### `Outbox` / `ProfileSync` / `SyncCoordinator`

Drop the `accessToken` parameter entirely:

- `Outbox.flush() async` (was `flush(accessToken: String?)`)
- `ProfileSync.pullProfile() async` (was `pullProfile(accessToken: String)`)
- `SyncCoordinator.sessionBecameActive()`: only checks
  `keychain.loadSession() != nil` to decide whether a sync attempt is worth
  making at all (cheap short-circuit for the fully-signed-out case); no
  longer reads or threads a token value.

Both `Outbox` and `ProfileSync` take `SupabaseClient` in their initializer
instead of relying on a passed-in token.

### `AppContainer`

Wires `supabase.observeSessionInvalidated { … }` once, to a new
`AppContainer`-level closure that `WayTwoApp` sets to call the existing
`AppView.logout()` cleanup path (minus the `signOut()` network call, since
the session is already dead; still clears Keychain + local DB + resets state
and sets the new `auth.sessionExpired` error key), and passes `supabase`
into `api`, `outbox`, `profileSync` (already does, for `api`; `outbox` and
`profileSync` gain the dependency).

No cold-launch hydration step is needed. The SDK restores its own persisted
session from its own Keychain entry the first time anything calls
`client.auth.session`, so the very first `supabase.currentAccessToken()` call
after launch (inside `syncCoordinator.sessionBecameActive()`) is sufficient.

## Error handling

- Individual outbox item failures (e.g. a genuine validation error from the
  backend): unchanged, log a warning and retry later.
- SDK reports the session as invalid (refresh token dead, `.signedOut`
  event): the `observeSessionInvalidated` handler fires once, clears
  Keychain + local profile/outbox, resets `AppReducer.State()`, and sets
  `state.auth.errorKey = "auth.sessionExpired"` so the sign-in screen
  explains why the user landed there. New string added to
  `Localizable.xcstrings` in `en` and `uk`.
- `Outbox.flush()` stops processing remaining items early if
  `supabase.currentAccessToken()` throws before the loop starts (no point
  retrying items one by one against a dead session).

## Testing

- `APIClient` 401-retry-once behavior via a stub `URLProtocol` (first
  response 401, second response 200 after a "refreshed" token is used;
  confirm the Authorization header changes between the two requests). Since
  `APIClient` now depends on `SupabaseClient` for tokens, this needs a
  lightweight seam (protocol matching `currentAccessToken`/`forceRefresh`)
  so the test doesn't require a live Supabase project.
- `Outbox`/`ProfileSync` tests updated to the new no-token signatures.
- Manual/integration check: sign in, force the stored session to be treated
  as expired (or wait past the token lifetime in a test project with a short
  expiry), trigger a sync, and confirm the request succeeds without a manual
  sign-out/sign-in cycle.

## Out of scope

- Building a custom expiry/refresh clock, persistence layer, or single-flight
  locking (the SDK's `KeychainLocalStorage` + `autoRefreshToken` +
  `sessionManager` already cover all of this).
- Multi-account / concurrent-session support.
- Changing the backend's 401 contract.
