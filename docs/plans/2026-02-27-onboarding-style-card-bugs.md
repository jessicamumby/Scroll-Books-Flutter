# Onboarding Style Card Bugs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the looping animation and the broken "Start reading →" button on the 4th onboarding card.

**Architecture:** Two targeted changes to `onboarding_screen.dart`: (1) attach a `StatusListener` to the existing `AnimationController` to restart the preview animation after each cycle; (2) wrap `onStyleSelected` in a try/catch inside `_complete()` so navigation always proceeds even if the Supabase save throws. One new test. No new files.

**Tech Stack:** Flutter, Dart, `AnimationController`, `provider`, Supabase (upsert), `go_router`, `flutter_test`

---

> **Supabase prerequisite (manual — do before running the app):**
> Run the following in your Supabase SQL editor if not already done:
> ```sql
> ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
>
> CREATE POLICY "Users can manage own preferences"
>   ON user_preferences
>   USING (auth.uid() = user_id)
>   WITH CHECK (auth.uid() = user_id);
> ```
> This is not a code task — it cannot be tested by `flutter test`.

---

### Task 1: Fix the animation so it loops continuously

**Files:**
- Modify: `lib/screens/onboarding_screen.dart` (around line 52–55, inside `initState`)

**Context:**
`_previewController` is an `AnimationController` created in `initState`. Currently it just calls `.forward()` once. We need it to restart automatically after each cycle with a 600ms pause, using `addStatusListener`. The listener must guard with `mounted` before resetting because `Future.delayed` fires asynchronously.

Do NOT use `.repeat()` — it blocks `pumpAndSettle()` in tests.

**Step 1: Write the failing test**

There is no automated test for "animation restarts after completion" — animation state isn't easily verified in widget tests. Skip the TDD step for this specific change and proceed directly to implementation. Run the full test suite after to confirm nothing broke.

**Step 2: Implement**

In `lib/screens/onboarding_screen.dart`, find `initState`. The current code is:

```dart
_previewController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2500),
)..forward();
```

Replace with:

```dart
_previewController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2500),
);
_previewController.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _previewController.reset();
        _previewController.forward();
      }
    });
  }
});
_previewController.forward();
```

Note: the `..forward()` cascade on the constructor is removed. The listener is attached first, then `.forward()` is called as a separate statement.

**Step 3: Run tests to verify nothing broke**

```bash
flutter test
```

Expected: All existing tests pass (count unchanged — this change doesn't affect test behaviour because `Future.delayed` doesn't hold the frame scheduler).

**Step 4: Commit**

```bash
git add lib/screens/onboarding_screen.dart
git commit -m "fix: loop onboarding style preview animation with 600ms pause"
```

---

### Task 2: Fix "Start reading →" button + add resilience test

**Files:**
- Modify: `lib/screens/onboarding_screen.dart` (the `_complete()` method, around line 82–88)
- Modify: `test/screens/onboarding_screen_test.dart` (add one new test)

**Context:**
`_complete()` currently has no error handling. If `widget.onStyleSelected(style)` throws (Supabase error, network failure, etc.), the exception propagates and `context.go('/app/library')` is never reached. The user sees a button that appears to do nothing.

The fix is a try/catch around `onStyleSelected` only — `onComplete` and `context.go` must always execute.

**Step 1: Write the failing test first**

Open `test/screens/onboarding_screen_test.dart`. Add this test inside the existing `group('OnboardingScreen', () {` block, after the last test:

```dart
testWidgets('Start reading navigates even if onStyleSelected throws',
    (tester) async {
  await tester.pumpWidget(_wrap(
    onStyleSelected: (_) async => throw Exception('save failed'),
  ));
  await tester.pumpAndSettle();
  await _scrollToStyleCard(tester);
  await tester.tap(find.text('Swipe down'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start reading →'));
  await tester.pumpAndSettle();
  expect(find.text('library'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: The new test FAILS — the exception propagates and the library screen is never shown.

**Step 3: Implement the fix**

In `lib/screens/onboarding_screen.dart`, find `_complete()`. The current code is:

```dart
Future<void> _complete() async {
  final style = _selectedStyle;
  if (style == null) return;
  await widget.onStyleSelected(style);
  await widget.onComplete();
  if (mounted) context.go('/app/library');
}
```

Replace with:

```dart
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

**Step 4: Run tests to verify all pass**

```bash
flutter test
```

Expected: All tests pass including the new resilience test.

**Step 5: Commit**

```bash
git add lib/screens/onboarding_screen.dart test/screens/onboarding_screen_test.dart
git commit -m "fix: catch onStyleSelected error so Start reading always navigates"
```
