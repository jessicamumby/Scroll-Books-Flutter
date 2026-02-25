# Library Screen Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the compact book list rows with large vertical cards grouped by curated section (Free Books / Trending / New), each with a unique per-book gradient cover, blurb snippet, and author · year line.

**Architecture:** Two tasks. (1) Add a `coverGradients` map to `catalogue.dart` — static data keyed by book ID, no `Book` model change. (2) Replace `ListView.builder` + `_BookRow` in `library_screen.dart` with a `SingleChildScrollView` containing section groups, each group rendered with a `_SectionHeader` widget and `_BookCard` widgets. Books appear in every section they belong to (a book in two sections appears twice). Tests updated to reflect duplicates.

**Tech Stack:** Flutter, Material 3, `go_router`, `provider`, `google_fonts`, `AppTheme`

---

### Task 1: Add `coverGradients` map to catalogue.dart

**Files:**
- Create: `test/data/catalogue_test.dart`
- Modify: `lib/data/catalogue.dart`

**Step 1: Write the failing test**

Create a new file `test/data/catalogue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/data/catalogue.dart';

void main() {
  test('every book has a coverGradient entry with 2 colours', () {
    for (final book in catalogue) {
      expect(
        coverGradients.containsKey(book.id),
        isTrue,
        reason: 'Missing gradient for ${book.id}',
      );
      expect(coverGradients[book.id]!.length, equals(2));
    }
  });
}
```

**Step 2: Run the test to verify it fails**

```bash
flutter test test/data/catalogue_test.dart
```

Expected: FAIL — `'coverGradients' isn't defined`

**Step 3: Add `coverGradients` to `lib/data/catalogue.dart`**

Add `import 'package:flutter/material.dart';` at the very top of the file (line 1), then append the map at the bottom of the file, after `getBookById`:

```dart
import 'package:flutter/material.dart';
```

```dart
const Map<String, List<Color>> coverGradients = {
  'moby-dick':           [Color(0xFF1A3A5C), Color(0xFF2E7D9A)],
  'pride-and-prejudice': [Color(0xFF8B5E6E), Color(0xFF5E7B6A)],
  'jane-eyre':           [Color(0xFF3D2B4E), Color(0xFF7A6070)],
  'don-quixote':         [Color(0xFF8B4513), Color(0xFFC4956A)],
  'great-gatsby':        [Color(0xFFB8952A), Color(0xFF2C4A3E)],
  'frankenstein':        [Color(0xFF1A3322), Color(0xFF4A5568)],
};
```

**Step 4: Run the test to verify it passes**

```bash
flutter test test/data/catalogue_test.dart
```

Expected: PASS — `+1: All tests passed!`

**Step 5: Run the full suite**

```bash
flutter test
```

Expected: `+53: All tests passed!`

**Step 6: Commit**

```bash
git add lib/data/catalogue.dart test/data/catalogue_test.dart
git commit -m "Add coverGradients map to catalogue for per-book cover colours"
```

---

### Task 2: Redesign LibraryScreen with sections and `_BookCard`

**Files:**
- Modify: `lib/screens/library_screen.dart`
- Modify: `test/screens/library_screen_test.dart`

**Context:** The current `LibraryScreen` uses a flat `ListView.builder` with `_BookRow` (48×64px cover, title, author, Add/In Library button). We replace the entire body and `_BookRow` with section groups and `_BookCard`. Books appear in every section they belong to, so a book in two sections renders twice — tests must account for this.

**Step 1: Add a failing test for section headers**

Open `test/screens/library_screen_test.dart` and add this test inside the existing `group('LibraryScreen', ...)` block, after the last test:

```dart
    testWidgets('shows section headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('FREE BOOKS'), findsOneWidget);
      expect(find.text('TRENDING'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
    });
```

**Step 2: Run the test to verify it fails**

```bash
flutter test test/screens/library_screen_test.dart
```

Expected: FAIL — `Expected: exactly one matching node ... FREE BOOKS: Found 0`

**Step 3: Replace `lib/screens/library_screen.dart` entirely**

Replace the file with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _sections = ['Free Books', 'Trending', 'New'];
  static const _labels = {
    'Free Books': 'FREE BOOKS',
    'Trending': 'TRENDING',
    'New': 'NEW',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Library')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in _sections) ...[
                  _SectionHeader(label: _labels[section]!),
                  for (final book in catalogue.where((b) => b.sections.contains(section)))
                    _BookCard(book: book, inLibrary: provider.library.contains(book.id)),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppTheme.amber,
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final bool inLibrary;
  const _BookCard({required this.book, required this.inLibrary});

  @override
  Widget build(BuildContext context) {
    final gradient = coverGradients[book.id] ?? [AppTheme.coverDeep, AppTheme.coverRich];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/app/library/${book.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.author} · ${book.year}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.tobacco,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          book.blurb,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.pewter,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: inLibrary
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.forestPale,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'In Library',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppTheme.forest,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : TextButton(
                                onPressed: () {
                                  final userId = Supabase.instance.client.auth
                                          .currentUser?.id ??
                                      '';
                                  Provider.of<AppProvider>(context,
                                          listen: false)
                                      .addToLibrary(userId, book.id);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Add to Library',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppTheme.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Update three existing tests in `test/screens/library_screen_test.dart`**

With sections, books appear multiple times (Moby Dick is in Free Books AND Trending, so renders twice). Three tests must be updated:

**Change 1** — `shows all 6 catalogue books`: `findsOneWidget` → `findsWidgets`

Find:
```dart
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(find.text('Frankenstein'), findsOneWidget);
```

Replace with:
```dart
      expect(find.text('Moby Dick'), findsWidgets);
      expect(find.text('Pride and Prejudice'), findsWidgets);
      expect(find.text('Frankenstein'), findsWidgets);
```

**Change 2** — `shows In Library badge for saved books`: Moby Dick appears in 2 sections → 2 badges. `findsOneWidget` → `findsNWidgets(2)`

Find:
```dart
      expect(find.text('In Library'), findsOneWidget);
```

Replace with:
```dart
      expect(find.text('In Library'), findsNWidgets(2));
```

**Change 3** — `tapping a book navigates to book detail`: `find.text('Moby Dick')` now matches 2 widgets; use `.first` to disambiguate.

Find:
```dart
      await tester.tap(find.text('Moby Dick'));
```

Replace with:
```dart
      await tester.tap(find.text('Moby Dick').first);
```

**Step 5: Run the library screen tests**

```bash
flutter test test/screens/library_screen_test.dart
```

Expected: `+5: All tests passed!`

**Step 6: Run the full suite**

```bash
flutter test
```

Expected: `+54: All tests passed!`

**Step 7: Commit**

```bash
git add lib/screens/library_screen.dart test/screens/library_screen_test.dart
git commit -m "Redesign LibraryScreen: section groups, large book cards, per-book gradient covers"
```
