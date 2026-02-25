# ElevatedButton Foreground Colour — Design

**Date:** 2026-02-25
**Status:** Approved

---

## Goal

Fix invisible text on the "Start Reading" `ElevatedButton` in `BookDetailScreen`.

---

## Root Cause

In Material 3, `ElevatedButton.styleFrom` without an explicit `foregroundColor` defaults the label colour to `colorScheme.primary`. The button background is also `amber` (the primary colour), producing amber text on an amber background — invisible.

---

## Fix

Add `foregroundColor: AppTheme.surface` to the `ElevatedButtonThemeData` in `lib/core/theme.dart`.

`AppTheme.surface` (`0xFFFAF6EE`) is a light cream that contrasts clearly against amber and stays on-brand. This fixes all `ElevatedButton` instances globally with one line.

---

## What Changes

| File | Change |
|---|---|
| `lib/core/theme.dart` | Add `foregroundColor: surface` to `ElevatedButton.styleFrom(...)` in `elevatedButtonTheme` |

## What Does Not Change

- `book_detail_screen.dart`
- Any other screen or widget
- Tests (all 50 continue to pass)
