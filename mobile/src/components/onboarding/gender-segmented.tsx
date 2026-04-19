import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { BorderRadius, FontSize, FontWeight, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

type Gender = 'male' | 'female' | 'other';

type GenderSegmentedProps = {
  value: Gender | null;
  onChange: (v: Gender) => void;
};

export function GenderSegmented({ value, onChange }: GenderSegmentedProps) {
  const { t } = useTranslation();
  const c = useAuthColors();
  const options: { key: Gender; label: string }[] = [
    { key: 'male', label: t('onboarding.you.genderMale') },
    { key: 'female', label: t('onboarding.you.genderFemale') },
    { key: 'other', label: t('onboarding.you.genderOther') },
  ];
  return (
    <View style={styles.wrap}>
      <View
        style={[
          styles.track,
          {
            borderColor: c.inputBorder,
            backgroundColor: c.inputBg,
          },
        ]}
      >
        {options.map((opt, index) => {
          const selected = value === opt.key;
          return (
            <Pressable
              key={opt.key}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              onPress={() => onChange(opt.key)}
              style={({ pressed }) => [
                styles.segment,
                index > 0 ? [styles.segmentDivider, { borderLeftColor: c.inputBorder }] : null,
                selected ? { backgroundColor: c.buttonBg } : null,
                pressed && !selected ? { opacity: 0.92 } : null,
              ]}
            >
              <Text style={[styles.segmentText, { color: selected ? c.buttonText : c.text }]}>
                {opt.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: Spacing.xl,
  },
  track: {
    flexDirection: 'row',
    borderRadius: BorderRadius.full,
    borderWidth: 1,
    overflow: 'hidden',
    minHeight: Size.inputHeight,
  },
  segment: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.sm,
  },
  segmentDivider: {
    borderLeftWidth: 1,
  },
  segmentText: {
    fontSize: FontSize.md,
    fontWeight: FontWeight.semibold,
  },
});
