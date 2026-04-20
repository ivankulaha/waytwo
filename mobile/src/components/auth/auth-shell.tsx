import { type ReactNode } from 'react';
import { KeyboardAvoidingView, Platform, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { RadialBlob } from '@/components/ui/radial-blob';
import { BackButton } from '@/components/ui/back-button';
import {
  useRadialBlobSpec,
  type RadialBlobGeometryName,
  type RadialBlobPaletteName,
} from '@/constants/gradients';
import { FontSize, FontWeight, LineHeight, Size, Spacing } from '@/constants/tokens';
import { useAuthColors } from '@/hooks/use-auth-colors';

/**
 * Background variants. All variants render on top of `c.surface` so the
 * page colour follows the system theme; only the optional decorative blob
 * differs between modes.
 */
export type AuthShellBackgroundMode = 'flow' | 'onboardingIntro' | 'plain';
export type AuthShellLayoutMode = 'default' | 'introHero';

type AuthShellProps = {
  title: string;
  subtitle?: string;
  children: ReactNode;
  showBack?: boolean;
  onBack?: () => void;
  step?: { current: number; total: number };
  stepAccessibilityLabel?: string;
  titleAlign?: 'center' | 'left';
  stepAlign?: 'center' | 'left';
  backgroundMode?: AuthShellBackgroundMode;
  layoutMode?: AuthShellLayoutMode;
};

export function AuthShell({
  title,
  subtitle,
  children,
  showBack,
  onBack,
  step,
  stepAccessibilityLabel,
  titleAlign = 'center',
  stepAlign = 'left',
  backgroundMode = 'flow',
  layoutMode = 'default',
}: AuthShellProps) {
  const c = useAuthColors();

  const paletteName: RadialBlobPaletteName | null =
    backgroundMode === 'flow'
      ? 'authPrimary'
      : backgroundMode === 'onboardingIntro'
        ? 'onboardingIntro'
        : null;

  const geometryName: RadialBlobGeometryName =
    backgroundMode === 'onboardingIntro' ? 'bottomAnchoredCircle' : 'topAnchoredWide';

  const blobSpec = useRadialBlobSpec(paletteName ?? 'authPrimary', geometryName);
  const gradientLayer = paletteName ? <RadialBlob spec={blobSpec} /> : null;

  const surfaceColor = c.surface;
  const titleColor = c.text;
  const subtitleColor = c.textSubtle;

  const titleTextAlign = titleAlign;

  const titleBlock = (
    <>
      {step ? (
        <View
          accessible
          accessibilityRole="text"
          accessibilityLabel={stepAccessibilityLabel}
          style={[
            styles.stepRow,
            { alignSelf: stepAlign === 'center' ? 'center' : 'flex-start' },
          ]}
        >
          <Text accessible={false} style={[styles.stepCurrent, { color: c.text }]}>
            {String(step.current).padStart(2, '0')}
          </Text>
          <Text accessible={false} style={[styles.stepTotal, { color: c.textSubtle }]}>
            {' '}
            / {String(step.total).padStart(2, '0')}
          </Text>
        </View>
      ) : null}
      <Text
        style={[
          styles.title,
          { color: titleColor, textAlign: titleTextAlign },
          backgroundMode === 'plain' && layoutMode === 'default' ? styles.titleFormScreen : null,
        ]}
      >
        {title}
      </Text>
      {subtitle ? (
        <Text
          style={[
            styles.subtitle,
            layoutMode === 'introHero' ? styles.subtitleIntroHero : null,
            { color: subtitleColor, textAlign: titleTextAlign },
          ]}
        >
          {subtitle}
        </Text>
      ) : null}
    </>
  );

  const body = (
    <View style={layoutMode === 'introHero' ? styles.bodyIntroFooter : styles.body}>{children}</View>
  );

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: surfaceColor }]} edges={['top', 'bottom']}>
      {gradientLayer}
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboard}
      >
        <View style={styles.inner}>
          {showBack && onBack ? (
            <BackButton
              onPress={onBack}
              style={{ alignSelf: 'flex-start', marginBottom: Spacing.xl }}
            />
          ) : (
            <View style={styles.backPlaceholder} />
          )}
          {layoutMode === 'introHero' ? (
            <>
              <View style={styles.hero}>{titleBlock}</View>
              {body}
            </>
          ) : (
            <>
              {titleBlock}
              {body}
            </>
          )}
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
  hero: {
    flex: 1,
    justifyContent: 'center',
    paddingBottom: Spacing['4xl'],
  },
  backPlaceholder: {
    height: Size.iconButton,
    marginBottom: Spacing.xl,
  },
  stepRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: Spacing.lg,
  },
  stepCurrent: {
    fontSize: FontSize['5xl'],
    fontWeight: FontWeight.semibold,
    lineHeight: LineHeight.loose,
    letterSpacing: -0.5,
  },
  stepTotal: {
    fontSize: FontSize['2xl'],
    fontWeight: FontWeight.medium,
    lineHeight: LineHeight.relaxed,
  },
  title: {
    fontSize: FontSize['3xl'],
    fontWeight: FontWeight.semibold,
    marginBottom: Spacing.md,
    lineHeight: LineHeight.loose,
  },
  titleFormScreen: {
    marginBottom: Spacing['2xl'],
  },
  subtitle: {
    fontSize: FontSize.md,
    marginBottom: Spacing['3xl'],
    lineHeight: LineHeight.tight,
  },
  subtitleIntroHero: {
    marginBottom: Spacing['2xl'],
  },
  body: {
    flex: 1,
    paddingTop: Spacing.md,
  },
  bodyIntroFooter: {
    width: '100%',
    paddingTop: 0,
    paddingBottom: Spacing['3xl'],
  },
});
