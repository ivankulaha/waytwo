# ADR-0004: OpenAPI documentation for the Next.js API

## Status

Accepted

## Context

The API lives in `backend/api` as Next.js 14 App Router route handlers under `/api/v1`. We need a machine-readable contract and interactive documentation for consumers and QA.

## Decision

1. Generate **OpenAPI 3** with **`swagger-jsdoc`** from **`@swagger` YAML blocks** in JSDoc on each route handler.
2. Expose the spec at **`GET /api/docs/spec`** and interactive **Swagger UI** at **`GET /api/docs`**, served as HTML that loads **`swagger-ui-dist`** from **`unpkg.com`**.
3. Keep the default strict **CSP** for the rest of the app; apply a **narrower, relaxed CSP** only for `/api/docs` and `/api/docs/:path*` so Swagger UI scripts and styles load.
4. For **`output: 'standalone'`**, set **`experimental.outputFileTracingIncludes`** for route `/api/docs/spec` so **`src/app/api/**/*.ts`** is copied into the standalone bundle and JSDoc scanning works in production.

## Alternatives considered

- **`@scalar/nextjs-api-reference`:** requires **Next.js 15+** peer dependency; incompatible with the current Next 14 stack without a framework upgrade.
- **Static `openapi.yaml` only:** simpler for deployment but duplicates route behavior and drifts from code; rejected in favor of co-located JSDoc.

## Consequences

- New versioned routes should add matching **`@swagger`** blocks and stay in `src/app/api` so the glob picks them up.
- Production relies on **unpkg** availability for the docs UI (not for the JSON spec).

## Related

- `backend/api/src/lib/swagger.ts`
- `backend/api/src/app/api/docs/route.ts`
- `backend/api/src/app/api/docs/spec/route.ts`
- Feature: `architecture/features/openapi-swagger.md`

**Author:** Ivan Kulaha
