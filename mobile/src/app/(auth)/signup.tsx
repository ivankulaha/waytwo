import { useMemo, useState } from 'react';
import { router, useLocalSearchParams } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { LabeledInput } from '@/components/auth/labeled-input';
import { PrimaryButton } from '@/components/auth/primary-button';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';
import { parsePassword } from '@/lib/validation';

export default function AuthSignupScreen() {
  const { t } = useTranslation();
  const { email: emailParam } = useLocalSearchParams<{ email?: string }>();
  const email = typeof emailParam === 'string' ? emailParam : '';
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const minMsg = t('validation.minPassword12');
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
    const { error: signError } = await supabase.auth.signUp({
      email,
      password: parsed.data,
    });
    setLoading(false);
    if (signError) {
      log.warn('signUp failed', { message: signError.message });
      setError(t('auth.couldNotCreateAccount'));
      return;
    }
    router.replace('/(tabs)');
  };

  const canSubmit = passwordCheck.success;

  return (
    <AuthShell
      flow="signup"
      title={t('auth.createAccountTitle')}
      subtitle={t('auth.choosePasswordSubtitle')}
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
        error={inlineHint ?? error}
      />
      <PrimaryButton label={t('auth.continue')} onPress={onSubmit} disabled={!canSubmit} loading={loading} />
    </AuthShell>
  );
}
