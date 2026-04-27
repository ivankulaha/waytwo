import { useMemo } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { PartnerSlot } from '@/components/home/partner-slot';
import { ProfileAvatarCircle } from '@/components/profile/profile-avatar-circle';
import { RadialBlob } from '@/components/ui/radial-blob';
import {
  RadialBlobGeometryPreset,
  homePartnerGlowStopsFromHex,
  type RadialBlobSpec,
} from '@/constants/gradients';
import { OnboardingPalette } from '@/constants/theme/onboarding';
import { FontSize, FontWeight, LineHeight, Size, Spacing } from '@/constants/tokens';
import { useAuth } from '@/context/AuthContext';
import { useProfile } from '@/context/ProfileContext';
import { useAppColors } from '@/hooks/use-app-colors';
import { log } from '@/lib/log';

type HomeScreenState = 'pairing' | 'paired';

function hexForColorId(id: string | null): string | undefined {
  if (!id) return undefined;
  return OnboardingPalette.find((p) => p.id === id)?.hex;
}

export default function HomeScreen() {
  const homeState: HomeScreenState = 'pairing';
  const c = useAppColors();
  const { user } = useAuth();
  const { profile } = useProfile();
  const accentColorHex = hexForColorId(profile?.color_id ?? null) ?? c.profileAccentFallback;

  const blobSpec = useMemo((): RadialBlobSpec => {
    return {
      geometry: RadialBlobGeometryPreset.homePartnerGlow,
      stops: homePartnerGlowStopsFromHex(hexForColorId(profile?.color_id ?? null)),
    };
  }, [profile?.color_id]);

  const displayName = profile?.display_name?.trim() ?? '';
  const remoteUpdatedMs = profile?.remote_updated_at
    ? Date.parse(profile.remote_updated_at)
    : Date.now();

  return (
    <View style={[styles.root, { backgroundColor: c.homeBg }]}>
      <SafeAreaView style={[styles.safe, styles.safeAboveBlob]} edges={['top']}>
        <View style={styles.column}>
          <View style={styles.avatarBlock}>
            <ProfileAvatarCircle
              displayName={displayName.length > 0 ? displayName : '?'}
              localUri={profile?.photo_local_uri ?? null}
              remoteUserId={user?.id ?? null}
              remotePhotoPath={profile?.photo_path ?? null}
              remoteUpdatedAtMs={Number.isFinite(remoteUpdatedMs) ? remoteUpdatedMs : Date.now()}
              showFrameBorder={false}
            />
            {displayName.length > 0 ? (
              <Text style={[styles.name, { color: c.text }]} numberOfLines={1}>
                {displayName}
              </Text>
            ) : null}
          </View>
        </View>
      </SafeAreaView>

      {homeState === 'pairing' ? (
        <RadialBlob spec={blobSpec}>
          <PartnerSlot
            state="no-invite"
            accentColorHex={accentColorHex}
            onInvitePress={() => {
              log.info('invite_partner_tap', { op: 'home', step: 'invite', status: 'noop' });
            }}
          />
        </RadialBlob>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  safe: {
    flex: 1,
  },
  safeAboveBlob: {
    zIndex: 1,
  },
  column: {
    flex: 1,
    alignItems: 'center',
    paddingTop: Spacing['3xl'],
  },
  avatarBlock: {
    alignItems: 'center',
    gap: Spacing.lg,
  },
  name: {
    fontSize: FontSize.xl,
    fontWeight: FontWeight.medium,
    lineHeight: LineHeight.normal,
    textAlign: 'center',
    maxWidth: Size.onboardingAvatar + Spacing['4xl'],
  },
});
