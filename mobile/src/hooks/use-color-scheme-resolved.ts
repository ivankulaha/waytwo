import type { AppColorScheme } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

export function useColorSchemeResolved(): AppColorScheme {
  return useColorScheme() === 'dark' ? 'dark' : 'light';
}
