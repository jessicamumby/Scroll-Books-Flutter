# Share Button Tap Conflict — Design

## Problem

In Stories Style (horizontal) reader mode, tapping the share button advances the page instead of showing the share modal.

**Root cause:** `ReaderScreen` wraps the `PageView` in a `Stack` with a `Positioned.fill` overlay of two `GestureDetector` tap zones (left = previous, right = next). The right tap zone (`flex: 3`, `HitTestBehavior.translucent`) covers the bottom-right corner where the share button lives. Because the overlay is higher in the Stack, its gesture recognizer enters the arena first and wins — so `nextPage` fires and the share button's `onPressed` never does.

## Design

**Hoist the share button above the tap overlay in the Stack.**

The share button moves out of `ReaderCard` and into `ReaderScreen`'s Stack as a third layer, placed above the tap zone overlay. Since it is rendered last in the Stack it is hit-tested first and always wins the gesture arena.

```
Stack
├── PageView                      (bottom)
├── Row of GestureDetector zones  (middle — unchanged)
└── Positioned IconButton share   (top — new)
```

### ReaderCard changes

- Remove `onShare` parameter
- Remove the `IconButton` from the footer row
- Footer row becomes just the page label (left-aligned)

### ReaderScreen changes

- Add `_currentIndex` state field, initialised to `_startIndex`
- Update `_onPageChanged` to also `setState(() => _currentIndex = index)`
- In the horizontal `Stack`, add a `Positioned` share button above the overlay layer
- Positioning: `bottom: MediaQuery.of(context).padding.bottom + 20`, `right: 4` (matches card's bottom padding and right edge; IconButton has built-in padding so `right: 4` aligns the icon to ~16px from screen edge)
- Button calls `_share(_chunks[_currentIndex])`

### Vertical mode (unchanged)

Vertical scroll mode uses the plain `PageView` without a Stack overlay. The share button remains inside `ReaderCard` for vertical mode... wait, if we remove `onShare` from `ReaderCard`, the share button disappears in vertical mode too.

**Resolution:** Hoist the share button into `ReaderScreen` for both modes. In both modes, a `Positioned` share button is overlaid on the body (wrapped in a `Stack`). This is consistent and removes the tap conflict entirely.

The body becomes:

```dart
Stack(
  children: [
    pageView,
    if (isHorizontal) tapZoneOverlay,
    Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      right: 4,
      child: IconButton(
        icon: const Icon(Icons.share_outlined),
        color: AppTheme.pewter,
        onPressed: () => _share(_chunks[_currentIndex]),
      ),
    ),
  ],
)
```

## Files

- `lib/widgets/reader/reader_card.dart` — remove `onShare` param + `IconButton`
- `lib/screens/reader_screen.dart` — add `_currentIndex` state + hoisted share button

## Out of Scope

- Changing the tap zone layout
- Changing the share content/modal
- Any change to vertical scroll behaviour beyond removing the share button from the card
