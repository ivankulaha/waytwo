import { Pressable, StyleSheet, View } from 'react-native';

import { OnboardingPalette } from '@/constants/theme';
import { Opacity, Size, Spacing } from '@/constants/tokens';

type ColorPaletteProps = {
  value: string | null;
  onChange: (colorId: string) => void;
};

const ROW1 = OnboardingPalette.slice(0, 6);
const ROW2 = OnboardingPalette.slice(6, 12);

type SwatchItem = (typeof OnboardingPalette)[number];

function Swatch({
  item,
  selected,
  onSelect,
}: {
  item: SwatchItem;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <View style={styles.swatchCell}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ selected }}
        onPress={onSelect}
        style={({ pressed }) => [
          styles.swatchOuter,
          selected ? { borderColor: item.hex } : styles.outerUnselected,
          pressed ? { opacity: Opacity.pressed } : null,
        ]}
      >
        <View style={[styles.swatchInner, { backgroundColor: item.hex }]} />
      </Pressable>
    </View>
  );
}

export function ColorPalette({ value, onChange }: ColorPaletteProps) {
  return (
    <View style={styles.wrap}>
      <View style={styles.row}>
        {ROW1.map((item) => (
          <Swatch
            key={item.id}
            item={item}
            selected={value === item.id}
            onSelect={() => onChange(item.id)}
          />
        ))}
      </View>
      <View style={styles.row}>
        {ROW2.map((item) => (
          <Swatch
            key={item.id}
            item={item}
            selected={value === item.id}
            onSelect={() => onChange(item.id)}
          />
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: Spacing.swatchRowGap,
  },
  row: {
    flexDirection: 'row',
    width: '100%',
    gap: Spacing.sm,
    alignItems: 'center',
  },
  swatchCell: {
    flex: 1,
    minWidth: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  swatchOuter: {
    width: Size.swatchTap,
    height: Size.swatchTap,
    borderRadius: Size.swatchTap / 2,
    borderWidth: Size.swatchSelectionRing,
    alignItems: 'center',
    justifyContent: 'center',
  },
  outerUnselected: {
    borderColor: 'transparent',
  },
  swatchInner: {
    width: Size.swatchInner,
    height: Size.swatchInner,
    borderRadius: Size.swatchInner / 2,
  },
});
