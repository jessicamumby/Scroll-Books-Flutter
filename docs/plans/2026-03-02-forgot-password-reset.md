# Forgot Password Reset Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let users complete the password reset flow end-to-end: tap the email link → land on a Change Password screen → enter a new password → arrive at the library.

**Architecture:** Four changes: (1) new `ChangePasswordScreen` at `/change-password` with a password + confirm form; (2) `ForgotPasswordScreen` gains an `onAuthStateChange` listener for `passwordRecovery` events that navigates to `/change-password`, plus `emailRedirectTo` on the reset call; (3) the router gets the new route; (4) Profile gets a "Change password" tile as a second entry point.

**Tech Stack:** Flutter, `supabase_flutter ^2.x`, `go_router ^13.x`, `dart:async`

---

## Background

`ForgotPasswordScreen` calls `supabase.auth.resetPasswordForEmail` without `emailRedirectTo`. When the user taps the reset link, `getSessionFromUrl` in `main.dart` creates a Supabase **recovery** session (`AuthChangeEvent.passwordRecovery`). The router's `refreshListenable` doesn't reliably redirect away from `/forgot-password`, so the user stays on "Check your inbox". Even if the router did fire, there is no screen in the app to enter a new password.

The fix mirrors what was done for email confirmation (PR #11): subscribe to `onAuthStateChange` directly inside `ForgotPasswordScreen` and navigate to `/change-password` on the recovery event.

---

### Task 1: Create `ChangePasswordScreen`

**Files:**
- Create: `lib/screens/change_password_screen.dart`
- Create: `test/screens/change_password_screen_test.dart`

> **Note on testability:** `auth.updateUser` is only called when the form passes client-side validation. Tests that exercise validation failures never reach Supabase, so no Supabase initialisation is needed.

---

**Step 1: Create the test file**

```dart
// test/screens/change_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/change_password_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/change-password',
        routes: [
          GoRoute(
            path: '/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
          ),
        ],
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ChangePasswordScreen', () {
    testWidgets('shows New password field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'New password'), findsOneWidget);
    });

    testWidgets('shows Confirm password field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Confirm password'), findsOneWidget);
    });

    testWidgets('shows Update Password button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('shows Required errors when submitted empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows mismatch error when passwords differ', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'New password'), 'password123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'), 'different');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
flutter test test/screens/change_password_screen_test.dart
```

Expected: FAIL — `change_password_screen.dart` does not exist yet.

**Step 3: Create the implementation**

```dart
// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await supabase.auth.updateUser(UserAttributes(password: _password.text));
      if (mounted) context.go('/app/library');
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'New password'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _password.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style:
                          TextStyle(color: AppTheme.sienna, fontSize: 14)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/change_password_screen_test.dart
```

Expected: 5 tests pass.

**Step 5: Commit**

```bash
git add lib/screens/change_password_screen.dart test/screens/change_password_screen_test.dart
git commit -m "feat: add ChangePasswordScreen"
```

---

### Task 2: Update `ForgotPasswordScreen`

**Files:**
- Modify: `lib/screens/forgot_password_screen.dart`
- Create: `test/screens/forgot_password_screen_test.dart`

> **Note on testability:** `ForgotPasswordScreen.initState` will subscribe to `Supabase.instance.client.auth.onAuthStateChange`. Without Supabase initialised, this crashes test pumps. Add a `setUpAll` block using the same mock pattern as `test/core/router_test.dart` and `test/screens/email_confirm_screen_test.dart`.

---

**Step 1: Create the test file**

```dart
// test/screens/forgot_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/forgot_password_screen.dart';

class _NoOpAsyncStorage extends GotrueAsyncStorage {
  const _NoOpAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/change-password',
            builder: (_, __) => const Scaffold(body: Text('change-password')),
          ),
        ],
      ),
    );

void main() {
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

  group('ForgotPasswordScreen', () {
    testWidgets('shows email field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    });

    testWidgets('shows Send Reset Email button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Send Reset Email'), findsOneWidget);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
flutter test test/screens/forgot_password_screen_test.dart
```

Expected: FAIL — Supabase crashes because `initState` subscribes to `onAuthStateChange` but that code doesn't exist yet. (Tests may also pass if current `initState` doesn't subscribe — that's fine, proceed.)

**Step 3: Update `ForgotPasswordScreen`**

In `lib/screens/forgot_password_screen.dart`, make three changes:

**a) Add `dart:async` import** (first line of imports):
```dart
import 'dart:async';
```

**b) Add `_authSub` field** (after `bool _sent = false;`):
```dart
StreamSubscription? _authSub;
```

**c) Add `initState` override** (before the existing `dispose`):
```dart
@override
void initState() {
  super.initState();
  _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.type == AuthChangeEvent.passwordRecovery && mounted) {
      context.go('/change-password');
    }
  });
}
```

**d) Update `dispose`** — add `_authSub?.cancel()` before `_email.dispose()`:
```dart
@override
void dispose() {
  _authSub?.cancel();
  _email.dispose();
  super.dispose();
}
```

**e) Add `emailRedirectTo`** to the `resetPasswordForEmail` call (line 29):
```dart
await supabase.auth.resetPasswordForEmail(
  _email.text.trim(),
  emailRedirectTo: 'scrollbooks://auth-callback',
);
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/forgot_password_screen_test.dart
```

Expected: 2 tests pass.

**Step 5: Run the full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/forgot_password_screen.dart test/screens/forgot_password_screen_test.dart
git commit -m "fix: navigate to /change-password on password recovery deep link"
```

---

### Task 3: Add `/change-password` route to the router

**Files:**
- Modify: `lib/core/router.dart`

No new tests needed — the new route has no redirect logic, and the router test suite doesn't test individual route existence.

---

**Step 1: Update `lib/core/router.dart`**

Add the import at the top (with the other screen imports):
```dart
import '../screens/change_password_screen.dart';
```

Add the route after the `/forgot-password` route (around line 53):
```dart
GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
```

**Step 2: Run the full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 3: Commit**

```bash
git add lib/core/router.dart
git commit -m "feat: add /change-password route"
```

---

### Task 4: Add "Change password" tile to `ProfileScreen`

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Modify: `test/screens/profile_screen_test.dart`

---

**Step 1: Update the test file**

In `test/screens/profile_screen_test.dart`:

**a) Add `/change-password` stub route** to `_wrap()` (alongside the existing stubs):
```dart
GoRoute(
  path: '/change-password',
  builder: (_, __) => const Scaffold(body: Text('change-password')),
),
```

**b) Add two new tests** inside the `group('ProfileScreen', ...)` block:
```dart
testWidgets('shows Change password tile', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.text('Change password'), findsOneWidget);
});

testWidgets('tapping Change password navigates to /change-password',
    (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Change password'));
  await tester.pumpAndSettle();
  expect(find.text('change-password'), findsOneWidget);
});
```

**Step 2: Run tests to verify the two new ones fail**

```bash
flutter test test/screens/profile_screen_test.dart
```

Expected: 5 existing pass, 2 new fail (tile doesn't exist yet).

**Step 3: Add the tile to `ProfileScreen`**

In `lib/screens/profile_screen.dart`, add the following block after the Reading Style `ListTile` and its trailing `Divider` (between Reading style and Reset onboarding):

```dart
const Divider(color: AppTheme.borderSoft),
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(
    'Change password',
    style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15),
  ),
  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
  onTap: () => context.push('/change-password'),
),
```

**Step 4: Run tests to verify all pass**

```bash
flutter test test/screens/profile_screen_test.dart
```

Expected: 7 tests pass.

**Step 5: Run the full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/profile_screen.dart test/screens/profile_screen_test.dart
git commit -m "feat: add Change password entry point in ProfileScreen"
```

---

## Manual Smoke Test

After merging and running on a physical device:

**Password reset flow:**
1. Log out → tap "Forgot password" → enter your email → tap "Send Reset Email"
2. Check inbox → tap the reset link
3. App opens and navigates directly to the Change Password screen
4. Enter a new password + confirm → tap "Update Password"
5. App navigates to the Library

**Profile flow:**
1. Log in → tap Profile tab → tap "Change password"
2. Enter a new password + confirm → tap "Update Password"
3. App navigates to the Library
