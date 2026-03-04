# Resume Last Book — Design

**Date:** 2026-03-04

## Goal

When a user opens the app and taps the Read tab, automatically resume the last book they were reading rather than showing the empty "Start Reading" state.

---

## Problem

`ReadTabScreen` has auto-navigation logic in `didChangeDependencies` that checks `provider.progress` for any book with progress > 0. However, `didChangeDependencies` fires before `AppProvider` has loaded data from SharedPreferences/Supabase, so `provider.progress` is empty at that moment and navigation never triggers. The user sees the empty state instead of their book.

---

## Solution

Persist a dedicated `lastReadBookId` key to SharedPreferences the moment a user opens any book in the reader. `ReadTabScreen` reads this value reactively and navigates as soon as it's available (~50ms, SharedPreferences load), well before Supabase data arrives. No flash.

---

## Section 1 — AppProvider

Add `String? lastReadBookId` field.

In `_loadLocalStats` (runs first, before Supabase fetch), read:
```dart
lastReadBookId = prefs.getString('last_read_book_id');
```

Add a public method called by the reader when a book opens:
```dart
void setLastReadBook(String bookId) {
  lastReadBookId = bookId;
  SharedPreferences.getInstance().then((p) => p.setString('last_read_book_id', bookId));
  notifyListeners();
}
```

SharedPreferences key: `'last_read_book_id'`

---

## Section 2 — ReaderScreen

In `_loadReader`, after initialisation completes, call:
```dart
if (mounted) context.read<AppProvider>().setLastReadBook(widget.bookId);
```

This ensures the key is always up-to-date with whichever book the user most recently opened.

---

## Section 3 — ReadTabScreen

Replace the `didChangeDependencies` one-shot approach with a reactive `context.watch<AppProvider>()` check in `build()`.

When `provider.lastReadBookId != null` and not yet navigated, schedule navigation via `addPostFrameCallback`. The `_navigated` guard remains to prevent repeated triggers.

The empty state ("Start Reading") remains as the fallback for brand-new users who have never opened a book.

---

## Files Changed

| File | Change |
|---|---|
| `lib/providers/app_provider.dart` | Add `lastReadBookId` field; load from SharedPreferences in `_loadLocalStats`; add `setLastReadBook()` method |
| `lib/screens/reader_screen.dart` | Call `provider.setLastReadBook(widget.bookId)` in `_loadReader` |
| `lib/screens/read_tab_screen.dart` | Replace `didChangeDependencies` with reactive `context.watch` in `build()` |
| `test/providers/app_provider_test.dart` | Add test: `setLastReadBook` sets field and persists |
| `test/screens/read_tab_screen_test.dart` | **Create** — navigates when `lastReadBookId` set; shows empty state when null |
