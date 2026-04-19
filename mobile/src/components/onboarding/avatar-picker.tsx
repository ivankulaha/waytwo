import { useId } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Image } from 'expo-image';
import Svg, { Circle, Defs, RadialGradient, Stop } from 'react-native-svg';
import { useTranslation } from 'react-i18next';

import { OnboardingAvatarGlowGradientStops, OnboardingAvatarInitialsColor } from '@/constants/theme';
import { FontSize, FontWeight, LineHeight, Size, Spacing } from '@/constants/tokens';
import { avatarPublicObjectUrl } from '@/lib/avatar-path';
import { useAuthColors } from '@/hooks/use-auth-colors';

type AvatarPickerProps = {
  displayName: string;
  localUri: string | null;
  remoteUserId: string | null;
  remotePhotoPath: string | null;
  remoteUpdatedAtMs: number;
  glowColor?: string | null;
  onPickPress: () => void;
};

function initials(name: string): string {
  const t = name.trim();
  if (!t) return '?';
  return t.slice(0, 1).toUpperCase();
}

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
  const c = useAuthColors();
  const letter = initials(displayName);
  const remoteUrl =
    remoteUserId && remotePhotoPath
      ? avatarPublicObjectUrl(remoteUserId, remoteUpdatedAtMs)
      : null;
  const showImage = Boolean(localUri || remoteUrl);
  const glowSize = Size.onboardingAvatarGlowStage;
  const reactId = useId();
  const glowGradientId = `avatarGlow_${reactId.replace(/:/g, '_')}`;

  const avatarCore = (
    <Pressable
      accessibilityRole="button"
      onPress={onPickPress}
      style={[styles.avatarFrame, { backgroundColor: c.surface, borderColor: c.inputBorder }]}
    >
      {showImage ? (
        <View style={styles.imageClip}>
          <Image
            source={localUri ? { uri: localUri } : { uri: remoteUrl! }}
            style={styles.imageFill}
            contentFit="cover"
            transition={120}
          />
        </View>
      ) : (
        <Text style={styles.initials}>{letter}</Text>
      )}
    </Pressable>
  );

  return (
    <View style={styles.block}>
      <View style={styles.avatarSlot}>
        {glowColor ? (
          <Svg
            width={glowSize}
            height={glowSize}
            style={[
              styles.glowSvg,
              {
                marginLeft: -glowSize / 2,
                marginTop: -glowSize / 2,
              },
            ]}
            pointerEvents="none"
          >
            <Defs>
              <RadialGradient id={glowGradientId} cx="50%" cy="50%" r="50%" fx="50%" fy="50%">
                {OnboardingAvatarGlowGradientStops.map((s) => (
                  <Stop
                    key={s.offset}
                    offset={s.offset}
                    stopColor={glowColor}
                    stopOpacity={s.opacity}
                  />
                ))}
              </RadialGradient>
            </Defs>
            <Circle cx="50%" cy="50%" r="50%" fill={`url(#${glowGradientId})`} />
          </Svg>
        ) : null}
        <View style={styles.avatarForeground}>{avatarCore}</View>
      </View>
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
  avatarSlot: {
    width: Size.onboardingAvatar,
    height: Size.onboardingAvatar,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    overflow: 'visible',
  },
  glowSvg: {
    position: 'absolute',
    left: '50%',
    top: '50%',
    zIndex: -1,
  },
  avatarForeground: {
    zIndex: 1,
  },
  avatarFrame: {
    width: Size.onboardingAvatar,
    height: Size.onboardingAvatar,
    borderRadius: Size.onboardingAvatar / 2,
    borderWidth: Size.borderWidth,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  imageClip: {
    width: Size.onboardingAvatar,
    height: Size.onboardingAvatar,
    borderRadius: Size.onboardingAvatar / 2,
    overflow: 'hidden',
  },
  imageFill: {
    width: Size.onboardingAvatar,
    height: Size.onboardingAvatar,
  },
  initials: {
    fontSize: FontSize.onboardingAvatarGlyph,
    fontWeight: FontWeight.bold,
    lineHeight: FontSize.onboardingAvatarGlyph,
    color: OnboardingAvatarInitialsColor,
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
