# Feature: Authentication
## Goal
To allow users to securely access the application with modern, convenient authentication options.
## Description
The Login feature provides secure access to the Couples App using multiple authentication methods. At minimum, the app supports:
- Email + Password
- Apple ID (Sign in with Apple)


The feature includes core authorization actions:
- Login with any supported method
- Forgot Password / Password Reset flow
- Session persistence across app restarts
- Optional onboarding path if user logs in for the first time or hasn’t joined a couple yet
- The login system must integrate with future pairing logic (connecting two users into a couple).

## UX
- Entry screen: email field, **Continue**, and on iOS **Continue with Apple** (Apple bypasses the email branch).
- After **Continue**, the app calls the API to see if the email is already registered:
  - **Registered** → password screen only (same email; no re-entry).
  - **Not registered** → sign-up screen: choose password only (email shown as non-editable hint text, not a second email field).
- Forgot password flow from the password screen; reset email as today.
- Loading states on Continue and submit actions; errors:
  - Failed email check (network / server) — user-visible retry message.
  - Invalid password on sign-in — generic invalid credentials message (no redirect to sign-up).
  - Sign-up failures — generic create-account error.
- Minimum password length **6** characters (must match Supabase Auth project settings).
- Password fields use platform autofill hints (`textContentType` / `autoComplete`) for Keychain and password manager compatibility.
- After successful login, the app routes via `index` + `ProfileProvider`: **Home (tabs)** when onboarding is complete; **`/(onboarding)`** when onboarding is not finished. Couple pairing / invite is out of scope for this document.

## Notifications
  - Password reset email 
