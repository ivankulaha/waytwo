import { useState } from 'react';
import { Linking, Pressable, StyleSheet, Text, TextInput } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { PrimaryButton } from '@/components/auth/primary-button';
import { BorderRadius, FontSize, LineHeight, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';
import { passwordResetRedirectTo } from '@/lib/deeplinks';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';
import { parseEmail } from '@/lib/validation';

export default function AuthForgotPasswordScreen() {
  const { t } = useTranslation();
  const c = useAuthColors();
  const { email: initialEmail } = useLocalSearchParams<{ email?: string }>();
  const [email, setEmail] = useState(typeof initialEmail === 'string' ? initialEmail : '');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const onSend = async () => {
    setError(undefined);
    const parsed = parseEmail(email, t('validation.invalidEmail'));
    if (!parsed.success) {
      setError(parsed.error.flatten().formErrors[0] ?? t('validation.invalidEmail'));
      return;
    }
    setLoading(true);
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(parsed.data, {
      redirectTo: passwordResetRedirectTo,
    });
    setLoading(false);
    if (resetError) {
      log.warn('resetPasswordForEmail failed', { message: resetError.message });
      setError(t('auth.couldNotSendReset'));
      return;
    }
    setSent(true);
  };

  const openMail = () => {
    Linking.openURL('message:').catch(() => {});
  };

  if (sent) {
    return (
      <AuthShell flow="forgot" title={t('auth.emailSentTitle')} showBack onBack={() => router.replace('/(auth)')}>
        <Text style={[styles.body, { color: c.textSubtle }]}>{t('auth.emailSentBody')}</Text>
        <PrimaryButton label={t('auth.openMail')} onPress={openMail} />
        <Pressable onPress={() => router.replace('/(auth)')}>
          <Text style={[styles.link, { color: c.textSubtle }]}>{t('auth.backToSignIn')}</Text>
        </Pressable>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      flow="forgot"
      title={t('auth.resetPasswordTitle')}
      subtitle={t('auth.resetPasswordSubtitle')}
      showBack
      onBack={() => router.back()}
    >
      <TextInput
        style={[
          styles.input,
          {
            backgroundColor: c.inputBg,
            borderColor: error ? c.errorText : c.inputBorder,
            color: c.text,
          },
        ]}
        placeholder={t('auth.emailPlaceholder')}
        placeholderTextColor={c.placeholderText}
        keyboardType="email-address"
        autoCapitalize="none"
        autoCorrect={false}
        value={email}
        onChangeText={(v) => {
          setEmail(v);
          setError(undefined);
        }}
      />
      {error ? <Text style={[styles.err, { color: c.errorText }]}>{error}</Text> : null}
      <PrimaryButton label={t('auth.continue')} onPress={onSend} disabled={!email.trim()} loading={loading} />
    </AuthShell>
  );
}

const styles = StyleSheet.create({
  input: {
    height: Size.inputHeight,
    borderRadius: BorderRadius.md,
    paddingHorizontal: Spacing.xl,
    fontSize: FontSize.lg,
    borderWidth: Size.borderWidth,
    marginBottom: Spacing.md,
  },
  err: {
    fontSize: FontSize.sm,
    marginBottom: Spacing.md,
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
