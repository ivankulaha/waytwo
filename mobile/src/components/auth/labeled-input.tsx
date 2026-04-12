import { useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { BorderRadius, FontSize, IconSize, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

type LabeledInputProps = {
  label: string;
  value: string;
  onChangeText: (t: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address';
  autoCapitalize?: 'none' | 'sentences';
  secure?: boolean;
  editable?: boolean;
  error?: string;
  textContentType?: TextInputProps['textContentType'];
  autoComplete?: TextInputProps['autoComplete'];
  importantForAutofill?: TextInputProps['importantForAutofill'];
};

export function LabeledInput({
  label,
  value,
  onChangeText,
  placeholder,
  keyboardType = 'default',
  autoCapitalize = 'none',
  secure,
  editable = true,
  error,
  textContentType,
  autoComplete,
  importantForAutofill,
}: LabeledInputProps) {
  const c = useAuthColors();
  const [showSecret, setShowSecret] = useState(false);
  const isSecure = secure && !showSecret;

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, { color: c.textSubtle }]}>{label}</Text>
      <View
        style={[
          styles.fieldRow,
          {
            backgroundColor: c.inputBg,
            borderColor: error ? c.errorText : c.inputBorder,
          },
        ]}
      >
        <TextInput
          style={[styles.input, { color: c.text }]}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={c.placeholderText}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          autoCorrect={false}
          secureTextEntry={isSecure}
          editable={editable}
          textContentType={textContentType}
          autoComplete={autoComplete}
          importantForAutofill={importantForAutofill}
        />
        {secure ? (
          <Pressable
            accessibilityRole="button"
            onPress={() => setShowSecret((s) => !s)}
            style={styles.eye}
            hitSlop={Spacing.md}
          >
            <Ionicons
              name={showSecret ? 'eye-off-outline' : 'eye-outline'}
              size={IconSize.lg}
              color={c.placeholderText}
            />
          </Pressable>
        ) : null}
      </View>
      {error ? <Text style={[styles.error, { color: c.errorText }]}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: Spacing.xl,
  },
  label: {
    fontSize: FontSize.xs,
    marginBottom: Spacing.sm,
    marginLeft: Spacing.xxs,
  },
  fieldRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: BorderRadius.md,
    borderWidth: Size.borderWidth,
    minHeight: Size.inputHeight,
    paddingHorizontal: Spacing.inputX,
  },
  input: {
    flex: 1,
    fontSize: FontSize.lg,
    paddingVertical: Spacing.lg,
  },
  eye: {
    padding: Spacing.xs,
  },
  error: {
    fontSize: FontSize.sm,
    marginTop: Spacing.sm,
    marginLeft: Spacing.xxs,
  },
});
