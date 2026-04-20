import { useState } from 'react';
import { Modal, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { FormSelectField, FormTextField } from '@/components/ui/form-field';
import { BorderRadius, FontSize, FontWeight, Overlay, Spacing } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';
import { useColorSchemeResolved } from '@/hooks/use-color-scheme-resolved';
import { log } from '@/lib/log';

function parseIsoDate(s: string | null): Date | null {
  if (!s || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return null;
  const d = new Date(`${s}T12:00:00`);
  return Number.isNaN(d.getTime()) ? null : d;
}

function formatIso(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export type DatePickerFieldProps = {
  value: string | null;
  onChange: (iso: string | null) => void;
  fieldLabel: string;
  doneLabel: string;
  clearAccessibilityLabel: string;
  sheetBackdropAccessibilityLabel: string;
};

export function DatePickerField({
  value,
  onChange,
  fieldLabel,
  doneLabel,
  clearAccessibilityLabel,
  sheetBackdropAccessibilityLabel,
}: DatePickerFieldProps) {
  const c = useAppColors();
  const colorScheme = useColorSchemeResolved();
  const insets = useSafeAreaInsets();
  const [open, setOpen] = useState(false);
  const [iosPickerDate, setIosPickerDate] = useState(() => new Date(2000, 0, 1));
  const parsed = parseIsoDate(value);
  const display =
    parsed != null
      ? parsed.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
      : null;

  const openPicker = () => {
    setIosPickerDate(parsed ?? new Date(2000, 0, 1));
    setOpen(true);
  };

  const clearDob = () => {
    log.info('DatePickerField cleared', { op: 'date_picker_clear', field: 'dob' });
    onChange(null);
  };

  if (Platform.OS === 'web') {
    const filled = Boolean(value?.trim());
    return (
      <View style={styles.wrap}>
        <FormTextField
          label={fieldLabel}
          value={value ?? ''}
          onChangeText={(v) => {
            const trimmed = v.trim();
            if (!trimmed) onChange(null);
            else if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) onChange(trimmed);
          }}
          placeholder={fieldLabel}
          onClear={filled ? clearDob : undefined}
          clearAccessibilityLabel={clearAccessibilityLabel}
          accessibilityLabel={fieldLabel}
        />
      </View>
    );
  }

  return (
    <View style={styles.wrap}>
      <FormSelectField
        label={fieldLabel}
        value={display}
        onPress={openPicker}
        onClear={parsed != null ? clearDob : undefined}
        clearAccessibilityLabel={clearAccessibilityLabel}
        accessibilityLabel={fieldLabel}
      />
      {Platform.OS === 'ios' ? (
        <Modal
          visible={open}
          animationType="slide"
          transparent
          presentationStyle="overFullScreen"
          onRequestClose={() => setOpen(false)}
        >
          <View style={styles.modalRoot}>
            <Pressable
              style={[styles.modalDim, { backgroundColor: Overlay.modalBackdrop }]}
              onPress={() => setOpen(false)}
              accessibilityRole="button"
              accessibilityLabel={sheetBackdropAccessibilityLabel}
            />
            <View
              style={[
                styles.modalSheet,
                {
                  backgroundColor: c.inputBg,
                  paddingBottom: Spacing.xl + insets.bottom,
                },
              ]}
            >
              <View style={[styles.grabber, { backgroundColor: c.separatorColor }]} />
              <DateTimePicker
                value={iosPickerDate}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                textColor={c.text}
                themeVariant={colorScheme}
                onChange={(event, date) => {
                  if (event.type === 'dismissed') return;
                  if (!date) return;
                  setIosPickerDate(date);
                  onChange(formatIso(date));
                }}
              />
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={doneLabel}
                onPress={() => {
                  onChange(formatIso(iosPickerDate));
                  setOpen(false);
                }}
                style={styles.doneRow}
              >
                <Text style={[styles.doneText, { color: c.text }]}>{doneLabel}</Text>
              </Pressable>
            </View>
          </View>
        </Modal>
      ) : null}
      {Platform.OS === 'android' && open ? (
        <DateTimePicker
          value={parsed ?? new Date(2000, 0, 1)}
          mode="date"
          display="default"
          maximumDate={new Date()}
          onChange={(event, date) => {
            setOpen(false);
            if (event.type === 'dismissed') return;
            if (date) onChange(formatIso(date));
          }}
        />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 0,
  },
  modalRoot: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  modalDim: {
    ...StyleSheet.absoluteFillObject,
  },
  modalSheet: {
    borderTopLeftRadius: BorderRadius.lg,
    borderTopRightRadius: BorderRadius.lg,
    paddingTop: Spacing.md,
    paddingHorizontal: Spacing.xl,
  },
  grabber: {
    alignSelf: 'center',
    width: Spacing['4xl'],
    height: Spacing.xs,
    borderRadius: BorderRadius.full,
    marginBottom: Spacing.md,
  },
  doneRow: {
    alignSelf: 'flex-end',
    paddingVertical: Spacing.md,
  },
  doneText: {
    fontSize: FontSize.md,
    fontWeight: FontWeight.semibold,
  },
});
