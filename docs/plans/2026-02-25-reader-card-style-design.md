# Reader Card Style — Design

**Date:** 2026-02-25
**Status:** Approved

---

## Goal

Update `ReaderCard` so each chunk feels visually grounded: the text sits inside a surface-coloured panel rather than floating directly on the page background, and the bottom bar shows the reader's position (page number + percentage) alongside the existing share button.

---

## Design

### Layout

```
┌─────────────────────────────┐  ← AppTheme.page background (16px side padding)
│  ┌───────────────────────┐  │  ← AppTheme.surface card (rounded 16px, borderSoft border)
│  │                       │  │
│  │   chunk text here     │  │  ← Playfair Display italic 18px, AppTheme.ink
│  │                       │  │
│  └───────────────────────┘  │
│  p. 1 · 0%        [share]  │  ← bottom row on page background
└─────────────────────────────┘
```

### Outer container

- Background: `AppTheme.page`
- Padding: 16px horizontal, 20px vertical

### Inner card

- Background: `AppTheme.surface`
- Border radius: 16px
- Border: 1px solid `AppTheme.borderSoft`
- Fills all available vertical space (`Expanded`)
- Internal padding: 20px horizontal, 24px vertical
- Text: scrollable, Playfair Display italic 18px, `AppTheme.ink`, line height 1.75

### Bottom row

- Layout: `Row` with `MainAxisAlignment.spaceBetween`
- Left: `"p. ${chunkIndex + 1} · ${percentage}%"` — DM Mono 12px, `AppTheme.pewter`
- Right: share `IconButton`, `AppTheme.pewter` (unchanged)
- Percentage: `((chunkIndex + 1) / totalChunks * 100).round()` — whole number

---

## What Changes

| File | Change |
|---|---|
| `lib/widgets/reader/reader_card.dart` | Add `chunkIndex` + `totalChunks` params; restructure layout |
| `lib/screens/reader_screen.dart` | Pass `chunkIndex: index` and `totalChunks: _chunks.length` to each `ReaderCard` |
| `test/widgets/reader_card_test.dart` | Update tests for new required params; add test for position display |

## What Does Not Change

- Text style (Playfair Display italic 18px)
- Share button behaviour
- Progress sync logic in `ReaderScreen`
