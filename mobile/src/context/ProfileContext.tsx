import NetInfo from '@react-native-community/netinfo';
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { AppState } from 'react-native';

import { useAuth } from '@/context/AuthContext';
import { closeAndWipe, getOpenedDb, openProfileDb } from '@/lib/db/client';
import { getProfile, type LocalProfileRow } from '@/lib/db/profile-repo';
import { log } from '@/lib/log';
import {
  initProfileDb,
  pullProfile,
  pushAvatar,
  pushCompleteOnboarding,
  pushProfileUpdate,
  type ProfilePatch,
} from '@/lib/sync/profile-sync';
import { flushOutbox } from '@/lib/sync/outbox';

type ProfileContextValue = {
  ready: boolean;
  profile: LocalProfileRow | null;
  updateProfile: (partial: ProfilePatch) => Promise<void>;
  completeOnboarding: () => Promise<void>;
  pushAvatarFromPicker: (localUri: string) => Promise<void>;
  refreshFromDb: () => Promise<void>;
};

const ProfileContext = createContext<ProfileContextValue | null>(null);

export function ProfileProvider({ children }: { children: ReactNode }) {
  const { session, initialized } = useAuth();
  const [profile, setProfile] = useState<LocalProfileRow | null>(null);
  const [ready, setReady] = useState(false);

  const refreshFromDb = useCallback(async () => {
    const db = getOpenedDb();
    if (!db) {
      setProfile(null);
      return;
    }
    const p = await getProfile(db);
    setProfile(p);
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function run() {
      if (!initialized) return;

      if (!session?.user?.id || !session.access_token) {
        await closeAndWipe();
        if (!cancelled) {
          setProfile(null);
          setReady(true);
        }
        return;
      }

      setReady(false);
      const userId = session.user.id;
      const token = session.access_token;

      try {
        const db = await openProfileDb(userId);
        await initProfileDb(db, userId);
        try {
          await pullProfile(db, token);
        } catch (e) {
          log.warn('pullProfile failed', { message: e instanceof Error ? e.message : String(e) });
        }
        if (cancelled) return;
        await refreshFromDb();
        await flushOutbox(db);
        if (!cancelled) await refreshFromDb();
      } catch (e) {
        log.error('Profile DB init failed', { message: e instanceof Error ? e.message : String(e) });
        if (!cancelled) setProfile(null);
      } finally {
        if (!cancelled) setReady(true);
      }
    }

    void run();
    return () => {
      cancelled = true;
    };
  }, [initialized, session?.user?.id, session?.access_token, refreshFromDb]);

  useEffect(() => {
    if (!session?.user?.id || !ready) return;

    const onActive = (state: string) => {
      if (state !== 'active') return;
      const db = getOpenedDb();
      if (!db) return;
      void flushOutbox(db)
        .then(() => refreshFromDb())
        .catch((e) => log.warn('flush on AppState failed', { message: e instanceof Error ? e.message : String(e) }));
    };

    const sub = AppState.addEventListener('change', onActive);
    const unsubNet = NetInfo.addEventListener((state) => {
      if (state.isConnected) {
        const db = getOpenedDb();
        if (!db) return;
        void flushOutbox(db)
          .then(() => refreshFromDb())
          .catch((e) => log.warn('flush on NetInfo failed', { message: e instanceof Error ? e.message : String(e) }));
      }
    });

    return () => {
      sub.remove();
      unsubNet();
    };
  }, [session?.user?.id, ready, refreshFromDb]);

  const updateProfile = useCallback(
    async (partial: ProfilePatch) => {
      const db = getOpenedDb();
      if (!db) throw new Error('Profile database not open');
      await pushProfileUpdate(db, partial);
      await refreshFromDb();
    },
    [refreshFromDb],
  );

  const completeOnboarding = useCallback(async () => {
    const db = getOpenedDb();
    if (!db) throw new Error('Profile database not open');
    await pushCompleteOnboarding(db);
    await refreshFromDb();
  }, [refreshFromDb]);

  const pushAvatarFromPicker = useCallback(
    async (localUri: string) => {
      const db = getOpenedDb();
      if (!db) throw new Error('Profile database not open');
      await pushAvatar(db, localUri);
      await refreshFromDb();
    },
    [refreshFromDb],
  );

  const value = useMemo<ProfileContextValue>(
    () => ({
      ready,
      profile,
      updateProfile,
      completeOnboarding,
      pushAvatarFromPicker,
      refreshFromDb,
    }),
    [ready, profile, updateProfile, completeOnboarding, pushAvatarFromPicker, refreshFromDb],
  );

  return <ProfileContext.Provider value={value}>{children}</ProfileContext.Provider>;
}

export function useProfile() {
  const ctx = useContext(ProfileContext);
  if (!ctx) {
    throw new Error('useProfile must be used within ProfileProvider');
  }
  return ctx;
}
