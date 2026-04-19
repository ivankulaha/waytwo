import { useCallback, useEffect, useState } from 'react';
import { InteractionManager, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import ImageCropPicker from 'react-native-image-crop-picker';
import type { Href } from 'expo-router';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { PrimaryButton } from '@/components/auth/primary-button';
import { AvatarPicker } from '@/components/onboarding/avatar-picker';
import { ColorPalette } from '@/components/onboarding/color-palette';
import { OnboardingShell } from '@/components/onboarding/onboarding-shell';
import { OnboardingPalette } from '@/constants/theme';
import { BorderRadius, FontSize, FontWeight, LineHeight, Size, Spacing } from '@/constants/tokens';
import { useAuth } from '@/context/AuthContext';
import { useProfile } from '@/context/ProfileContext';
import { useAuthColors } from '@/hooks/use-auth-colors';
import { log } from '@/lib/log';

function hexForColorId(id: string | null): string | undefined {
  if (!id) return undefined;
  return OnboardingPalette.find((p) => p.id === id)?.hex;
}

function toFileUri(path: string): string {
  return path.startsWith('file://') ? path : `file://${path}`;
}

async function waitForPickerDismissal() {
  if (Platform.OS !== 'ios') return;
  await new Promise<void>((resolve) => {
    InteractionManager.runAfterInteractions(() => resolve());
  });
  await new Promise<void>((resolve) => setTimeout(resolve, 750));
  await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
}

export default function OnboardingLookScreen() {
  const { t } = useTranslation();
  const c = useAuthColors();
  const { user } = useAuth();
  const { profile, updateProfile, completeOnboarding, pushAvatarFromPicker } = useProfile();
  const [colorId, setColorId] = useState<string | null>(null);
  const [localUri, setLocalUri] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const displayName = profile?.display_name?.trim() || '?';

  useEffect(() => {
    setLocalUri(profile?.photo_local_uri ?? null);
  }, [profile?.photo_local_uri]);

  useEffect(() => {
    setColorId(profile?.color_id ?? null);
  }, [profile?.color_id]);

  const onColorSelect = useCallback(
    (id: string) => {
      setColorId(id);
      void updateProfile({ color_id: id }).catch((e) => {
        log.warn('Onboarding color persist failed', {
          op: 'onboardingColorSelect',
          message: e instanceof Error ? e.message : String(e),
        });
      });
    },
    [updateProfile],
  );

  const pickImage = async () => {
    if (Platform.OS === 'web') {
      log.warn('Onboarding avatar picker skipped on web', { op: 'onboardingAvatarPick' });
      return;
    }
    log.info('Onboarding avatar pick pressed', { step: 2 });

    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      log.warn('Onboarding media library permission denied', { op: 'onboardingAvatarPick' });
      return;
    }

    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: false,
      quality: 1,
    });
    if (res.canceled || !res.assets[0]?.uri) return;

    await waitForPickerDismissal();

    try {
      const image = await ImageCropPicker.openCropper({
        path: res.assets[0].uri,
        mediaType: 'photo',
        width: 480,
        height: 480,
        cropperCircleOverlay: true,
        compressImageQuality: 0.85,
        cropperToolbarTitle: t('onboarding.look.cropTitle'),
        cropperChooseText: t('common.choose'),
        cropperCancelText: t('common.cancel'),
        cropperChooseColor: '#FFFFFF',
        cropperCancelColor: '#FFFFFF',
        cropperToolbarColor: '#000000',
        cropperToolbarWidgetColor: '#FFFFFF',
        cropperActiveWidgetColor: '#FFFFFF',
        cropperStatusBarLight: false,
        cropperNavigationBarLight: false,
      });
      const uri = toFileUri(image.path);
      setLocalUri(uri);
      try {
        await pushAvatarFromPicker(uri);
      } catch (e) {
        log.warn('Onboarding avatar upload enqueue failed', {
          message: e instanceof Error ? e.message : String(e),
        });
      }
    } catch (e: unknown) {
      const code =
        typeof e === 'object' && e !== null && 'code' in e
          ? String((e as { code: unknown }).code)
          : undefined;
      if (code === 'E_PICKER_CANCELLED') return;
      log.warn('Onboarding avatar crop failed', {
        message: e instanceof Error ? e.message : String(e),
        code,
      });
    }
  };

  const remoteUpdatedMs = profile?.remote_updated_at
    ? Date.parse(profile.remote_updated_at)
    : Date.now();

  const finish = async () => {
    setLoading(true);
    log.info('Onboarding finish pressed', { step: 2, hasColor: Boolean(colorId) });
    try {
      if (colorId) {
        await updateProfile({ color_id: colorId });
      }
      await completeOnboarding();
      router.replace('/(tabs)' as Href);
    } catch (e) {
      log.warn('Onboarding finish failed', { message: e instanceof Error ? e.message : String(e) });
    } finally {
      setLoading(false);
    }
  };

  const skip = async () => {
    setLoading(true);
    log.info('Onboarding skip pressed', { step: 2 });
    try {
      await completeOnboarding();
      router.replace('/(tabs)' as Href);
    } catch (e) {
      log.warn('Onboarding skip failed', { message: e instanceof Error ? e.message : String(e) });
    } finally {
      setLoading(false);
    }
  };

  const goBackToYou = async () => {
    log.info('Onboarding look back pressed', { step: 2 });
    try {
      await updateProfile({ onboarding_step: 1 });
      router.replace('/(onboarding)/you' as Href);
    } catch (e) {
      log.warn('Onboarding look back failed', { message: e instanceof Error ? e.message : String(e) });
    }
  };

  const glowColor = hexForColorId(colorId);

  return (
    <OnboardingShell
      variant="form"
      title={t('onboarding.look.title')}
      showBack
      onBack={() => void goBackToYou()}
      titleAlign="center"
    >
      <AvatarPicker
        displayName={displayName}
        localUri={localUri}
        remoteUserId={user?.id ?? null}
        remotePhotoPath={profile?.photo_path ?? null}
        remoteUpdatedAtMs={Number.isFinite(remoteUpdatedMs) ? remoteUpdatedMs : Date.now()}
        glowColor={glowColor}
        onPickPress={() => void pickImage()}
      />
      <View
        style={[
          styles.colorCard,
          {
            backgroundColor: c.groupedSurface,
            borderColor: c.inputBorder,
          },
        ]}
      >
        <Text style={[styles.sectionLabel, { color: c.textSubtle }]}>
          {t('onboarding.look.colorLabel')}
        </Text>
        <ColorPalette value={colorId} onChange={onColorSelect} />
      </View>
      <View style={styles.footer}>
        <PrimaryButton label={t('onboarding.look.finish')} onPress={() => void finish()} loading={loading} />
        <Pressable accessibilityRole="button" onPress={() => void skip()} disabled={loading} style={styles.skip}>
          <Text style={[styles.skipText, { color: c.text }]}>{t('onboarding.look.skip')}</Text>
        </Pressable>
      </View>
    </OnboardingShell>
  );
}

const styles = StyleSheet.create({
  colorCard: {
    borderRadius: BorderRadius.onboardingColorCard,
    borderWidth: Size.borderWidth,
    padding: Spacing.xl,
    gap: Spacing['3xl'],
    marginBottom: Spacing['2xl'],
  },
  sectionLabel: {
    fontSize: FontSize.sm,
    fontWeight: FontWeight.medium,
    lineHeight: LineHeight.profileColorLabel,
  },
  footer: {
    marginTop: 'auto',
    paddingBottom: Spacing['3xl'],
    gap: Spacing.lg,
  },
  skip: {
    alignItems: 'center',
    paddingVertical: Spacing.md,
  },
  skipText: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.semibold,
    lineHeight: LineHeight.normal,
    textAlign: 'center',
  },
});
