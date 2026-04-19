import { useCallback, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import type { Href } from 'expo-router';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { OnboardingNextButton } from '@/components/onboarding/onboarding-next-button';
import { OnboardingShell } from '@/components/onboarding/onboarding-shell';
import { FormSelectField, FormTextField } from '@/components/ui/form-field';
import { DatePickerField } from '@/components/ui/form-date-field';
import { FontSize, Spacing } from '@/constants/tokens';
import { useProfile } from '@/context/ProfileContext';
import { useAuthColors } from '@/hooks/use-auth-colors';
import { presentGenderPicker, type OnboardingGender } from '@/lib/onboarding-gender-picker';
import { log } from '@/lib/log';

export default function OnboardingYouScreen() {
  const { t } = useTranslation();
  const c = useAuthColors();
  const { profile, updateProfile } = useProfile();
  const [name, setName] = useState('');
  const [gender, setGender] = useState<OnboardingGender | null>(null);
  const [dob, setDob] = useState<string | null>(null);
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const remoteUserId = profile?.user_id;
  const remoteDisplayName = profile?.display_name;
  const remoteGender = profile?.gender as OnboardingGender | null | undefined;
  const remoteDob = profile?.date_of_birth;

  useFocusEffect(
    useCallback(() => {
      if (!remoteUserId) return;
      setName(remoteDisplayName ?? '');
      setGender(remoteGender ?? null);
      setDob(remoteDob ?? null);
    }, [remoteUserId, remoteDisplayName, remoteGender, remoteDob]),
  );

  const onContinue = async () => {
    setError(undefined);
    if (!name.trim()) {
      setError(t('onboarding.you.nameRequired'));
      return;
    }
    if (!gender) {
      setError(t('onboarding.you.genderRequired'));
      return;
    }
    setLoading(true);
    log.info('Onboarding you continue', { step: 1, hasDob: Boolean(dob) });
    try {
      await updateProfile({
        display_name: name.trim(),
        gender,
        date_of_birth: dob,
        onboarding_step: 2,
      });
      router.push('/(onboarding)/look' as Href);
    } catch (e) {
      log.warn('Onboarding you save failed', { message: e instanceof Error ? e.message : String(e) });
      setError(t('onboarding.errors.syncFailed'));
    } finally {
      setLoading(false);
    }
  };

  const goBackToIntro = async () => {
    log.info('Onboarding you back pressed', { step: 1 });
    try {
      await updateProfile({ onboarding_step: 0 });
      router.replace('/(onboarding)/intro' as Href);
    } catch (e) {
      log.warn('Onboarding you back failed', { message: e instanceof Error ? e.message : String(e) });
    }
  };

  const genderValueLine = gender
    ? { male: t('onboarding.you.genderMale'), female: t('onboarding.you.genderFemale'), other: t('onboarding.you.genderOther') }[
        gender
      ]
    : '';

  return (
    <OnboardingShell
      variant="form"
      title={t('onboarding.you.title')}
      showBack
      onBack={() => void goBackToIntro()}
      titleAlign="center"
    >
      <FormTextField
        label={t('onboarding.you.nameLabel')}
        placeholder={t('onboarding.you.namePlaceholder')}
        value={name}
        onChangeText={(v) => {
          setName(v);
          setError(undefined);
        }}
        autoCapitalize="words"
        textContentType="givenName"
        accessibilityLabel={t('onboarding.you.namePlaceholder')}
        invalid={Boolean(error && !name.trim())}
        onClear={
          name.trim()
            ? () => {
                log.info('Onboarding you field cleared', { op: 'onboarding_you_clear', field: 'name' });
                setName('');
                setError(undefined);
              }
            : undefined
        }
        clearAccessibilityLabel={t('common.clearField')}
      />
      <FormSelectField
        label={t('onboarding.you.genderLabel')}
        value={gender ? genderValueLine : null}
        onPress={() => {
          setError(undefined);
          presentGenderPicker(t, (g) => setGender(g));
        }}
        error={Boolean(error && !gender)}
        onClear={
          gender
            ? () => {
                log.info('Onboarding you field cleared', { op: 'onboarding_you_clear', field: 'gender' });
                setGender(null);
                setError(undefined);
              }
            : undefined
        }
        clearAccessibilityLabel={t('common.clearField')}
        accessibilityLabel={t('onboarding.you.genderLabel')}
      />
      <DatePickerField
        value={dob}
        onChange={setDob}
        fieldLabel={t('onboarding.you.dobRowLabel')}
        doneLabel={t('onboarding.you.dobDone')}
        clearAccessibilityLabel={t('common.clearField')}
        sheetBackdropAccessibilityLabel={t('common.dismissSheet')}
      />
      {error ? <Text style={[styles.error, { color: c.errorText }]}>{error}</Text> : null}
      <View style={styles.footer}>
        <OnboardingNextButton
          label={t('onboarding.you.next')}
          onPress={() => void onContinue()}
          loading={loading}
          disabled={!name.trim() || !gender}
        />
      </View>
    </OnboardingShell>
  );
}

const styles = StyleSheet.create({
  error: {
    fontSize: FontSize.sm,
    marginBottom: Spacing.lg,
  },
  footer: {
    marginTop: 'auto',
    paddingBottom: Spacing['3xl'],
  },
});
