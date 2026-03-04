# Resume Last Book Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When a user taps the Read tab, automatically resume the last book they were reading instead of showing the empty "Start Reading" state.

**Architecture:** Persist a `lastReadBookId` string to SharedPreferences the moment the reader opens any book. `ReadTabScreen` watches `AppProvider` reactively and navigates as soon as this value is available (~50ms, well before Supabase data arrives). The empty state remains as the fallback for brand-new users only.

**Tech Stack:** Flutter, `shared_preferences`, `provider` (ChangeNotifier), `go_router`

---

### Task 1: Add `lastReadBookId` to AppProvider

**Files:**
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/providers/app_provider_test.dart`

**Context:** `AppProvider` is in `lib/providers/app_provider.dart`. SharedPreferences key to use: `'last_read_book_id'`. The `_loadLocalStats` method (line 24) already reads multiple prefs keys — add to it. Follow the same fire-and-forget pattern used by `setBookTotalChunks` (lines 257–265) for the async save.

**Step 1: Write the failing tests**

Add a new group to `test/providers/app_provider_test.dart`:

```dart
group('AppProvider.lastReadBookId', () {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('is null initially', () {
    final provider = AppProvider();
    expect(provider.lastReadBookId, isNull);
  });

  test('setLastReadBook sets the field', () {
    final provider = AppProvider();
    provider.setLastReadBook('moby-dick');
    expect(provider.lastReadBookId, 'moby-dick');
  });

  test('setLastReadBook overwrites previous value', () {
    final provider = AppProvider();
    provider.setLastReadBook('moby-dick');
    provider.setLastReadBook('frankenstein');
    expect(provider.lastReadBookId, 'frankenstein');
  });
});
```

**Step 2: Run tests to verify they fail**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && flutter test test/providers/app_provider_test.dart --no-pub 2>&1)
```

Expected: 3 new failures — `getter 'lastReadBookId' not found`, `method 'setLastReadBook' not found`.

**Step 3: Add the field and method to AppProvider**

In `lib/providers/app_provider.dart`:

1. Add the field after line 22 (`String? bookmarkResetAt;`):

```dart
String? lastReadBookId;
```

2. In `_loadLocalStats` (after line 31, `bookmarkResetAt = prefs.getString('bookmark_reset_at');`), add:

```dart
lastReadBookId = prefs.getString('last_read_book_id');
```

3. Add the new public method at the end of the class (before the closing `}`):

```dart
void setLastReadBook(String bookId) {
  lastReadBookId = bookId;
  notifyListeners();
  SharedPreferences.getInstance().then(
    (prefs) => prefs.setString('last_read_book_id', bookId),
  ).catchError((Object e, StackTrace st) {
    debugPrint('AppProvider.setLastReadBook error: $e\n$st');
  });
}
```

**Step 4: Run tests to verify they pass**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && flutter test test/providers/app_provider_test.dart --no-pub 2>&1)
```

Expected: all tests pass (previous count + 3 new).

**Step 5: Commit**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && git add lib/providers/app_provider.dart test/providers/app_provider_test.dart && git commit -m "feat: add lastReadBookId to AppProvider with SharedPreferences persistence")
```

---

### Task 2: Call `setLastReadBook` from ReaderScreen

**Files:**
- Modify: `lib/screens/reader_screen.dart`

**Context:** `_loadReader` is at line 57. After the chunks load successfully and `mounted` is checked (line 97), the reader calls `setBookTotalChunks`. Add `setLastReadBook` in the same block. No new test needed — this is a one-liner wiring call; correctness is verified by the ReadTabScreen test in Task 3 and manual smoke testing.

**Step 1: Add the call in `_loadReader`**

In `lib/screens/reader_screen.dart`, find the block starting at line 97:

```dart
if (mounted) {
  Provider.of<AppProvider>(context, listen: false)
      .setBookTotalChunks(widget.bookId, chunks.length);
```

Add one line immediately after `setBookTotalChunks`:

```dart
if (mounted) {
  final provider = Provider.of<AppProvider>(context, listen: false);
  provider.setBookTotalChunks(widget.bookId, chunks.length);
  provider.setLastReadBook(widget.bookId);
```

**Step 2: Run the full test suite to check for regressions**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && flutter test --no-pub 2>&1 | tail -5)
```

Expected: same pass count as before (no regressions).

**Step 3: Commit**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && git add lib/screens/reader_screen.dart && git commit -m "feat: persist lastReadBookId when reader opens a book")
```

---

### Task 3: Make ReadTabScreen navigate reactively

**Files:**
- Modify: `lib/screens/read_tab_screen.dart`
- Create: `test/screens/read_tab_screen_test.dart`

**Context:** `ReadTabScreen` is at `lib/screens/read_tab_screen.dart`. Currently it uses `didChangeDependencies` (line 20) with `context.read` — a one-shot check that fires before data loads. Replace with a `context.watch` in `build()` that reacts to provider changes. Keep the `_navigated` bool guard to prevent repeated navigation.

The existing empty state ("Start Reading", "Pick a book from your Library to begin", "Go to Library" button) must remain for users with `lastReadBookId == null`.

**Step 1: Write the failing tests**

Create `test/screens/read_tab_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/read_tab_screen.dart';

AppProvider _provider({String? lastReadBookId}) {
  final p = AppProvider();
  p.lastReadBookId = lastReadBookId;
  return p;
}

Widget _wrap({String? lastReadBookId}) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: _provider(lastReadBookId: lastReadBookId),
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: '/read-tab',
          routes: [
            GoRoute(
              path: '/read-tab',
              builder: (_, __) => const ReadTabScreen(),
            ),
            GoRoute(
              path: '/read/:bookId',
              builder: (_, __) => const Scaffold(body: Text('reader')),
            ),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReadTabScreen', () {
    testWidgets('shows empty state when lastReadBookId is null', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Start Reading'), findsOneWidget);
      expect(find.text('Go to Library'), findsOneWidget);
    });

    testWidgets('navigates to reader when lastReadBookId is set', (tester) async {
      await tester.pumpWidget(_wrap(lastReadBookId: 'moby-dick'));
      await tester.pumpAndSettle();
      expect(find.text('reader'), findsOneWidget);
      expect(find.text('Start Reading'), findsNothing);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && flutter test test/screens/read_tab_screen_test.dart --no-pub 2>&1)
```

Expected: "navigates to reader" test fails — navigation never triggers because `didChangeDependencies` fires before data loads.

**Step 3: Replace `ReadTabScreen` implementation**

Replace the entire contents of `lib/screens/read_tab_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class ReadTabScreen extends StatefulWidget {
  const ReadTabScreen({super.key});

  @override
  State<ReadTabScreen> createState() => _ReadTabScreenState();
}

class _ReadTabScreenState extends State<ReadTabScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lastBookId = provider.lastReadBookId;

    if (!_navigated && lastBookId != null) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/read/$lastBookId');
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📜', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                Text(
                  'Start Reading',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pick a book from your Library to begin',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    color: AppTheme.inkMid,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/app/library'),
                  child: const Text('Go to Library'),
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
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && flutter test test/screens/read_tab_screen_test.dart --no-pub 2>&1)
```

Expected: both tests pass.

**Step 5: Run the full suite to check for regressions**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && flutter test --no-pub 2>&1 | tail -5)
```

Expected: previous pass count + 2 new tests (no regressions).

**Step 6: Commit**

```bash
(cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter && git add lib/screens/read_tab_screen.dart test/screens/read_tab_screen_test.dart && git commit -m "feat: auto-resume last book on Read tab using reactive lastReadBookId")
```
