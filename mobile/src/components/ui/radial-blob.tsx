import { type ReactNode } from 'react';
import { Canvas, RadialGradient, Rect } from '@shopify/react-native-skia';
import {
  StyleSheet,
  View,
  useWindowDimensions,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import type { RadialBlobSpec } from '@/constants/gradients';

type Props = {
  spec: RadialBlobSpec;
  /**
   * When provided, RadialBlob acts as a wrapper: the glow canvas renders
   * as the absolute-fill background and children are centered on top.
   * Without children, it renders as a standalone fullscreen canvas layer.
   */
  children?: ReactNode;
  style?: StyleProp<ViewStyle>;
  testID?: string;
};

export function RadialBlob({ spec, children, style, testID }: Props) {
  const { width: w, height: h } = useWindowDimensions();
  const { geometry, stops } = spec;

  const cx = geometry.cxW * w;
  const cy = geometry.cyH * h;
  const rx = geometry.rxW * w;
  const ry = geometry.ryW * w;
  const aspect = ry / rx;

  const canvas = (
    <Canvas
      pointerEvents="none"
      testID={testID}
      style={StyleSheet.absoluteFill}>
      <Rect x={0} y={0} width={w} height={h}>
        <RadialGradient
          c={{ x: cx, y: cy / aspect }}
          r={rx}
          colors={[...stops.colors]}
          positions={[...stops.positions]}
          transform={[{ scaleY: aspect }]}
        />
      </Rect>
    </Canvas>
  );

  if (children) {
    return (
      <View
        pointerEvents="box-none"
        style={[StyleSheet.absoluteFill, styles.wrapper, style]}>
        {canvas}
        <View pointerEvents="box-none" style={styles.content}>
          {children}
        </View>
      </View>
    );
  }

  return (
    <Canvas
      pointerEvents="none"
      testID={testID}
      style={[StyleSheet.absoluteFill, style]}>
      <Rect x={0} y={0} width={w} height={h}>
        <RadialGradient
          c={{ x: cx, y: cy / aspect }}
          r={rx}
          colors={[...stops.colors]}
          positions={[...stops.positions]}
          transform={[{ scaleY: aspect }]}
        />
      </Rect>
    </Canvas>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    zIndex: 2,
    elevation: 2,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
