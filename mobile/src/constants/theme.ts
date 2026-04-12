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
    inputBg: '#f4f4f5',
    inputBorder: '#d4d4d8',
    text: '#09090b',
    textSubtle: '#52525b',
    placeholderText: '#a1a1aa',
    separatorColor: '#d4d4d8',
    errorText: '#dc2626',
    buttonBg: '#ffffff',
    buttonText: '#000000',
    glassBg: 'rgba(255,255,255,0.2)',
    glassBorder: 'rgba(255,255,255,0.35)',
  },
  dark: {
    gradientEnd: '#000000',
    surface: '#000000',
    inputBg: '#0d0d0d',
    inputBorder: '#2f2f2f',
    text: '#ffffff',
    textSubtle: '#d1d6ff',
    placeholderText: '#6b7280',
    separatorColor: '#4b4b60',
    errorText: '#f87171',
    buttonBg: '#ffffff',
    buttonText: '#000000',
    glassBg: 'rgba(255,255,255,0.12)',
    glassBorder: 'rgba(255,255,255,0.22)',
  },
} as const;

export type AuthSemanticColors = (typeof AuthColors)['light'] | (typeof AuthColors)['dark'];

export const AuthFlowGradients = {
  email: ['#5B6CF5', '#2D2870', '#0D0A2A'] as const,
  login: ['#2dd4bf', '#0f766e', '#0a1f1c'] as const,
  signup: ['#e879f9', '#a855f7', '#1a0a2e'] as const,
  forgot: ['#f97316', '#9a3412', '#1c0a05'] as const,
  newPassword: ['#9333ea', '#4c1d95', '#0f0518'] as const,
} as const;

export type AuthFlowVariant = keyof typeof AuthFlowGradients;

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
