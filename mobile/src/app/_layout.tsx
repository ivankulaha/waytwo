import { useEffect } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { Stack, useRouter, useSegments } from 'expo-router';
import type { ErrorBoundaryProps } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as Linking from 'expo-linking';
import { I18nextProvider, useTranslation } from 'react-i18next';
import 'react-native-reanimated';

import { AuthProvider, useAuth } from '@/context/AuthContext';
import { BorderRadius, FontSize, LineHeight, Spacing } from '@/constants/tokens';
import { useColorScheme } from '@/hooks/use-color-scheme';
import i18n from '@/lib/i18n';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';

function NavigationRoot() {
  const { t } = useTranslation();
  const colorScheme = useColorScheme();
  const { session, initialized, needsNewPassword, setNeedsNewPassword } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    const consumeUrl = async (url: string | null) => {
      if (!url) return;
      const lower = url.toLowerCase();
      if (lower.includes('code=') || lower.includes('access_token')) {
        const { error } = await supabase.auth.exchangeCodeForSession(url);
        if (error) {
          // Never log the URL — it may contain code= or access_token= params
          log.error('Deep-link session exchange failed', {
            message: error.message,
            code: (error as { code?: string }).code,
          });
          return;
        }
        setNeedsNewPassword(true);
        router.replace('/(auth)/new-password');
      }
    };

    void Linking.getInitialURL().then(consumeUrl);
    const sub = Linking.addEventListener('url', ({ url }) => {
      void consumeUrl(url);
    });
    return () => sub.remove();
  }, [router, setNeedsNewPassword]);

  useEffect(() => {
    if (!initialized) return;
    const root = String(segments[0] ?? '');
    const leaf = String(segments[1] ?? '');
    const inTabs = root === '(tabs)';
    const inAuth = root === '(auth)';

    if (!session && inTabs) {
      router.replace('/(auth)');
      return;
    }

    if (session && needsNewPassword && inTabs) {
      router.replace('/(auth)/new-password');
      return;
    }

    if (session && inAuth && leaf !== 'new-password' && !needsNewPassword) {
      router.replace('/(tabs)');
    }
  }, [initialized, session, segments, router, needsNewPassword]);

  if (!initialized) {
    return null;
  }

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="modal" options={{ presentation: 'modal', title: t('modal.title') }} />
      </Stack>
      <StatusBar style="auto" />
    </ThemeProvider>
  );
}

export function ErrorBoundary({ error, retry }: ErrorBoundaryProps) {
  log.error('Unhandled render error', { message: error.message });
  if (__DEV__ && error.stack) {
    log.debug('Stack trace', { stack: error.stack });
  }

  const { t } = useTranslation();

  return (
    <View style={styles.errorContainer}>
      <Text style={styles.errorTitle}>{t('error.title')}</Text>
      <Text style={styles.errorHint}>{t('error.hint')}</Text>
      <Pressable onPress={retry} style={styles.retryButton}>
        <Text style={styles.retryText}>{t('error.retry')}</Text>
      </Pressable>
    </View>
  );
}

export default function RootLayout() {
  useEffect(() => {
    if (typeof ErrorUtils !== 'undefined') {
      const prev = ErrorUtils.getGlobalHandler();
      ErrorUtils.setGlobalHandler((err, isFatal) => {
        log.error('Global JS error', {
          message: err?.message,
          fatal: isFatal,
        });
        prev(err, isFatal);
      });
    }
  }, []);

  return (
    <I18nextProvider i18n={i18n}>
      <AuthProvider>
        <NavigationRoot />
      </AuthProvider>
    </I18nextProvider>
  );
}

const styles = StyleSheet.create({
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing['4xl'],
    backgroundColor: '#000',
  },
  errorTitle: {
    color: '#fff',
    fontSize: FontSize['2xl'],
    fontWeight: '600',
    marginBottom: Spacing.lg,
    textAlign: 'center',
  },
  errorHint: {
    color: '#aaa',
    fontSize: FontSize.base,
    lineHeight: LineHeight.snug,
    textAlign: 'center',
    marginBottom: Spacing['3xl'],
  },
  retryButton: {
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing['3xl'],
    borderRadius: BorderRadius.md,
    backgroundColor: '#fff',
  },
  retryText: {
    color: '#000',
    fontSize: FontSize.lg,
    fontWeight: '600',
  },
});
