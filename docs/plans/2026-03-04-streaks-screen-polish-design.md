# Streaks Screen Polish — Design

**Date:** 2026-03-04

## Goal

Polish the Streaks screen for real users: replace all mocked data with live calculations, add bookmark reset logic with backend persistence, fix the StreakCounter overflow and add an animated fire emoji.

---

## Section 1 — Genre Badges (real data)

### Data model

Add `List<String> genres` to `Book` in `catalogue.dart`:

```dart
class Book {
  // ... existing fields
  final List<String> genres;
}
```

Genre mapping for the 6 catalogue books:

| Book | Genres |
|---|---|
| Moby Dick | ['Adventure', 'Gothic'] |
| Pride and Prejudice | ['Romance'] |
| Jane Eyre | ['Gothic', 'Romance'] |
| Don Quixote | ['Adventure', 'Satire'] |
| The Great Gatsby | ['Satire'] |
| Frankenstein | ['Gothic', 'Sci-Fi'] |

Philosophy has no books in the current catalogue — it stays locked for all users for now.

### AppProvider getter

Add a computed getter (no new persistence — derived from existing `progress` + `catalogue`):

```dart
Map<String, int> get genreCounts {
  final counts = <String, int>{};
  for (final book in catalogue) {
    final p = progress[book.id];
    if (p != null && p > 0) {
      for (final g in book.genres) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
  }
  return counts;
}
```

A book counts as "read" when `progress[book.id] > 0` (at least one passage opened).

### GenreBadgesGrid changes

- Accept `Map<String, int> genreCounts` as a required parameter (remove const data)
- Badge `unlocked` = `genreCounts[badge.name] != null`
- Badge `booksRead` = `genreCounts[badge.name] ?? 0`
- Call site in `_BadgesTab`: `GenreBadgesGrid(genreCounts: provider.genreCounts)`

---

## Section 2 — Bookmark Reset (1 week from first use)

### Logic

Tokens start at 2. When the **first** token is used (i.e. `bookmarkTokens == 2` before decrement), record `bookmarkResetAt = today + 7 days` as an ISO date string (e.g. `'2026-03-11'`).

On every app load (`_loadLocalStats` + backend fetch), check: if today ≥ `bookmarkResetAt`, reset `bookmarkTokens = 2` and clear `bookmarkResetAt = null`.

Using the second token does **not** change `bookmarkResetAt` — the clock started on first use.

### New AppProvider state

```dart
String? bookmarkResetAt; // ISO date string, null when no active reset cycle
```

### BookmarkCard UI

Accept `String? bookmarkResetAt` as a new parameter. When `bookmarksRemaining == 0`:

- Compute days remaining: `bookmarkResetAt` date minus today
- Show: `'Resets in X days'` (or `'Resets tomorrow'` if 1 day)
- Fallback to `'No Bookmarks Left'` if `bookmarkResetAt` is null (shouldn't happen)

---

## Section 3 — Backend storage for bookmarks

### Why

Users may read on multiple devices. Bookmark state must follow the account, not the device.

### Supabase schema change

Extend `user_preferences` with three new columns (no new table needed — already one-row-per-user):

```sql
ALTER TABLE user_preferences
  ADD COLUMN bookmark_tokens     INTEGER  NOT NULL DEFAULT 2,
  ADD COLUMN bookmark_reset_at   TEXT,
  ADD COLUMN frozen_days         JSONB    NOT NULL DEFAULT '[]';
```

### UserDataService changes

`UserData` gains three new fields:

```dart
final int bookmarkTokens;         // default 2
final String? bookmarkResetAt;    // nullable
final List<String> frozenDays;    // default []
```

`fetchAll` reads them from `user_preferences`.

New method:

```dart
static Future<void> saveBookmarkState(
  String userId, {
  required int bookmarkTokens,
  required String? bookmarkResetAt,
  required List<String> frozenDays,
}) async {
  await supabase.from('user_preferences').upsert(
    {
      'user_id': userId,
      'bookmark_tokens': bookmarkTokens,
      'bookmark_reset_at': bookmarkResetAt,
      'frozen_days': jsonEncode(frozenDays),
    },
    onConflict: 'user_id',
  );
}
```

### AppProvider changes

- `load()` reads `bookmarkTokens`, `bookmarkResetAt`, `frozenDays` from backend (falling back to SharedPreferences if fetch fails)
- `useBookmarkToken()` calls `UserDataService.saveBookmarkState(...)` fire-and-forget after local update
- On load, after setting state from backend, run the reset check: if today ≥ `bookmarkResetAt`, reset tokens to 2 and clear date, then save

SharedPreferences remains as a local cache/fallback for offline support.

---

## Section 4 — Milestone fix

`_checkMilestone` in `app_provider.dart`:

```dart
const milestones = [7, 30, 90, 365]; // was [7, 30, 100]
```

This aligns the celebration logic with what `MilestonesList` and `LongevityBadgesList` show to the user.

---

## Section 5 — Weekly dots include frozen days

In `_StreaksTab._getWeeklyCompletion`, a day counts as complete if it appears in either `readDays` or `frozenDays` (a bookmark-protected day is a kept streak day):

```dart
return readDays.contains(dayStr) || frozenDays.contains(dayStr);
```

Pass `provider.frozenDays` down to `_getWeeklyCompletion`.

---

## Section 6 — StreakCounter redesign

### Overflow fix

- Increase circle from 130×130 to 150×150
- Reduce `letterSpacing` on "DAY STREAK" label from `2.0` to `1.0`

### Animated fire emoji

Convert `StreakCounter` from `StatelessWidget` to `StatefulWidget with SingleTickerProviderStateMixin`.

```dart
late final AnimationController _controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 500),
)..repeat(reverse: true);

late final Animation<double> _scale = Tween<double>(begin: 0.85, end: 1.15)
    .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

late final Animation<double> _opacity = Tween<double>(begin: 0.65, end: 1.0)
    .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
```

Apply to the fire emoji:

```dart
FadeTransition(
  opacity: _opacity,
  child: ScaleTransition(
    scale: _scale,
    child: const Text('🔥', style: TextStyle(fontSize: 30)),
  ),
)
```

Dispose controller in `dispose()`.

---

## Files Changed

| File | Change |
|---|---|
| `lib/data/catalogue.dart` | Add `genres` field to `Book`; add genre lists to all 6 books |
| `lib/providers/app_provider.dart` | Add `bookmarkResetAt` field; add `genreCounts` getter; update `useBookmarkToken()`, `load()`, `_loadLocalStats()` |
| `lib/services/user_data_service.dart` | Add bookmark fields to `UserData`; update `fetchAll`; add `saveBookmarkState` |
| `lib/widgets/genre_badges_grid.dart` | Accept `genreCounts` parameter; remove const mock data |
| `lib/widgets/bookmark_card.dart` | Accept `bookmarkResetAt` parameter; show "Resets in X days" |
| `lib/widgets/streak_counter.dart` | Convert to StatefulWidget; add fire animation; fix circle size + label spacing |
| `lib/screens/streaks_screen.dart` | Pass `genreCounts` to `GenreBadgesGrid`; pass `bookmarkResetAt` to `BookmarkCard`; include `frozenDays` in weekly completion |
| `test/widgets/streak_counter_test.dart` | **Create** — animation present, overflow absent |
| `test/widgets/genre_badges_grid_test.dart` | **Create** — real data wired, unlocked/locked states |
| `test/widgets/bookmark_card_test.dart` | **Create** — "Resets in X days" shown when tokens = 0 |
| `test/services/user_data_service_test.dart` | Update — bookmark fields in fetchAll + saveBookmarkState |
| `test/providers/app_provider_test.dart` | Update — genreCounts getter, reset logic |
