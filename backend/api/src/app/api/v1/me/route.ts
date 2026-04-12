import { headers } from 'next/headers';
import { NextResponse } from 'next/server';

import { toErrorResponse } from '@/lib/route-errors';

/**
 * @swagger
 * /api/v1/me:
 *   get:
 *     summary: Current authenticated user
 *     tags: [User]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current user id
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 userId:
 *                   type: string
 *                   format: uuid
 *       401:
 *         description: Missing or invalid token
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 */
export async function GET() {
  try {
    const h = await headers();
    const userId = h.get('x-user-id');
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json({ userId });
  } catch (err) {
    return toErrorResponse(err);
  }
}
