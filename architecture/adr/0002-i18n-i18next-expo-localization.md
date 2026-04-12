# ADR-0002: Mobile i18n with i18next and expo-localization

## Status

Accepted

## Context

The product targets **English** and **Ukrainian** (per design). The app needs runtime strings, validation messages, and tab/stack titles that follow the device language when supported.

## Decision

1. Use **`i18next`** with **`react-i18next`** for translation API and React bindings.
2. Use **`expo-localization`** to read the device locale and pick **`uk`** when the primary language code is Ukrainian; otherwise use **`en`**, with **`en`** as fallback.
3. Store translations in **JSON** files under `mobile/locales/{en,uk}/common.json`, loaded at init (default namespace `translation`).
4. Disable suspense for React i18n (`useSuspense: false`) to avoid extra Suspense boundaries in Expo Router.
5. Do **not** use `next-intl` or server-driven i18n on the Next.js API for user-facing mobile copy (API remains English-only JSON for now).

## Alternatives considered

- **`expo-localization` only** with a hand-rolled map: less interpolation/plural features and weaker ecosystem.
- **`react-intl` (FormatJS):** heavier bundle and different conventions; team-standard JSON + i18next is sufficient.

## Consequences

- New copy requires updating **two** JSON files in lockstep.
- Tab titles and other navigation strings must be set from components under `I18nextProvider`.

## Related

- `mobile/lib/i18n.ts`
- Feature: `architecture/features/i18n.md`

**Author:** Ivan Kulaha
