import Animated from 'react-native-reanimated';

import { FontSize, LayoutOffset, LineHeight } from '@/constants/tokens';

export function HelloWave() {
  return (
    <Animated.Text
      style={{
        fontSize: FontSize['4xl'],
        lineHeight: LineHeight.loose,
        marginTop: LayoutOffset.helloWaveMarginTop,
        animationName: {
          '50%': { transform: [{ rotate: '25deg' }] },
        },
        animationIterationCount: 4,
        animationDuration: '300ms',
      }}>
      👋
    </Animated.Text>
  );
}
