import { NextResponse } from 'next/server';

import { logger } from '@/lib/logger';
import { toErrorResponse } from '@/lib/route-errors';
import { createSupabaseUserClient } from '@/lib/supabase-user';

function routeMeta(request: Request) {
  const u = new URL(request.url);
  return { route: u.pathname, method: request.method };
}

/**
 * @swagger
 * /api/v1/me/profile/complete:
 *   post:
 *     summary: Mark onboarding as completed for the current user
 *     tags: [Profile]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile with onboarding_completed_at set
 *       401:
 *         description: Unauthorized
 */
export async function POST(request: Request) {
  const started = Date.now();
  const meta = routeMeta(request);
  const userId = request.headers.get('x-user-id');
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  logger.info('profile complete POST entry', { ...meta, userId });
  try {
    const supabase = createSupabaseUserClient(request);
    const completedAt = new Date().toISOString();
    const { data: existing } = await supabase.from('profiles').select('user_id').eq('user_id', userId).maybeSingle();
    const query = existing
      ? supabase
          .from('profiles')
          .update({ onboarding_completed_at: completedAt })
          .eq('user_id', userId)
          .select('*')
          .single()
      : supabase
          .from('profiles')
          .insert({ user_id: userId, onboarding_completed_at: completedAt })
          .select('*')
          .single();
    const { data, error } = await query;
    if (error) {
      logger.warn('profile complete upsert failed', {
        ...meta,
        message: error.message,
        code: error.code,
      });
      return NextResponse.json({ error: 'Failed to complete onboarding' }, { status: 500 });
    }
    logger.info('onboarding completed', { ...meta, userId, durationMs: Date.now() - started });
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}
