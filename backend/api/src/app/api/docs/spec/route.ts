import { NextResponse } from 'next/server';

import { getOpenAPISpec } from '@/lib/swagger';

export async function GET() {
  return NextResponse.json(getOpenAPISpec());
}
