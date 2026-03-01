# Sign-Up Onboarding Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the onboarding "Start reading →" CTA with "Sign up" + "Log in" buttons, and persist the user's style choice through the auth boundary so it is applied after sign-up.

**Architecture:** Four independent-ish tasks: (1) swap the onboarding CTAs, (2) add a "Don't have an account?" link to LoginScreen, (3) make `UserData.readingStyle` nullable so we can distinguish "no preference set" from "preference is vertical", (4) wire up SharedPreferences to bridge the style pick across sign-up. Tasks 1 and 2 can land independently. Task 4 depends on Task 3.

**Tech Stack:** Flutter, go_router, shared_preferences, Supabase (already wired), flutter_test

---

### Background: how routing works

The router (`lib/core/router.dart`) has a redirect guard:

```
if (!authed && requiresAuth)  → /login
if (authed && !onboarded)     → /onboarding
if (authed && public page)    → /app/library
```

After onboarding completes (`onboardingCompleted = true`), an unauthenticated user trying to reach `/app/library` is sent to `/login`. Currently LoginScreen has no sign-up link, so new users are stuck. These tasks fix that.

---

### Task 1: Swap "Start reading →" for "Sign up" + "Log in" on the style picker card

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Modify: `test/screens/onboarding_screen_test.dart`

---

**Step 1: Write the failing tests**

Open `test/screens/onboarding_screen_test.dart`.

First, update `_wrapWithCallback` to add `/signup` and `/login` stub routes (the new navigation targets):

```dart
Widget _wrapWithCallback({Future<void> Function(String)? onStyleSelected}) =>
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => OnboardingScreen(
              onComplete: () async {},
              onStyleSelected: onStyleSelected ?? (style) async {},
            ),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
          ),
          GoRoute(
            path: '/signup',
            builder: (_, __) => const Scaffold(body: Text('signup')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
        ],
      ),
    );
```

Then update the three tests that reference `'Start reading →'` to reference `'Sign up'` instead, and update the navigation assertion from `'library'` to `'signup'`:

```dart
testWidgets('Sign up is disabled before style selected', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  final button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Sign up'),
  );
  expect(button.onPressed, isNull);
});

testWidgets('tapping style tile enables Sign up', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  await tester.tap(find.text('Swipe down'));
  await tester.pumpAndSettle();
  final button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Sign up'),
  );
  expect(button.onPressed, isNotNull);
});

testWidgets('tapping Sign up passes correct style and navigates to /signup',
    (tester) async {
  String? capturedStyle;
  await tester.pumpWidget(_wrapWithCallback(
    onStyleSelected: (style) async { capturedStyle = style; },
  ));
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  await tester.tap(find.text('Swipe down'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
  expect(capturedStyle, 'vertical');
  expect(find.text('signup'), findsOneWidget);
});

testWidgets('tapping Tap across passes horizontal style', (tester) async {
  String? capturedStyle;
  await tester.pumpWidget(_wrapWithCallback(onStyleSelected: (s) async => capturedStyle = s));
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  await tester.tap(find.text('Tap across'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
  expect(capturedStyle, 'horizontal');
});

testWidgets('Sign up navigates even if onStyleSelected throws',
    (tester) async {
  await tester.pumpWidget(_wrapWithCallback(
    onStyleSelected: (_) async => throw Exception('save failed'),
  ));
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  await tester.tap(find.text('Swipe down'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
  expect(find.text('signup'), findsOneWidget);
});

testWidgets('Log in is always enabled without a style selected', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  final button = tester.widget<TextButton>(
    find.widgetWithText(TextButton, 'Log in'),
  );
  expect(button.onPressed, isNotNull);
});

testWidgets('tapping Log in navigates to /login', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  await tester.tap(find.text('Log in'));
  await tester.pumpAndSettle();
  expect(find.text('login'), findsOneWidget);
});
```

Delete the three old tests that reference `'Start reading →'`:
- `'Start reading is disabled before style selected'`
- `'tapping style tile enables Start reading'`
- `'tapping Start reading passes correct style and navigates to library'`
- `'tapping Tap across passes horizontal style'` (update in place, don't delete)
- `'Start reading navigates even if onStyleSelected throws'` (update in place)

**Step 2: Run tests to verify they fail**

```bash
cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter
flutter test test/screens/onboarding_screen_test.dart
```

Expected: failures on the new `'Sign up'` / `'Log in'` tests because the button label still says `'Start reading →'`.

**Step 3: Implement — update `_buildStylePickerCard` and replace `_complete()`**

In `lib/screens/onboarding_screen.dart`:

**3a. Replace `_complete()` with `_goSignUp()` and `_goLogIn()`.**

Remove the existing `_complete()` method entirely:

```dart
// DELETE THIS:
Future<void> _complete() async {
  final style = _selectedStyle;
  if (style == null) return;
  try {
    await widget.onStyleSelected(style);
  } catch (_) {
    // Preference save failed — still navigate
  }
  await widget.onComplete();
  if (mounted) context.go('/app/library');
}
```

Add these two methods in its place:

```dart
Future<void> _goSignUp() async {
  final style = _selectedStyle!;
  try {
    await widget.onStyleSelected(style);
  } catch (_) {}
  await widget.onComplete();
  if (mounted) context.go('/signup');
}

Future<void> _goLogIn() async {
  await widget.onComplete();
  if (mounted) context.go('/login');
}
```

**3b. Update the button section at the bottom of `_buildStylePickerCard`.**

Find this block at the end of `_buildStylePickerCard`:

```dart
const Spacer(),
_DotRow(current: _featureCards.length + 1, total: totalCards),
const SizedBox(height: 16),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _selectedStyle != null ? _complete : null,
    child: const Text('Start reading →'),
  ),
),
```

Replace with:

```dart
const Spacer(),
_DotRow(current: _featureCards.length + 1, total: totalCards),
const SizedBox(height: 16),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _selectedStyle != null ? _goSignUp : null,
    child: const Text('Sign up'),
  ),
),
const SizedBox(height: 8),
SizedBox(
  width: double.infinity,
  child: TextButton(
    onPressed: _goLogIn,
    child: const Text('Log in'),
  ),
),
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: all tests pass.

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/onboarding_screen.dart test/screens/onboarding_screen_test.dart
git commit -m "feat: replace Start reading with Sign up / Log in on style picker"
```

---

### Task 2: Add "Don't have an account? Sign up" link to LoginScreen

**Files:**
- Modify: `lib/screens/login_screen.dart`
- Modify: `test/screens/login_screen_test.dart`

---

**Step 1: Write the failing tests**

Open `test/screens/login_screen_test.dart`.

Add `/signup` to the `_wrap()` helper:

```dart
Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const Scaffold(body: Text('forgot'))),
        GoRoute(path: '/signup', builder: (_, __) => const Scaffold(body: Text('signup'))),
      ]),
    );
```

Add two new tests inside the `'LoginScreen'` group:

```dart
testWidgets('shows sign up link', (tester) async {
  await tester.pumpWidget(_wrap());
  expect(find.textContaining('Sign up'), findsOneWidget);
});

testWidgets('tapping sign up navigates to /signup', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.tap(find.textContaining('Sign up'));
  await tester.pumpAndSettle();
  expect(find.text('signup'), findsOneWidget);
});
```

**Step 2: Run tests to verify they fail**

```bash
flutter test test/screens/login_screen_test.dart
```

Expected: failures on both new tests (`'Sign up'` text not found).

**Step 3: Implement — add TextButton to LoginScreen**

In `lib/screens/login_screen.dart`, locate this block (after the "Forgot password?" button):

```dart
TextButton(
  onPressed: () => context.go('/forgot-password'),
  child: const Text('Forgot password?'),
),
```

Add a new `TextButton` immediately after it:

```dart
TextButton(
  onPressed: () => context.go('/signup'),
  child: Text(
    "Don't have an account? Sign up",
    style: TextStyle(color: AppTheme.amber),
  ),
),
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/login_screen_test.dart
```

Expected: all 6 tests pass.

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/login_screen.dart test/screens/login_screen_test.dart
git commit -m "feat: add sign up link to LoginScreen"
```

---

### Task 3: Make `UserData.readingStyle` nullable

This is preparatory for Task 4. Currently `fetchAll` returns `'vertical'` both when the user has no preference row AND when their preference is genuinely `'vertical'`. Making it nullable lets `AppProvider.load()` distinguish the two cases.

**Files:**
- Modify: `lib/services/user_data_service.dart`
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/services/user_data_service_test.dart`

---

**Step 1: Write the failing test**

In `test/services/user_data_service_test.dart`, update the existing test `'readingStyle defaults to vertical'`:

```dart
// Replace this:
test('readingStyle defaults to vertical', () {
  final data = UserData(library: [], progress: {}, readDays: []);
  expect(data.readingStyle, 'vertical');
});

// With this:
test('readingStyle is null when not provided', () {
  final data = UserData(library: [], progress: {}, readDays: []);
  expect(data.readingStyle, isNull);
});
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: FAIL — `readingStyle` is currently `'vertical'` not `null`.

**Step 3: Implement**

In `lib/services/user_data_service.dart`:

**3a.** Change the `UserData` field and constructor default:

```dart
// Before:
final String readingStyle;

const UserData({
  required this.library,
  required this.progress,
  required this.readDays,
  this.readingStyle = 'vertical',
});

// After:
final String? readingStyle;

const UserData({
  required this.library,
  required this.progress,
  required this.readDays,
  this.readingStyle,
});
```

**3b.** Change `fetchAll` to return null instead of `'vertical'` when no row exists:

```dart
// Before (line 45):
final readingStyle = prefs?['reading_style'] as String? ?? 'vertical';

// After:
final readingStyle = prefs?['reading_style'] as String?;
```

In `lib/providers/app_provider.dart`, update `load()` to handle the nullable value:

```dart
// Before (line 19):
readingStyle = data.readingStyle;

// After:
readingStyle = data.readingStyle ?? 'vertical';
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: all tests pass.

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/services/user_data_service.dart lib/providers/app_provider.dart test/services/user_data_service_test.dart
git commit -m "refactor: make UserData.readingStyle nullable to distinguish no-preference from vertical"
```

---

### Task 4: Persist pending style across the auth boundary

When a new user taps "Sign up" on the onboarding style picker, they are not yet authenticated. `onStyleSelected` currently no-ops when `userId` is null, so the selected style is lost when `AppProvider.load()` runs after sign-up. This task saves the style to `SharedPreferences` before sign-up, then reads and syncs it after auth.

**Files:**
- Modify: `lib/core/router.dart`
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/services/user_data_service_test.dart`

---

**Step 1: Write the failing test**

In `test/services/user_data_service_test.dart`, add a test in the `'AppProvider'` group:

```dart
test('readingStyle can be set directly (pending style simulation)', () {
  final provider = AppProvider();
  provider.readingStyle = 'horizontal';
  expect(provider.readingStyle, 'horizontal');
});
```

This test already passes (field is settable), so it acts as a regression anchor. The real behaviour (SharedPreferences round-trip in `load()`) requires a live platform channel and is verified manually.

**Step 2: Run tests to confirm baseline**

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: all tests pass.

**Step 3: Implement — router saves pending style when no userId**

In `lib/core/router.dart`, add the import at the top:

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

Then update the `onStyleSelected` callback inside the `/onboarding` route builder:

```dart
// Before:
onStyleSelected: (style) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId != null) {
    await Provider.of<AppProvider>(context, listen: false)
        .setReadingStyle(userId, style);
  }
},

// After:
onStyleSelected: (style) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId != null) {
    await Provider.of<AppProvider>(context, listen: false)
        .setReadingStyle(userId, style);
  } else {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_reading_style', style);
  }
},
```

**Step 4: Implement — AppProvider.load() applies pending style**

In `lib/providers/app_provider.dart`, add the import at the top:

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

Then update `load()` to apply the pending style when Supabase has no preference:

```dart
// Before:
Future<void> load(String userId) async {
  loading = true;
  notifyListeners();
  try {
    final data = await UserDataService.fetchAll(userId);
    library = data.library;
    progress = data.progress;
    readDays = data.readDays;
    readingStyle = data.readingStyle ?? 'vertical';
  } finally {
    loading = false;
    notifyListeners();
  }
}

// After:
Future<void> load(String userId) async {
  loading = true;
  notifyListeners();
  try {
    final data = await UserDataService.fetchAll(userId);
    library = data.library;
    progress = data.progress;
    readDays = data.readDays;
    if (data.readingStyle != null) {
      readingStyle = data.readingStyle!;
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pending = prefs.getString('pending_reading_style');
        if (pending != null) {
          readingStyle = pending;
          await prefs.remove('pending_reading_style');
          UserDataService.saveReadingStyle(userId, pending); // fire-and-forget
        }
      } catch (_) {}
    }
  } finally {
    loading = false;
    notifyListeners();
  }
}
```

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/core/router.dart lib/providers/app_provider.dart test/services/user_data_service_test.dart
git commit -m "feat: persist reading style selection across sign-up flow"
```

---

## Manual Smoke Test

After all four tasks:

1. Fresh install (or clear app data) → app opens to onboarding
2. Swipe through all cards → reach style picker
3. Tap "Tap across" (Stories Style) → "Sign up" button activates
4. Confirm "Log in" text button is visible below
5. Tap "Sign up" → navigates to `/signup` screen
6. Create a new account → confirm email → log in
7. Reach library → open Profile → Reading Style should show **Stories Style** (horizontal), not the default Scroll Style
8. Return to onboarding (fresh data) → tap "Log in" → confirm it navigates to `/login`
9. From `/login` → confirm "Don't have an account? Sign up" link is visible and tappable
