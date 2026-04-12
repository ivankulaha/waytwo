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
- Clean login screen with Email/Password fields and “Continue with Apple.”
- Forgot password link leads to email reset flow.
- Loading state and error handling:
  - Invalid password
  - Account not found
- After successful login, user is redirected to:
  - The Home Screen if already paired
  - Couple Setup / Invite Flow if new user 

## Notifications
  - Password reset email 
