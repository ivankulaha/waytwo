import { useState } from 'react';
import { Pressable, StyleSheet, Text } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { LabeledInput } from '@/components/auth/labeled-input';
import { PrimaryButton } from '@/components/auth/primary-button';
import { FontSize, LineHeight, Spacing } from '@/constants/tokens';
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
      router.replace({
        pathname: '/(auth)/signup',
        params: { email },
      });
      return;
    }
    router.replace('/(tabs)');
  };

  const canSubmit = password.length > 0;

  return (
    <AuthShell
      flow="login"
      title={t('auth.enterPasswordTitle')}
      showBack
      onBack={() => router.back()}
    >
      <LabeledInput label={t('auth.emailLabel')} value={email} onChangeText={() => undefined} editable={false} />
      <LabeledInput
        label={t('auth.passwordLabel')}
        value={password}
        onChangeText={(v) => {
          setPassword(v);
          setError(undefined);
        }}
        placeholder={t('auth.passwordPlaceholder')}
        secure
        error={error}
      />
      <PrimaryButton label={t('auth.continue')} onPress={onSubmit} disabled={!canSubmit} loading={loading} />
      <Pressable onPress={() => router.push({ pathname: '/(auth)/forgot-password', params: { email } })}>
        <Text style={[styles.link, { color: c.textSubtle }]}>{t('auth.forgotPassword')}</Text>
      </Pressable>
    </AuthShell>
  );
}

const styles = StyleSheet.create({
  link: {
    fontSize: FontSize.base,
    textAlign: 'center',
    marginTop: Spacing.md,
    textDecorationLine: 'underline',
    lineHeight: LineHeight.snug,
  },
});
