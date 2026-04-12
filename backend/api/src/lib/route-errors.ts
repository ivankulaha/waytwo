import { NextResponse } from 'next/server';

import { logger } from '@/lib/logger';

export function toErrorResponse(err: unknown): NextResponse {
  const message = err instanceof Error ? err.message : String(err);
  logger.error('Route handler error', { message });
  return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
}
