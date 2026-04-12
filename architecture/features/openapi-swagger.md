# OpenAPI / Swagger (backend API)

## Overview

The Next.js API documents versioned endpoints with **OpenAPI 3**, generated at runtime from **JSDoc `@swagger` blocks** via **`swagger-jsdoc`**.

## Endpoints

| URL | Purpose |
|-----|---------|
| `GET /api/docs/spec` | OpenAPI JSON |
| `GET /api/docs` | Swagger UI |

Middleware under `/api/v1` does not apply to `/api/docs*`.

## Implementation

- Swagger UI HTML is served from [`backend/api/src/app/api/docs/route.ts`](../../backend/api/src/app/api/docs/route.ts) and loads **`swagger-ui-dist`** from **`unpkg.com`** (see ADR-0004 for CSP implications).
- Base definition and glob: [`backend/api/src/lib/swagger.ts`](../../backend/api/src/lib/swagger.ts) (`apis: ['./src/app/api/**/*.ts']`).
- Example annotations: [`backend/api/src/app/api/v1/health/route.ts`](../../backend/api/src/app/api/v1/health/route.ts), [`backend/api/src/app/api/v1/me/route.ts`](../../backend/api/src/app/api/v1/me/route.ts).
- Standalone tracing: [`backend/api/next.config.mjs`](../../backend/api/next.config.mjs) — `experimental.outputFileTracingIncludes` for `/api/docs/spec`.

## Author

Ivan Kulaha
