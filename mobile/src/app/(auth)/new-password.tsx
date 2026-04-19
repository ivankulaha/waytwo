import { useMemo, useState } from 'react';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { FormTextField } from '@/components/ui/form-field';
import { PrimaryButton } from '@/components/auth/primary-button';
import { useAuth } from '@/context/AuthContext';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';
import { parsePassword } from '@/lib/validation';

export default function AuthNewPasswordScreen() {
  const { t } = useTranslation();
  const { setNeedsNewPassword } = useAuth();
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const minMsg = t('validation.minPassword6');
  const passwordCheck = useMemo(() => parsePassword(password, minMsg), [password, minMsg]);
  const inlineHint =
    password.length > 0 && !passwordCheck.success
      ? passwordCheck.error.flatten().formErrors[0]
      : undefined;

  const onSave = async () => {
    setError(undefined);
    const parsed = parsePassword(password, minMsg);
    if (!parsed.success) {
      setError(parsed.error.flatten().formErrors[0] ?? minMsg);
      return;
    }
    setLoading(true);
    const { error: updateError } = await supabase.auth.updateUser({ password: parsed.data });
    setLoading(false);
    if (updateError) {
      log.warn('updateUser password failed', { message: updateError.message });
      setError(t('auth.couldNotUpdatePassword'));
      return;
    }
    setNeedsNewPassword(false);
    router.replace('/');
  };

  return (
    <AuthShell title={t('auth.createNewPasswordTitle')} showBack onBack={() => router.back()}>
      <FormTextField
        label={t('auth.passwordLabel')}
        placeholder={t('auth.newPasswordPlaceholder')}
        value={password}
        onChangeText={(v) => {
          setPassword(v);
          setError(undefined);
        }}
        secure
        textContentType="newPassword"
        autoComplete="password-new"
        importantForAutofill="yes"
        errorMessage={inlineHint ?? error}
        accessibilityLabel={t('auth.newPasswordPlaceholder')}
      />
      <PrimaryButton
        label={t('auth.savePassword')}
        onPress={onSave}
        disabled={!passwordCheck.success}
        loading={loading}
      />
    </AuthShell>
  );
}
