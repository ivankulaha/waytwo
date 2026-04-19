import { NextResponse } from 'next/server';
import { z } from 'zod';

import { logger } from '@/lib/logger';
import { toErrorResponse } from '@/lib/route-errors';
import { createSupabaseUserClient } from '@/lib/supabase-user';

const patchSchema = z
  .object({
    display_name: z.string().trim().min(1).max(120).optional(),
    gender: z.enum(['male', 'female', 'other']).optional(),
    date_of_birth: z
      .union([z.string().regex(/^\d{4}-\d{2}-\d{2}$/), z.null()])
      .optional(),
    color_id: z.string().trim().min(1).max(64).optional().nullable(),
    photo_path: z.string().trim().min(1).max(512).optional().nullable(),
    onboarding_step: z.number().int().min(0).max(10).optional(),
  })
  .strict();

function expectedAvatarPath(userId: string): string {
  return `${userId}/avatar.jpg`;
}

function routeMeta(request: Request) {
  const u = new URL(request.url);
  return { route: u.pathname, method: request.method };
}

/**
 * @swagger
 * /api/v1/me/profile:
 *   get:
 *     summary: Current user profile (creates empty row if missing)
 *     tags: [Profile]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile row
 *       401:
 *         description: Unauthorized
 *   patch:
 *     summary: Partial update of current user profile
 *     tags: [Profile]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Updated profile
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
export async function GET(request: Request) {
  const started = Date.now();
  const meta = routeMeta(request);
  const userId = request.headers.get('x-user-id');
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  logger.info('profile GET entry', { ...meta, userId });
  try {
    const supabase = createSupabaseUserClient(request);
    const { data: row, error } = await supabase.from('profiles').select('*').eq('user_id', userId).maybeSingle();
    if (error) {
      logger.warn('profile GET select failed', {
        ...meta,
        message: error.message,
        code: error.code,
      });
      return NextResponse.json({ error: 'Failed to load profile' }, { status: 500 });
    }
    if (!row) {
      const { data: inserted, error: insertError } = await supabase
        .from('profiles')
        .insert({ user_id: userId })
        .select('*')
        .single();
      if (insertError) {
        logger.warn('profile GET insert failed', {
          ...meta,
          message: insertError.message,
          code: insertError.code,
        });
        return NextResponse.json({ error: 'Failed to create profile' }, { status: 500 });
      }
      logger.info('profile GET created blank', { ...meta, userId, durationMs: Date.now() - started });
      return NextResponse.json(inserted);
    }
    logger.info('profile GET ok', { ...meta, userId, durationMs: Date.now() - started });
    return NextResponse.json(row);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function PATCH(request: Request) {
  const started = Date.now();
  const meta = routeMeta(request);
  const userId = request.headers.get('x-user-id');
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  logger.info('profile PATCH entry', { ...meta, userId });
  try {
    let json: unknown;
    try {
      json = await request.json();
    } catch {
      logger.warn('profile PATCH invalid JSON', meta);
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
    }
    const parsed = patchSchema.safeParse(json);
    if (!parsed.success) {
      logger.warn('profile PATCH validation failed', {
        ...meta,
        issues: parsed.error.flatten().fieldErrors,
      });
      return NextResponse.json({ error: 'Invalid body', issues: parsed.error.flatten() }, { status: 400 });
    }
    const body = parsed.data;
    if (body.photo_path !== undefined && body.photo_path !== null) {
      const expected = expectedAvatarPath(userId);
      if (body.photo_path !== expected) {
        logger.warn('profile PATCH invalid photo_path', { ...meta, userId });
        return NextResponse.json({ error: 'Invalid photo_path' }, { status: 400 });
      }
    }
    const supabase = createSupabaseUserClient(request);
    const updatePayload: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(body)) {
      if (v !== undefined) updatePayload[k] = v;
    }
    if (Object.keys(updatePayload).length === 0) {
      logger.warn('profile PATCH empty body', meta);
      return NextResponse.json({ error: 'No fields to update' }, { status: 400 });
    }
    const fieldsChanged = Object.keys(updatePayload);
    const { data: existing } = await supabase.from('profiles').select('user_id').eq('user_id', userId).maybeSingle();
    const query = existing
      ? supabase.from('profiles').update(updatePayload).eq('user_id', userId).select('*').single()
      : supabase.from('profiles').insert({ user_id: userId, ...updatePayload }).select('*').single();
    const { data, error } = await query;
    if (error) {
      logger.warn('profile PATCH upsert failed', {
        ...meta,
        message: error.message,
        code: error.code,
      });
      return NextResponse.json({ error: 'Failed to save profile' }, { status: 500 });
    }
    logger.info('profile upserted', {
      ...meta,
      userId,
      fieldsChanged,
      step: data?.onboarding_step,
      durationMs: Date.now() - started,
    });
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}
