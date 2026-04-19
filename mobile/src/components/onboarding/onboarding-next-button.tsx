import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';

import { BorderRadius, FontSize, FontWeight, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

type OnboardingNextButtonProps = {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
};

export function OnboardingNextButton({ label, onPress, disabled, loading }: OnboardingNextButtonProps) {
  const c = useAuthColors();
  const inactive = disabled || loading;
  const enabled = !inactive;

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      disabled={inactive}
      style={({ pressed }) => [
        styles.btn,
        enabled
          ? {
              backgroundColor: pressed ? c.buttonPressedBg : c.buttonBg,
              borderColor: c.buttonOutline,
            }
          : {
              backgroundColor: c.buttonDisabledBg,
              borderColor: c.buttonOutline,
            },
      ]}
    >
      {loading ? (
        <ActivityIndicator color={c.buttonText} />
      ) : (
        <Text
          style={[
            styles.text,
            { color: enabled ? c.buttonText : c.buttonDisabledText },
          ]}
        >
          {label}
        </Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  btn: {
    height: Size.buttonHeight,
    borderRadius: BorderRadius.full,
    borderWidth: Size.borderWidth,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.lg,
  },
  text: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.semibold,
  },
});
