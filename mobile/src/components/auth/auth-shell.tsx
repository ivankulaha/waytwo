import type { ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';

import { AuthFlowGradients, type AuthFlowVariant } from '@/constants/theme';
import { BorderRadius, FontSize, FontWeight, IconSize, LineHeight, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

type AuthShellProps = {
  flow: AuthFlowVariant;
  title: string;
  subtitle?: string;
  children: ReactNode;
  showBack?: boolean;
  onBack?: () => void;
};

export function AuthShell({ flow, title, subtitle, children, showBack, onBack }: AuthShellProps) {
  const c = useAuthColors();
  const base = AuthFlowGradients[flow];
  const gradientColors = [base[0], base[1], base[2], c.gradientEnd] as [string, string, string, string];

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: c.surface }]} edges={['top', 'bottom']}>
      <LinearGradient colors={gradientColors} locations={[0, 0.35, 0.65, 1]} style={StyleSheet.absoluteFill} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboard}
      >
        <View style={styles.inner}>
          {showBack && onBack ? (
            <Pressable
              accessibilityRole="button"
              onPress={onBack}
              style={({ pressed }) => [
                styles.back,
                { backgroundColor: c.glassBg, borderColor: c.glassBorder },
                pressed && styles.pressed,
              ]}
            >
              <Ionicons name="chevron-back" size={IconSize.lg} color={c.text} />
            </Pressable>
          ) : (
            <View style={styles.backPlaceholder} />
          )}
          <Text style={[styles.title, { color: c.text }]}>{title}</Text>
          {subtitle ? (
            <Text style={[styles.subtitle, { color: c.textSubtle }]}>{subtitle}</Text>
          ) : null}
          <View style={styles.body}>{children}</View>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  keyboard: {
    flex: 1,
  },
  inner: {
    flex: 1,
    paddingHorizontal: Spacing.xl,
    paddingTop: Spacing.md,
  },
  back: {
    alignSelf: 'flex-start',
    width: Size.iconButton,
    height: Size.iconButton,
    borderRadius: BorderRadius.xl,
    borderWidth: Size.borderWidth,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.xl,
  },
  backPlaceholder: {
    height: Size.iconButton,
    marginBottom: Spacing.xl,
  },
  pressed: {
    opacity: 0.85,
  },
  title: {
    fontSize: FontSize['3xl'],
    fontWeight: FontWeight.semibold,
    textAlign: 'center',
    marginBottom: Spacing.md,
    lineHeight: LineHeight.loose,
  },
  subtitle: {
    fontSize: FontSize.md,
    textAlign: 'center',
    marginBottom: Spacing['3xl'],
    lineHeight: LineHeight.tight,
  },
  body: {
    flex: 1,
    paddingTop: Spacing.md,
  },
});
