# ADR-0007: Native iOS Migration POC from React Native

## Status

Accepted

## Context

WayTwo currently ships mobile functionality from `mobile/` using React Native and Expo. The product direction requires validating whether a native iOS architecture provides better long-term maintainability, stronger platform integration, and clearer state-management boundaries for complex flows (authentication, onboarding, local-first profile sync).

The repository already contains a new iOS target under `mobile-ios/`, but it is currently template-level and does not implement application features.

## Decision

1. Build a **native iOS POC** in `mobile-ios/` using SwiftUI and The Composable Architecture (TCA).
2. Keep `mobile/` unchanged during the POC. React Native remains the reference implementation until the native app is validated.
3. Use native iOS equivalents for core infrastructure:
   - Session persistence: Keychain (`Security.framework`)
   - Local-first persistence: SwiftData
   - Reachability: `Network.NWPathMonitor`
   - Navigation: `NavigationStack` + `TabView`
   - Localization: String Catalogs (`.xcstrings`) with English and Ukrainian locales
4. Integrate with the existing Supabase backend using the official Supabase Swift SDK.
5. Implement feature parity in this order: app shell and root state, auth, onboarding, profile, home.

## Consequences

- Native iOS work can progress without disrupting the active React Native app.
- Teams can compare delivery speed, code quality, runtime behavior, and maintainability between stacks.
- Short-term maintenance cost increases because both implementations coexist during validation.
- The POC can be promoted to the primary app path only after explicit validation and rollout criteria are met.

## Validation Criteria

The POC is considered successful when:

1. Auth, onboarding, profile, and home flows are available in `mobile-ios/`.
2. Local profile data persists and sync logic works under offline/online transitions.
3. The app uses centralized, testable state reducers with dependency injection boundaries.
4. Localization parity exists for all user-facing strings used by implemented screens.

## Related

- Existing ADRs: `architecture/adr/0001-authentication-with-supabase.md`, `architecture/adr/0006-local-first-profile-with-expo-sqlite.md`
- Requirements: `requirements/auhentication.md`, `requirements/onboarding.md`, `requirements/pair-creation.md`

**Author:** Ivan Kulaha
