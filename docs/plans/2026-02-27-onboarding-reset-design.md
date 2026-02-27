# Onboarding Reset — Design Doc

**Date:** 2026-02-27

---

## Goal

Fix the router so an authenticated user who hasn't completed onboarding is always redirected there, and add a "Reset onboarding" tile to Profile so the flow can be reliably re-triggered for testing (and useful for users who want a refresher).

---

## Root Cause

### Bug — router redirect misses authenticated non-public routes

The current redirect in `router.dart`:

```dart
if (authed && publicOnly.contains(loc)) {
  return onboarded ? '/app/library' : '/onboarding';
}
```

Only redirects to `/onboarding` when the user lands on a `publicOnly` page (`/`, `/login`, etc.). If the user has a live Supabase session but `_onboardingCompleted` is `false` (e.g. after clearing SharedPreferences), they land directly on `/app/library` (the `initialLocation`) and the condition never fires.

### Missing feature — no in-app way to reset onboarding

There is no mechanism to clear `'onboarding_completed'` from within the app. Testing requires manually clearing SharedPreferences via ADB or device settings, which is unreliable (Supabase tokens live in Android Keystore, so "Clear Data" often restores the session before the flag is re-checked).

---

## Design

### Fix 1: Router redirect

Add one guard above the existing `publicOnly` check:

```dart
if (authed && !onboarded && loc != '/onboarding') return '/onboarding';
if (authed && publicOnly.contains(loc)) return '/app/library';
```

The `loc != '/onboarding'` guard prevents an infinite redirect loop.

The original second branch is simplified — once the first line handles the `!onboarded` case, the only remaining `publicOnly` redirect is to `/app/library` (always `onboarded` at that point).

### Fix 2: `resetOnboarding()` function in `router.dart`

```dart
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_completed');
  _onboardingCompleted = false;
  _onboardingNotifier.notify();
}
```

Calling this clears the flag and notifies the router's `refreshListenable`, triggering a redirect evaluation. With Fix 1 in place, the user is immediately sent to `/onboarding`.

### Fix 3: "Reset onboarding" tile in `ProfileScreen`

New `ListTile` below the existing "Reading style" tile:

```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(
    'Reset onboarding',
    style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15),
  ),
  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
  onTap: () async => resetOnboarding(),
),
```

No confirmation dialog — the user can always tap "Back" on the onboarding screen to return to their library.

---

## Tests

### `test/core/router_test.dart` (new file)

One unit test for `resetOnboarding()`:

```dart
test('resetOnboarding clears SharedPreferences flag and resets state', () async {
  SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  await loadOnboardingCompleted();
  expect(isOnboardingCompleted, true);
  await resetOnboarding();
  expect(isOnboardingCompleted, false);
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getBool('onboarding_completed'), isNull);
});
```

### `test/screens/profile_screen_test.dart` (existing file)

One new widget test that verifies the tile is present:

```dart
testWidgets('shows Reset onboarding tile', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.text('Reset onboarding'), findsOneWidget);
});
```

---

## Files Touched

| File | Change |
|------|--------|
| `lib/core/router.dart` | Fix redirect logic; add `resetOnboarding()` |
| `lib/screens/profile_screen.dart` | Add "Reset onboarding" `ListTile` |
| `test/core/router_test.dart` | New — unit test for `resetOnboarding()` |
| `test/screens/profile_screen_test.dart` | New tile presence test |

---

## Out of Scope

- Confirmation dialog before resetting
- Resetting reading style preference when onboarding resets
