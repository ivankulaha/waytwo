/**
 * Below are the colors that are used in the app. The colors are defined in the light and dark mode.
 * There are many other ways to style your app. For example, [Nativewind](https://www.nativewind.dev/), [Tamagui](https://tamagui.dev/), [unistyles](https://reactnativeunistyles.vercel.app), etc.
 */

import { Platform } from 'react-native';

const tintColorLight = '#0a7ea4';
const tintColorDark = '#fff';

export type AuthColorScheme = 'light' | 'dark';

export const AuthColors = {
  light: {
    gradientEnd: '#ffffff',
    surface: '#ffffff',
    /** Opaque grouped panel (e.g. onboarding color grid) on white page. */
    groupedSurface: '#f2f2f7',
    inputBg: '#ffffff',
    inputBorder: '#C4C4CC',
    inputBorderFocused: '#000000',
    inputLabelFilled: '#7c7c7c',
    text: '#09090b',
    textSubtle: '#52525b',
    placeholderText: '#7c7c7c',
    separatorColor: '#c4c4cc',
    errorText: '#dc2626',
    buttonBg: '#ffffff',
    buttonText: '#000000',
    buttonOutline: '#C4C4CC',
    buttonPressedBg: '#f0f0f0',
    buttonDisabledBg: '#e4e4e7',
    buttonDisabledText: '#a1a1aa',
    ssoBg: '#000000',
    /** Intentional: contrast on Apple button. */
    ssoText: '#ffffff',
    ssoPressedBg: '#242424',
    glassBg: 'rgba(0,0,0,0.08)',
    glassBorder: 'rgba(0,0,0,0.15)',
    linkText: '#0a7ea4',
  },
  dark: {
    gradientEnd: '#000000',
    surface: '#000000',
    /** Same as `surface` so grouped panels (e.g. look color grid) don’t read as a separate gray slab on black. */
    groupedSurface: '#000000',
    inputBg: '#000000',
    inputBorder: '#2f2f2f',
    inputBorderFocused: '#ffffff',
    inputLabelFilled: '#a1a1a1',
    text: '#ffffff',
    textSubtle: '#d1d6ff',
    placeholderText: '#a1a1a1',
    separatorColor: '#4b4b60',
    errorText: '#f87171',
    buttonBg: '#ffffff',
    buttonText: '#000000',
    buttonOutline: 'transparent',
    buttonPressedBg: '#e0e0e0',
    buttonDisabledBg: '#262626',
    buttonDisabledText: '#737373',
    ssoBg: '#ffffff',
    ssoText: '#000000',
    ssoPressedBg: '#e0e0e0',
    glassBg: 'rgba(255,255,255,0.12)',
    glassBorder: 'rgba(255,255,255,0.22)',
    linkText: '#0a84ff',
  },
} as const;

export type AuthSemanticColors = (typeof AuthColors)['light'] | (typeof AuthColors)['dark'];

/** Figma onboarding look avatar placeholder letter (node 124:6276). */
export const OnboardingAvatarInitialsColor = '#a1a1a1';

/** Radial glow behind onboarding avatar — one smooth falloff (avoids banded “double ring”); brighter than a low-opacity core + separate halo. */
export const OnboardingAvatarGlowGradientStops = [
  { offset: '0%', opacity: 1 },
  { offset: '18%', opacity: 0.95 },
  { offset: '38%', opacity: 0.78 },
  { offset: '58%', opacity: 0.52 },
  { offset: '76%', opacity: 0.26 },
  { offset: '90%', opacity: 0.08 },
  { offset: '100%', opacity: 0 },
] as const;

/**
 * Onboarding look: 12 swatches, row-major (6+6). Matches product reference: warm hues → green/teal → blues → purple → magenta → pink → deep red.
 * FIGMA_GAP: export exact fills from Figma node `326:6051` when available; hexes tuned for on-screen saturation.
 */
export const OnboardingPalette = [
  { id: 'c1', hex: '#F04A23' },
  { id: 'c2', hex: '#FF8A24' },
  { id: 'c3', hex: '#F5B41C' },
  { id: 'c4', hex: '#F5E86B' },
  { id: 'c5', hex: '#7ED321' },
  { id: 'c6', hex: '#00C4A3' },
  { id: 'c7', hex: '#2BB4F0' },
  { id: 'c8', hex: '#2B6BFF' },
  { id: 'c9', hex: '#8B5CF6' },
  { id: 'c10', hex: '#D946EF' },
  { id: 'c11', hex: '#F43F8C' },
  { id: 'c12', hex: '#DC2626' },
] as const;

export const ExploreTemplateColors = {
  headerBackground: { light: '#D0D0D0', dark: '#353636' } as const,
  headerIcon: '#808080',
} as const;

export const Colors = {
  light: {
    text: '#11181C',
    background: '#fff',
    tint: tintColorLight,
    icon: '#687076',
    tabIconDefault: '#687076',
    tabIconSelected: tintColorLight,
  },
  dark: {
    text: '#ECEDEE',
    background: '#151718',
    tint: tintColorDark,
    icon: '#9BA1A6',
    tabIconDefault: '#9BA1A6',
    tabIconSelected: tintColorDark,
  },
};

export const Fonts = Platform.select({
  ios: {
    /** iOS `UIFontDescriptorSystemDesignDefault` */
    sans: 'system-ui',
    /** iOS `UIFontDescriptorSystemDesignSerif` */
    serif: 'ui-serif',
    /** iOS `UIFontDescriptorSystemDesignRounded` */
    rounded: 'ui-rounded',
    /** iOS `UIFontDescriptorSystemDesignMonospaced` */
    mono: 'ui-monospace',
  },
  default: {
    sans: 'normal',
    serif: 'serif',
    rounded: 'normal',
    mono: 'monospace',
  },
  web: {
    sans: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    serif: "Georgia, 'Times New Roman', serif",
    rounded: "'SF Pro Rounded', 'Hiragino Maru Gothic ProN', Meiryo, 'MS PGothic', sans-serif",
    mono: "SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace",
  },
});
