# ADR-0003: Design tokens in TypeScript (no CSS-in-JS theme framework)

## Status

Accepted

## Context

Screens used scattered numeric values for spacing, type, and radii, and a few hardcoded hex colors outside the theme module. Figma defines semantic colors for auth and onboarding; the codebase needs a single place for layout/typography scales and a clear split between app semantics and legacy template colors.

## Decision

1. Keep **semantic colors** in **`mobile/src/constants/theme/`** (`AppColors`, `palette.ts`, `AuthSsoColors`, onboarding exports). Apple SSO merges via **`useAuthColors()`**; other UI uses **`useAppColors()`**. Legacy Expo tab/demo colors live next to those screens or in **`use-theme-color.ts`**, not in `AppColors`. Keep **Figma-shaped radial blob palettes and geometry** in **`mobile/src/constants/gradients.ts`**, rendered via **`mobile/src/components/ui/radial-blob.tsx`** (Skia).
2. Keep **`mobile/src/constants/tokens.ts`** for non-color design decisions: **`Spacing`**, **`FontSize`**, **`LineHeight`**, **`FontWeight`**, **`BorderRadius`**, **`Size`**, **`IconSize`**, **`Opacity`**, **`LayoutOffset`**.
3. **Do not** adopt NativeWind, Tamagui, or Unistyles for this iteration; `StyleSheet.create` + tokens keeps dependencies low and matches current patterns.
4. When Figma and code disagree, prefer aligning new work to Figma and record discrepancies with **`FIGMA_GAP`** comments in `tokens.ts` (or adjacent to the relevant color token).

## Consequences

- UI code imports tokens explicitly; refactors are grep-friendly.
- Theming libraries can still be evaluated later without blocking i18n or auth work.

## Related

- `.cursor/rules/figma-design-context.mdc`
- Feature: `architecture/features/design-system.md`

**Author:** Ivan Kulaha
