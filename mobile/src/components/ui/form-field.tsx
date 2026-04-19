import { useState } from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
  type TextInputProps,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { BorderRadius, FontSize, IconSize, LineHeight, Opacity, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

export function FormFieldFloatingText({
  filled,
  emptyText,
  fieldLabel,
  valueLine,
}: {
  filled: boolean;
  emptyText: string;
  fieldLabel: string;
  valueLine: string;
}) {
  const c = useAuthColors();
  if (!filled) {
    return (
      <Text style={[styles.staticText, { color: c.placeholderText }]} numberOfLines={1}>
        {emptyText}
      </Text>
    );
  }
  return (
    <View>
      <Text style={[styles.floatingFieldLabel, { color: c.inputLabelFilled }]} numberOfLines={1}>
        {fieldLabel}
      </Text>
      <Text style={[styles.staticText, { color: c.text }]} numberOfLines={1}>
        {valueLine}
      </Text>
    </View>
  );
}

type FormTextFieldProps = {
  label: string;
  value: string;
  onChangeText: (t: string) => void;
  placeholder?: string;
  onClear?: () => void;
  clearAccessibilityLabel?: string;
  errorMessage?: string;
  /** Red border when set even if `errorMessage` is empty (e.g. screen-level validation). */
  invalid?: boolean;
  keyboardType?: TextInputProps['keyboardType'];
  autoCapitalize?: TextInputProps['autoCapitalize'];
  secure?: boolean;
  editable?: boolean;
  textContentType?: TextInputProps['textContentType'];
  autoComplete?: TextInputProps['autoComplete'];
  importantForAutofill?: TextInputProps['importantForAutofill'];
  accessibilityLabel?: string;
};

export function FormTextField({
  label,
  value,
  onChangeText,
  placeholder,
  onClear,
  clearAccessibilityLabel,
  errorMessage,
  invalid,
  keyboardType = 'default',
  autoCapitalize = 'none',
  secure,
  editable = true,
  textContentType,
  autoComplete,
  importantForAutofill,
  accessibilityLabel,
}: FormTextFieldProps) {
  const c = useAuthColors();
  const [showSecret, setShowSecret] = useState(false);
  const [focused, setFocused] = useState(false);
  const isSecure = secure && !showSecret;
  const filled = Boolean(value.trim());
  const borderColor =
    errorMessage || invalid ? c.errorText : focused ? c.inputBorderFocused : c.inputBorder;
  const placeholderText = placeholder ?? label;
  const showClear = Boolean(onClear && filled && editable);

  return (
    <View style={styles.wrap}>
      <View style={[styles.row, { backgroundColor: c.inputBg, borderColor }]}>
        <View style={styles.main}>
          {filled ? (
            <Text style={[styles.floatingFieldLabel, { color: c.inputLabelFilled }]} numberOfLines={1}>
              {label}
            </Text>
          ) : null}
          <TextInput
            style={[
              styles.input,
              filled ? styles.inputWithFloatingLabel : null,
              { color: c.text },
            ]}
            value={value}
            onChangeText={onChangeText}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            placeholder={filled ? '' : placeholderText}
            placeholderTextColor={c.placeholderText}
            keyboardType={keyboardType}
            autoCapitalize={autoCapitalize}
            autoCorrect={false}
            underlineColorAndroid="transparent"
            secureTextEntry={isSecure}
            editable={editable}
            textContentType={textContentType}
            autoComplete={autoComplete}
            importantForAutofill={importantForAutofill}
            accessibilityLabel={accessibilityLabel ?? label}
          />
        </View>
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
        {showClear && onClear ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={clearAccessibilityLabel}
            onPress={onClear}
            hitSlop={Spacing.lg}
            style={styles.clearHit}
          >
            <Ionicons name="close-circle" size={IconSize.lg} color={c.text} />
          </Pressable>
        ) : null}
      </View>
      {errorMessage ? (
        <Text style={[styles.errorText, { color: c.errorText }]}>{errorMessage}</Text>
      ) : null}
    </View>
  );
}

type FormSelectFieldProps = {
  label: string;
  value: string | null;
  onPress: () => void;
  onClear?: () => void;
  clearAccessibilityLabel?: string;
  error?: boolean;
  accessibilityLabel: string;
};

export function FormSelectField({
  label,
  value,
  onPress,
  onClear,
  clearAccessibilityLabel,
  error,
  accessibilityLabel,
}: FormSelectFieldProps) {
  const c = useAuthColors();
  const borderColor = error ? c.errorText : c.inputBorder;
  const filled = Boolean(value?.trim());
  const showClear = Boolean(filled && onClear);

  return (
    <View style={styles.selectWrap}>
      <View style={[styles.row, { backgroundColor: c.inputBg, borderColor }]}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={accessibilityLabel}
          onPress={onPress}
          style={({ pressed }) => [styles.pressableMain, { opacity: pressed ? Opacity.pressedLight : 1 }]}
        >
          <FormFieldFloatingText
            filled={filled}
            emptyText={label}
            fieldLabel={label}
            valueLine={value ?? ''}
          />
        </Pressable>
        {showClear && onClear ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={clearAccessibilityLabel}
            onPress={onClear}
            hitSlop={Spacing.lg}
            style={styles.clearHit}
          >
            <Ionicons name="close-circle" size={IconSize.lg} color={c.text} />
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

type FormRowStaticTextProps = {
  text: string;
  muted?: boolean;
};

export function FormRowStaticText({ text, muted }: FormRowStaticTextProps) {
  const c = useAuthColors();
  return (
    <Text style={[styles.staticText, { color: muted ? c.placeholderText : c.text }]} numberOfLines={1}>
      {text}
    </Text>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: Spacing.xl,
  },
  selectWrap: {
    marginBottom: Spacing.xl,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: Size.inputHeight,
    borderRadius: BorderRadius.md,
    borderWidth: Size.borderWidth,
    paddingHorizontal: Spacing.xl,
  },
  main: {
    flex: 1,
    minWidth: 0,
    justifyContent: 'center',
  },
  pressableMain: {
    flex: 1,
    minWidth: 0,
    alignSelf: 'stretch',
    justifyContent: 'center',
  },
  input: {
    fontSize: FontSize.lg,
    minHeight: Size.inputHeight - Spacing['2xl'],
    paddingVertical: Spacing.sm,
  },
  inputWithFloatingLabel: {
    minHeight: FontSize.lg + Spacing.md,
    paddingTop: 0,
    paddingBottom: Spacing.xxs,
  },
  eye: {
    padding: Spacing.xs,
  },
  clearHit: {
    justifyContent: 'center',
    paddingLeft: Spacing.md,
  },
  floatingFieldLabel: {
    fontSize: FontSize.xs,
    lineHeight: LineHeight.tight,
    marginBottom: Spacing.xxs,
  },
  staticText: {
    fontSize: FontSize.lg,
  },
  errorText: {
    fontSize: FontSize.sm,
    marginTop: Spacing.sm,
    marginLeft: Spacing.xxs,
  },
});
