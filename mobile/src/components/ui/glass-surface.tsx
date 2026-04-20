import { type ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { GlassView, isGlassEffectAPIAvailable, isLiquidGlassAvailable } from 'expo-glass-effect';

import { Size } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';

export type GlassSurfaceGlassStyle = 'regular' | 'clear';

export type GlassSurfaceProps = {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  glassStyle?: GlassSurfaceGlassStyle;
};

export function GlassSurface({ children, style, glassStyle = 'regular' }: GlassSurfaceProps) {
  const c = useAppColors();
  const useGlass = isLiquidGlassAvailable() && isGlassEffectAPIAvailable();
  const flat = StyleSheet.flatten(style) as ViewStyle | undefined;
  const borderRadius =
    typeof flat?.borderRadius === 'number' ? flat.borderRadius : 0;

  if (useGlass) {
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
          style={[
            StyleSheet.absoluteFillObject,
            {
              borderRadius,
            },
          ]}
        />
        {children}
      </View>
    );
  }

  return (
    <View
      style={[
        style,
        {
          backgroundColor: c.surfaceElevated,
          borderColor: c.inputBorder,
          borderWidth: Size.borderWidth,
        },
      ]}
    >
      {children}
    </View>
  );
}
