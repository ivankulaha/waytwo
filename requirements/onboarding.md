# Feature: Onboarding

## Goal

Guide new users through a short, emotionally warm setup that collects essential personal information for personalization, themes, and future relationship features. Onboarding should feel gentle and personal — not like filling a form.

Partner-specific fields (partner name, relationship dates) are **not** collected here; they belong to the future pair-creation flow.

## Description

Onboarding runs after the user signs in for the first time (or until they complete or skip the avatar step). Data is persisted locally first and replicated to Supabase; the user can resume from the last saved step after app restart.

### Navigation and exit rules

- **Back button** is shown on every onboarding step.
- **First screen (intro):** if the user presses back, show a system confirmation dialog asking whether they want to **log out**. On confirm, sign out and return to the auth flow.
- **Skip** is available **only** on the avatar / profile color step. Choosing skip completes onboarding and sends the user to the main app (Home / tabs). Invite link is added later.
- **Resume:** on relaunch, continue from the last saved step (`onboarding_step`).

### Steps

1. **Intro** — Welcome copy and a single primary action to continue (no inputs).
2. **Your info** — Display name (required), gender (required: male / female / other), date of birth (optional).
3. **Look** — Profile photo (optional) and profile color (optional). Primary action completes onboarding; secondary **Skip** completes onboarding without requiring photo or color.

### Collected information (this flow only)

| Field | Required | Notes |
|-------|----------|--------|
| Display name | Yes | First name or nickname; partner-facing copy deferred to pair flow. |
| Gender | Yes | male, female, other — for tone and UI. |
| Date of birth | No | For birthday-related features later. |
| Profile picture | No | Stored at stable path `avatars/{user_id}/avatar.jpg` in Supabase Storage. |
| Profile color | No | Personal accent; couple gradient deferred to pair flow. |

## After onboarding

The user lands on the **main screen** (tabs / home). Couple pairing and invite flow are out of scope for this feature.

## Design references

- **Figma file (MCP):** [WayTwo (Copy)](https://www.figma.com/design/NIofouu7Ph9yhZs118YH9j/WayTwo--Copy-) — `fileKey` `NIofouu7Ph9yhZs118YH9j`.
- **Onboarding v2 (canonical):** [section `326:5994`](https://www.figma.com/design/NIofouu7Ph9yhZs118YH9j/WayTwo--Copy-?node-id=326-5994) — frames **07–12** (intro, three field steps, look, finish). Prefer per-frame `get_design_context` on child frame IDs from MCP metadata.
- **Onboarding v1 (legacy):** [section `150:3008`](https://www.figma.com/design/NIofouu7Ph9yhZs118YH9j/WayTwo--Copy-?node-id=150-3008) — frames **01–06**; use only for historical comparison.

## Author

Ivan Kulaha
