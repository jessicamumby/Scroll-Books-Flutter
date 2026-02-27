# Onboarding Style Card Bugs — Design Doc

**Date:** 2026-02-27

---

## Goal

Fix two bugs on the 4th onboarding card ("How do you like to read?"):

1. **Animation freezes** after one play — should loop continuously with a pause between cycles.
2. **"Start reading →" button does nothing** — an unhandled exception in `_complete()` prevents navigation; compounded by missing Supabase RLS policies blocking the upsert.

---

## Root Causes

### Bug 1 — Animation freezes

During development `AnimationController.repeat()` was replaced with `.forward()` to unblock `pumpAndSettle()` in widget tests. The result is the animation plays once on card entry and then stops. Users who miss the first play see static tiles with no motion cue.

### Bug 2 — Button does nothing

`_complete()` calls `widget.onStyleSelected(style)` with no error handling. `onStyleSelected` calls `AppProvider.setReadingStyle()` → `UserDataService.saveReadingStyle()` → Supabase upsert on `user_preferences`. If the upsert throws (RLS policy blocking, network error, etc.), the exception propagates unhandled out of `_complete()` and `context.go('/app/library')` is never reached. Flutter catches the async exception at the framework level, so the app doesn't crash — the button silently does nothing.

The `user_preferences` table was created without RLS policies. Supabase enables RLS by default on new tables, which blocks all access until policies are added.

### Why no test caught this

A test exists for "Start reading navigates to library" but it mocks `onStyleSelected` as a simple lambda. The mock never exercises the real Supabase path and cannot catch upsert failures. The missing test is one that passes a *throwing* `onStyleSelected` and asserts navigation still reaches the library.

---

## Design

### Fix 1: Looping animation

In `_OnboardingScreenState.initState()`, attach a `StatusListener` that restarts the animation after a 600ms pause on completion:

```dart
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

`Future.delayed` does not hold the Flutter frame scheduler, so `pumpAndSettle()` in tests still settles after the first forward pass. No test changes needed.

The existing `onPageChanged` reset (replays on return to card 4) is unchanged.

### Fix 2a: Code resilience in `_complete()`

Wrap `onStyleSelected` in try/catch so navigation always proceeds regardless of save outcome:

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

### Fix 2b: Supabase RLS policies

Run in the Supabase SQL editor:

```sql
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own preferences"
  ON user_preferences
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Fix 2c: New resilience test

```dart
testWidgets('Start reading navigates even if onStyleSelected throws', (tester) async {
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

---

## Files Touched

| File | Change |
|------|--------|
| `lib/screens/onboarding_screen.dart` | `addStatusListener` loop in `initState()`; try/catch in `_complete()` |
| `test/screens/onboarding_screen_test.dart` | New resilience test |

---

## Out of Scope

- Showing an error message if style save fails (silent fallback is acceptable)
- Per-book reading style
