# Email Confirm Auto-Navigate — Design

## Problem

After tapping the confirmation email link, `getSessionFromUrl` in `main.dart` correctly creates a Supabase session. However, the router's `refreshListenable` mechanism doesn't reliably fire the redirect away from `/email-confirm` in time — the user stays stuck on "Check your inbox". Manually navigating to `/login` works (router immediately sees `authed=true` and redirects to `/app/library`), confirming the session exists.

## Solution

Add an `onAuthStateChange` listener directly inside `EmailConfirmScreen`. When the event fires with a non-null session and the widget is still mounted, navigate to `/app/library`. This bypasses the router refresh timing entirely — the screen responds immediately to the auth state change.

## Design

### `lib/screens/email_confirm_screen.dart`

Add a `StreamSubscription` field to `_EmailConfirmScreenState`. Subscribe in `initState()`, cancel in `dispose()`.

```dart
// Add import at top:
import 'dart:async';

// In _EmailConfirmScreenState:
StreamSubscription? _authSub;

@override
void initState() {
  super.initState();
  _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session != null && mounted) {
      context.go('/app/library');
    }
  });
}

@override
void dispose() {
  _authSub?.cancel();
  super.dispose();
}
```

No other changes needed. The existing `_handleDeepLinks()` in `main.dart` continues to call `getSessionFromUrl` — this screen now responds to the resulting `onAuthStateChange` event directly.

## Files

- `lib/screens/email_confirm_screen.dart` — add auth listener in `initState`, cancel in `dispose`
- `test/screens/email_confirm_screen_test.dart` — verify screen navigates to `/app/library` when session is established

## Out of Scope

- Removing or changing `_handleDeepLinks()` in `main.dart`
- Changing the router's `publicOnly` list (already fixed in PR #10)
- Handling errors from `getSessionFromUrl`
