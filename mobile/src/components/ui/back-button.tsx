import { Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { GlassView, isGlassEffectAPIAvailable, isLiquidGlassAvailable } from 'expo-glass-effect';
import { useTranslation } from 'react-i18next';

import { BorderRadius, IconSize, Size } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';

export type BackButtonProps = {
  onPress: () => void;
  accessibilityLabel?: string;
  style?: StyleProp<ViewStyle>;
};

const hitSlop = { top: 8, bottom: 8, left: 8, right: 8 } as const;

const springConfig = { damping: 12, stiffness: 300 } as const;

export function BackButton({ onPress, accessibilityLabel, style }: BackButtonProps) {
  const { t } = useTranslation();
  const c = useAppColors();
  const label = accessibilityLabel ?? t('common.back');
  const useGlass = isLiquidGlassAvailable() && isGlassEffectAPIAvailable();

  const sizeStyle = {
    width: Size.iconButton,
    height: Size.iconButton,
    borderRadius: BorderRadius.xl,
    alignItems: 'center' as const,
    justifyContent: 'center' as const,
  };

  if (useGlass) {
    // Pressable is the outer node so the gesture stream reaches GlassView,
    // letting isInteractive run the native water-drop morph on iOS 26+.
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        hitSlop={hitSlop}
        onPress={onPress}
        style={[sizeStyle, style]}
      >
        <GlassView
          glassEffectStyle="regular"
          isInteractive
          style={[
            StyleSheet.absoluteFillObject,
            { borderRadius: BorderRadius.xl, alignItems: 'center', justifyContent: 'center' },
          ]}
        >
          <Ionicons name="chevron-back" size={IconSize.lg} color={c.text} />
        </GlassView>
      </Pressable>
    );
  }

  // Fallback for iOS < 26 and Android: spring scale provides tactile press feedback.
  const pressed = useSharedValue(false);
  const animStyle = useAnimatedStyle(() => ({
    transform: [{ scale: withSpring(pressed.value ? 0.88 : 1, springConfig) }],
  }));

  return (
    <Animated.View style={[sizeStyle, style, animStyle]}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        hitSlop={hitSlop}
        onPress={onPress}
        onPressIn={() => { pressed.value = true; }}
        onPressOut={() => { pressed.value = false; }}
        style={[
          StyleSheet.absoluteFillObject,
          {
            alignItems: 'center',
            justifyContent: 'center',
            borderRadius: BorderRadius.xl,
            backgroundColor: c.glassBg,
            borderColor: c.glassBorder,
            borderWidth: Size.borderWidth,
          },
        ]}
      >
        <Ionicons name="chevron-back" size={IconSize.lg} color={c.text} />
      </Pressable>
    </Animated.View>
  );
}
