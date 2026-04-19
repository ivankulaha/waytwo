# Feature: Design system (tokens + theme)

## Overview

WayTwo mobile UI uses React Native **`StyleSheet.create`**. Visual consistency comes from TypeScript modules:

1. **`mobile/src/constants/theme.ts`** — color semantics:
   - **`AuthColors`** (light/dark) for auth surfaces, inputs, text, buttons, glass controls, errors.
   - **`Colors`** — default app / tab theming (`useThemeColor`).
   - **`ExploreTemplateColors`** — template Explore header background (light/dark) and muted icon color.
   - **`Fonts`** — platform font stacks for template screens.
   - Onboarding-specific constants (`OnboardingPalette`, avatar glow stops, etc.).

2. **`mobile/src/constants/gradients.ts`** — Figma-shaped **radial blob** presets:
   - **`RadialBlobGeometryPreset`** — screen-width-relative ellipse geometry (shared auth + onboarding intro).
   - **`RadialBlobPalette`** — named palettes as `{ colors, positions }` pairs (same stop model as the Figma radial picker).
   - **`useRadialBlobSpec`** — resolves palette + geometry for the current (or overridden) color scheme.

3. **`mobile/src/constants/tokens.ts`** — layout and typography:
   - **`Spacing`**, **`FontSize`**, **`LineHeight`**, **`FontWeight`**, **`BorderRadius`**, **`Size`**, **`IconSize`**, **`Opacity`**, **`LayoutOffset`**.

## Radial blob backgrounds (Skia)

- **`mobile/src/components/ui/radial-blob.tsx`** — `@shopify/react-native-skia` `Canvas` + `RadialGradient`; elliptical blobs use a Y-scale transform on the shader (Skia radial is circular in shader space).
- Palettes and geometry live in **`gradients.ts`**; screens and shells should not duplicate magic numbers for blob layout.
- Stop lists should match Figma picker stops **1:1** (count + positions); avoid ad hoc easing rows unless a design explicitly requires them.

## Figma

Design reference: Way-Two file (see `.cursor/rules/figma-design-context.mdc`). Token values should be reconciled with Figma; documented gaps use **`FIGMA_GAP`** in `tokens.ts`.

## Theming behavior

- Auth and onboarding intro: **`AuthShell`** composes **`<RadialBlob>`** when `backgroundMode` is `flow` or `onboardingIntro`, using `useRadialBlobSpec` + `AuthColors` / system scheme rules for surfaces and copy colors.
- Non-auth tabs: **`ThemedText` / `ThemedView`** and **`useThemeColor`**.

**Author:** Ivan Kulaha
