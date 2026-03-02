# Forgot Password Reset — Design

## Problem

After requesting a password reset, `ForgotPasswordScreen` shows "Check your inbox to reset your password." When the user taps the link in the email, the app opens but stays on that screen — the same go_router `refreshListenable` timing issue as the email confirmation bug (fixed in PR #11). Additionally, there is no screen in the app where the user can actually enter their new password, and `resetPasswordForEmail` is called without `emailRedirectTo`.

## Solution

Add a `ChangePasswordScreen` at `/change-password`, accessible from both the password reset email link and the Profile screen. In `ForgotPasswordScreen`, listen for `AuthChangeEvent.passwordRecovery` directly (same `onAuthStateChange` pattern used in `EmailConfirmScreen`) and navigate to `/change-password` when it fires. Add `emailRedirectTo` to the `resetPasswordForEmail` call for consistency.

## Design

### New: `lib/screens/change_password_screen.dart`

Stateful widget. Two fields: "New password" and "Confirm password". On submit:
- Validates both fields are non-empty and match
- Calls `supabase.auth.updateUser(UserAttributes(password: newPassword))`
- On success → `context.go('/app/library')`
- On `AuthException` → shows the error message inline
- Loading state disables the button and shows a spinner

### `lib/screens/forgot_password_screen.dart`

- Add `emailRedirectTo: 'scrollbooks://auth-callback'` to `resetPasswordForEmail`
- Add `StreamSubscription? _authSub`, subscribe in `initState`, cancel in `dispose`
- Listener: `if (event.type == AuthChangeEvent.passwordRecovery && mounted) context.go('/change-password')`

### `lib/core/router.dart`

Add one route outside the shell:
```dart
GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
```

`/change-password` is NOT added to `publicOnly` — authenticated users need to remain on it.

### `lib/screens/profile_screen.dart`

Add a "Change password" `ListTile` between the Reading Style tile and the Reset Onboarding tile:
```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text('Change password', style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15)),
  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
  onTap: () => context.push('/change-password'),
),
```

## Files

- Create: `lib/screens/change_password_screen.dart`
- Modify: `lib/screens/forgot_password_screen.dart` — add `emailRedirectTo`, add auth listener
- Modify: `lib/core/router.dart` — add `/change-password` route
- Modify: `lib/screens/profile_screen.dart` — add "Change password" tile
- Create: `test/screens/change_password_screen_test.dart`

## Out of Scope

- Changing the deep link handler in `main.dart`
- Any minimum password length UI validation (Supabase enforces this server-side)
- Removing the "Reset onboarding" tile from Profile
