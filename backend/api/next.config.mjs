const csp = [
  "default-src 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: https:",
  "font-src 'self'",
  "connect-src 'self' https://*.supabase.co",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ');

const docsCsp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' https://unpkg.com",
  "style-src 'self' 'unsafe-inline' https://unpkg.com",
  "img-src 'self' data: https:",
  "font-src 'self' https://unpkg.com",
  "connect-src 'self' https://*.supabase.co",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ');

const securityHeaders = [
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
];

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  experimental: {
    outputFileTracingIncludes: {
      '/api/docs/spec': ['./src/app/api/**/*.ts'],
    },
  },
  async headers() {
    return [
      {
        source: '/api/docs',
        headers: [{ key: 'Content-Security-Policy', value: docsCsp }, ...securityHeaders],
      },
      {
        source: '/api/docs/:path*',
        headers: [{ key: 'Content-Security-Policy', value: docsCsp }, ...securityHeaders],
      },
      {
        source: '/:path*',
        headers: [{ key: 'Content-Security-Policy', value: csp }, ...securityHeaders],
      },
    ];
  },
};

export default nextConfig;
