/**
 * Layout, typography, and radius tokens. Colors live in `theme.ts`.
 * Cross-check onboarding with Figma Copy (`NIofouu7Ph9yhZs118YH9j`, section `326:5994`) and `.cursor/rules/figma-design-context.mdc`; auth board `52:791` in that rule for auth-only.
 * Input states (empty / active / filled) and full-width pill button colors are aligned to Figma `344:723` (Input) and `344:682` (Button) in `AuthColors`.
 */

export const Spacing = {
  xxs: 2,
  xs: 4,
  sm: 6,
  md: 8,
  lg: 12,
  /** Figma color swatch rows (node 124:6280). */
  swatchRowGap: 10,
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
  /** Figma onboarding look: avatar placeholder letter (node 124:6276). */
  onboardingAvatarGlyph: 48,
} as const;

export const LineHeight = {
  tight: 20,
  /** Figma profile color section label (13px / 16px, node 124:6279). */
  profileColorLabel: 16,
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
  /** Onboarding profile-color section outer radius (Figma look screen). */
  onboardingColorCard: 26,
  full: 28,
} as const;

export const Size = {
  /** Figma onboarding look avatar (node 124:6275). */
  onboardingAvatar: 120,
  /** Stage for radial glow — diameter near screen edges (Figma look screen). */
  onboardingAvatarGlowStage: 364,
  inputHeight: 56,
  buttonHeight: 56,
  iconButton: 48,
  /** Figma onboarding look: color swatch tap target (`48` pt, section `326:5994`). */
  swatchTap: 48,
  /** Figma onboarding look: filled color disk inside tap target (`36` pt, section `326:5994`). */
  swatchInner: 36,
  borderWidth: 1,
  /** Selected profile-color swatch ring; matches swatch hex (not white). Gap = (swatchTap - swatchInner) / 2. */
  swatchSelectionRing: 2,
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
  /** Dim layer behind bottom-sheet modals (e.g. date picker). */
  modalBackdrop: 0.45,
} as const;

export const Overlay = {
  /** rgba black with `Opacity.modalBackdrop` alpha for modal scrims. */
  modalBackdrop: `rgba(0,0,0,${Opacity.modalBackdrop})`,
} as const;

export const LayoutOffset = {
  exploreHeaderImageBottom: -90,
  exploreHeaderImageLeft: -35,
  helloWaveMarginTop: -6,
} as const;
