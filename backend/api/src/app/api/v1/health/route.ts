import { NextResponse } from 'next/server';

/**
 * @swagger
 * /api/v1/health:
 *   get:
 *     summary: Health check
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: API is reachable
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: ok
 *                 version:
 *                   type: string
 *                   example: v1
 */
export async function GET() {
  return NextResponse.json({ status: 'ok', version: 'v1' });
}
