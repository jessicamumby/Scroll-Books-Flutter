# Onboarding Reset Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the router redirect so any authenticated user who hasn't completed onboarding is always sent there, and add a "Reset onboarding" tile to Profile for reliable re-triggering.

**Architecture:** Two targeted changes — (1) a one-line redirect guard in `router.dart` plus a new `resetOnboarding()` function that mirrors the existing `completeOnboarding()` pattern; (2) a new `ListTile` in `ProfileScreen` that calls it. One new test file (`test/core/router_test.dart`) plus one new test in the existing profile test.

**Tech Stack:** Flutter, Dart, `go_router`, `shared_preferences`, `flutter_test`

---

### Task 1: Add `resetOnboarding()` and fix router redirect

**Files:**
- Create: `test/core/router_test.dart`
- Modify: `lib/core/router.dart` (around lines 47–65)

**Context:**

`router.dart` exposes two global functions and two global getters that manage onboarding state via SharedPreferences:

```
loadOnboardingCompleted()   // called from main.dart at boot
completeOnboarding()        // called when user finishes onboarding
isOnboardingCompleted       // public getter for _onboardingCompleted
_onboardingNotifier.notify() // triggers router refresh
```

We need a mirror of `completeOnboarding()` that clears the flag instead of setting it, and a one-line redirect fix.

**Step 1: Write the failing test**

Create `test/core/router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scroll_books/core/router.dart';

void main() {
  group('resetOnboarding', () {
    test('clears SharedPreferences flag and resets isOnboardingCompleted', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      await loadOnboardingCompleted();
      expect(isOnboardingCompleted, true);

      await resetOnboarding();

      expect(isOnboardingCompleted, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isNull);
    });
  });
}
```

**Step 2: Run test to confirm it fails**

```bash
flutter test test/core/router_test.dart
```

Expected: FAIL — `resetOnboarding` is not defined.

**Step 3: Implement `resetOnboarding()` in `router.dart`**

In `lib/core/router.dart`, after the existing `completeOnboarding()` function (currently ending at line 52), add:

```dart
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_completed');
  _onboardingCompleted = false;
  _onboardingNotifier.notify();
}
```

**Step 4: Run test to confirm it passes**

```bash
flutter test test/core/router_test.dart
```

Expected: PASS.

**Step 5: Fix the router redirect**

The current redirect (lines 56–66) is:

```dart
redirect: (context, state) {
  final loc = state.matchedLocation;
  final authed = _isAuthenticated;
  final onboarded = _onboardingCompleted;
  final publicOnly = ['/', '/login', '/signup', '/forgot-password'];
  final requiresAuth = loc.startsWith('/app') || loc.startsWith('/read') || loc == '/onboarding';
  if (!authed && requiresAuth) return '/login';
  if (authed && publicOnly.contains(loc)) {
    return onboarded ? '/app/library' : '/onboarding';
  }
  return null;
},
```

Replace with:

```dart
redirect: (context, state) {
  final loc = state.matchedLocation;
  final authed = _isAuthenticated;
  final onboarded = _onboardingCompleted;
  final publicOnly = ['/', '/login', '/signup', '/forgot-password'];
  final requiresAuth = loc.startsWith('/app') || loc.startsWith('/read') || loc == '/onboarding';
  if (!authed && requiresAuth) return '/login';
  if (authed && !onboarded && loc != '/onboarding') return '/onboarding';
  if (authed && publicOnly.contains(loc)) return '/app/library';
  return null;
},
```

The two key changes:
- New line: `if (authed && !onboarded && loc != '/onboarding') return '/onboarding';` — catches non-public routes (e.g. `/app/library`) for un-onboarded users.
- Simplified: the `publicOnly` branch no longer needs a ternary — if we reach that line the user is always `onboarded`.

**Step 6: Run the full test suite**

```bash
flutter test
```

Expected: All existing tests pass (count unchanged — the redirect logic is not covered by widget tests, so nothing breaks).

**Step 7: Commit**

```bash
git add lib/core/router.dart test/core/router_test.dart
git commit -m "fix: redirect un-onboarded users from any route; add resetOnboarding()"
```

---

### Task 2: "Reset onboarding" tile in ProfileScreen

**Files:**
- Modify: `lib/screens/profile_screen.dart` (after the "Reading style" divider, around line 79)
- Modify: `test/screens/profile_screen_test.dart` (add one test inside the existing group)

**Context:**

`ProfileScreen` is a `StatelessWidget`. Tiles follow this pattern (see "Reading style" tile):

```dart
const Divider(color: AppTheme.borderSoft),
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text('…', style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15)),
  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
  onTap: () { … },
),
```

`resetOnboarding()` is exported from `lib/core/router.dart`. `profile_screen.dart` doesn't currently import `router.dart` — that import needs to be added.

The `_wrap()` helper in the test file already includes a `/onboarding` stub route, so no test fixture changes are needed beyond the new test.

**Step 1: Write the failing test**

In `test/screens/profile_screen_test.dart`, inside `group('ProfileScreen', () {`, after the last test, add:

```dart
testWidgets('shows Reset onboarding tile', (tester) async {
  await tester.pumpWidget(_wrap());
  expect(find.text('Reset onboarding'), findsOneWidget);
});
```

**Step 2: Run test to confirm it fails**

```bash
flutter test test/screens/profile_screen_test.dart
```

Expected: FAIL — `find.text('Reset onboarding')` finds nothing.

**Step 3: Implement the tile in `ProfileScreen`**

In `lib/screens/profile_screen.dart`:

1. Add the import for `router.dart` after the existing imports (before the `class ProfileScreen` line):

```dart
import '../core/router.dart';
```

2. Find the closing `const Divider(color: AppTheme.borderSoft),` that follows the `Consumer<AppProvider>` block (currently line 79). After it, insert:

```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(
    'Reset onboarding',
    style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15),
  ),
  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
  onTap: () => resetOnboarding(),
),
const Divider(color: AppTheme.borderSoft),
```

The full column after this change, from "How Scroll Books works" onward, should read:

```
Divider
ListTile — How Scroll Books works
Divider
Consumer → ListTile — Reading style
Divider
ListTile — Reset onboarding      ← new
Divider
SizedBox(24)
Sign Out button
```

**Step 4: Run all tests to confirm everything passes**

```bash
flutter test
```

Expected: All tests pass including the new tile test.

**Step 5: Commit**

```bash
git add lib/screens/profile_screen.dart test/screens/profile_screen_test.dart
git commit -m "feat: add Reset onboarding tile to ProfileScreen"
```
