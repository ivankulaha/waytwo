# Feature: Design system (tokens + theme)

## Overview

WayTwo mobile UI uses React Native **`StyleSheet.create`**. Visual consistency comes from TypeScript modules:

1. **`mobile/src/constants/theme/`** — modular color and typography foundations:
   - **`semantic.ts`** — **`AppColors`** (light/dark): surfaces (`surface`, **`surfaceElevated`** for cards / glass fallbacks), inputs, text, buttons, glass controls, errors, links.
   - **`palette.ts`** — raw hex values referenced by semantic and auth SSO tokens.
   - **`auth.ts`** — **`AuthSsoColors`**: Apple SSO button only (`ssoBg`, `ssoText`, `ssoPressedBg`).
   - **`onboarding.ts`** — `OnboardingPalette`, avatar glow stops, initials color.
   - **`fonts.ts`** — **`Fonts`**: platform font stacks (used by product and template screens).
   - **`index.ts`** — re-exports the above. Does **not** export Expo-starter tab/template palettes (those live next to legacy screens or in `use-theme-color.ts`).

2. **`mobile/src/hooks/use-app-colors.ts`** — **`useAppColors()`** returns the current scheme’s **`AppSemanticColors`**. Use this for almost all UI (onboarding, forms, glass primitives, shared components).

3. **`mobile/src/hooks/use-auth-colors.ts`** — **`useAuthColors()`** returns **`AppSemanticColors` merged with `AuthSsoColors`** for auth screens that render Apple Sign In.

4. **`mobile/src/hooks/use-theme-color.ts`** — legacy Expo-starter palette for **`ThemedText`**, **`ThemedView`**, parallax demo, and **`(tabs)/index`**. Marked for removal with the new home/tab redesign.

5. **`mobile/src/constants/gradients.ts`** — Figma-shaped **radial blob** presets:
   - **`RadialBlobGeometryPreset`** — screen-width-relative ellipse geometry (shared auth + onboarding intro).
   - **`RadialBlobPalette`** — named palettes as `{ colors, positions }` pairs (same stop model as the Figma radial picker).
   - **`useRadialBlobSpec`** — resolves palette + geometry for the current (or overridden) color scheme.

6. **`mobile/src/constants/tokens.ts`** — layout and typography:
   - **`Spacing`**, **`FontSize`**, **`LineHeight`**, **`FontWeight`**, **`BorderRadius`**, **`Size`**, **`IconSize`**, **`Opacity`**, **`LayoutOffset`**.

## Radial blob backgrounds (Skia)

- **`mobile/src/components/ui/radial-blob.tsx`** — `@shopify/react-native-skia` `Canvas` + `RadialGradient`; elliptical blobs use a Y-scale transform on the shader (Skia radial is circular in shader space).
- Palettes and geometry live in **`gradients.ts`**; screens and shells should not duplicate magic numbers for blob layout.
- Stop lists should match Figma picker stops **1:1** (count + positions); avoid ad hoc easing rows unless a design explicitly requires them.

## Glass UI primitives

Two shared components gate native glass behind a feature-availability check and fall back gracefully on older OS versions.

- **`mobile/src/components/ui/back-button.tsx`** — `BackButton`. Renders a `GlassView` (from `expo-glass-effect`) when both `isLiquidGlassAvailable()` and `isGlassEffectAPIAvailable()` return `true` (iOS 26+). Otherwise renders a flat control with **`AppColors.glassBg`** / **`AppColors.glassBorder`**.
- **`mobile/src/components/ui/glass-surface.tsx`** — `GlassSurface`. Card-like container using the same gate; fallback uses **`AppColors.surfaceElevated`** / **`AppColors.inputBorder`**.

**iOS 26+ requirement:** native liquid glass (`GlassView`) is only available on iOS 26 and later. Both components call the Expo SDK capability helpers at render time — no build-time flag is needed.

**Fallback behavior:** on iOS < 26 and all Android targets the components render flat surfaces using **`useAppColors()`** tokens; visual appearance degrades gracefully without layout shifts.

**Usage:** `AuthShell` uses `BackButton` in place of an inline `Pressable`; the onboarding `look.tsx` color card is wrapped in `GlassSurface`.

## Figma

Design reference: Way-Two file (see `.cursor/rules/figma-design-context.mdc`). Token values should be reconciled with Figma; documented gaps use **`FIGMA_GAP`** in `tokens.ts`.

## Theming behavior

- Auth and onboarding intro: **`AuthShell`** composes **`<RadialBlob>`** when `backgroundMode` is `flow` or `onboardingIntro`, using `useRadialBlobSpec` + **`useAuthColors()`** (same tokens as app semantics plus SSO keys unused by the shell) and system scheme rules for surfaces and copy colors.
- Legacy template tabs / demo: **`ThemedText` / `ThemedView`** and **`useThemeColor`** (see hook file TODO).

**Author:** Ivan Kulaha
