# Reader Card Layout — Design

**Date:** 2026-02-25
**Status:** Approved

---

## Goal

Fix two layout issues in `ReaderCard`:
1. The card width scales with text content, causing inconsistency across chunks.
2. Short text starts at the top of the card rather than sitting in the middle of the screen.

---

## Design

### Layout

```
┌─────────────────────────────┐  ← AppTheme.page, full screen width
│  ┌───────────────────────┐  │  ← card always fills available width
│  │                       │  │
│  │   chunk text here     │  │  ← vertically centred in card
│  │                       │  │
│  └───────────────────────┘  │
│  p. 1 · 0%        [share]  │
└─────────────────────────────┘
```

### Changes

**Card width** — add `crossAxisAlignment: CrossAxisAlignment.stretch` to the outer `Column`. The `Expanded` card fills the full available width regardless of text length.

**Vertical centering** — replace `SingleChildScrollView(child: Text(...))` inside the card with `Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(...)])`. Short passages float in the middle; text remains left-aligned (appropriate for prose).

### Trade-off

Without `SingleChildScrollView`, a very long chunk could overflow the card. Given chunks are deliberately short, this is unlikely in practice. Flutter will clip rather than crash if it occurs.

---

## What Changes

| File | Change |
|---|---|
| `lib/widgets/reader/reader_card.dart` | Add `crossAxisAlignment: CrossAxisAlignment.stretch` to outer `Column`; replace `SingleChildScrollView` with centered `Column` inside card |

## What Does Not Change

- `ReaderScreen`
- Tests
- All other files
