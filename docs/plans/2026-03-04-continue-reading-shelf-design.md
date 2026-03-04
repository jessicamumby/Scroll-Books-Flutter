# ContinueReadingShelf — Design

**Date:** 2026-03-04

## Goal

Build a `ContinueReadingShelf` horizontal carousel that appears at the top of the Library screen, showing books the user has started reading with cover art, title, and a brand-coloured progress bar.

## Design Pattern

- Horizontally scrollable shelf of cover cards with snap-to-page behaviour
- Active (front) card: 180px wide, elevated with brand drop shadow, full opacity
- Inactive cards: 140px wide, 60% opacity, no shadow
- Cards partially peek from the right to signal scrollability
- Tapping brings a card to the active position
- Section heading "CONTINUE READING" in existing brand heading style
- Hidden entirely when no books are in progress

## Data Flow

### Total chunks caching

`AppProvider.progress` stores `Map<String, int>` (bookId → chunkIndex). To show a percentage, we need total chunks — not currently in the catalogue.

**Solution: cache after first reader load**

- `reader_screen.dart` saves `SharedPreferences.setInt('total_chunks_$bookId', chunks.length)` after fetching chunks
- `AppProvider` adds `Map<String, int> bookTotalChunks = {}`, loaded in `load()` by reading `total_chunks_$bookId` for each catalogue book from SharedPreferences
- If `bookTotalChunks[bookId]` is null (never opened), progress bar renders empty (0%)
- Percentage = `((chunkIndex + 1) / totalChunks * 100).clamp(0, 100)`

### Books to display

```dart
catalogue.where((b) => b.hasChunks && (provider.progress[b.id] ?? 0) > 0)
```

If this list is empty, `ContinueReadingShelf` returns `SizedBox.shrink()`.

## Widget Architecture

### ContinueReadingShelf (StatefulWidget)

```
ContinueReadingShelf
└── Column
    ├── _SectionHeader("CONTINUE READING")
    └── SizedBox(height: 220)
        └── PageView.builder(
              controller: PageController(viewportFraction: ~0.55),
              onPageChanged: setState(_activePage),
              itemBuilder: _ShelfCard(book, isActive, chunkIndex, totalChunks)
            )
```

State: `int _activePage = 0`, updated via `onPageChanged`.

### _ShelfCard (StatelessWidget, private)

```
AnimatedContainer(
  width: isActive ? 180 : 140,
  duration: 200ms, curve: easeOut
)
└── AnimatedOpacity(opacity: isActive ? 1.0 : 0.6)
    └── Column
        ├── Container(
        │     decoration: BoxDecoration(
        │       borderRadius: BorderRadius.circular(10),
        │       boxShadow: isActive ? [BoxShadow(brand, blur:16, spread:2)] : []
        │     )
        │     child: ClipRRect → Image.asset(fit: BoxFit.cover, 3:4 ratio)
        │     errorBuilder: gradient fallback (coverGradients)
        │   )
        ├── SizedBox(8)
        ├── Text(title, maxLines:2, overflow:ellipsis, GoogleFonts.lora, 12sp, ink)
        └── SizedBox(6)
            └── _ProgressBar(percent, cardWidth)
```

Cover image height = `cardWidth * (4/3)` to maintain 3:4 aspect ratio.

### _ProgressBar (StatelessWidget, private)

- Full card width, height 4px
- Background: `Container` with `AppTheme.border`, `BorderRadius.circular(2)`
- Fill: `AnimatedContainer` with `AppTheme.brand`, width = `percent/100 * totalWidth`
- Smooth fill transitions on progress updates

## Files Changed

| File | Change |
|---|---|
| `lib/widgets/continue_reading_shelf.dart` | **Create** — full component |
| `lib/screens/library_screen.dart` | Insert `ContinueReadingShelf()` at top of Column inside `Consumer<AppProvider>` |
| `lib/screens/reader_screen.dart` | Add `prefs.setInt('total_chunks_${widget.bookId}', chunks.length)` after chunks loaded |
| `lib/providers/app_provider.dart` | Add `bookTotalChunks` field + load from SharedPreferences in `load()` |
| `test/widgets/continue_reading_shelf_test.dart` | **Create** — widget tests |

## Tests

- Hidden (`SizedBox.shrink`) when no in-progress books
- Shows book title when progress > 0 exists
- Active card width is 180, inactive is 140
- Progress bar fill width proportional to percentage
- Tapping inactive card changes active page
