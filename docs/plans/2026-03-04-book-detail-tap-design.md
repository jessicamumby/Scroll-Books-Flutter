# Book Detail Tap — Design

**Date:** 2026-03-04

## Goal

Tapping a book in the My Library tab navigates to the existing BookDetailScreen, giving users a way to start reading a book they haven't opened yet. Also replaces the disabled "In Library" placeholder with an active "Remove from Library" button (with confirmation).

---

## Problem

`MyLibraryList` uses hardcoded `_mockBooks` with no book IDs — tapping does nothing and the displayed books don't reflect the user's real library. `BookDetailScreen` exists and is fully routed (`/app/library/:id`) but is unreachable from the Library screen.

Additionally, once a book is in a user's library there is no way to remove it.

---

## Section 1 — MyLibraryList data layer

Remove the `_LibraryBook` struct and `_mockBooks` constant entirely.

`MyLibraryList` becomes a `Consumer<AppProvider>` widget that:

1. Reads `provider.library` (List of book IDs the user owns)
2. Looks up each via `getBookById(id)` from `catalogue.dart`
3. Computes progress %:
   - `(provider.progress[id]! / provider.bookTotalChunks[id]! * 100).clamp(0, 100).round()`
   - Falls back to `0` if either value is absent (book added but never opened)
4. If `getBookById(id)` returns null (data inconsistency): skip that entry silently

Stats bar (Books / Finished / Reading) computed from the real data.

The "last read" timestamp column is dropped — not stored per-book in the data model.

**Empty state** when `provider.library` is empty:
> "Your library is empty — discover a book to get started."

---

## Section 2 — Tap navigation

Each book card in `MyLibraryList` is wrapped in a `GestureDetector`:
```dart
onTap: () => context.go('/app/library/${book.id}')
```

Routes to the existing `BookDetailScreen` — no changes to that screen's routing or display logic.

**DiscoverStore:** A TODO comment added to `_DiscoverCard.build()`:
```dart
// TODO: wire tap → context.go('/app/library/:id') when Discover books have real IDs
```

---

## Section 3 — Remove from Library

### BookDetailScreen

Replace the disabled "In Library" `OutlinedButton` with an active "Remove from Library" button. Tapping shows a confirmation `AlertDialog`:

- Title: "Remove from library?"
- Body: "This will remove [title] from your library. Your reading progress will be kept."
- Actions: Cancel | Remove (tomato colour)

Confirming calls `provider.removeFromLibrary(userId, bookId)`.

### AppProvider

New method:
```dart
Future<void> removeFromLibrary(String userId, String bookId) async {
  library = library.where((id) => id != bookId).toList();
  notifyListeners();
  UserDataService.removeFromLibrary(userId, bookId).catchError((Object e, StackTrace st) {
    debugPrint('AppProvider.removeFromLibrary error: $e\n$st');
  });
}
```

### UserDataService

New static method that deletes the row from the Supabase `library` table:
```dart
static Future<void> removeFromLibrary(String userId, String bookId) async {
  await supabase
      .from('library')
      .delete()
      .eq('user_id', userId)
      .eq('book_id', bookId);
}
```

---

## Section 4 — Testing & error handling

| Test | Location |
|------|----------|
| `removeFromLibrary` removes book from list | `test/providers/app_provider_test.dart` |
| `removeFromLibrary` is a no-op if book not in list | `test/providers/app_provider_test.dart` |
| `BookDetailScreen` shows "Remove from Library" when `inLibrary: true` | `test/screens/book_detail_screen_test.dart` |
| Confirmation dialog appears on tap | `test/screens/book_detail_screen_test.dart` |
| Confirming calls `removeFromLibrary` | `test/screens/book_detail_screen_test.dart` |
| `MyLibraryList` renders books from `provider.library` | `test/widgets/my_library_list_test.dart` |
| `MyLibraryList` shows empty state when library is empty | `test/widgets/my_library_list_test.dart` |

**Error handling:**
- `removeFromLibrary` uses fire-and-forget `catchError` — local state updates immediately, Supabase failure is logged
- Optimistic update: if Supabase call fails, the book stays removed from the local list (acceptable MVP trade-off)

---

## Files Changed

| File | Change |
|------|--------|
| `lib/widgets/my_library_list.dart` | Replace mock data with real `AppProvider` data; add tap navigation |
| `lib/screens/book_detail_screen.dart` | Replace disabled "In Library" button with active "Remove from Library" + confirmation dialog |
| `lib/providers/app_provider.dart` | Add `removeFromLibrary()` method |
| `lib/services/user_data_service.dart` | Add `removeFromLibrary()` static method |
| `test/providers/app_provider_test.dart` | Add `removeFromLibrary` tests |
| `test/screens/book_detail_screen_test.dart` | **Create** — Remove from Library button + dialog tests |
| `test/widgets/my_library_list_test.dart` | **Create** — real data rendering + empty state tests |
