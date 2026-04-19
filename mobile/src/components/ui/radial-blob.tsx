import { Canvas, RadialGradient, Rect } from '@shopify/react-native-skia';
import {
  StyleSheet,
  useWindowDimensions,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import type { RadialBlobSpec } from '@/constants/gradients';

type Props = {
  spec: RadialBlobSpec;
  style?: StyleProp<ViewStyle>;
  testID?: string;
};

export function RadialBlob({ spec, style, testID }: Props) {
  const { width: w, height: h } = useWindowDimensions();
  const { geometry, stops } = spec;

  const cx = geometry.cxW * w;
  const cy = geometry.cyH * h;
  const rx = geometry.rxW * w;
  const ry = geometry.ryW * w;

  const aspect = ry / rx;

  return (
    <Canvas pointerEvents="none" testID={testID} style={[StyleSheet.absoluteFill, style]}>
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
