import { Pressable, StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { BorderRadius, FontSize, LineHeight, Opacity, Size, Spacing } from '@/constants/tokens';
import { useThemeColor } from '@/hooks/use-theme-color';
import { log } from '@/lib/log';
import { supabase } from '@/lib/supabase';

export default function HomeScreen() {
  const { t } = useTranslation();
  const backgroundColor = useThemeColor({}, 'background');
  const textColor = useThemeColor({}, 'text');
  const tint = useThemeColor({}, 'tint');

  return (
    <ThemedView style={[styles.container, { backgroundColor }]}>
      <ThemedText type="title" style={{ color: textColor }}>
        {t('home.title')}
      </ThemedText>
      <ThemedText style={[styles.sub, { color: textColor }]}>
        {t('home.subtitle')}
      </ThemedText>
      <Pressable
        accessibilityRole="button"
        onPress={() =>
          void supabase.auth.signOut().then(({ error }) => {
            if (error) log.warn('signOut failed', { message: error.message });
          })
        }
        style={[styles.signOut, { borderColor: tint }]}
      >
        <ThemedText type="defaultSemiBold" style={{ color: tint }}>
          {t('home.signOut')}
        </ThemedText>
      </Pressable>
      <View />
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: Spacing['3xl'],
    justifyContent: 'center',
    gap: Spacing.xl,
  },
  sub: {
    opacity: Opacity.subtitle,
    lineHeight: LineHeight.snug,
    fontSize: FontSize.lg,
  },
  signOut: {
    alignSelf: 'flex-start',
    marginTop: Spacing.md,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing['2xl'],
    borderRadius: BorderRadius.md,
    borderWidth: Size.borderWidth,
  },
});
