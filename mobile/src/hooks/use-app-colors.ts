import { AppColors, type AppSemanticColors } from '@/constants/theme';
import { useColorSchemeResolved } from '@/hooks/use-color-scheme-resolved';

export function useAppColors(): AppSemanticColors {
  const scheme = useColorSchemeResolved();
  return AppColors[scheme];
}
