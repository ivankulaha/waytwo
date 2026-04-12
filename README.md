# WayTwo

Couples app monorepo: Expo (React Native) mobile client, Supabase for auth and data, and a versioned Next.js API under `backend/api`.

**Author:** Ivan Kulaha

## Prerequisites

- Node.js 22+ and npm
- Docker and Docker Compose (for running the API in a container)
- Xcode (for the iOS Simulator)
- A [Supabase](https://supabase.com) project

## Environment

### Mobile (`mobile/`)

Copy the example file and fill in values from the Supabase project (**Settings → API Keys** — use the **Publishable** key, `sb_publishable_...`):

```bash
cp mobile/.env.example mobile/.env
```

(You can use `mobile/.env.local` instead if you prefer; Expo loads both.)

| Variable | Description |
|----------|-------------|
| `EXPO_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Supabase **publishable** (public) API key — never use a **secret** or **service_role** key in the app |
| `EXPO_PUBLIC_API_URL` | Versioned API base, e.g. `http://localhost:3000/api/v1` |

If you still have the legacy JWT **anon** key only, you can temporarily set `EXPO_PUBLIC_SUPABASE_ANON_KEY` instead; the app accepts it until you switch to a publishable key.

For a physical device on the same network, replace `localhost` with your computer’s LAN IP (e.g. `http://192.168.1.10:3000/api/v1`).

The mobile app supports **English** and **Ukrainian** (device locale `uk` → Ukrainian; otherwise English). Strings live in `mobile/locales/en/common.json` and `mobile/locales/uk/common.json`.

### API (`backend/api/`)

```bash
cp backend/api/.env.local.example backend/api/.env.local
```

Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (same publishable key as the mobile app). Legacy `SUPABASE_ANON_KEY` still works if set. Optional: `CORS_ORIGIN` for browser or Expo web (default `http://localhost:8081`).

## Running the API

### Docker (production-like)

From the repository root:

```bash
docker compose -f backend/api/docker-compose.yml up --build
```

The server listens on **http://localhost:3000**. Versioned routes:

- `GET http://localhost:3000/api/v1/health` — public
- `GET http://localhost:3000/api/v1/me` — `Authorization: Bearer <supabase_access_token>`
- `GET http://localhost:3000/api/docs/spec` — OpenAPI 3 JSON (generated from JSDoc on route handlers)
- `GET http://localhost:3000/api/docs` — Swagger UI (loads assets from `unpkg.com`; relaxed CSP applies only to these paths)

`docker-compose` loads variables from `backend/api/.env.local`.

### Local development (hot reload)

```bash
cd backend/api
npm install
npm run dev
```

Same URLs as above.

## Running the mobile app

```bash
cd mobile
npm install
npx expo start
```

Press `i` for the iOS Simulator. Use a development build if you rely on native modules such as Sign in with Apple (`expo run:ios`).

## Supabase dashboard checklist

- **Authentication → Providers:** enable **Apple** if you use Sign in with Apple.
- **Authentication → URL configuration:** add redirect URLs used by the app, e.g. the deep link from `expo-linking` for password reset (see `mobile/lib/deeplinks.ts`) and your `waytwo://` scheme.
- **Database:** enable **Row Level Security** on user-owned tables before exposing them through the API.

## API versioning

Only paths under **`/api/v1`** are part of the public contract. Future breaking changes should introduce `/api/v2`, etc. The mobile app should set `EXPO_PUBLIC_API_URL` to the versioned base (including `/api/v1`) so resource paths stay stable (`/health`, `/me`, …).
