# Reader Card Border Redesign — Design

**Date:** 2026-03-03

## Goal

Replace the reader card's brand-red glow shadow and left accent strip with a thin brandPale border around the whole card perimeter.

## Context

The current `ReaderCard` widget (`lib/widgets/reader/reader_card.dart`) has two decorative elements that were recently added:
- A `boxShadow` using `AppTheme.brand` (coral-red) at 22% opacity with `blurRadius: 18, spreadRadius: 2` — creates a red glow behind the card
- A 3px-wide `Container(color: AppTheme.brand)` as the first child of the card's inner `Row` — creates a red accent strip on the left edge

Both are being removed in favour of a clean `Border.all` using `AppTheme.brandPale` (#FFD0C8, soft blush-pink).

## Chosen Approach

**`Border.all` in BoxDecoration (Option A)**

The simplest, most idiomatic change:
1. Remove `boxShadow` from the outer card `BoxDecoration`
2. Add `border: Border.all(color: AppTheme.brandPale, width: 1.5)` to the same `BoxDecoration`
3. Remove the 3px left-strip `Container` from the inner `Row`
4. Keep `ClipRRect` (still needed to clip inner content to the rounded corners)

Only `lib/widgets/reader/reader_card.dart` needs to change in production code.

## Test Changes

File: `test/widgets/reader_card_test.dart`

- Update existing test `'card decoration has brand glow shadow and no border'` → rename to `'card decoration has brandPale border and no box shadow'` and invert assertions: `border` must be non-null (with `brandPale`), `boxShadow` must be null
- Add new test: `'does not render left accent strip'` — asserts no 3px-wide `Container` with `AppTheme.brand` fill exists in the widget tree

## Non-changes

- `lib/screens/reader_screen.dart` — no changes needed
- `lib/core/theme.dart` — no changes needed; `AppTheme.brandPale` already exists

## Success Criteria

- Card renders with a 1.5px brandPale perimeter border and no glow, no left strip
- All existing widget tests pass
- Two updated/new tests cover the new border assertion and strip removal
