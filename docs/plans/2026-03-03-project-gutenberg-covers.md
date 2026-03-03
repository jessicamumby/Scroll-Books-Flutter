# Project Gutenberg Covers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace placeholder cover images with real Project Gutenberg covers, remove the amber tint from library cards, and show a centred portrait cover thumbnail on the book detail screen.

**Architecture:** Three independent tasks. Task 1 replaces asset files (no code change). Task 2 removes a `ColorFiltered` wrapper from `library_screen.dart` and inverts an existing test. Task 3 replaces a gradient container in `book_detail_screen.dart` with a `ClipRRect`-wrapped `Image.asset` and adds a new widget test.

**Tech Stack:** Flutter/Dart, `flutter_test`, `curl` (for downloading assets)

---

### Task 1: Download and replace Gutenberg cover assets

**Files:**
- Replace: `assets/covers/moby-dick.jpg`
- Replace: `assets/covers/pride-and-prejudice.jpg`
- Replace: `assets/covers/jane-eyre.jpg`
- Replace: `assets/covers/don-quixote.jpg`
- Replace: `assets/covers/great-gatsby.jpg`
- Replace: `assets/covers/frankenstein.jpg`

No code changes. No new tests. `pubspec.yaml` already declares `assets/covers/`.

**Step 1: Download the 6 Gutenberg covers**

Run from the project root:

```bash
curl -L "https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg" -o assets/covers/moby-dick.jpg
curl -L "https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg" -o assets/covers/pride-and-prejudice.jpg
curl -L "https://www.gutenberg.org/cache/epub/1260/pg1260.cover.medium.jpg" -o assets/covers/jane-eyre.jpg
curl -L "https://www.gutenberg.org/cache/epub/996/pg996.cover.medium.jpg" -o assets/covers/don-quixote.jpg
curl -L "https://www.gutenberg.org/cache/epub/64317/pg64317.cover.medium.jpg" -o assets/covers/great-gatsby.jpg
curl -L "https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg" -o assets/covers/frankenstein.jpg
```

**Step 2: Verify each file is a valid JPEG (not an error page)**

```bash
file assets/covers/*.jpg
```

Expected: each file reports `JPEG image data`. If any says `HTML document` or `ASCII text`, the URL failed — check the Gutenberg ID.

**Step 3: Run the test suite**

```bash
flutter test --no-pub
```

Expected: all 129 tests pass. Asset files don't affect unit/widget tests.

**Step 4: Commit**

```bash
git add assets/covers/
git commit -m "feat: replace placeholder covers with Project Gutenberg images"
```

---

### Task 2: Remove amber ColorFilter from library screen

**Files:**
- Modify: `test/screens/library_screen_test.dart:76-80`
- Modify: `lib/screens/library_screen.dart:92-121`

There is an existing test on line 76 that currently asserts `ColorFiltered` is **present**. That test must be inverted first, then the implementation made.

**Step 1: Update the existing test**

In `test/screens/library_screen_test.dart`, replace lines 76–80:

```dart
    testWidgets('book cards use image assets with color filter', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(ColorFiltered), findsWidgets);
    });
```

With:

```dart
    testWidgets('book cards display image assets without color filter', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(ColorFiltered), findsNothing,
          reason: 'Amber ColorFilter should be removed; Gutenberg covers display true colours');
    });
```

**Step 2: Run the test to verify it fails**

```bash
flutter test test/screens/library_screen_test.dart --no-pub
```

Expected: FAIL — `'book cards display image assets without color filter'` fails because `ColorFiltered` is still present.

**Step 3: Remove the ColorFiltered wrapper from library_screen.dart**

In `lib/screens/library_screen.dart`, find `_BookCard.build`. The current cover widget (lines ~92–121) is:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: ColorFiltered(
    colorFilter: ColorFilter.mode(
      AppTheme.amber.withValues(alpha: 0.3),
      BlendMode.multiply,
    ),
    child: Image.asset(
      'assets/covers/${book.id}.jpg',
      width: 80,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        final gradient = coverGradients[book.id] ??
            [AppTheme.coverDeep, AppTheme.coverRich];
        return Container(
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
        );
      },
    ),
  ),
),
```

Replace with (remove `ColorFiltered` wrapper entirely):

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Image.asset(
    'assets/covers/${book.id}.jpg',
    width: 80,
    height: 120,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) {
      final gradient = coverGradients[book.id] ??
          [AppTheme.coverDeep, AppTheme.coverRich];
      return Container(
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
      );
    },
  ),
),
```

**Step 4: Run the full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass, 0 failures.

**Step 5: Commit**

```bash
git add test/screens/library_screen_test.dart lib/screens/library_screen.dart
git commit -m "feat: remove amber color filter from library book covers"
```

---

### Task 3: Add portrait cover thumbnail to book detail screen

**Files:**
- Modify: `test/screens/book_detail_screen_test.dart`
- Modify: `lib/screens/book_detail_screen.dart:38-49`

**Step 1: Add a failing test to book_detail_screen_test.dart**

In `test/screens/book_detail_screen_test.dart`, add this test inside the `group('BookDetailScreen', ...)` block, after the existing `'shows not found for unknown book'` test:

```dart
    testWidgets('shows cover image as 150x220 portrait thumbnail', (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(
        images.any((img) => img.width == 150 && img.height == 220),
        isTrue,
        reason: 'Expected a 150×220 Image widget for the book cover thumbnail',
      );
    });
```

**Step 2: Run the test to verify it fails**

```bash
flutter test test/screens/book_detail_screen_test.dart --no-pub
```

Expected: FAIL — `'shows cover image as 150x220 portrait thumbnail'` fails because no `Image` widget with those dimensions exists (current widget is a gradient `Container`).

**Step 3: Update book_detail_screen.dart**

In `lib/screens/book_detail_screen.dart`, find the cover container (lines 38–49):

```dart
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppTheme.coverDeep, AppTheme.coverRich],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
```

Replace with:

```dart
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/covers/${book.id}.jpg',
                        width: 150,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          final gradient = coverGradients[book.id] ??
                              [AppTheme.coverDeep, AppTheme.coverRich];
                          return Container(
                            width: 150,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
```

Also add the `catalogue.dart` import if not already present — `coverGradients` is needed for the fallback:

```dart
import '../data/catalogue.dart';
```

(It is already imported on line 7 — no change needed.)

**Step 4: Run the full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass, 0 failures. Count should be 130 (129 + 1 new test).

**Step 5: Commit**

```bash
git add test/screens/book_detail_screen_test.dart lib/screens/book_detail_screen.dart
git commit -m "feat: add portrait cover thumbnail to book detail screen"
```
