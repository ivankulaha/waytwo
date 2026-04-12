import { useState } from 'react';
import { Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { router } from 'expo-router';
import * as AppleAuthentication from 'expo-apple-authentication';
import * as Crypto from 'expo-crypto';
import { Ionicons } from '@expo/vector-icons';
import { useTranslation } from 'react-i18next';

import { AuthShell } from '@/components/auth/auth-shell';
import { PrimaryButton } from '@/components/auth/primary-button';
import { BorderRadius, FontSize, FontWeight, IconSize, Opacity, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';
import { parseEmail } from '@/lib/validation';

export default function AuthEmailScreen() {
  const { t } = useTranslation();
  const c = useAuthColors();
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [appleLoading, setAppleLoading] = useState(false);

  const onContinue = () => {
    setError(undefined);
    const parsed = parseEmail(email, t('validation.invalidEmail'));
    if (!parsed.success) {
      setError(parsed.error.flatten().formErrors[0] ?? t('validation.invalidEmail'));
      return;
    }
    router.push({
      pathname: '/(auth)/password',
      params: { email: parsed.data },
    });
  };

  const onApple = async () => {
    setAppleLoading(true);
    setError(undefined);
    try {
      const rawNonce = Crypto.randomUUID();
      const hashedNonce = await Crypto.digestStringAsync(
        Crypto.CryptoDigestAlgorithm.SHA256,
        rawNonce,
      );
      const credential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
          AppleAuthentication.AppleAuthenticationScope.EMAIL,
        ],
        nonce: hashedNonce,
      });
      if (!credential.identityToken) {
        setError(t('auth.appleNoToken'));
        return;
      }
      const { error: signError } = await supabase.auth.signInWithIdToken({
        provider: 'apple',
        token: credential.identityToken,
        nonce: rawNonce,
      });
      if (signError) {
        log.warn('Apple signInWithIdToken failed', { message: signError.message });
        setError(t('auth.appleSignInError'));
        return;
      }
      router.replace('/(tabs)');
    } catch (e: unknown) {
      if (e && typeof e === 'object' && 'code' in e && (e as { code?: string }).code === 'ERR_REQUEST_CANCELED') {
        return;
      }
      log.error('Apple sign-in threw', {
        message: e instanceof Error ? e.message : String(e),
      });
      setError(t('auth.appleSignInError'));
    } finally {
      setAppleLoading(false);
    }
  };

  const canSubmit = email.trim().length > 0;

  return (
    <AuthShell
      flow="email"
      title={t('auth.signInOrCreateTitle')}
      subtitle={t('auth.signInOrCreateSubtitle')}
    >
      {Platform.OS === 'ios' ? (
        <Pressable
          accessibilityRole="button"
          onPress={onApple}
          disabled={appleLoading}
          style={({ pressed }) => [
            styles.apple,
            { backgroundColor: c.buttonBg },
            appleLoading && styles.disabled,
            pressed && !appleLoading && styles.pressed,
          ]}
        >
          <Ionicons name="logo-apple" size={IconSize.md} color={c.buttonText} />
          <Text style={[styles.appleText, { color: c.buttonText }]}>{t('auth.continueWithApple')}</Text>
        </Pressable>
      ) : null}

      {Platform.OS === 'ios' ? (
        <View style={styles.sepRow}>
          <View style={[styles.sepLine, { backgroundColor: c.separatorColor }]} />
          <Text style={[styles.sepText, { color: c.separatorColor }]}>{t('auth.or')}</Text>
          <View style={[styles.sepLine, { backgroundColor: c.separatorColor }]} />
        </View>
      ) : null}

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
      {error ? <Text style={[styles.error, { color: c.errorText }]}>{error}</Text> : null}

      <PrimaryButton label={t('auth.continue')} onPress={onContinue} disabled={!canSubmit} />
    </AuthShell>
  );
}

const styles = StyleSheet.create({
  apple: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.md,
    height: Size.buttonHeight,
    borderRadius: BorderRadius.full,
    marginBottom: Spacing.xl,
  },
  appleText: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.semibold,
  },
  disabled: {
    opacity: Opacity.appleDisabled,
  },
  pressed: {
    opacity: Opacity.pressedLight,
  },
  sepRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.xl,
    gap: Spacing.lg,
  },
  sepLine: {
    flex: 1,
    height: Size.separatorLine,
  },
  sepText: {
    fontSize: FontSize.md,
  },
  input: {
    height: Size.inputHeight,
    borderRadius: BorderRadius.md,
    paddingHorizontal: Spacing.xl,
    fontSize: FontSize.lg,
    borderWidth: Size.borderWidth,
    marginBottom: Spacing.md,
  },
  error: {
    fontSize: FontSize.sm,
    marginBottom: Spacing.md,
  },
});
