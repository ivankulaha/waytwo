/**
 * Layout, typography, and radius tokens. Colors live in `theme.ts`.
 * Cross-check with Figma (node 52:791) and `.cursor/rules/figma-design-context.mdc`.
 * FIGMA_GAP: Figma lists `inputBg` `#0a0a0a`; `AuthColors.dark.inputBg` uses `#0d0d0d` for contrast with borders.
 */

export const Spacing = {
  xxs: 2,
  xs: 4,
  sm: 6,
  md: 8,
  lg: 12,
  inputX: 14,
  mdLg: 15,
  xl: 16,
  '2xl': 20,
  '3xl': 24,
  '4xl': 32,
} as const;

export const FontSize = {
  xs: 12,
  sm: 13,
  md: 14,
  base: 15,
  lg: 16,
  xl: 17,
  '2xl': 20,
  '3xl': 24,
  '4xl': 28,
  '5xl': 32,
} as const;

export const LineHeight = {
  tight: 20,
  snug: 22,
  normal: 24,
  relaxed: 30,
  loose: 32,
} as const;

export const FontWeight = {
  regular: '400' as const,
  medium: '500' as const,
  semibold: '600' as const,
  bold: '700' as const,
};

export const BorderRadius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 28,
} as const;

export const Size = {
  inputHeight: 56,
  buttonHeight: 56,
  iconButton: 48,
  borderWidth: 1,
  separatorLine: 1,
  tabBarIcon: 28,
  parallaxHeader: 250,
  demoImage: 100,
} as const;

export const IconSize = {
  sm: 18,
  md: 20,
  lg: 22,
  xl: 28,
  hero: 310,
} as const;

export const Opacity = {
  disabled: 0.45,
  pressed: 0.85,
  pressedLight: 0.88,
  appleDisabled: 0.5,
  subtitle: 0.85,
} as const;

export const LayoutOffset = {
  exploreHeaderImageBottom: -90,
  exploreHeaderImageLeft: -35,
  helloWaveMarginTop: -6,
} as const;
