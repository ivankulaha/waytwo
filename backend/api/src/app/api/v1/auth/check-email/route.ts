import { NextResponse } from 'next/server';
import { z } from 'zod';

import { logger } from '@/lib/logger';
import { isAuthEmailRegistered } from '@/lib/supabase-admin';

const bodySchema = z.object({
  email: z.string().trim().email(),
});

/**
 * @swagger
 * /api/v1/auth/check-email:
 *   post:
 *     summary: Check if an email is registered (Auth)
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Registration flag (public; enables email enumeration)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 registered:
 *                   type: boolean
 *       400:
 *         description: Invalid body
 *       500:
 *         description: Server or upstream error
 */
export async function POST(request: Request) {
  try {
    let json: unknown;
    try {
      json = await request.json();
    } catch {
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
    }

    const parsed = bodySchema.safeParse(json);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid email' }, { status: 400 });
    }

    const registered = await isAuthEmailRegistered(parsed.data.email);
    return NextResponse.json({ registered });
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : String(e);
    if (message.includes('Missing SUPABASE_URL') || message.includes('SERVICE_ROLE')) {
      logger.error('check-email misconfigured');
      return NextResponse.json({ error: 'Server misconfigured' }, { status: 500 });
    }
    logger.error('check-email admin lookup failed');
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
