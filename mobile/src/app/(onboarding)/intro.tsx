import { useState } from 'react';
import { Alert, StyleSheet, View } from 'react-native';
import type { Href } from 'expo-router';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { PrimaryButton } from '@/components/auth/primary-button';
import { OnboardingShell } from '@/components/onboarding/onboarding-shell';
import { useProfile } from '@/context/ProfileContext';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';

export default function OnboardingIntroScreen() {
  const { t } = useTranslation();
  const { updateProfile } = useProfile();
  const [loading, setLoading] = useState(false);

  const onBack = () => {
    log.info('Onboarding intro back pressed', { step: 0 });
    Alert.alert(t('onboarding.logoutTitle'), t('onboarding.logoutMessage'), [
      { text: t('onboarding.logoutCancel'), style: 'cancel' },
      {
        text: t('onboarding.logoutConfirm'),
        style: 'destructive',
        onPress: () => {
          log.info('Onboarding logout confirmed', { step: 0 });
          void supabase.auth.signOut();
        },
      },
    ]);
  };

  const onContinue = async () => {
    log.info('Onboarding intro continue', { step: 0 });
    setLoading(true);
    try {
      await updateProfile({ onboarding_step: 1 });
      router.push('/(onboarding)/you' as Href);
    } catch (e) {
      log.warn('Onboarding intro continue failed', { message: e instanceof Error ? e.message : String(e) });
    } finally {
      setLoading(false);
    }
  };

  return (
    <OnboardingShell
      variant="intro"
      title={t('onboarding.intro.title')}
      subtitle={t('onboarding.intro.subtitle')}
      onBack={onBack}
    >
      <View style={styles.footer}>
        <PrimaryButton label={t('onboarding.intro.cta')} onPress={() => void onContinue()} loading={loading} />
      </View>
    </OnboardingShell>
  );
}

const styles = StyleSheet.create({
  footer: {
    width: '100%',
  },
});
