import { useTranslation } from 'react-i18next';
import { StyleSheet, Text, View } from 'react-native';

import { InviteIcon } from '@/components/icons/invite-icon';
import { GlassSurface } from '@/components/ui/glass-surface';
import { FontSize, FontWeight, LineHeight, Size, Spacing } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';

export type PartnerSlotState = 'no-invite';

type Props = {
  state: PartnerSlotState;
  onInvitePress: () => void;
  accentColorHex: string;
};

const inviteCircleRadius = Size.onboardingAvatar / 2;
const INVITE_ICON_HEIGHT = 44;

export function PartnerSlot({ state, onInvitePress }: Props) {
  const { t } = useTranslation();
  const c = useAppColors();

  if (state !== 'no-invite') {
    return null;
  }

  return (
    <View style={styles.wrap}>
      <GlassSurface
        glassStyle="clear"
        translucentFallback
        onPress={onInvitePress}
        accessibilityRole="button"
        accessibilityLabel={t('home.invitePartner')}
        style={{
          width: Size.onboardingAvatar,
          height: Size.onboardingAvatar,
          borderRadius: inviteCircleRadius,
          alignItems: 'center',
          justifyContent: 'center',
        }}>
        <InviteIcon height={INVITE_ICON_HEIGHT} />
      </GlassSurface>
      <Text style={[styles.label, { color: c.text }]}>{t('home.invitePartner')}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    gap: Spacing.lg,
    zIndex: 2,
  },
  label: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.medium,
    lineHeight: LineHeight.normal,
    textAlign: 'center',
  },
});
