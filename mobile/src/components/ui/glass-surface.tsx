import { type ReactNode } from 'react';
import {
  type AccessibilityRole,
  Pressable,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import { GlassView, isGlassEffectAPIAvailable, isLiquidGlassAvailable } from 'expo-glass-effect';

import { palette } from '@/constants/theme/palette';
import { Animation, Size } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';

export type GlassSurfaceGlassStyle = 'regular' | 'clear';

export type GlassSurfaceProps = {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  glassStyle?: GlassSurfaceGlassStyle;
  /** When native glass is unavailable, use a near-transparent fill instead of `surfaceElevated`. */
  translucentFallback?: boolean;
  /**
   * When provided the surface becomes interactive:
   * - native glass: `Pressable` wraps a `GlassView isInteractive` so iOS 26 water-drop morph fires
   * - fallback: `Animated.View` spring-scales on press
   */
  onPress?: () => void;
  onPressIn?: () => void;
  onPressOut?: () => void;
  accessibilityRole?: AccessibilityRole;
  accessibilityLabel?: string;
};

export function GlassSurface({
  children,
  style,
  glassStyle = 'regular',
  translucentFallback = false,
  onPress,
  onPressIn,
  onPressOut,
  accessibilityRole,
  accessibilityLabel,
}: GlassSurfaceProps) {
  const c = useAppColors();
  const useGlass = isLiquidGlassAvailable() && isGlassEffectAPIAvailable();
  const flat = StyleSheet.flatten(style) as ViewStyle | undefined;
  const borderRadius = typeof flat?.borderRadius === 'number' ? flat.borderRadius : 0;

  // Always initialise — avoids conditional hook call when onPress or useGlass changes.
  const pressed = useSharedValue(false);
  const animStyle = useAnimatedStyle(() => ({
    transform: [
      {
        scale: withSpring(
          pressed.value ? Animation.glassPressScale : 1,
          Animation.glassPressSpring,
        ),
      },
    ],
  }));

  const isDarkSurface = c.surface === palette.black;
  const fallbackTranslucent: ViewStyle = translucentFallback
    ? {
        backgroundColor: isDarkSurface ? 'rgba(255,255,255,0.06)' : 'rgba(255,255,255,0.22)',
        borderColor: isDarkSurface ? 'rgba(255,255,255,0.14)' : 'rgba(0,0,0,0.08)',
        borderWidth: Size.borderWidth,
      }
    : {
        backgroundColor: c.surfaceElevated,
        borderColor: c.inputBorder,
        borderWidth: Size.borderWidth,
      };

  if (useGlass) {
    if (onPress) {
      // Pressable is the outer node so the gesture stream reaches GlassView.
      // Children go INSIDE GlassView (mounted into UIVisualEffectView.contentView)
      // so UIKit hit-testing always lands on the glass layer — required for
      // isInteractive to receive UIKit touches and run the long-press deformation.
      // Merging layout styles from `style` with absoluteFill so alignment/centering
      // props still apply to the children inside contentView.
      return (
        <Pressable
          style={[style, { overflow: 'hidden' }]}
          onPress={onPress}
          onPressIn={onPressIn}
          onPressOut={onPressOut}
          accessibilityRole={accessibilityRole}
          accessibilityLabel={accessibilityLabel}
        >
          <GlassView
            glassEffectStyle={glassStyle}
            isInteractive
            style={[style, StyleSheet.absoluteFillObject]}
          >
            {children}
          </GlassView>
        </Pressable>
      );
    }

    return (
      <View
        style={[
          style,
          {
            position: 'relative',
            overflow: 'hidden',
            backgroundColor: 'transparent',
            borderColor: 'transparent',
            borderWidth: 0,
          },
        ]}
      >
        <GlassView
          glassEffectStyle={glassStyle}
          style={[StyleSheet.absoluteFillObject, { borderRadius }]}
        />
        {children}
      </View>
    );
  }

  if (onPress) {
    return (
      <Animated.View style={[style, fallbackTranslucent, animStyle]}>
        <Pressable
          style={StyleSheet.absoluteFillObject}
          onPress={onPress}
          onPressIn={() => {
            pressed.value = true;
            onPressIn?.();
          }}
          onPressOut={() => {
            pressed.value = false;
            onPressOut?.();
          }}
          accessibilityRole={accessibilityRole}
          accessibilityLabel={accessibilityLabel}
        >
          {children}
        </Pressable>
      </Animated.View>
    );
  }

  return <View style={[style, fallbackTranslucent]}>{children}</View>;
}
