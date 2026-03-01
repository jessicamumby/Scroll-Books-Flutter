# Email Confirm Router Fix — Design

## Problem

After tapping the confirmation link in the email, the app opens and `getSessionFromUrl` creates a session. The `_AuthNotifier` fires, the router re-evaluates — but `/email-confirm` is not in the `publicOnly` list, so no redirect fires and the user is stuck on the "Check your inbox" screen. Tapping "Already confirmed? Log in" works as a workaround (it navigates to `/login`, which IS in `publicOnly`, and the router immediately redirects to `/app/library`), but the user should never need to do that.

## Solution

Add `/email-confirm` to the `publicOnly` list in `lib/core/router.dart`. The existing rule `if (authed && publicOnly.contains(loc)) return '/app/library';` already handles the redirect — `/email-confirm` just needs to be included in the list.

## Design

### `lib/core/router.dart`

```dart
// BEFORE:
final publicOnly = ['/', '/login', '/signup', '/forgot-password'];

// AFTER:
final publicOnly = ['/', '/login', '/signup', '/forgot-password', '/email-confirm'];
```

One-line change. Semantically correct: `publicOnly` means "screens authenticated users shouldn't remain on", and `/email-confirm` is exactly that.

## Files

- `lib/core/router.dart` — add `/email-confirm` to `publicOnly`

## Out of Scope

- Any change to the deep link handler in `main.dart`
- Any change to `EmailConfirmScreen`
- Any change to the Supabase configuration
