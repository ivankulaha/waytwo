import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { ProfileAvatarCircle } from '@/components/profile/profile-avatar-circle';
import { FontSize, FontWeight, LineHeight, Spacing } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';

type AvatarPickerProps = {
  displayName: string;
  localUri: string | null;
  remoteUserId: string | null;
  remotePhotoPath: string | null;
  remoteUpdatedAtMs: number;
  glowColor?: string | null;
  onPickPress: () => void;
};

export function AvatarPicker({
  displayName,
  localUri,
  remoteUserId,
  remotePhotoPath,
  remoteUpdatedAtMs,
  glowColor,
  onPickPress,
}: AvatarPickerProps) {
  const { t } = useTranslation();
  const c = useAppColors();

  return (
    <View style={styles.block}>
      <ProfileAvatarCircle
        displayName={displayName}
        localUri={localUri}
        remoteUserId={remoteUserId}
        remotePhotoPath={remotePhotoPath}
        remoteUpdatedAtMs={remoteUpdatedAtMs}
        glowColor={glowColor}
        onPress={onPickPress}
      />
      <Pressable accessibilityRole="button" onPress={onPickPress} style={styles.linkWrap}>
        <Text style={[styles.changePhoto, { color: c.text }]}>{t('onboarding.look.changePhoto')}</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  block: {
    alignItems: 'center',
    marginBottom: Spacing.xl,
    overflow: 'visible',
  },
  linkWrap: {
    marginTop: Spacing.lg,
  },
  changePhoto: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.semibold,
    lineHeight: LineHeight.normal,
    textAlign: 'center',
  },
});
