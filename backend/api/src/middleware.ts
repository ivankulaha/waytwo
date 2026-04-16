import { createClient } from '@supabase/supabase-js';
import { type NextRequest, NextResponse } from 'next/server';

import { logger } from '@/lib/logger';

export async function middleware(request: NextRequest) {
  const supabaseUrl = process.env.SUPABASE_URL?.trim();
  const supabasePublishableKey =
    process.env.SUPABASE_PUBLISHABLE_KEY?.trim() || process.env.SUPABASE_ANON_KEY?.trim();
  const corsOrigin = process.env.CORS_ORIGIN ?? 'http://localhost:8081';

  function corsHeaders(): HeadersInit {
    return {
      'Access-Control-Allow-Origin': corsOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      'Access-Control-Max-Age': '86400',
    };
  }

  const { pathname } = request.nextUrl;

  if (!pathname.startsWith('/api/v1')) {
    return NextResponse.next();
  }

  if (request.method === 'OPTIONS') {
    return new NextResponse(null, { status: 204, headers: corsHeaders() });
  }

  if (pathname === '/api/v1/health' || pathname.startsWith('/api/v1/health/')) {
    const res = NextResponse.next();
    Object.entries(corsHeaders()).forEach(([k, v]) => res.headers.set(k, v));
    return res;
  }

  if (pathname === '/api/v1/auth/check-email' && request.method === 'POST') {
    const res = NextResponse.next();
    Object.entries(corsHeaders()).forEach(([k, v]) => res.headers.set(k, v));
    return res;
  }

  if (!supabaseUrl || !supabasePublishableKey) {
    logger.error('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY');
    return NextResponse.json({ error: 'Server misconfigured' }, { status: 500, headers: corsHeaders() });
  }

  const auth = request.headers.get('authorization');
  if (!auth?.startsWith('Bearer ')) {
    logger.warn('Missing or malformed Authorization header', { path: pathname });
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders() });
  }

  const token = auth.slice('Bearer '.length).trim();
  if (!token) {
    logger.warn('Empty bearer token', { path: pathname });
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders() });
  }

  const supabase = createClient(supabaseUrl, supabasePublishableKey);
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);

  if (error || !user) {
    logger.warn('getUser failed', { message: error?.message, path: pathname });
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders() });
  }

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-user-id', user.id);

  const res = NextResponse.next({
    request: { headers: requestHeaders },
  });
  Object.entries(corsHeaders()).forEach(([k, v]) => res.headers.set(k, v));
  return res;
}

export const config = {
  matcher: ['/api/v1/:path*'],
};
