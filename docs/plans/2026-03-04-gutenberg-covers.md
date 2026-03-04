# Gutenberg Covers & Production Catalogue — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Trim the catalogue to 6 production books, show real Project Gutenberg cover images throughout the app, fix the reader to fetch any book by ID, and add a back button to BookDetailScreen.

**Architecture:** All catalogue data lives in `lib/data/catalogue.dart` — that's the single source of truth. Cover images are bundled as local assets in `assets/covers/`. The reader constructs a per-book Supabase Storage URL from a base env var + book ID. Navigation uses `context.push()` so the back stack is preserved.

**Tech Stack:** Flutter/Dart, GoRouter (`context.push`/`context.pop`), flutter_dotenv, `http` package, `Image.asset` with `errorBuilder` fallback.

---

### Task 1: Catalogue overhaul

**Files:**
- Modify: `lib/data/catalogue.dart`
- Create: `test/data/catalogue_test.dart`

**Step 1: Write the failing tests**

Create `test/data/catalogue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/data/catalogue.dart';

void main() {
  group('catalogue', () {
    test('contains exactly 6 production books', () {
      expect(catalogue.length, 6);
    });

    test('does not contain removed books', () {
      final ids = catalogue.map((b) => b.id).toSet();
      expect(ids.contains('jane-eyre'), isFalse);
      expect(ids.contains('don-quixote'), isFalse);
    });

    test('contains all production books', () {
      final ids = catalogue.map((b) => b.id).toSet();
      expect(ids, containsAll([
        'moby-dick',
        'frankenstein',
        'great-gatsby',
        'pride-and-prejudice',
        'romeo-and-juliet',
        'wuthering-heights',
      ]));
    });

    test('all books have hasChunks: true', () {
      for (final book in catalogue) {
        expect(book.hasChunks, isTrue,
            reason: '${book.id} should have hasChunks: true');
      }
    });

    test('coverGradients has entry for every book', () {
      for (final book in catalogue) {
        expect(coverGradients.containsKey(book.id), isTrue,
            reason: '${book.id} missing from coverGradients');
      }
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
flutter test test/data/catalogue_test.dart --no-pub
```

Expected: multiple failures (wrong count, missing books, hasChunks false on some).

**Step 3: Update `lib/data/catalogue.dart`**

Replace the entire `catalogue` list and `coverGradients` map with the following. Keep the `Book` class and `getBookById` function unchanged.

```dart
const List<Book> catalogue = [
  Book(
    id: 'moby-dick',
    title: 'Moby Dick',
    author: 'Herman Melville',
    year: 1851,
    blurb: "Call me Ishmael. An obsessive sea captain pursues a great white whale across the world's oceans in this monumental American epic of obsession, fate, and the sublime terror of nature.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'moby-dick',
    sections: ['Free Books', 'Trending'],
    genres: ['Adventure', 'Gothic'],
  ),
  Book(
    id: 'pride-and-prejudice',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    year: 1813,
    blurb: "It is a truth universally acknowledged… Austen's sharp wit and devastating social observation make this the definitive comedy of manners — and one of the greatest love stories ever written.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'pride-and-prejudice',
    sections: ['Free Books', 'New'],
    genres: ['Romance'],
  ),
  Book(
    id: 'great-gatsby',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    year: 1925,
    blurb: "Green light, old sport. Jazz Age excess and lost illusions on Long Island Sound. The definitive portrait of the American Dream — and its gorgeous, inevitable collapse.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'great-gatsby',
    sections: ['New', 'Trending'],
    genres: ['Satire'],
  ),
  Book(
    id: 'frankenstein',
    title: 'Frankenstein',
    author: 'Mary Shelley',
    year: 1818,
    blurb: "The modern Prometheus. A young scientist creates life and cannot live with what he has made. The founding text of science fiction, and still its most haunting moral question.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'frankenstein',
    sections: ['Free Books', 'Trending'],
    genres: ['Gothic', 'Sci-Fi'],
  ),
  Book(
    id: 'romeo-and-juliet',
    title: 'Romeo & Juliet',
    author: 'William Shakespeare',
    year: 1597,
    blurb: "Star-crossed lovers. Two young people from warring Veronese families fall desperately in love, setting in motion an unstoppable tragedy. Shakespeare's most celebrated romance — and his most heartbreaking.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'romeo-and-juliet',
    sections: ['Free Books', 'Trending'],
    genres: ['Romance', 'Tragedy'],
  ),
  Book(
    id: 'wuthering-heights',
    title: 'Wuthering Heights',
    author: 'Emily Brontë',
    year: 1847,
    blurb: "Wild and elemental. An orphan raised on the Yorkshire moors returns as a brooding, vengeful figure, his obsessive love for Cathy undiminished by time or cruelty. Emily Brontë's haunting tale of passion on the windswept moors.",
    price: 'FREE',
    isFree: true,
    hasChunks: true,
    cover: 'wuthering-heights',
    sections: ['Free Books', 'New'],
    genres: ['Gothic', 'Romance'],
  ),
];
```

Replace `coverGradients` with:

```dart
const Map<String, List<Color>> coverGradients = {
  'moby-dick':           [Color(0xFF1A3A5C), Color(0xFF2E7D9A)],
  'pride-and-prejudice': [Color(0xFF8B5E6E), Color(0xFF5E7B6A)],
  'great-gatsby':        [Color(0xFFB8952A), Color(0xFF2C4A3E)],
  'frankenstein':        [Color(0xFF1A3322), Color(0xFF4A5568)],
  'romeo-and-juliet':    [Color(0xFF8B1A2A), Color(0xFFC47080)],
  'wuthering-heights':   [Color(0xFF2D1F3D), Color(0xFF5C4A6E)],
};
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/data/catalogue_test.dart --no-pub
```

Expected: 5 tests pass.

**Step 5: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all previously passing tests still pass (the catalogue change does not affect widget tests since they use real book IDs like `moby-dick`).

**Step 6: Commit**

```bash
git add lib/data/catalogue.dart test/data/catalogue_test.dart
git commit -m "Trim catalogue to 6 production books; add Romeo & Juliet and Wuthering Heights"
```

---

### Task 2: Download cover assets

**Files:**
- Create: `assets/covers/romeo-and-juliet.jpg`
- Create: `assets/covers/wuthering-heights.jpg`
- Delete: `assets/covers/jane-eyre.jpg`
- Delete: `assets/covers/don-quixote.jpg`

> No unit tests for this task — it's a file operation. Visual verification after the next task.

**Step 1: Download covers from Project Gutenberg**

Run from the repo root:

```bash
curl -L "https://www.gutenberg.org/cache/epub/1112/pg1112.cover.medium.jpg" \
  -o assets/covers/romeo-and-juliet.jpg

curl -L "https://www.gutenberg.org/cache/epub/768/pg768.cover.medium.jpg" \
  -o assets/covers/wuthering-heights.jpg
```

**Step 2: Verify the files downloaded correctly**

```bash
ls -lh assets/covers/
```

Expected: `romeo-and-juliet.jpg` and `wuthering-heights.jpg` are non-zero in size (should be ~30–80 KB each). If either file is 0 bytes or very small (<1 KB), the download failed — try opening the URL directly in a browser to verify it's reachable.

**Step 3: Delete removed book covers**

```bash
rm assets/covers/jane-eyre.jpg
rm assets/covers/don-quixote.jpg
```

**Step 4: Commit**

```bash
git add assets/covers/
git commit -m "Swap cover assets: add Romeo & Juliet and Wuthering Heights, remove Jane Eyre and Don Quixote"
```

---

### Task 3: Library list — real cover thumbnails

**Files:**
- Modify: `lib/widgets/my_library_list.dart`
- Modify: `test/widgets/my_library_list_test.dart`

**Step 1: Write the failing test**

Add to the `'MyLibraryList'` group in `test/widgets/my_library_list_test.dart`:

```dart
testWidgets('renders Image widget for each book cover', (tester) async {
  final provider = AppProvider();
  provider.library = ['moby-dick', 'frankenstein'];
  await tester.pumpWidget(_wrap(provider));
  await tester.pumpAndSettle();
  // One Image per book card
  expect(find.byType(Image), findsNWidgets(2));
});
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/widgets/my_library_list_test.dart --no-pub
```

Expected: FAIL — `find.byType(Image)` finds 0 widgets (currently using Container gradient, not Image).

**Step 3: Update `_BookCard` in `lib/widgets/my_library_list.dart`**

Add `bookId` to `_BookCard`'s constructor and fields:

```dart
class _BookCard extends StatelessWidget {
  final String bookId;   // ADD THIS
  final String title;
  final String author;
  final Color color;
  final int progressPct;
  const _BookCard({
    required this.bookId,  // ADD THIS
    required this.title,
    required this.author,
    required this.color,
    required this.progressPct,
  });
```

Update the call site (inside `MyLibraryList.build`):

```dart
child: _BookCard(
  bookId: book.id,     // ADD THIS LINE
  title: book.title,
  author: book.author,
  color: color,
  progressPct: pct,
),
```

Inside `_BookCard.build`, replace the entire gradient spine `Container` (the 38×54 block with `Stack` containing the spine line and check icon) with:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: Image.asset(
    'assets/covers/$bookId.jpg',
    width: 38,
    height: 54,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
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
      child: isComplete
          ? const Center(
              child: Icon(Icons.check, color: Colors.white, size: 18),
            )
          : null,
    ),
  ),
),
```

> Note: `isComplete` is already defined earlier in `_BookCard.build` — keep that line in place.

**Step 4: Run tests**

```bash
flutter test test/widgets/my_library_list_test.dart --no-pub
```

Expected: all 4 tests pass.

**Step 5: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/widgets/my_library_list.dart test/widgets/my_library_list_test.dart
git commit -m "Show real cover images in Library list"
```

---

### Task 4: Discover store cleanup

**Files:**
- Modify: `lib/widgets/discover_store.dart`
- Create: `test/widgets/discover_store_test.dart`

**Step 1: Write the failing test**

Create `test/widgets/discover_store_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/discover_store.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('DiscoverStore', () {
    testWidgets('shows only production books', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DiscoverStore())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Wuthering Heights'), findsOneWidget);
      expect(find.text('Romeo & Juliet'), findsOneWidget);
      expect(find.text('Jane Eyre'), findsNothing);
      expect(find.text('Don Quixote'), findsNothing);
      expect(find.text('The Odyssey'), findsNothing);
      expect(find.text('Dracula'), findsNothing);
    });

    testWidgets('does not show Epic filter tag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DiscoverStore())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Epic'), findsNothing);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
flutter test test/widgets/discover_store_test.dart --no-pub
```

Expected: FAIL — Jane Eyre, Don Quixote, Odyssey, Dracula are currently found; Wuthering Heights and Romeo & Juliet are missing; Epic filter is present.

**Step 3: Update `lib/widgets/discover_store.dart`**

**3a.** Add `id` field to `_DiscoverBook`:

```dart
class _DiscoverBook {
  final String id;        // ADD THIS
  final String title;
  final String author;
  final Color color;
  final String price;
  final bool isFree;
  final String? tag;

  const _DiscoverBook({
    required this.id,     // ADD THIS
    required this.title,
    required this.author,
    required this.color,
    required this.price,
    required this.isFree,
    this.tag,
  });
}
```

**3b.** Replace `_discoverBooks` with:

```dart
const _discoverBooks = [
  _DiscoverBook(id: 'moby-dick', title: 'Moby Dick', author: 'Herman Melville', color: Color(0xFF1A3A5C), price: 'Free', isFree: true, tag: 'Classic'),
  _DiscoverBook(id: 'pride-and-prejudice', title: 'Pride and Prejudice', author: 'Jane Austen', color: Color(0xFF8B5E6E), price: 'Free', isFree: true, tag: 'Popular'),
  _DiscoverBook(id: 'great-gatsby', title: 'The Great Gatsby', author: 'F. Scott Fitzgerald', color: Color(0xFFB8952A), price: 'Free', isFree: true, tag: 'Short'),
  _DiscoverBook(id: 'frankenstein', title: 'Frankenstein', author: 'Mary Shelley', color: Color(0xFF1A3322), price: 'Free', isFree: true, tag: 'Classic'),
  _DiscoverBook(id: 'romeo-and-juliet', title: 'Romeo & Juliet', author: 'William Shakespeare', color: Color(0xFF8B1A2A), price: 'Free', isFree: true, tag: 'Classic'),
  _DiscoverBook(id: 'wuthering-heights', title: 'Wuthering Heights', author: 'Emily Brontë', color: Color(0xFF2D1F3D), price: 'Free', isFree: true, tag: 'Popular'),
];
```

**3c.** Replace `_filterTags` (remove 'Epic' — no matching books):

```dart
const _filterTags = ['All', 'Free', 'Classic', 'Popular', 'Short'];
```

**3d.** In `_DiscoverCard.build`, replace the cover area `Container` (the one with `height: 100` and gradient decoration) with:

```dart
SizedBox(
  height: 100,
  child: Stack(
    children: [
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: Image.asset(
          'assets/covers/${book.id}.jpg',
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                colors: [
                  book.color,
                  book.color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 10, top: 0, bottom: 0,
                  child: Container(
                    width: 2,
                    color: AppTheme.warmGold.withValues(alpha: 0.40),
                  ),
                ),
                Positioned(
                  left: 14, top: 0, bottom: 0,
                  child: Container(
                    width: 0.5,
                    color: AppTheme.warmGold.withValues(alpha: 0.25),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      book.title.toUpperCase(),
                      style: AppTheme.monoLabel(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (book.tag != null)
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              book.tag!.toUpperCase(),
              style: AppTheme.monoLabel(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
    ],
  ),
),
```

> The tag badge is now an overlay on top of the image (via the outer `Stack`), so it appears whether the image loads or the gradient fallback is shown.

**Step 4: Run tests**

```bash
flutter test test/widgets/discover_store_test.dart --no-pub
```

Expected: both tests pass.

**Step 5: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/widgets/discover_store.dart test/widgets/discover_store_test.dart
git commit -m "Trim Discover store to 6 production books; show cover images in grid"
```

---

### Task 5: Reader URL pattern

**Files:**
- Modify: `lib/screens/reader_screen.dart`
- Modify: `.env`
- Modify: `.env.example`

> **Manual step required before coding:** In the Supabase dashboard, rename the Moby Dick file from `pg2701.json` to `moby-dick.json`. Navigate to: Storage → books bucket → rename `pg2701.json` → `moby-dick.json`. The other uploaded books should already be named `frankenstein.json`, `great-gatsby.json`, `pride-and-prejudice.json`, `romeo-and-juliet.json`, `wuthering-heights.json`.

> No unit tests for this task — the URL construction is a one-line change inside `initState`, and testing it would require mocking `flutter_dotenv` and `http`. Manual smoke testing on device covers it.

**Step 1: Update `.env`**

Change line 3 from:
```
BOOKS_BUCKET_URL=https://macttsmfxjwgtosiqzeb.supabase.co/storage/v1/object/public/books/pg2701.json
```
To:
```
BOOKS_BUCKET_BASE_URL=https://macttsmfxjwgtosiqzeb.supabase.co/storage/v1/object/public/books
```

**Step 2: Update `.env.example`**

Change line 3 from:
```
BOOKS_BUCKET_URL=
```
To:
```
BOOKS_BUCKET_BASE_URL=
```

**Step 3: Update `lib/screens/reader_screen.dart`**

Find these two lines (around line 90–91):
```dart
final url = dotenv.env['BOOKS_BUCKET_URL'] ?? '';
if (url.isEmpty) throw Exception('BOOKS_BUCKET_URL not set');
```

Replace with:
```dart
final baseUrl = dotenv.env['BOOKS_BUCKET_BASE_URL'] ?? '';
if (baseUrl.isEmpty) throw Exception('BOOKS_BUCKET_BASE_URL not set');
final url = '$baseUrl/${widget.bookId}.json';
```

(The `final response = await http.get(Uri.parse(url));` line immediately after stays unchanged.)

**Step 4: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass (reader screen tests don't mock dotenv, so this is about not breaking anything).

**Step 5: Commit**

```bash
git add lib/screens/reader_screen.dart .env.example
git commit -m "Per-book reader URL: BOOKS_BUCKET_BASE_URL + bookId.json"
```

> `.env` is git-ignored and should NOT be committed.

---

### Task 6: Back button on BookDetailScreen

**Files:**
- Modify: `lib/widgets/my_library_list.dart`
- Modify: `lib/screens/book_detail_screen.dart`
- Modify: `test/screens/book_detail_screen_test.dart`

**Step 1: Write the failing test**

Add to the `'BookDetailScreen'` group in `test/screens/book_detail_screen_test.dart`:

```dart
testWidgets('shows arrow_back_ios back button', (tester) async {
  await tester.pumpWidget(_wrap('moby-dick'));
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/book_detail_screen_test.dart --no-pub
```

Expected: FAIL — no `Icons.arrow_back_ios` currently in the widget tree.

**Step 3: Update `lib/widgets/my_library_list.dart`**

Change `context.go` to `context.push` (one line, inside the `GestureDetector.onTap`):

```dart
onTap: () => context.push('/app/library/${book.id}'),
```

**Step 4: Update `lib/screens/book_detail_screen.dart`**

Find the `AppBar()` on the non-null book path (inside `Consumer<AppProvider>.builder`). Replace:

```dart
appBar: AppBar(),
```

With:

```dart
appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios),
    onPressed: () => context.pop(),
  ),
),
```

> The `appBar: AppBar()` on the "book not found" path (outside the Consumer) can also be updated the same way for consistency.

**Step 5: Run tests**

```bash
flutter test test/screens/book_detail_screen_test.dart --no-pub
```

Expected: all 5 tests pass (4 existing + 1 new).

**Step 6: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass. Note: the `my_library_list_test.dart` navigation test uses `context.push` now — the GoRouter in the test has `/app/library/:id` registered, so the navigation still works and the test still passes.

**Step 7: Commit**

```bash
git add lib/widgets/my_library_list.dart lib/screens/book_detail_screen.dart test/screens/book_detail_screen_test.dart
git commit -m "Add arrow_back_ios back button to BookDetailScreen; use context.push for library navigation"
```
