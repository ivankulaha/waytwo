import { useState } from 'react';
import { Pressable, StyleSheet, Text } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { FormTextField } from '@/components/ui/form-field';
import { PrimaryButton } from '@/components/auth/primary-button';
import { FontSize, FontWeight, LineHeight, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';

export default function AuthPasswordScreen() {
  const { t } = useTranslation();
  const c = useAuthColors();
  const { email: emailParam } = useLocalSearchParams<{ email?: string }>();
  const email = typeof emailParam === 'string' ? emailParam : '';
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const onSubmit = async () => {
    setError(undefined);
    if (!email) {
      router.replace('/(auth)');
      return;
    }
    if (!password) {
      setError(t('auth.invalidEmailOrPassword'));
      return;
    }
    setLoading(true);
    const { error: signError } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (signError) {
      log.warn('signInWithPassword failed', { message: signError.message });
      setError(t('auth.invalidEmailOrPassword'));
      return;
    }
    router.replace('/');
  };

  const canSubmit = password.length > 0;

  return (
    <AuthShell
      title={t('auth.enterPasswordTitle')}
      showBack
      onBack={() => router.back()}
    >
      <FormTextField
        label={t('auth.emailLabel')}
        placeholder={t('auth.emailPlaceholder')}
        value={email}
        onChangeText={() => undefined}
        editable={false}
        keyboardType="email-address"
        textContentType="emailAddress"
        autoComplete="email"
        accessibilityLabel={t('auth.emailLabel')}
      />
      <FormTextField
        label={t('auth.passwordLabel')}
        placeholder={t('auth.passwordPlaceholder')}
        value={password}
        onChangeText={(v) => {
          setPassword(v);
          setError(undefined);
        }}
        secure
        textContentType="password"
        autoComplete="current-password"
        importantForAutofill="yes"
        errorMessage={error}
        accessibilityLabel={t('auth.passwordPlaceholder')}
      />
      <PrimaryButton label={t('auth.continue')} onPress={onSubmit} disabled={!canSubmit} loading={loading} />
      <Pressable
        accessibilityRole="button"
        onPress={() => router.push({ pathname: '/(auth)/forgot-password', params: { email } })}
        style={styles.forgotPasswordHit}
      >
        <Text style={[styles.forgotPassword, { color: c.text }]}>{t('auth.forgotPassword')}</Text>
      </Pressable>
    </AuthShell>
  );
}

const styles = StyleSheet.create({
  forgotPasswordHit: {
    marginTop: Spacing['3xl'],
    minHeight: 24,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  forgotPassword: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.semibold,
    lineHeight: LineHeight.normal,
    textAlign: 'center',
  },
});
