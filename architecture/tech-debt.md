# Technical debt

Tracked follow-ups for security, scale, and reliability. **Author:** Ivan Kulaha

## Open items

| ID | Area | Risk | Proposed direction | Status |
|----|------|------|-------------------|--------|
| TD-1 | `POST /api/v1/auth/check-email` | Abuse and large-scale **email enumeration**; high request volume to Auth Admin `listUsers` pagination | **Rate limiting:** per-IP and/or per normalized email; shared store or edge/gateway when multiple instances; respond with `429` and a generic body; log counts/metrics without logging raw email at `error` level | Open |
| TD-2 | `POST /api/v1/auth/check-email` | Automated probing without human friction | **CAPTCHA / bot mitigation:** e.g. Cloudflare Turnstile or hCaptcha — client obtains token, server verifies before admin lookup; combine with TD-1. Alternative: device attestation (heavier) | Open |

## Context

The public check-email endpoint intentionally reveals whether an email is registered so the app can branch to login vs signup. Mitigations above are deferred; see [ADR-0001](adr/0001-authentication-with-supabase.md) amendment.
