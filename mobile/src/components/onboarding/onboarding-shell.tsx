import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';

import {
  AuthShell,
  type AuthShellBackgroundMode,
  type AuthShellLayoutMode,
} from '@/components/auth/auth-shell';

type OnboardingShellVariant = 'intro' | 'form';

type OnboardingShellProps = {
  title: string;
  subtitle?: string;
  children: ReactNode;
  showBack?: boolean;
  onBack?: () => void;
  step?: { current: number; total: number };
  titleAlign?: 'center' | 'left';
  stepAlign?: 'center' | 'left';
  variant?: OnboardingShellVariant;
};

export function OnboardingShell({
  title,
  subtitle,
  children,
  showBack = true,
  onBack,
  step,
  titleAlign,
  stepAlign,
  variant = 'form',
}: OnboardingShellProps) {
  const { t } = useTranslation();
  const stepA11y =
    step != null
      ? t('onboarding.common.stepA11y', { current: step.current, total: step.total })
      : undefined;

  const backgroundMode: AuthShellBackgroundMode =
    variant === 'intro' ? 'onboardingIntro' : 'plain';
  const layoutMode: AuthShellLayoutMode = variant === 'intro' ? 'introHero' : 'default';
  const resolvedTitleAlign = titleAlign ?? (variant === 'intro' ? 'center' : 'center');
  const resolvedStepAlign = stepAlign ?? 'center';

  return (
    <AuthShell
      title={title}
      subtitle={subtitle}
      showBack={showBack}
      onBack={onBack}
      step={step}
      stepAccessibilityLabel={stepA11y}
      titleAlign={resolvedTitleAlign}
      stepAlign={resolvedStepAlign}
      backgroundMode={backgroundMode}
      layoutMode={layoutMode}
    >
      {children}
    </AuthShell>
  );
}
