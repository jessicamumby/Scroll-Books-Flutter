# Long-Press to Share — Design

## Problem

The share button (a `Positioned` overlay in `ReaderScreen`'s Stack) covers content while reading and overlaps the page label during card swipes in Stories Style. The button needs to be removed in favour of a gesture-based approach that doesn't interfere with the reading experience.

## Design

### Part 1 — Reader (`lib/screens/reader_screen.dart`)

Remove the `Positioned` share `IconButton` from the Stack entirely.

In the `PageView.itemBuilder`, wrap each `ReaderCard` in a `GestureDetector` with `onLongPress: () => _share(_chunks[index])`.

Long-press is a distinct gesture from tap. The existing `HitTestBehavior.translucent` tap-zone `GestureDetector`s only declare `onTap`, so they do not compete with long-press recognition. The long-press fires on the underlying card in both Scroll Style and Stories Style.

Also remove the `_currentIndex` tracking field and its `setState` call in `_onPageChanged` — it was only needed to know which chunk the Positioned button should share. With `onLongPress` inside `itemBuilder`, `index` is already in scope.

### Part 2 — Onboarding (`lib/screens/onboarding_screen.dart`)

Insert a new card at position 3 (2nd to last, before the style picker):

**Content:**
- Icon: `Icons.share_outlined` (amber, 56px — matches existing feature cards)
- Headline: "Long press to share."
- Body: "Hold any passage to share it with a friend."
- Animation: mini reader card with a replaying press-and-reveal animation (see below)

**Animation:**
A new `AnimationController` (`_shareController`, duration 2500ms) drives two visual elements:

1. **Press indicator** — an amber semi-transparent circle (`width: 40, height: 40, shape: BoxShape.circle, color: AppTheme.amber.withOpacity(0.25)`) centred on the mini reader card.
   - Fades in: 0.0 → 1.0, interval 0.0–0.25
   - Scales up: 1.0 → 1.4, interval 0.0–0.45 (simulates finger pressing and holding)
   - Fades out: 1.0 → 0.0, interval 0.45–0.65

2. **Share icon** — `Icons.share_outlined` in amber, positioned at bottom-right of the mini card.
   - Fades in: 0.0 → 1.0, interval 0.6–0.8
   - Fades out: 1.0 → 0.0, interval 0.85–1.0 (clears before loop resets)

Both elements use `TweenSequence` or multiple `Interval`-based `CurvedAnimation`s on `_shareController`.

Replay loop: same pattern as `_previewController` — on `AnimationStatus.completed`, wait 600ms then `reset()` + `forward()`.

**Controller lifecycle:**
- `SingleTickerProviderStateMixin` → `TickerProviderStateMixin` (to support two controllers)
- `onPageChanged(i)`:
  - `i == _featureCards.length` → restart `_shareController`, cancel `_previewController` loop timer
  - `i == _featureCards.length + 1` → restart `_previewController`, cancel `_shareController` loop timer
- Both controllers disposed in `dispose()`

**Card count:** `totalCards = _featureCards.length + 2`

**`itemBuilder` logic:**
- `index < _featureCards.length` → `_buildFeatureCard`
- `index == _featureCards.length` → `_buildShareTipCard` (new)
- `index == _featureCards.length + 1` → `_buildStylePickerCard` (existing last card)

## Files

- `lib/screens/reader_screen.dart` — remove Positioned share button + `_currentIndex`; add `GestureDetector.onLongPress` in `itemBuilder`
- `lib/screens/onboarding_screen.dart` — add share tip card, `_shareController`, animation fields, updated `onPageChanged` and `itemBuilder`
- `test/screens/reader_screen_test.dart` — update tests (no share icon in widget tree, long-press share works)
- `test/screens/onboarding_screen_test.dart` — add test for share tip card presence

## Out of Scope

- Changing the share sheet content
- Adding haptic feedback on long-press
- Any change to the style picker card
