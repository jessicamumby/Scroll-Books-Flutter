# Profile Screen: Show Username Instead of Email

**Date:** 2026-03-08
**Status:** Approved

---

## Problem

The profile screen shows the user's email address below the AppBar. Since users now set a `@username` handle during signup, email is the wrong identifier to surface — it's private, not their public identity, and the username is already used for profile sharing.

The share profile button lives in the AppBar actions, disconnected from the identity it shares.

---

## Solution

**Single-file change in `lib/screens/profile_screen.dart`:**

1. Replace the `Text(email)` sliver with a `Row` containing:
   - `@${provider.username}` text on the left (same `AppTheme.tobacco` style, `fontSize: 15`)
   - A small share icon (`Icons.share, size: 18`) on the right, wired to `_shareProfile`, disabled when `provider.username == null`

2. Remove the share `IconButton` from `AppBar` actions — the settings gear stays.

3. Remove `_currentEmail()` method — dead code.

4. Remove `import 'package:supabase_flutter/supabase_flutter.dart'` — only needed by `_currentEmail()`. The `_userId` getter uses `supabase` from `supabase_client.dart` which already imports it.

---

## Out of Scope

- No changes to `_shareProfile`, `_profileShareCardKey`, or `ProfileShareCard`
- No changes to the settings screen or any other file
- No changes to `AppProvider` — `username` is already loaded
- No null-safety changes needed for existing users (app is new, all users have usernames)

---

## Testing

Add or update `test/screens/profile_screen_test.dart` to assert:
- `@username` text is visible
- Email text is not visible
- Share icon appears in the username row (not in the AppBar)
