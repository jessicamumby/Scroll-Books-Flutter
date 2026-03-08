# Streak Badge Sharing Design

**Date:** 2026-03-08
**Status:** Approved

---

## Problem

Users earn streak milestones and badges (Week Worm, Page Turner, Bibliophile, Literary Legend) but have no way to share them. The profile share and passage share flows already exist — streak badges are a natural third shareable moment.

---

## Solution

Follow the exact pattern used by `shareProfileImage` and `sharePassageImage`: wrap a widget in `RepaintBoundary`, capture as PNG, share via native share sheet (`Share.shareXFiles`).

### New: `StreakBadgeShareCard` widget

`lib/widgets/streak_badge_share_card.dart` — a shareable card showing:
- Big badge emoji (fontSize: 56)
- Badge name ("Page Turner"), Playfair Display bold
- Streak subtitle ("30 day reading streak"), Playfair Display lighter
- `@username · SCROLL BOOKS` at the bottom in monoLabel style
- width: 280, cream background, warm shadow — matches `ProfileShareCard`

### New: `shareStreakBadgeImage()` utility

`lib/utils/share_streak_badge_image.dart` — same `RepaintBoundary → .toImage() → Share.shareXFiles()` pattern as existing share utils.

Share text: `'I earned the $badgeName badge on Scroll Books!'`

### Entry point 1: `MilestoneCelebrationOverlay`

Add a "Share" `TextButton` below "Tap to continue". The overlay receives two new params: `username` (String) and `repaintKey` (GlobalKey). The off-screen `StreakBadgeShareCard` is rendered at `left: -1000` (same pattern as `ProfileShareCard` on profile screen). Tapping Share calls `shareStreakBadgeImage()`. Overlay stays open after sharing so the user can still dismiss.

`StreaksScreen` already has `provider` in scope — passing `username` is a one-liner.

### Entry point 2: Earned badge cards (`LongevityBadgesList`)

Add a small share `IconButton` (`Icons.share, size: 16`) to the right of the "✓ EARNED" label in `_LongevityCard`, visible only when `unlocked`. Each unlocked card has its own `GlobalKey` for its `RepaintBoundary`.

`LongevityBadgesList` receives a new required `username` param. `_BadgesTab` in `streaks_screen.dart` already wraps in `Consumer<AppProvider>`, so `provider.username` is available.

---

## Out of Scope

- No changes to `GenreBadgesGrid` (genre badges are not streak milestones)
- No changes to `MilestonesList` in the Streaks tab — the Badges tab is the right place for resharing
- No bottom sheet preview before sharing — consistent with existing share flows
- No new dependencies — `share_plus` already in pubspec

---

## Files Changed

- Create: `lib/widgets/streak_badge_share_card.dart`
- Create: `lib/utils/share_streak_badge_image.dart`
- Modify: `lib/widgets/milestone_celebration_overlay.dart` — add `username`, `repaintKey` params + Share button
- Modify: `lib/widgets/longevity_badges_list.dart` — add `username` param, share button on earned cards
- Modify: `lib/screens/streaks_screen.dart` — pass `username` and `repaintKey` to overlay and badges list

---

## Testing

- `StreakBadgeShareCard` renders emoji, badge name, streak text, username
- `MilestoneCelebrationOverlay` shows share button
- Earned `_LongevityCard` shows share icon; locked card does not
