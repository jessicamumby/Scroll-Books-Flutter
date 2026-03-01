# Email Confirm Router Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redirect authenticated users away from `/email-confirm` automatically so tapping the confirmation email link lands them on `/app/library` without any extra taps.

**Architecture:** One-line change in `lib/core/router.dart`. The router already has a rule `if (authed && publicOnly.contains(loc)) return '/app/library'` — `/email-confirm` just needs to be added to that list. When `getSessionFromUrl` creates a session, `_AuthNotifier` fires, the router re-evaluates, and this rule now triggers.

**Tech Stack:** Flutter, `go_router ^13.x`

---

## Background: why the bug exists

After sign-up, the user lands on `/email-confirm`. When they tap the confirmation link, `_handleDeepLinks()` in `main.dart` calls `getSessionFromUrl(uri)`, which creates a session. `_AuthNotifier` fires `notifyListeners()`, causing the router to re-evaluate its redirect rules. The rules are:

```dart
if (!authed && !onboarded && requiresAuth) return '/onboarding';
if (!authed && requiresAuth) return '/login';
if (authed && !onboarded && loc != '/onboarding' && loc != '/email-confirm') return '/onboarding';
if (authed && publicOnly.contains(loc)) return '/app/library';
```

`publicOnly` is `['/', '/login', '/signup', '/forgot-password']`. `/email-confirm` is not in the list, so the fourth rule never fires, and the user stays on the screen.

---

### Task 1: Add `/email-confirm` to `publicOnly`

**Files:**
- Modify: `lib/core/router.dart` (line 41)

> Note: The router's `_isAuthenticated` getter reads directly from `Supabase.instance.client.auth.currentSession`. The test harness uses `EmptyLocalStorage`, so `currentSession` is always null in tests — authenticated redirect behaviour cannot be unit-tested without mocking the Supabase internals. The change is verified by running the full suite (nothing breaks) and the manual smoke test.

---

**Step 1: Run the existing test suite as baseline**

```bash
cd /path/to/worktree
flutter test
```

Expected: 94 tests pass.

**Step 2: Make the change**

In `lib/core/router.dart`, line 41, change:

```dart
// BEFORE:
final publicOnly = ['/', '/login', '/signup', '/forgot-password'];

// AFTER:
final publicOnly = ['/', '/login', '/signup', '/forgot-password', '/email-confirm'];
```

**Step 3: Run the test suite again**

```bash
flutter test
```

Expected: still 94 tests pass (no regressions).

**Step 4: Commit**

```bash
git add lib/core/router.dart
git commit -m "fix: redirect authenticated users away from /email-confirm"
```

---

## Manual Smoke Test

After merging and running on a physical device:

1. Sign up with a real email address
2. Check inbox → tap the confirmation link
3. The app should open and immediately navigate to `/app/library` — no "Already confirmed? Log in" tap required
