/** Figma onboarding look avatar placeholder letter (node 124:6276). */
export const OnboardingAvatarInitialsColor = '#a1a1a1';

/** Radial glow behind onboarding avatar; match Figma stops when reconciling. */
export const OnboardingAvatarGlowGradientStops = [
  { offset: '0%', opacity: 1 },
  { offset: '18%', opacity: 0.95 },
  { offset: '38%', opacity: 0.78 },
  { offset: '58%', opacity: 0.52 },
  { offset: '76%', opacity: 0.26 },
  { offset: '90%', opacity: 0.08 },
  { offset: '100%', opacity: 0 },
] as const;

/**
 * Onboarding look: 12 swatches, row-major (6+6). FIGMA_GAP: export exact fills from Figma node `326:6051` when available.
 */
export const OnboardingPalette = [
  { id: 'c1', hex: '#F04A23' },
  { id: 'c2', hex: '#FF8A24' },
  { id: 'c3', hex: '#F5B41C' },
  { id: 'c4', hex: '#F5E86B' },
  { id: 'c5', hex: '#7ED321' },
  { id: 'c6', hex: '#00C4A3' },
  { id: 'c7', hex: '#2BB4F0' },
  { id: 'c8', hex: '#2B6BFF' },
  { id: 'c9', hex: '#8B5CF6' },
  { id: 'c10', hex: '#D946EF' },
  { id: 'c11', hex: '#F43F8C' },
  { id: 'c12', hex: '#DC2626' },
] as const;
