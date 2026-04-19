export function expectedAvatarObjectPath(userId: string): string {
  return `${userId}/avatar.jpg`;
}

export function avatarPublicObjectUrl(userId: string, cacheBustMs: number): string {
  const base = process.env.EXPO_PUBLIC_SUPABASE_URL?.trim().replace(/\/$/, '');
  if (!base) return '';
  const path = `avatars/${encodeURIComponent(userId)}/avatar.jpg`;
  return `${base}/storage/v1/object/public/${path}?v=${cacheBustMs}`;
}
