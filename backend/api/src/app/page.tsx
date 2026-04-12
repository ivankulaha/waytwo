export default function Home() {
  return (
    <main style={{ fontFamily: 'system-ui', padding: 24 }}>
      <h1>WayTwo API</h1>
      <p>
        Versioned HTTP API is under <code>/api/v1</code>. Use{' '}
        <code>GET /api/v1/health</code> and <code>GET /api/v1/me</code> with a Supabase JWT.
      </p>
      <p>
        OpenAPI spec: <code>GET /api/docs/spec</code>. Interactive docs:{' '}
        <a href="/api/docs">/api/docs</a>.
      </p>
    </main>
  );
}
