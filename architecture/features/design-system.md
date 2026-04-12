# Feature: Design system (tokens + theme)

## Overview

WayTwo mobile UI uses React Native **`StyleSheet.create`**. Visual consistency comes from two TypeScript modules:

1. **`mobile/constants/theme.ts`** — color semantics:
   - **`AuthColors`** (light/dark) for auth surfaces, inputs, text, buttons, glass controls, errors.
   - **`AuthFlowGradients`** — per-flow gradient stops; last stop ties to `gradientEnd` for the active scheme.
   - **`Colors`** — default app / tab theming (`useThemeColor`).
   - **`ExploreTemplateColors`** — template Explore header background (light/dark) and muted icon color.
   - **`Fonts`** — platform font stacks for template screens.

2. **`mobile/constants/tokens.ts`** — layout and typography:
   - **`Spacing`**, **`FontSize`**, **`LineHeight`**, **`FontWeight`**, **`BorderRadius`**, **`Size`**, **`IconSize`**, **`Opacity`**, **`LayoutOffset`**.

## Figma

Design reference: Way-Two file (see `.cursor/rules/figma-design-context.mdc`). Token values should be reconciled with Figma; documented gaps use **`FIGMA_GAP`** in `tokens.ts`.

## Theming behavior

- Auth: gradient header is brand-stable; **surface and controls** follow **`useAuthColors()`** (`useColorScheme`).
- Non-auth tabs: **`ThemedText` / `ThemedView`** and **`useThemeColor`**.

**Author:** Ivan Kulaha
