# Gutenberg Covers & Production Catalogue — Design

**Date:** 2026-03-04

## Goal

Trim the catalogue to the 6 production books uploaded to Supabase Storage, add real Project Gutenberg cover images throughout the app, fix the reader to fetch any book by ID, and add a back button to BookDetailScreen.

---

## Section 1 — Catalogue overhaul

Remove `jane-eyre` and `don-quixote` from `catalogue.dart` and `coverGradients`.

Add two new books:

| Field | Romeo & Juliet | Wuthering Heights |
|-------|---------------|-------------------|
| id | `romeo-and-juliet` | `wuthering-heights` |
| author | William Shakespeare | Emily Brontë |
| year | 1597 | 1847 |
| genres | Romance, Tragedy | Gothic, Romance |
| sections | Free Books, Trending | Free Books, New |
| hasChunks | true | true |

Set `hasChunks: true` on all 6 remaining books (all are in Supabase Storage).

Add `coverGradients` fallback entries for `romeo-and-juliet` and `wuthering-heights`.

**Production catalogue (final):**
- moby-dick
- frankenstein
- great-gatsby
- pride-and-prejudice
- romeo-and-juliet
- wuthering-heights

---

## Section 2 — Book covers

**Assets (`assets/covers/`):**
- Download Project Gutenberg cover images for `romeo-and-juliet.jpg` and `wuthering-heights.jpg`
- Remove `jane-eyre.jpg` and `don-quixote.jpg`
- Existing: moby-dick.jpg, frankenstein.jpg, great-gatsby.jpg, pride-and-prejudice.jpg (keep as-is)

**`lib/widgets/my_library_list.dart` — `_BookCard`:**

Replace the 38×54 gradient spine with a real cover image:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: Image.asset(
    'assets/covers/${book.id}.jpg',
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
    ),
  ),
),
```

**`lib/widgets/discover_store.dart` — `_DiscoverCard` cover area:**

Replace the gradient block with a cover image at the same 100px height. Gradient stays as errorBuilder fallback.

---

## Section 3 — Discover store cleanup

Replace `_discoverBooks` with the 6 production books. Remove: Jane Eyre, Don Quixote, The Odyssey, Dracula. Add: Romeo & Juliet, Wuthering Heights.

`_DiscoverBook` keeps its own struct (no catalogue coupling) but data is updated to match production set.

Tag assignments:
| Book | Tag |
|------|-----|
| Moby Dick | Classic |
| Frankenstein | Classic |
| The Great Gatsby | Short |
| Pride and Prejudice | Popular |
| Romeo & Juliet | Classic |
| Wuthering Heights | Popular |

Featured banner: update from "coming soon" framing to reflect Wuthering Heights is now available. Button stays non-functional (Discover tap wiring is a separate TODO).

---

## Section 4 — Reader URL pattern

**`.env`:** rename `BOOKS_BUCKET_URL` → `BOOKS_BUCKET_BASE_URL`

Base URL value:
```
BOOKS_BUCKET_BASE_URL=https://macttsmfxjwgtosiqzeb.supabase.co/storage/v1/object/public/books
```

**`lib/screens/reader_screen.dart`:** construct per-book URL:
```dart
final baseUrl = dotenv.env['BOOKS_BUCKET_BASE_URL'] ?? '';
if (baseUrl.isEmpty) throw Exception('BOOKS_BUCKET_BASE_URL not set');
final url = '$baseUrl/${widget.bookId}.json';
final response = await http.get(Uri.parse(url));
```

Files in the `books` bucket are named `{book-id}.json` (e.g. `moby-dick.json`, `romeo-and-juliet.json`).

---

## Section 5 — Back button on BookDetailScreen

**`lib/widgets/my_library_list.dart`:**

Change tap navigation from `context.go()` to `context.push()` so the navigation stack is preserved and hardware back works on Android:
```dart
onTap: () => context.push('/app/library/${book.id}'),
```

**`lib/screens/book_detail_screen.dart`:**

Add back button matching the reader screen — `Icons.arrow_back_ios` in `leading` position:
```dart
appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios),
    onPressed: () => context.pop(),
  ),
),
```

---

## Files Changed

| File | Change |
|------|--------|
| `lib/data/catalogue.dart` | Remove jane-eyre, don-quixote; add romeo-and-juliet, wuthering-heights; hasChunks: true on all; update coverGradients |
| `lib/widgets/discover_store.dart` | Trim _discoverBooks to 6 production books; add cover images to cards; update featured banner |
| `lib/widgets/my_library_list.dart` | Replace gradient spine with Image.asset cover; change context.go → context.push |
| `lib/screens/book_detail_screen.dart` | Add arrow_back_ios leading button |
| `lib/screens/reader_screen.dart` | BOOKS_BUCKET_URL → BOOKS_BUCKET_BASE_URL; construct per-book URL |
| `assets/covers/romeo-and-juliet.jpg` | New — downloaded from Project Gutenberg |
| `assets/covers/wuthering-heights.jpg` | New — downloaded from Project Gutenberg |
| `assets/covers/jane-eyre.jpg` | Delete |
| `assets/covers/don-quixote.jpg` | Delete |
| `.env` | Rename BOOKS_BUCKET_URL → BOOKS_BUCKET_BASE_URL |
