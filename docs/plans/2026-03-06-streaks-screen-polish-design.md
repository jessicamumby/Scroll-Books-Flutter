# Streaks Screen Polish & Profile Sharing Design

**Date:** 2026-03-06
**Status:** Approved

---

## Goal

Polish the Streaks screen with richer animations, improve bookmark UX with a refill progress animation, and introduce a profile sharing system with unique usernames, public profiles, and a follow mechanism as groundwork for a future social feed.

---

## 1. Streaks Screen Visual Improvements

### 1.1 Fire / Wood Emoji Animation (`streak_counter.dart`)

The current single pulsing 🔥 is replaced with a state-aware emoji that reflects the user's actual streak length.

**Streak tiers:**

| Streak | Emoji | Size | Idle state |
|--------|-------|------|------------|
| 0 | 🪵 | 48px | Gentle slow rock (rotate ±8°) |
| 1–6 | 🔥 small | 52px | Soft flicker (scale 0.95→1.05, irregular timing) |
| 7–29 | 🔥 medium | 64px | Energetic flicker + subtle warm glow shadow |
| 30–89 | 🔥 large | 80px | Fast flicker + amber glow ring |
| 90+ | 🔥 extra large | 96px | Rapid flicker + deep orange glow ring |

**Animation loop behaviour:**
- On screen load: plays 2–3 animation loops then settles into a static idle state.
- On user tap: plays 4–5 loops as a reward interaction, then settles again.
- Never loops continuously — avoids overwhelming the user.

**Wood → Fire transition:**
When streak goes from 0 → 1 (user opens streaks screen after their first read day), a one-shot transition plays: 🪵 fades/scales out (200ms), 🔥 scales in from 0.5 → 1.0 with an elastic curve (400ms).

**Streak at risk state:**
If `readDays` does not contain today's date when the user views the screen, the emoji renders at 60% opacity with a slow dimming pulse — a nudge to read before midnight. Clears immediately once `markReadToday()` is called.

---

### 1.2 Longest Streak Display

`longestStreak` already exists in `AppProvider` but is not shown on the Streaks screen. Add a secondary stat line beneath the main counter:

```
🔥 14       Personal best: 21 days
```

Small, subdued text in `AppTheme.tobacco`. No interaction needed.

---

### 1.3 Weekly Dots Differentiation (`weekly_progress_dots.dart`)

Currently dots are binary: read / not read. Introduce a third state:

- **Green dot** — read day (existing)
- **Amber dot** — frozen day (bookmark used, `frozenDays` contains this date)
- **Empty dot** — no reading, no freeze (existing)

Frozen days show a small 🔖 icon or amber fill so users can visually distinguish earned streak days from protected ones.

---

### 1.4 Milestone Celebration Overlay

`pendingMilestone` already tracked in `AppProvider` (set at 7 / 30 / 90 / 365 days). Upgrade the celebration from a simple toast to:

- Full-screen semi-transparent overlay
- Animated badge card scales in with an elastic bounce
- Confetti burst (using an existing Flutter confetti package or custom particle implementation)
- Dismiss on tap or after 4 seconds
- Only fires once per milestone (AppProvider clears `pendingMilestone` after showing)

---

## 2. Bookmark Card Improvements (`bookmark_card.dart`)

### 2.1 Refill Animation

After a bookmark token is used, the empty pennant shows a **liquid fill** animation:

- Progress driven by: `elapsedHours / 168.0` (168 hours = 7-day reset window)
- The pennant fill rises from bottom to top as days pass
- A small `"X days left"` label sits beneath the token (e.g. "5 days left")
- The fill colour matches `AppTheme.brand` at reduced opacity until full

**Token refilled celebration:**
When the user opens the app and a token has refilled since their last visit (`DateTime.now() >= bookmarkResetAt`), a brief pop animation plays on that token (scale 0.8 → 1.1 → 1.0, 300ms) with a soft amber glow — makes the refill moment feel rewarding.

### 2.2 Cross-Device Verification

Bookmark tokens, reset date, and frozen days are already stored in Supabase (`user_preferences` table) and loaded via `UserDataService.fetchAll()`. A test should confirm the load path works correctly on a fresh device login (no regression from existing behaviour).

---

## 3. Profile Sharing & Username

### 3.1 Username at Signup (`signup_screen.dart`)

A `username` field is added to the signup form (between name and email fields).

**Validation rules:**
- Format: `^[a-z0-9_]{3,20}$` (lowercase alphanumeric + underscores, 3–20 chars)
- Uniqueness: real-time availability check, debounced 400ms, queries `profiles.username`
- Content moderation: checked client-side against a blocklist package for immediate feedback AND server-side via `is_username_available()` Postgres function that checks against `blocked_usernames` table
- Blocked names return "not available" without revealing why (prevents gaming the filter)
- Username stored in `profiles.username` (new `TEXT UNIQUE` column)

### 3.2 Share Button (`profile_screen.dart`)

The hardcoded `'JM'` initials in the Profile screen app bar are replaced with an `Icons.ios_share` icon button.

**On tap:**
1. Generates a profile share card PNG: username, streak tier emoji, current streak, badges earned count, passages saved count
2. Opens native share sheet with the PNG **and** the deep link text: `scrollbooks://profile/username`

### 3.3 Public Profile Screen (new route: `/app/profile/view/:username`)

A read-only screen accessible without auth when the account is public. Shows:

- `@username` + streak tier emoji
- Current streak + longest streak
- Badges earned (genre + longevity grid; locked badges hidden from public view)
- Passages saved count (number only — no text content shown)
- **Follow / Following button** — taps to toggle follow state, writes to `follows` table
- Follower count + Following count (tappable labels, list views deferred to feed feature)

**When private:** Shows "This profile is private 🔒" with no other data.

### 3.4 Deep Link Routing

Uses the existing `app_links` package (already in `pubspec.yaml`). The URI scheme `scrollbooks://profile/:username` is handled in the router to navigate to `/app/profile/view/:username`. If the app is not installed, the link is inert (web fallback deferred).

---

## 4. Settings Additions (`settings_screen.dart`)

Two new settings items:

**Username** — displays current `@username`. "Edit" opens a bottom sheet with the same validation as signup (availability check + profanity filter). Server-side update via `profiles` upsert.

**Account Visibility** — toggle between `Public` (default) and `Private`. Stored as `profiles.is_private`. On switching to Private, brief confirmation text: "Your profile will be hidden from non-followers."

---

## 5. Follow System (Supabase)

### `follows` table

```sql
follows (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
)
```

RLS policies:
- SELECT: allowed if `following_id`'s profile is public, OR if the viewer is the follower/following
- INSERT: `follower_id = auth.uid()` only
- DELETE: `follower_id = auth.uid()` only

Future use: the `follows` table is the foundation for a reading activity feed (see who your friends are reading, their streaks, passages saved).

---

## 6. Supabase Schema Changes

See SQL migration below. Tables/columns changed:

| Change | Detail |
|--------|--------|
| `profiles.username` | New `TEXT UNIQUE NOT NULL` column |
| `profiles.is_private` | New `BOOLEAN DEFAULT FALSE` column |
| `blocked_usernames` | New table with initial word list |
| `is_username_available()` | New Postgres function |
| `follows` | New table with RLS |

---

## Out of Scope (deferred)

- Social feed / activity timeline
- Follow request / approval flow (private account follow requests)
- Username change rate limiting
- Web fallback page for `scrollbooks://` deep links
- Push notifications for new followers
- Universal Links (HTTPS scheme) — upgrade path from custom URI scheme
