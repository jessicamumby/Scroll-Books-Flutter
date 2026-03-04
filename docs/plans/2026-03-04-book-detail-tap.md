# Book Detail Tap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tapping a book in the My Library tab navigates to the existing BookDetailScreen; replace the disabled "In Library" button with an active "Remove from Library" button (with confirmation dialog).

**Architecture:** Four tasks in dependency order: add `removeFromLibrary` to `AppProvider` (unit-testable, no Supabase in tests), add the matching `UserDataService` method (no unit test — mirrors `addToLibrary` pattern), update `BookDetailScreen` with the remove button and dialog, then rewrite `MyLibraryList` to use real provider data with tap navigation.

**Tech Stack:** Flutter, `provider` (ChangeNotifier + Consumer/context.watch), `go_router`, `shared_preferences`, Supabase

---

### Task 1: Add `removeFromLibrary` to AppProvider

**Files:**
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/providers/app_provider_test.dart`

**Context:** `AppProvider` is at `lib/providers/app_provider.dart`. The new method updates `library` synchronously (optimistic update), calls `notifyListeners()`, then fires the Supabase delete in the background — same fire-and-forget pattern as `setBookTotalChunks` (lines 259–267). Guard with `if (userId.isNotEmpty)` so unit tests with empty userId don't touch Supabase.

**Step 1: Write the failing tests**

Add a new group to `test/providers/app_provider_test.dart` after the `bookmarkResetAt` group:

```dart
group('AppProvider.removeFromLibrary', () {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('removes book from library list', () {
    final provider = AppProvider();
    provider.library = ['moby-dick', 'frankenstein'];
    provider.removeFromLibrary('', 'moby-dick');
    expect(provider.library, ['frankenstein']);
    expect(provider.library.contains('moby-dick'), isFalse);
  });

  test('is a no-op if book not in library', () {
    final provider = AppProvider();
    provider.library = ['moby-dick'];
    provider.removeFromLibrary('', 'frankenstein');
    expect(provider.library, ['moby-dick']);
  });
});
```

**Step 2: Run tests to verify they fail**

```bash
(cd <worktree> && flutter test test/providers/app_provider_test.dart --no-pub 2>&1)
```

Expected: 2 new failures — `method 'removeFromLibrary' not found`.

**Step 3: Add the method to AppProvider**

Add after the `setLastReadBook` method (end of class, before closing `}`):

```dart
Future<void> removeFromLibrary(String userId, String bookId) async {
  library = library.where((id) => id != bookId).toList();
  notifyListeners();
  if (userId.isNotEmpty) {
    UserDataService.removeFromLibrary(userId, bookId).catchError(
      (Object e, StackTrace st) {
        debugPrint('AppProvider.removeFromLibrary error: $e\n$st');
      },
    );
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
(cd <worktree> && flutter test test/providers/app_provider_test.dart --no-pub 2>&1)
```

Expected: all tests pass (previous count + 2 new).

**Step 5: Commit**

```bash
(cd <worktree> && git add lib/providers/app_provider.dart test/providers/app_provider_test.dart && git commit -m "feat: add removeFromLibrary to AppProvider")
```

---

### Task 2: Add `removeFromLibrary` to UserDataService

**Files:**
- Modify: `lib/services/user_data_service.dart`

**Context:** `UserDataService` is at `lib/services/user_data_service.dart`. The `library` Supabase table has columns `user_id` and `book_id`. Mirror the `addToLibrary` method (line 73) — same table, same column names, just a `delete` instead of `upsert`. No unit test needed: this is a single Supabase call that requires a live connection.

**Step 1: Add the method**

Add after `addToLibrary` (after line 77):

```dart
static Future<void> removeFromLibrary(String userId, String bookId) async {
  await supabase
      .from('library')
      .delete()
      .eq('user_id', userId)
      .eq('book_id', bookId);
}
```

**Step 2: Run the full test suite to check for regressions**

```bash
(cd <worktree> && flutter test --no-pub 2>&1 | tail -5)
```

Expected: same pass count as before (no regressions).

**Step 3: Commit**

```bash
(cd <worktree> && git add lib/services/user_data_service.dart && git commit -m "feat: add removeFromLibrary to UserDataService")
```

---

### Task 3: Update BookDetailScreen — Remove from Library button

**Files:**
- Modify: `lib/screens/book_detail_screen.dart`
- Create: `test/screens/book_detail_screen_test.dart`

**Context:** `BookDetailScreen` is at `lib/screens/book_detail_screen.dart`. It is a `StatelessWidget` using `Consumer<AppProvider>`. Currently the library button is a disabled `OutlinedButton` that shows "In Library" when `inLibrary == true` (line 111–122). Replace with an active "Remove from Library" button that shows a confirmation `AlertDialog`. Define the dialog logic as a private top-level function `_showRemoveDialog` to keep the `build` method readable.

**Step 1: Create the failing tests**

Create `test/screens/book_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/book_detail_screen.dart';

Widget _wrap(String bookId, {bool inLibrary = false}) {
  final provider = AppProvider();
  if (inLibrary) provider.library = [bookId];
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light,
      home: BookDetailScreen(bookId: bookId),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BookDetailScreen', () {
    testWidgets('shows "Add to Library" when book is not in library',
        (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      expect(find.text('Add to Library'), findsOneWidget);
      expect(find.text('Remove from Library'), findsNothing);
    });

    testWidgets('shows "Remove from Library" when book is in library',
        (tester) async {
      await tester.pumpWidget(_wrap('moby-dick', inLibrary: true));
      await tester.pumpAndSettle();
      expect(find.text('Remove from Library'), findsOneWidget);
      expect(find.text('Add to Library'), findsNothing);
    });

    testWidgets('tapping "Remove from Library" shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(_wrap('moby-dick', inLibrary: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Library'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from library?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('tapping Cancel closes dialog without removing book',
        (tester) async {
      final provider = AppProvider();
      provider.library = ['moby-dick'];
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const BookDetailScreen(bookId: 'moby-dick'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from library?'), findsNothing);
      expect(provider.library, contains('moby-dick'));
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
(cd <worktree> && flutter test test/screens/book_detail_screen_test.dart --no-pub 2>&1)
```

Expected: tests about "Remove from Library" fail — button not found, dialog not found.

**Step 3: Update BookDetailScreen**

Add this private function at the top level of `lib/screens/book_detail_screen.dart` (after the imports, before the class definition):

```dart
Future<void> _showRemoveDialog(
  BuildContext context,
  AppProvider provider,
  Book book,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove from library?'),
      content: Text(
        'This will remove ${book.title} from your library. '
        'Your reading progress will be kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.tomato),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) provider.removeFromLibrary(userId, book.id);
  }
}
```

Then replace the existing `OutlinedButton` block (lines 111–122) with:

```dart
SizedBox(
  width: double.infinity,
  child: inLibrary
      ? OutlinedButton(
          onPressed: () => _showRemoveDialog(context, provider, book),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.tomato,
            side: const BorderSide(color: AppTheme.tomato),
          ),
          child: const Text('Remove from Library'),
        )
      : OutlinedButton(
          onPressed: () {
            final userId = supabase.auth.currentUser?.id;
            if (userId != null) provider.addToLibrary(userId, book.id);
          },
          child: const Text('Add to Library'),
        ),
),
```

**Step 4: Run tests to verify they pass**

```bash
(cd <worktree> && flutter test test/screens/book_detail_screen_test.dart --no-pub 2>&1)
```

Expected: all 4 tests pass.

**Step 5: Run the full suite to check for regressions**

```bash
(cd <worktree> && flutter test --no-pub 2>&1 | tail -5)
```

Expected: previous pass count + 4 new tests (no regressions).

**Step 6: Commit**

```bash
(cd <worktree> && git add lib/screens/book_detail_screen.dart test/screens/book_detail_screen_test.dart && git commit -m "feat: replace 'In Library' with 'Remove from Library' button on BookDetailScreen")
```

---

### Task 4: Rewrite MyLibraryList with real data + tap navigation

**Files:**
- Modify: `lib/widgets/my_library_list.dart`
- Modify: `lib/widgets/discover_store.dart`
- Create: `test/widgets/my_library_list_test.dart`

**Context:** `MyLibraryList` is at `lib/widgets/my_library_list.dart`. It currently uses a hardcoded `_mockBooks` list with no book IDs — replace entirely with `context.watch<AppProvider>()`. The `_StatCard` and `_BookCard` private classes stay; `_BookCard` signature changes from accepting `_LibraryBook` to accepting named fields `title`, `author`, `color`, `progressPct`. `DiscoverStore` just needs a TODO comment added — no logic change.

Cover colour source: `coverGradients` from `lib/data/catalogue.dart` is `Map<String, List<Color>>`. Use `.first` of the gradient as the spine colour, falling back to `AppTheme.coverDeep`.

Progress calculation:
- `p = provider.progress[book.id] ?? 0`
- `t = provider.bookTotalChunks[book.id] ?? 0`
- `pct = t > 0 ? (p / t * 100).clamp(0.0, 100.0).round() : 0`
- Finished: `t > 0 && p >= t - 1`

**Step 1: Create the failing tests**

Create `test/widgets/my_library_list_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/widgets/my_library_list.dart';

Widget _wrap(AppProvider provider) => ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: '/lib',
          routes: [
            GoRoute(
              path: '/lib',
              builder: (_, __) => const Scaffold(body: MyLibraryList()),
            ),
            GoRoute(
              path: '/app/library/:id',
              builder: (_, __) => const Scaffold(body: Text('detail')),
            ),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MyLibraryList', () {
    testWidgets('shows empty state when library is empty', (tester) async {
      await tester.pumpWidget(_wrap(AppProvider()));
      await tester.pumpAndSettle();
      expect(
        find.text('Your library is empty — discover a book to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('shows books from provider.library', (tester) async {
      final provider = AppProvider();
      provider.library = ['moby-dick', 'frankenstein'];
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Frankenstein'), findsOneWidget);
    });

    testWidgets('tapping a book navigates to /app/library/:id', (tester) async {
      final provider = AppProvider();
      provider.library = ['moby-dick'];
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moby Dick'));
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
(cd <worktree> && flutter test test/widgets/my_library_list_test.dart --no-pub 2>&1)
```

Expected: "shows books" and "tapping a book" fail — widget still shows mock data.

**Step 3: Replace MyLibraryList implementation**

Replace the entire contents of `lib/widgets/my_library_list.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class MyLibraryList extends StatelessWidget {
  const MyLibraryList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final libraryIds = provider.library;

    if (libraryIds.isEmpty) {
      return Container(
        color: AppTheme.warmWhite,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Your library is empty — discover a book to get started.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                color: AppTheme.inkMid,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final books = libraryIds.map(getBookById).whereType<Book>().toList();

    int finished = 0;
    int reading = 0;
    for (final book in books) {
      final p = provider.progress[book.id] ?? 0;
      final t = provider.bookTotalChunks[book.id] ?? 0;
      if (t > 0 && p >= t - 1) {
        finished++;
      } else if (p > 0) {
        reading++;
      }
    }

    return Container(
      color: AppTheme.warmWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatCard(value: books.length, label: 'BOOKS'),
                const SizedBox(width: 10),
                _StatCard(value: finished, label: 'FINISHED'),
                const SizedBox(width: 10),
                _StatCard(value: reading, label: 'READING'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'MY BOOKS',
              style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
            ),
            const SizedBox(height: 12),
            ...books.asMap().entries.map((entry) {
              final i = entry.key;
              final book = entry.value;
              final p = provider.progress[book.id] ?? 0;
              final t = provider.bookTotalChunks[book.id] ?? 0;
              final pct = t > 0 ? (p / t * 100).clamp(0.0, 100.0).round() : 0;
              final color = (coverGradients[book.id] ??
                      [AppTheme.coverDeep, AppTheme.coverRich])
                  .first;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i < books.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => context.go('/app/library/${book.id}'),
                  child: _BookCard(
                    title: book.title,
                    author: book.author,
                    color: color,
                    progressPct: pct,
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String title;
  final String author;
  final Color color;
  final int progressPct;
  const _BookCard({
    required this.title,
    required this.author,
    required this.color,
    required this.progressPct,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = progressPct == 100;
    final progressFraction = progressPct / 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 3,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.5,
                    color: AppTheme.warmGold.withValues(alpha: 0.40),
                  ),
                ),
                if (isComplete)
                  const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  author,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11.5,
                    color: AppTheme.inkMid,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.parchment,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progressFraction,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: isComplete
                                    ? const LinearGradient(
                                        colors: [AppTheme.sage, AppTheme.sage],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          AppTheme.tomato,
                                          AppTheme.amber,
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progressPct%',
                      style: AppTheme.monoLabel(
                        fontSize: 10,
                        color: AppTheme.inkLight,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Add TODO comment to DiscoverStore**

In `lib/widgets/discover_store.dart`, at the top of `_DiscoverCard.build()` (line 224, before `return Container(`), add:

```dart
// TODO: wire tap → context.go('/app/library/:id') when Discover books have real IDs
```

**Step 5: Run tests to verify they pass**

```bash
(cd <worktree> && flutter test test/widgets/my_library_list_test.dart --no-pub 2>&1)
```

Expected: all 3 tests pass.

**Step 6: Run the full suite to check for regressions**

```bash
(cd <worktree> && flutter test --no-pub 2>&1 | tail -5)
```

Expected: previous pass count + 3 new tests (no regressions).

**Step 7: Commit**

```bash
(cd <worktree> && git add lib/widgets/my_library_list.dart lib/widgets/discover_store.dart test/widgets/my_library_list_test.dart && git commit -m "feat: wire MyLibraryList to real AppProvider data with tap navigation")
```
