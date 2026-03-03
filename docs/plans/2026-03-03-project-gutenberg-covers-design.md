# Project Gutenberg Covers — Design

**Date:** 2026-03-03

## Goal

Replace placeholder cover images with real Project Gutenberg covers, and display the cover prominently on the book detail screen as a centred portrait thumbnail with drop shadow.

## Context

- `assets/covers/` already contains 6 placeholder JPGs (one per book), declared in `pubspec.yaml`
- `lib/screens/library_screen.dart` loads covers via `Image.asset('assets/covers/${book.id}.jpg')` with a gradient fallback; a `ColorFiltered` amber tint is applied
- `lib/screens/book_detail_screen.dart` shows a hardcoded gradient container (no image at all)
- `lib/data/catalogue.dart` has `coverGradients` map used as the fallback

## Changes

### 1. Asset files — replace with Gutenberg covers

Download the `medium` cover from Project Gutenberg for each book and save over the existing file:

| File | Gutenberg URL |
|---|---|
| `assets/covers/moby-dick.jpg` | `https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg` |
| `assets/covers/pride-and-prejudice.jpg` | `https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg` |
| `assets/covers/jane-eyre.jpg` | `https://www.gutenberg.org/cache/epub/1260/pg1260.cover.medium.jpg` |
| `assets/covers/don-quixote.jpg` | `https://www.gutenberg.org/cache/epub/996/pg996.cover.medium.jpg` |
| `assets/covers/great-gatsby.jpg` | `https://www.gutenberg.org/cache/epub/64317/pg64317.cover.medium.jpg` |
| `assets/covers/frankenstein.jpg` | `https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg` |

No `pubspec.yaml` change needed — the folder is already declared.

### 2. Library screen — remove amber ColorFilter

In `lib/screens/library_screen.dart`, remove the `ColorFiltered` wrapper from the cover `Image.asset` in `_BookCard`. The amber multiply filter was compensating for placeholder images; Gutenberg covers have their own colour palette. Everything else (size, radius, fallback) is unchanged.

Before:
```dart
ColorFiltered(
  colorFilter: ColorFilter.mode(
    AppTheme.amber.withValues(alpha: 0.3),
    BlendMode.multiply,
  ),
  child: Image.asset('assets/covers/${book.id}.jpg', ...),
),
```

After:
```dart
Image.asset('assets/covers/${book.id}.jpg', ...),
```

### 3. Book detail screen — centred portrait thumbnail

In `lib/screens/book_detail_screen.dart`, replace the 200px gradient container with a centred portrait book cover:

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

## Success Criteria

- All 6 Gutenberg covers display correctly in the library list
- Library covers show true colours (no amber tint)
- Book detail screen shows the cover as a 150×220 portrait thumbnail, centred, with drop shadow
- Gradient fallback still works if an image fails to load
- No pubspec changes needed
