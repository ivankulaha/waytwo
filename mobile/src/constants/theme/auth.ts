import { palette } from '@/constants/theme/palette';

export const AuthSsoColors = {
  light: {
    ssoBg: palette.ssoBgLight,
    ssoText: palette.ssoTextLight,
    ssoPressedBg: palette.ssoPressedLight,
  },
  dark: {
    ssoBg: palette.ssoBgDark,
    ssoText: palette.ssoTextDark,
    ssoPressedBg: palette.ssoPressedDark,
  },
} as const;

export type AuthSsoSemantic = (typeof AuthSsoColors)['light'];
