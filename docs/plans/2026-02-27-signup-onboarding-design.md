# Sign-Up Onboarding — Design

## Problem

After completing onboarding, unauthenticated users are redirected to `/login` by the router. The login screen has no "Sign up" link. New users are stuck with no path to create an account.

## Design

### Part 1 — Style picker card (`lib/screens/onboarding_screen.dart`)

Replace the single `ElevatedButton('Start reading →')` with two CTAs:

- **Primary:** `ElevatedButton('Sign up')` — disabled until a style is selected
- **Secondary:** `TextButton('Log in')` — always tappable

Tapping **Sign up**:
1. Saves `_selectedStyle` to `SharedPreferences` under key `'pending_reading_style'`
2. Calls `widget.onComplete()`
3. Routes to `/signup`

Tapping **Log in**:
1. Calls `widget.onComplete()`
2. Routes to `/login`

Remove the existing `_complete()` method. Replace with `_goSignUp()` and `_goLogIn()`.

### Part 2 — Style persistence (`lib/core/router.dart` + `lib/providers/app_provider.dart`)

When a new user taps "Sign up" they are not yet authenticated. `onStyleSelected` currently no-ops when `userId` is null, and `AppProvider.load()` fires after auth and overwrites in-memory state with the Supabase default (`'vertical'`), losing their pick.

**`lib/core/router.dart` — `onStyleSelected` callback:**
When `userId` is null, save `style` to `SharedPreferences('pending_reading_style')` instead of silently skipping.

**`lib/providers/app_provider.dart` — `load()`:**
After `fetchAll` returns, if no `user_preferences` row exists in Supabase (i.e. `readingStyle` came back as the default `'vertical'` with no row), read `'pending_reading_style'` from `SharedPreferences`. If present: apply it as `readingStyle`, fire-and-forget `UserDataService.saveReadingStyle(userId, style)`, and delete the key.

> Note: `UserDataService.fetchAll` currently conflates "no preference row" with "preference is vertical". To disambiguate, `fetchAll` should return `null` for `readingStyle` when no row exists, and `AppProvider.load()` falls back to `'vertical'` only after checking the pending key.

### Part 3 — Login screen (`lib/screens/login_screen.dart`)

Add a `TextButton` below "Forgot password?":

```
Don't have an account? Sign up
```

Routes to `/signup`. Handles users who arrive at `/login` directly (landing screen, or after tapping "Log in" from the onboarding style picker) and realise they need to create an account.

## Files

- `lib/screens/onboarding_screen.dart` — replace `_complete()` + button with `_goSignUp()` / `_goLogIn()` + two-CTA footer
- `lib/core/router.dart` — `onStyleSelected`: save to `SharedPreferences` when `userId` is null
- `lib/providers/app_provider.dart` — `load()`: apply pending style from `SharedPreferences` after auth
- `lib/services/user_data_service.dart` — `fetchAll`: return `null` for `readingStyle` when no preference row exists
- `lib/screens/login_screen.dart` — add "Don't have an account? Sign up" `TextButton`
- `test/screens/onboarding_screen_test.dart` — update final card tests (new button labels, navigation)
- `test/screens/login_screen_test.dart` — add test for sign-up link presence

## Out of Scope

- Changing the sign-up form itself
- Guest/anonymous reading mode
- Social sign-in (Google, Apple)
- Any change to the email confirmation flow
