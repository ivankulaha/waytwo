export function parseHexRgb(hex: string): { r: number; g: number; b: number } | null {
  const s = hex.trim().replace(/^#/, '');
  if (s.length !== 6 || !/^[0-9a-fA-F]+$/i.test(s)) return null;
  const n = parseInt(s, 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

export function rgba(rgb: { r: number; g: number; b: number }, a: number): string {
  return `rgba(${rgb.r},${rgb.g},${rgb.b},${a})`;
}
