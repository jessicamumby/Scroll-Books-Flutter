# Reader Card Full Width — Design

**Date:** 2026-02-25
**Status:** Approved

---

## Goal

Fix a regression where short text chunks produce a narrow card in the reader.

---

## Root Cause

`crossAxisAlignment: CrossAxisAlignment.stretch` was incorrectly removed from the outer `Column` in `ReaderCard` during a code quality review. The reviewer called it a "no-op", but it is not: `Expanded` only fills the main axis (vertical) inside a `Column`. The cross axis (horizontal) still depends on `crossAxisAlignment`. Without `stretch`, children take their intrinsic width — so short text produces a short-width card.

---

## Fix

Add `crossAxisAlignment: CrossAxisAlignment.stretch` back to the outer `Column` in `lib/widgets/reader/reader_card.dart`.

One line. No other changes.

---

## What Changes

| File | Change |
|---|---|
| `lib/widgets/reader/reader_card.dart` | Restore `crossAxisAlignment: CrossAxisAlignment.stretch` to outer `Column` |

## What Does Not Change

- All other widget structure
- Tests (all 50 continue to pass)
- `ReaderScreen`
