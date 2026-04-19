import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';

import { BorderRadius, FontSize, FontWeight, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

type PrimaryButtonProps = {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
};

export function PrimaryButton({ label, onPress, disabled, loading }: PrimaryButtonProps) {
  const c = useAuthColors();
  const inactive = disabled || loading;
  const fg = inactive ? c.buttonDisabledText : c.buttonText;

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      disabled={inactive}
      style={({ pressed }) => [
        styles.btn,
        {
          backgroundColor: inactive
            ? c.buttonDisabledBg
            : pressed
              ? c.buttonPressedBg
              : c.buttonBg,
          borderColor: c.buttonOutline,
        },
      ]}
    >
      {loading ? (
        <ActivityIndicator color={fg} />
      ) : (
        <Text style={[styles.text, { color: fg }]}>{label}</Text>
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
