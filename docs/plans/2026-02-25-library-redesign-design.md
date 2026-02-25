# Library Screen Redesign — Design

**Date:** 2026-02-25
**Status:** Approved

---

## Goal

Make the library screen more engaging by replacing compact list rows with large vertical book cards, grouped by curated section, with unique per-book gradient covers.

---

## Problem

The current library shows a simple `ListView` of small rows: a 48×64px gradient placeholder, title, author, and an "Add to Library" button. Books feel cramped and undifferentiated. The blurb, year, and section data go unused.

---

## Design

### Screen Structure

- `Scaffold` and `AppBar` unchanged.
- Body: `SingleChildScrollView` → `Column` → three section groups.
- Section order: **Free Books → Trending → New**.
- Books appear in every section they belong to (a book may appear under multiple sections).

### Section Headers

- All-caps, DM Sans, 11px, letter-spacing 1.2px, `AppTheme.amber`
- Padding: 20px top, 8px bottom, 16px horizontal

### Book Card (`_BookCard`)

- Background: `AppTheme.surface`, 1px `AppTheme.border` stroke, 12px corner radius
- Margins: 16px horizontal, 6px vertical gap between cards
- Internal padding: 14px

**Cover placeholder** (left side):
- 80×120px, 8px corner radius
- Unique gradient per book (see table below)

**Content** (right side, 16px gap from cover):
- Title: Playfair Display, 17px, w600, `AppTheme.ink`
- Author · Year: DM Sans, 12px, `AppTheme.tobacco`, 4px below title
- Blurb snippet: DM Sans, 12px, `AppTheme.pewter`, max 3 lines + ellipsis, 8px below author
- Bottom-aligned: "In Library" badge (`AppTheme.forest` text on `AppTheme.forestPale` bg) OR "Add to Library" amber `TextButton`

### Per-Book Gradient Colours

Added as `const Map<String, List<Color>> coverGradients` in `lib/data/catalogue.dart`. The `Book` model is unchanged.

| Book ID | Gradient start | Gradient end |
|---|---|---|
| `moby-dick` | `#1A3A5C` (deep navy) | `#2E7D9A` (ocean teal) |
| `pride-and-prejudice` | `#8B5E6E` (dusty rose) | `#5E7B6A` (sage) |
| `jane-eyre` | `#3D2B4E` (deep plum) | `#7A6070` (warm mauve) |
| `don-quixote` | `#8B4513` (terracotta) | `#C4956A` (warm gold) |
| `great-gatsby` | `#B8952A` (champagne) | `#2C4A3E` (deep green) |
| `frankenstein` | `#1A3322` (dark forest) | `#4A5568` (stormy slate) |

---

## What Changes

| File | Change |
|---|---|
| `lib/data/catalogue.dart` | Add `coverGradients` map |
| `lib/screens/library_screen.dart` | Replace `ListView.builder` + `_BookRow` with section groups + `_BookCard` |
| `test/screens/library_screen_test.dart` | Update tests to match new card widget |

## What Does Not Change

- `AppTheme` / `lib/core/theme.dart`
- Router configuration
- `Book` model fields
- Navigation (`context.push` to book detail)
- All other screens
