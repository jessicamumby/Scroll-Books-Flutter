# Remove Hardcoded Header Avatar Button Design

**Date:** 2026-03-08
**Status:** Approved

---

## Problem

The `SharedHeader` widget renders a gradient avatar circle (40×40px, tomato→amber) in the top right corner of the Library and Streaks screens. It has no `onTap` handler and is purely decorative — it serves no function. The widget also owns a `_initials` getter that reads from Supabase auth, pulling in a `supabase_flutter` import solely to power this unused button.

---

## Solution

**Delete everything related to the avatar from `SharedHeader`:**

- Remove the avatar `Container` widget (the 40×40 gradient circle)
- Remove the `_initials` getter (no longer needed)
- Remove the `import 'package:supabase_flutter/supabase_flutter.dart'` (no longer needed)
- Replace the `Row(mainAxisAlignment: spaceBetween, ...)` wrapper with just the title `Column` directly, since there is now only one child

The outer `Container` and its padding remain unchanged. The call signature `SharedHeader(heading: '...')` is unchanged — no edits needed in `library_screen.dart` or `streaks_screen.dart`.

---

## Out of Scope

- No changes to `library_screen.dart` or `streaks_screen.dart`
- No navigation, state, or data changes
- No other screens use `SharedHeader`

---

## Testing

Update any `SharedHeader` widget tests that assert the avatar circle exists. Run the full test suite to confirm no regressions.
