# Back Navigation — Design

**Date:** 2026-02-25
**Status:** Approved

---

## Goal

Fix back navigation across the app so pressing the Android system back button never unexpectedly closes the app, and `BookDetailScreen` has a working back button to return to Library.

---

## Behaviour After Fix

| Screen | System back / AppBar back |
|---|---|
| `LibraryScreen` | Exit app (home tab — standard Android behaviour) |
| `BookDetailScreen` | Back to Library |
| `StatsScreen` | Back to Library |
| `ProfileScreen` | Back to Library |
| `ReaderScreen` | Back to Library (already works — no change) |

---

## Design

### Change 1 — `LibraryScreen`: push BookDetail instead of go

In `lib/screens/library_screen.dart` line 44, change:

```dart
onTap: () => context.go('/app/library/${book.id}'),
```

to:

```dart
onTap: () => context.push('/app/library/${book.id}'),
```

`context.push()` adds the route to the navigation stack. Flutter's `AppBar` automatically shows a back arrow, and the Android system back button calls `context.pop()` to return to Library. No changes needed to `BookDetailScreen` itself.

### Change 2 — `AppShell`: intercept back on non-home tabs

Wrap the `Scaffold` in `AppShell` with `PopScope`:

```dart
PopScope(
  canPop: _selectedIndex(context) == 0,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) context.go('/app/library');
  },
  child: Scaffold(...),
)
```

- On `LibraryScreen` (index 0): `canPop: true` → system back exits the app as normal.
- On `StatsScreen` / `ProfileScreen` (index 1, 2): `canPop: false` → back navigates to Library instead of closing.

---

## What Changes

| File | Change |
|---|---|
| `lib/screens/library_screen.dart` | `context.go` → `context.push` for book detail route (1 line) |
| `lib/widgets/app_shell.dart` | Wrap `Scaffold` in `PopScope` |

## What Does Not Change

- `ReaderScreen` back button (already works)
- `BookDetailScreen` (gets back arrow automatically via push)
- Router configuration
- All other screens
