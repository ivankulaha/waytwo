import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { BorderRadius, FontSize, FontWeight, Spacing } from '@/constants/tokens';
import { useAppColors } from '@/hooks/use-app-colors';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';

export default function SettingsScreen() {
  const { t } = useTranslation();
  const c = useAppColors();
  const insets = useSafeAreaInsets();

  return (
    <View
      style={[
        styles.root,
        {
          backgroundColor: c.surface,
          paddingTop: insets.top + Spacing['3xl'],
        },
      ]}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('settings.logOut')}
        onPress={() =>
          void supabase.auth.signOut().then(({ error }) => {
            if (error) log.warn('signOut failed', { message: error.message });
          })
        }
        style={({ pressed }) => [
          styles.logout,
          {
            backgroundColor: c.buttonBg,
            opacity: pressed ? 0.88 : 1,
          },
        ]}>
        <Text style={[styles.logoutLabel, { color: c.buttonText }]}>{t('settings.logOut')}</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    padding: Spacing['3xl'],
    justifyContent: 'flex-start',
  },
  logout: {
    alignSelf: 'stretch',
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing['2xl'],
    borderRadius: BorderRadius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoutLabel: {
    fontSize: FontSize.lg,
    fontWeight: FontWeight.semibold,
  },
});
