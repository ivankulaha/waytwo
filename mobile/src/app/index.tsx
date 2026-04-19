import type { Href } from 'expo-router';
import { Redirect } from 'expo-router';

import { useAuth } from '@/context/AuthContext';
import { useProfile } from '@/context/ProfileContext';
import { pathForOnboardingStep } from '@/lib/sync/profile-sync';

export default function Index() {
  const { session, initialized, needsNewPassword } = useAuth();
  const { ready: profileReady, profile } = useProfile();

  if (!initialized || (session && !profileReady)) {
    return null;
  }

  if (session && needsNewPassword) {
    return <Redirect href="/(auth)/new-password" />;
  }

  if (session) {
    if (!profile?.onboarding_completed_at) {
      return <Redirect href={pathForOnboardingStep(profile?.onboarding_step ?? 0) as Href} />;
    }
    return <Redirect href="/(tabs)" />;
  }

  return <Redirect href="/(auth)" />;
}
