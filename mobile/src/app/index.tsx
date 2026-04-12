import { Redirect } from 'expo-router';

import { useAuth } from '@/context/AuthContext';

export default function Index() {
  const { session, initialized, needsNewPassword } = useAuth();

  if (!initialized) {
    return null;
  }

  if (session && needsNewPassword) {
    return <Redirect href="/(auth)/new-password" />;
  }

  if (session) {
    return <Redirect href="/(tabs)" />;
  }

  return <Redirect href="/(auth)" />;
}
