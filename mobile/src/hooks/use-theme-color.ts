/**
 * TODO(legacy-template): Remove with new home / tab redesign. Expo starter palette only —
 * not part of AppColors. Used by ThemedText, ThemedView, parallax demo, and (tabs)/index.
 */
import { useColorSchemeResolved } from '@/hooks/use-color-scheme-resolved';

const LegacyTemplateColors = {
  light: {
    text: '#11181C',
    background: '#fff',
    tint: '#0a7ea4',
    icon: '#687076',
    tabIconDefault: '#687076',
    tabIconSelected: '#0a7ea4',
  },
  dark: {
    text: '#ECEDEE',
    background: '#151718',
    tint: '#fff',
    icon: '#9BA1A6',
    tabIconDefault: '#9BA1A6',
    tabIconSelected: '#fff',
  },
} as const;

export function useThemeColor(
  props: { light?: string; dark?: string },
  colorName: keyof typeof LegacyTemplateColors.light & keyof typeof LegacyTemplateColors.dark,
) {
  const scheme = useColorSchemeResolved();
  const colorFromProps = props[scheme];

  if (colorFromProps) {
    return colorFromProps;
  }
  return LegacyTemplateColors[scheme][colorName];
}
