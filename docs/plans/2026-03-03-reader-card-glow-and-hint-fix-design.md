# Reader Card Glow & Share Hint Fix Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:writing-plans to write the implementation plan for this design.

**Goal:** Fix the share hint persisting after a swipe, and replace the card's neutral border with a warm brand glow shadow.

---

## 1. Share Hint Swipe Fix

**Problem:** `_hintTimer?.cancel()` is called in `_onPageChanged` but `_showShareHint` is never set to `false`, so the hint stays visible when the user swipes before the 3-second timer fires.

**Fix:** In `_onPageChanged` in `lib/screens/reader_screen.dart`, add `setState(() => _showShareHint = false)` immediately after `_hintTimer?.cancel()`.

---

## 2. Card Brand Glow Shadow

**Problem:** The reader card has a flat neutral `Border.all(color: AppTheme.border)` ring that doesn't reinforce the "this is your reading moment" feel.

**Fix:** In `lib/widgets/reader/reader_card.dart`, replace the `Border.all(color: AppTheme.border)` border in the `BoxDecoration` with a `boxShadow`:

```dart
boxShadow: [
  BoxShadow(
    color: AppTheme.brand.withValues(alpha: 0.22),
    blurRadius: 18,
    spreadRadius: 2,
  ),
],
```

Remove the `border:` line entirely. Keep the 3px left bar (ClipRRect + Row) unchanged.
