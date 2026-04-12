import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';

import { BorderRadius, FontSize, FontWeight, Opacity, Size, Spacing } from '@/constants/tokens';
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

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      disabled={inactive}
      style={({ pressed }) => [
        styles.btn,
        { backgroundColor: c.buttonBg },
        inactive && styles.btnDisabled,
        pressed && !inactive && styles.pressed,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={c.buttonText} />
      ) : (
        <Text style={[styles.text, { color: c.buttonText }]}>{label}</Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  btn: {
    height: Size.buttonHeight,
    borderRadius: BorderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.lg,
  },
  btnDisabled: {
    opacity: Opacity.disabled,
  },
  pressed: {
    opacity: 0.9,
  },
  text: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.semibold,
  },
});
