import { Stack } from 'expo-router';
import type { ErrorBoundaryProps } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { BorderRadius, FontSize, LineHeight, Spacing } from '@/constants/tokens';
import { log } from '@/lib/log';

export function ErrorBoundary({ error, retry }: ErrorBoundaryProps) {
  log.error('Onboarding render error', { message: error.message });
  const { t } = useTranslation();
  return (
    <View style={styles.err}>
      <Text style={styles.title}>{t('error.title')}</Text>
      <Text style={styles.hint}>{t('error.hint')}</Text>
      <Pressable onPress={retry} style={styles.btn}>
        <Text style={styles.btnText}>{t('error.retry')}</Text>
      </Pressable>
    </View>
  );
}

export default function OnboardingLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="intro" />
      <Stack.Screen name="you" />
      <Stack.Screen name="look" />
    </Stack>
  );
}

const styles = StyleSheet.create({
  err: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing['4xl'],
    backgroundColor: '#000',
  },
  title: {
    color: '#fff',
    fontSize: FontSize['2xl'],
    fontWeight: '600',
    marginBottom: Spacing.lg,
    textAlign: 'center',
  },
  hint: {
    color: '#aaa',
    fontSize: FontSize.base,
    lineHeight: LineHeight.snug,
    textAlign: 'center',
    marginBottom: Spacing['3xl'],
  },
  btn: {
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing['3xl'],
    borderRadius: BorderRadius.md,
    backgroundColor: '#fff',
  },
  btnText: {
    color: '#000',
    fontSize: FontSize.lg,
    fontWeight: '600',
  },
});
