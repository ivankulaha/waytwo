import { useId } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Image } from 'expo-image';
import Svg, { Circle, Defs, RadialGradient, Stop } from 'react-native-svg';

import { OnboardingAvatarGlowGradientStops, OnboardingAvatarInitialsColor } from '@/constants/theme';
import { FontSize, FontWeight, Size } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';
import { avatarPublicObjectUrl } from '@/lib/avatar-path';

export type ProfileAvatarCircleProps = {
  displayName: string;
  localUri: string | null;
  remoteUserId: string | null;
  remotePhotoPath: string | null;
  remoteUpdatedAtMs: number;
  glowColor?: string | null;
  /** Figma onboarding look uses `inputBorder`; home pairing omits the ring. */
  showFrameBorder?: boolean;
  onPress?: () => void;
};

function initials(name: string): string {
  const t = name.trim();
  if (!t) return '?';
  return t.slice(0, 1).toUpperCase();
}

export function ProfileAvatarCircle({
  displayName,
  localUri,
  remoteUserId,
  remotePhotoPath,
  remoteUpdatedAtMs,
  glowColor,
  showFrameBorder = true,
  onPress,
}: ProfileAvatarCircleProps) {
  const c = useAppColors();
  const letter = initials(displayName);
  const remoteUrl =
    remoteUserId && remotePhotoPath
      ? avatarPublicObjectUrl(remoteUserId, remoteUpdatedAtMs)
      : null;
  const showImage = Boolean(localUri || remoteUrl);
  const glowSize = Size.onboardingAvatarGlowStage;
  const reactId = useId();
  const glowGradientId = `avatarGlow_${reactId.replace(/:/g, '_')}`;

  const inner = showImage ? (
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
  );

  const frame = (
    <View
      style={[
        styles.avatarFrame,
        {
          backgroundColor: c.inputBg,
          borderWidth: showFrameBorder ? Size.borderWidth : 0,
          borderColor: showFrameBorder ? c.inputBorder : 'transparent',
        },
      ]}>
      {inner}
    </View>
  );

  const framed = onPress ? (
    <Pressable accessibilityRole="button" onPress={onPress}>
      {frame}
    </Pressable>
  ) : (
    frame
  );

  return (
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
          pointerEvents="none">
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
      <View style={styles.avatarForeground}>{framed}</View>
    </View>
  );
}

const styles = StyleSheet.create({
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
});
