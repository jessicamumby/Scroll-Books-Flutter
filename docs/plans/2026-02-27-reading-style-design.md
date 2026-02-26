# Reading Style Feature — Design Doc

**Date:** 2026-02-27

---

## Goal

Let users choose between two reading modes — **Scroll Style** (vertical swipe, like TikTok/Reels) and **Stories Style** (horizontal tap, like Instagram/Facebook Stories) — with selection during onboarding and the ability to change it at any time via Profile Settings.

---

## Architecture

**State:** `AppProvider` (existing `ChangeNotifier`) owns `readingStyle`. Consistent with how `library`, `progress`, and `readDays` are managed.

**Persistence:** Supabase `user_preferences` table (synced, follows user across devices). `UserDataService` handles all reads/writes.

**Propagation:** `ReaderScreen` reads `readingStyle` from `AppProvider` at build time. Style picker screen writes via `AppProvider.setReadingStyle()`.

---

## Section 1: Data & State Layer

### Supabase schema

New table (create manually in Supabase dashboard or via migration):

```sql
CREATE TABLE user_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  reading_style text NOT NULL DEFAULT 'vertical'
);
```

`reading_style` values: `'vertical'` (Scroll Style) or `'horizontal'` (Stories Style).

### `UserData` model

Add field:

```dart
final String readingStyle; // default: 'vertical'
```

### `UserDataService.fetchAll()`

Add 4th parallel fetch:

```dart
supabase
  .from('user_preferences')
  .select('reading_style')
  .eq('user_id', userId)
  .maybeSingle()
```

If row is absent (existing users), default to `'vertical'`.

### New `UserDataService.saveReadingStyle()`

```dart
static Future<void> saveReadingStyle(String userId, String style) async {
  await supabase.from('user_preferences').upsert(
    {'user_id': userId, 'reading_style': style},
    onConflict: 'user_id',
  );
}
```

### `AppProvider` changes

```dart
String readingStyle = 'vertical';

// in load(): populate from UserDataService.fetchAll()

Future<void> setReadingStyle(String userId, String style) async {
  readingStyle = style;
  notifyListeners();
  await UserDataService.saveReadingStyle(userId, style);
}
```

### Existing users

Users who already completed onboarding have no `user_preferences` row. They receive `'vertical'` by default — current behaviour preserved, no disruption.

---

## Section 2: Onboarding 4th Card — Reading Style Picker

The existing 3 onboarding cards are unchanged. A 4th card is appended. `"Start reading →"` moves from card 3 to card 4.

### Dot indicator

Moves **inside each card** — a centered horizontal row of 4 dots at the bottom of each card's `Column`, above the CTA on the final card.

- Active dot: amber, `AnimatedContainer` pill shape (~24×8px)
- Inactive dot: fog, 8×8px circle
- Replaces the current right-side column of dots (the `Row` layout in `OnboardingScreen` is simplified to a single full-width `PageView`)

### 4th card content

```
Headline:  "How do you like to read?"   (Playfair Display 32px w700, ink)
Body:      "Pick a style. You can change it any time in Settings."
                                          (DM Sans 16px, tobacco)

[  Swipe down tile  ]  [  Tap across tile  ]

            [ Start reading → ]   (disabled until style chosen)
```

### Option tiles

Each tile:
- Tappable, rounded card (amber border if selected, fog border if not)
- Label: `"Swipe down"` / `"Tap across"` (DM Sans 14px w600 ink)
- Sub-label: `"Scroll Style"` / `"Stories Style"` (DM Mono 11px pewter)
- Mini reader simulation (see below)

### Mini reader simulation

Each tile contains a small scaled replica of a `ReaderCard` (~0.35 scale via `Transform.scale`).

A looping `AnimationController` (repeat, ~2.4s period) drives a `SlideTransition`:

- **Swipe tile:** card slides out upward, new card enters from below (`Offset(0, 1)` → `Offset(0, 0)` → `Offset(0, -1)`)
- **Tap tile:** card slides out left, new card enters from right (`Offset(1, 0)` → `Offset(0, 0)` → `Offset(-1, 0)`)

Both tiles animate simultaneously and loop continuously so the user can compare the two motions.

Pause between cycles: ~0.6s (achieved by adding a `CurvedAnimation` with a brief flat segment, or by using `AnimationController.repeat(reverse: false)` with a `Future.delayed` in a `StatusListener`).

### Behaviour

- Tapping a tile: `setState(() => _selectedStyle = style)`, amber border activates
- "Start reading →" enabled only when `_selectedStyle != null`
- On tap: `appProvider.setReadingStyle(userId, _selectedStyle!)` then `completeOnboarding()`

---

## Section 3: ReaderScreen — Dual Mode

### Scroll direction

```dart
final style = Provider.of<AppProvider>(context, listen: false).readingStyle;

PageView.builder(
  scrollDirection: style == 'horizontal' ? Axis.horizontal : Axis.vertical,
  ...
)
```

### Tap zones (Stories Style only)

When `style == 'horizontal'`, overlay two invisible `GestureDetector` regions:

- **Left 30% of screen:** `_pageController.previousPage(duration: 300ms, curve: Curves.easeInOut)`
- **Right 30% of screen:** `_pageController.nextPage(duration: 300ms, curve: Curves.easeInOut)`

```dart
if (style == 'horizontal')
  Positioned.fill(
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(onTap: _previousPage),
        ),
        const Spacer(flex: 4),
        Expanded(
          flex: 3,
          child: GestureDetector(onTap: _nextPage),
        ),
      ],
    ),
  ),
```

Stack this over the `PageView` in a `Stack` widget.

### `ReaderCard` widget

Unchanged — renders identically in both orientations.

### Style change mid-session

Style is read at `build()` via `listen: false`. If the user changes style in Settings while the reader is open, they must navigate away and back for it to take effect. Acceptable edge case.

---

## Section 4: Profile Screen — Reading Style Setting

### Profile tile

New `ListTile` below "How Scroll Books works":

```
Reading style       Scroll Style  >
```

- Title: `"Reading style"` (DM Sans 15px ink)
- Trailing: current style label in pewter + `Icons.chevron_right` in pewter
- On tap: `context.push('/app/profile/reading-style')`

### Reading style picker screen (`ReadingStyleScreen`)

Route: `/app/profile/reading-style` (nested under shell route)

- `AppBar` title: `"Reading style"`
- Two `ListTile`s: `"Scroll Style"` and `"Stories Style"`
- Selected tile: `Icons.check` in amber as trailing
- Unselected tile: no trailing icon
- On tap: `appProvider.setReadingStyle(userId, style)` then `context.pop()`

**No animation on this screen** — the mini simulation is onboarding-only. Settings is a quick utilitarian action.

---

## Files Touched

| File | Change |
|------|--------|
| `lib/services/user_data_service.dart` | `UserData.readingStyle` field; 4th fetch in `fetchAll()`; new `saveReadingStyle()` |
| `lib/providers/app_provider.dart` | `readingStyle` field; populate in `load()`; `setReadingStyle()` method |
| `lib/screens/onboarding_screen.dart` | 4th card; dot indicator moved inside cards; mini reader simulation |
| `lib/screens/reader_screen.dart` | Read `readingStyle` from provider; conditional scroll direction; tap zones |
| `lib/screens/profile_screen.dart` | New "Reading style" `ListTile` |
| `lib/screens/reading_style_screen.dart` | New screen — simple two-option picker |
| `lib/core/router.dart` | Add `/app/profile/reading-style` route |
| `test/services/user_data_service_test.dart` | Tests for `readingStyle` field and `saveReadingStyle()` |
| `test/providers/app_provider_test.dart` | Tests for `setReadingStyle()` |
| `test/screens/onboarding_screen_test.dart` | Tests for 4th card, style selection, CTA enable/disable |
| `test/screens/reader_screen_test.dart` | Tests for horizontal/vertical mode |
| `test/screens/profile_screen_test.dart` | Test for new tile |
| `test/screens/reading_style_screen_test.dart` | Tests for picker screen |

---

## Out of Scope

- Animating an already-open `ReaderScreen` when style changes in Settings
- Per-book reading style (style is global)
- Syncing style for unauthenticated users (guests always get `'vertical'`)
