# Bookmark Persistence Fix Design

**Date:** 2026-03-08
**Status:** Approved

---

## Problem

Bookmark tokens reset to 2 after force-closing the app, even after the user has spent them.

**Root cause:** `UserDataService.fetchAll` queries `user_preferences` with `.select('reading_style')` only. The fields `bookmark_tokens`, `bookmark_reset_at`, and `frozen_days` are never fetched from Supabase. On every app load, `data.bookmarkTokens` is `null`, which defaults to `2` in the `UserData` constructor, overwriting the correctly-saved spent state in SharedPreferences.

**Reproduction:**
1. Use both bookmark tokens (SharedPreferences: 0, Supabase user_preferences: 0)
2. Force-close the app
3. Reopen → `fetchAll` returns `bookmarkTokens: null → 2` → overrides local 0 → user sees 2 tokens

---

## Solution

**Option A (chosen): Fix the SELECT query**

Change the `user_preferences` query in `UserDataService.fetchAll` to include all bookmark fields:

```dart
// Before
supabase
    .from('user_preferences')
    .select('reading_style')
    .eq('user_id', userId)
    .maybeSingle(),

// After
supabase
    .from('user_preferences')
    .select('reading_style, bookmark_tokens, bookmark_reset_at, frozen_days')
    .eq('user_id', userId)
    .maybeSingle(),
```

No other changes required. The existing load/override flow is correct:
- SharedPreferences loaded first → instant offline state
- Supabase result overrides → authoritative cross-device state
- `resetBookmarksIfExpired()` runs after both → correct reset behaviour

---

## Out of Scope

- No changes to `useBookmarkToken`, `saveBookmarkState`, or `resetBookmarksIfExpired`
- No changes to SharedPreferences write paths
- No UI changes

---

## Testing

Add one test to `test/services/user_data_service_test.dart` (or a new `bookmark_fetch_test.dart`) confirming that when Supabase returns `bookmark_tokens: 1`, `fetchAll` surfaces `bookmarkTokens: 1` rather than the default `2`.

Existing bookmark widget tests cover the spend/display flow.
