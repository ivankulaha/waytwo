import { useMemo } from 'react';
import { useColorScheme } from 'react-native';

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
} as const satisfies Record<string, RadialBlobPaletteEntry>;

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
