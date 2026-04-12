import { AuthColors, type AuthSemanticColors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

export function useAuthColors(): AuthSemanticColors {
  const scheme = useColorScheme() ?? 'light';
  return AuthColors[scheme === 'dark' ? 'dark' : 'light'];
}
