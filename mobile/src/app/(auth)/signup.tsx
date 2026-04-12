import { useMemo, useState } from 'react';
import { Linking, Pressable, StyleSheet, Text } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { LabeledInput } from '@/components/auth/labeled-input';
import { PrimaryButton } from '@/components/auth/primary-button';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';
import { parsePassword } from '@/lib/validation';
import { FontSize, LineHeight, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

export default function AuthSignupScreen() {
  const { t } = useTranslation();
  const c = useAuthColors();
  const { email: emailParam } = useLocalSearchParams<{ email?: string }>();
  const email = typeof emailParam === 'string' ? emailParam : '';
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);
  const [needsEmailConfirmation, setNeedsEmailConfirmation] = useState(false);

  const minMsg = t('validation.minPassword6');
  const passwordCheck = useMemo(() => parsePassword(password, minMsg), [password, minMsg]);
  const inlineHint =
    password.length > 0 && !passwordCheck.success
      ? passwordCheck.error.flatten().formErrors[0]
      : undefined;

  const onSubmit = async () => {
    setError(undefined);
    if (!email) {
      router.replace('/(auth)');
      return;
    }
    const parsed = parsePassword(password, minMsg);
    if (!parsed.success) {
      setError(parsed.error.flatten().formErrors[0] ?? minMsg);
      return;
    }
    setLoading(true);
    const { data, error: signError } = await supabase.auth.signUp({
      email,
      password: parsed.data,
    });
    setLoading(false);
    if (signError) {
      log.warn('signUp failed', { message: signError.message });
      const m = signError.message?.toLowerCase() ?? '';
      const rateLimited =
        signError.status === 429 || m.includes('rate limit');
      setError(
        rateLimited ? t('auth.signupRateLimited') : t('auth.couldNotCreateAccount'),
      );
      return;
    }
    if (data.session) {
      router.replace('/(tabs)');
      return;
    }
    setNeedsEmailConfirmation(true);
  };

  const openMail = () => {
    Linking.openURL('message:').catch(() => {});
  };

  const canSubmit = passwordCheck.success;

  if (needsEmailConfirmation) {
    return (
      <AuthShell
        flow="signup"
        title={t('auth.confirmEmailTitle')}
        showBack
        onBack={() => router.replace('/(auth)')}
      >
        <Text style={[styles.body, { color: c.textSubtle }]}>
          {t('auth.confirmEmailBody', { email })}
        </Text>
        <PrimaryButton label={t('auth.openMail')} onPress={openMail} />
        <Pressable onPress={() => router.replace('/(auth)')}>
          <Text style={[styles.link, { color: c.textSubtle }]}>{t('auth.backToSignIn')}</Text>
        </Pressable>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      flow="signup"
      title={t('auth.createAccountTitle')}
      subtitle={t('auth.choosePasswordSubtitle')}
      showBack
      onBack={() => router.back()}
    >
      {email ? (
        <Text style={[styles.emailHint, { color: c.textSubtle }]}>{t('auth.signupEmailHint', { email })}</Text>
      ) : null}
      <LabeledInput
        label={t('auth.passwordLabel')}
        value={password}
        onChangeText={(v) => {
          setPassword(v);
          setError(undefined);
        }}
        placeholder={t('auth.passwordPlaceholder')}
        secure
        textContentType="newPassword"
        autoComplete="password-new"
        importantForAutofill="yes"
        error={inlineHint ?? error}
      />
      <PrimaryButton label={t('auth.continue')} onPress={onSubmit} disabled={!canSubmit} loading={loading} />
    </AuthShell>
  );
}

const styles = StyleSheet.create({
  emailHint: {
    fontSize: FontSize.md,
    lineHeight: LineHeight.tight,
    textAlign: 'center',
    marginBottom: Spacing.xl,
  },
  body: {
    fontSize: FontSize.base,
    lineHeight: LineHeight.snug,
    textAlign: 'center',
    marginBottom: Spacing['3xl'],
  },
  link: {
    fontSize: FontSize.base,
    textAlign: 'center',
    marginTop: Spacing.xl,
    textDecorationLine: 'underline',
  },
});
