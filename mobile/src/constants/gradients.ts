import { useMemo } from 'react';
import { useColorScheme } from 'react-native';

import { palette } from '@/constants/theme/palette';
import { parseHexRgb, rgba } from '@/lib/color-rgba';

export type ColorScheme = 'light' | 'dark';

/**
 * Screen-relative geometry.
 *  - cxW : center X as a fraction of screen WIDTH (0 = left edge, 1 = right edge).
 *  - cyH : center Y as a fraction of screen HEIGHT (0 = top edge, 1 = bottom edge).
 *          Negative or > 1 places the center OUTSIDE the viewport for partial visibility.
 *  - rxW, ryW : horizontal / vertical radius as fractions of screen WIDTH. rxW > 1
 *               hides side caps off-screen. Equal values produce a circle.
 *
 * Skia's RadialGradient is circular; `RadialBlob` renders the ellipse via a Y-scale transform.
 */
export type RadialBlobGeometry = { cxW: number; cyH: number; rxW: number; ryW: number };

export type RadialBlobStops = {
  /** 2-N hex colors, identical to a Figma radial picker. */
  colors: ReadonlyArray<string>;
  /** Same length as `colors`, values in [0..1]. */
  positions: ReadonlyArray<number>;
};

export type RadialBlobPaletteEntry = { light: RadialBlobStops; dark: RadialBlobStops };

/** Reusable geometries. Add presets here; do not inline magic numbers in screens. */
export const RadialBlobGeometryPreset = {
  /** Wide ellipse anchored just above the top edge; auth screens. */
  topAnchoredWide: { cxW: 0.5, cyH: -0.083, rxW: 1.6, ryW: 0.95 },
  /**
   * Onboarding intro: large circle of radius 1.5 * W, centred at the bottom
   * edge of the screen. The visible top half reaches above mid-screen so the
   * gradient washes through the centred title/subtitle.
   */
  bottomAnchoredCircle: { cxW: 0.5, cyH: 1, rxW: 1.5, ryW: 1.5 },
  /** Figma home partner glow — wide radius reads as one soft halo (pairing screen). */
  homePartnerGlow: { cxW: 0.5, cyH: 0.52, rxW: 0.88, ryW: 0.88 },
} as const satisfies Record<string, RadialBlobGeometry>;

export type RadialBlobGeometryName = keyof typeof RadialBlobGeometryPreset;

/**
 * Figma-shaped palettes. Naming uses design intent ("authPrimary", "onboardingIntro"),
 * not flow ids, so multiple flows share one preset.
 */
// Final transparent stop blends into the surface (Skia clamps past r otherwise).
export const RadialBlobPalette = {
  authPrimary: {
    dark: {
      colors: ['#B566FF', '#506DF1', 'rgba(80,109,241,0)'],
      positions: [0, 0.55, 1],
    },
    light: {
      colors: ['#DCC2FF', '#B8C8FA', 'rgba(184,200,250,0)'],
      positions: [0, 0.55, 1],
    },
  },
  /**
   * Figma 326:5995 — solid blue core with a long alpha tail. Intermediate
   * semi-transparent blues smooth the outer fade so it reads as a gentle
   * gradient instead of a hard ring at the visible boundary.
   */
  onboardingIntro: {
    dark: {
      colors: [
        '#5A9CFF',
        'rgba(90,156,255,0.7)',
        'rgba(90,156,255,0.3)',
        'rgba(90,156,255,0)',
      ],
      positions: [0, 0.4, 0.75, 1],
    },
    light: {
      colors: [
        '#5A9CFF',
        'rgba(90,156,255,0.7)',
        'rgba(90,156,255,0.3)',
        'rgba(90,156,255,0)',
      ],
      positions: [0, 0.4, 0.75, 1],
    },
  },
  /** Fallback when profile hex is missing; prefer `homePartnerGlowStopsFromHex`. */
  homePartnerGlow: {
    dark: {
      colors: ['#7C3AED', 'rgba(124,58,237,0.4)', 'rgba(124,58,237,0)'],
      positions: [0, 0.5, 1],
    },
    light: {
      colors: ['#9333EA', 'rgba(147,51,234,0.25)', 'rgba(147,51,234,0)'],
      positions: [0, 0.5, 1],
    },
  },
} as const satisfies Record<string, RadialBlobPaletteEntry>;

/**
 * Single smooth radial for the home pairing glow, tinted by profile color.
 */
export function homePartnerGlowStopsFromHex(hex: string | null | undefined): RadialBlobStops {
  const parsed = hex ? parseHexRgb(hex) : null;
  const fallbackRgb = parseHexRgb(palette.profileAccentFallback) ?? { r: 139, g: 92, b: 246 };
  const rgb = parsed ?? fallbackRgb;
  return {
    colors: [
      rgba(rgb, 0.38),
      rgba(rgb, 0.2),
      rgba(rgb, 0.09),
      rgba(rgb, 0.03),
      rgba(rgb, 0),
    ],
    positions: [0, 0.22, 0.48, 0.72, 1],
  };
}

export type RadialBlobPaletteName = keyof typeof RadialBlobPalette;

export type RadialBlobSpec = { geometry: RadialBlobGeometry; stops: RadialBlobStops };

export function useRadialBlobSpec(
  paletteName: RadialBlobPaletteName,
  geometryName: RadialBlobGeometryName = 'topAnchoredWide',
  options?: { scheme?: ColorScheme },
): RadialBlobSpec {
  const sysScheme = useColorScheme() === 'dark' ? 'dark' : 'light';
  const scheme = options?.scheme ?? sysScheme;
  return useMemo(
    () => ({
      geometry: RadialBlobGeometryPreset[geometryName],
      stops: RadialBlobPalette[paletteName][scheme],
    }),
    [paletteName, geometryName, scheme],
  );
}
