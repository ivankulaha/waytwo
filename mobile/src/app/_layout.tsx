import { useEffect } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import type { ErrorBoundaryProps, Href } from 'expo-router';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as Linking from 'expo-linking';
import { I18nextProvider, useTranslation } from 'react-i18next';
import 'react-native-reanimated';

import { AuthProvider, useAuth } from '@/context/AuthContext';
import { ProfileProvider, useProfile } from '@/context/ProfileContext';
import { Colors } from '@/constants/theme';
import { BorderRadius, FontSize, LineHeight, Spacing } from '@/constants/tokens';
import { useColorScheme } from '@/hooks/use-color-scheme';
import i18n from '@/lib/i18n';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';
import { pathForOnboardingStep } from '@/lib/sync/profile-sync';

const navigationLightTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: Colors.light.background,
    card: Colors.light.background,
  },
};

function NavigationRoot() {
  const { t } = useTranslation();
  const colorScheme = useColorScheme();
  const { session, initialized, needsNewPassword, setNeedsNewPassword } = useAuth();
  const { ready: profileReady, profile } = useProfile();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    const parseFragment = (url: string): Record<string, string> => {
      try {
        const idx = url.indexOf('#');
        if (idx === -1) return {};
        return Object.fromEntries(new URLSearchParams(url.substring(idx + 1)));
      } catch {
        return {};
      }
    };

    const consumeUrl = async (url: string | null) => {
      if (!url) return;

      // Default Supabase email: verify endpoint redirects with access_token/refresh_token in fragment
      const fragment = parseFragment(url);
      if (fragment.access_token && fragment.refresh_token) {
        const { error } = await supabase.auth.setSession({
          access_token: fragment.access_token,
          refresh_token: fragment.refresh_token,
        });
        if (error) {
          log.error('Deep-link setSession failed', {
            message: error.message,
            code: (error as { code?: string }).code,
          });
          return;
        }
        if (fragment.type === 'recovery') {
          setNeedsNewPassword(true);
          router.replace('/(auth)/new-password');
        }
        return;
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
    if (session && !profileReady) return;

    const root = String(segments[0] ?? '');
    const leaf = String(segments[1] ?? '');
    const inTabs = root === '(tabs)';
    const inAuth = root === '(auth)';
    const inOnboarding = root === '(onboarding)';
    const onboardingLeaf = inOnboarding ? String(segments[1] ?? '') : '';

    if (!session) {
      if (!inAuth) {
        router.replace('/(auth)' as Href);
      }
      return;
    }

    if (session && needsNewPassword && inTabs) {
      router.replace('/(auth)/new-password');
      return;
    }

    if (session && needsNewPassword && (inOnboarding || inTabs)) {
      router.replace('/(auth)/new-password');
      return;
    }

    if (session && needsNewPassword) {
      return;
    }

    const completed = Boolean(profile?.onboarding_completed_at);
    const step = profile?.onboarding_step ?? 0;

    if (session && !needsNewPassword && !completed) {
      const dest = pathForOnboardingStep(step) as Href;
      const wantLeaf = String(dest).replace('/(onboarding)/', '');
      if (!inOnboarding) {
        router.replace(dest);
        return;
      }
      if (onboardingLeaf !== wantLeaf) {
        router.replace(dest);
      }
      return;
    }

    if (session && completed && inOnboarding) {
      router.replace('/(tabs)' as Href);
      return;
    }

    if (session && !completed && inTabs) {
      router.replace(pathForOnboardingStep(step) as Href);
      return;
    }

    if (session && inAuth && leaf !== 'new-password' && !needsNewPassword) {
      if (completed) {
        router.replace('/(tabs)' as Href);
      } else {
        router.replace(pathForOnboardingStep(step) as Href);
      }
    }
  }, [initialized, session, segments, router, needsNewPassword, profileReady, profile]);

  if (!initialized || (session && !profileReady)) {
    return null;
  }

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : navigationLightTheme}>
      <Stack>
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="(onboarding)" options={{ headerShown: false }} />
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
        <ProfileProvider>
          <NavigationRoot />
        </ProfileProvider>
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
