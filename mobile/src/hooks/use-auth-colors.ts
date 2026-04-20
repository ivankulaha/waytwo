import { AppColors, AuthSsoColors, type AppSemanticColors } from '@/constants/theme';
import { useColorSchemeResolved } from '@/hooks/use-color-scheme-resolved';

export type AuthScreenColors = AppSemanticColors & {
  ssoBg: string;
  ssoText: string;
  ssoPressedBg: string;
};

export function useAuthColors(): AuthScreenColors {
  const scheme = useColorSchemeResolved();
  return { ...AppColors[scheme], ...AuthSsoColors[scheme] };
}
