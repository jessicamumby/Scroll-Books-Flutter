# Email Confirm Auto-Navigate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Navigate to `/app/library` automatically when `onAuthStateChange` fires with a session inside `EmailConfirmScreen`, bypassing the go_router `refreshListenable` timing issue.

**Architecture:** Add a `StreamSubscription` to `_EmailConfirmScreenState`. Subscribe in `initState()`, cancel in `dispose()`. When the event fires with a non-null session and the widget is mounted, call `context.go('/app/library')`. The existing `_handleDeepLinks()` in `main.dart` continues to call `getSessionFromUrl` — this screen now responds to the resulting auth event directly.

**Tech Stack:** Flutter, `supabase_flutter ^2.x`, `go_router ^13.x`, `dart:async`

---

## Background

After tapping the confirmation link, `getSessionFromUrl` creates a Supabase session. `_AuthNotifier` fires `notifyListeners()`, but go_router's `refreshListenable` mechanism doesn't reliably trigger a redirect while the user is already on `/email-confirm`. The router fix (PR #10, adding `/email-confirm` to `publicOnly`) was correct but not sufficient — the router rule works only if the refresh fires cleanly, which it doesn't in this timing window.

The fix: `EmailConfirmScreen` subscribes directly to `onAuthStateChange` and navigates itself when a session appears.

---

### Task 1: Add auth listener to `EmailConfirmScreen`

**Files:**
- Modify: `test/screens/email_confirm_screen_test.dart`
- Modify: `lib/screens/email_confirm_screen.dart`

> **Note on testability:** The `onAuthStateChange` stream comes from `Supabase.instance.client.auth`, which is a platform singleton. Mocking it would require replacing the entire `SupabaseClient` — a significant test infrastructure change outside the scope of this fix. As a result, the auth-triggered navigation path (`session != null → context.go('/app/library')`) cannot be unit-tested here. The existing 5 tests are preserved and verified not to crash.

---

**Step 1: Update the test file — add Supabase init and `/app/library` route**

The new `initState()` code subscribes to `Supabase.instance.client.auth.onAuthStateChange`. Without Supabase being initialised, this crashes the test pump with a `StateError`. Add a `setUpAll` block (using the same pattern as `test/core/router_test.dart`) and add a `/app/library` stub route to `_wrap()` so go_router can resolve the navigation target.

In `test/screens/email_confirm_screen_test.dart`, make the following changes:

Add imports at the top (after existing imports):
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

Add the `_NoOpAsyncStorage` helper class before `main()`:
```dart
class _NoOpAsyncStorage extends GotrueAsyncStorage {
  const _NoOpAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}
```

Add `/app/library` to the `_wrap()` router:
```dart
Widget _wrap({String email = 'test@example.com'}) => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/email-confirm',
        routes: [
          GoRoute(
            path: '/email-confirm',
            builder: (_, __) => EmailConfirmScreen(email: email),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
          ),
        ],
      ),
    );
```

Change the existing `setUpAll` block to add Supabase initialization:
```dart
setUpAll(() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://example.supabase.co',
    anonKey: 'test-anon-key',
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
      pkceAsyncStorage: _NoOpAsyncStorage(),
    ),
  );
});
```

**Step 2: Run the tests to confirm they still pass before touching the implementation**

```bash
flutter test test/screens/email_confirm_screen_test.dart
```

Expected: 5 tests pass.

**Step 3: Implement the auth listener in `EmailConfirmScreen`**

In `lib/screens/email_confirm_screen.dart`:

Add `dart:async` import at the top:
```dart
import 'dart:async';
```

Add `_authSub` field to `_EmailConfirmScreenState` (after the existing `_loading` field):
```dart
StreamSubscription? _authSub;
```

Add `initState` override (the class currently has no `initState`):
```dart
@override
void initState() {
  super.initState();
  _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session != null && mounted) {
      context.go('/app/library');
    }
  });
}
```

Add `dispose` override (the class currently has no `dispose`):
```dart
@override
void dispose() {
  _authSub?.cancel();
  super.dispose();
}
```

**Step 4: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass (no regressions).

**Step 5: Commit**

```bash
git add lib/screens/email_confirm_screen.dart test/screens/email_confirm_screen_test.dart
git commit -m "fix: auto-navigate from email-confirm when session is established"
```

---

## Manual Smoke Test

After merging and running on a physical device:

1. Sign up with a real email address
2. The app navigates to `/email-confirm` — "Check your inbox"
3. Open the email and tap the confirmation link
4. The app opens (or resumes) and navigates directly to `/app/library` — no extra taps required
