# Onboarding Flow — Design

**Date:** 2026-02-26
**Status:** Approved

---

## Goal

Build a complete new-user flow: signup screen, email confirmation screen, and a 3-card scrollable onboarding experience that mirrors the app's core reading mechanic. Existing users can replay onboarding from their Profile.

---

## Full Flow

```
New user:   Landing → Signup → Email Confirm → Onboarding → Library
Returning:  Landing → Login  → Library
Replay:     Profile → Onboarding → Library
```

The router detects auth session changes via Supabase. When a new user confirms their email and Supabase creates their session, the router sees them as authenticated with `onboarding_completed = false` and redirects to `/onboarding`. After tapping "Start reading →", the flag is set to `true` in `shared_preferences` and they land in the library permanently.

---

## Signup Screen (`/signup`)

- No AppBar — full-screen card-style layout on `AppTheme.page`
- **Top:** "Scroll Books" (Playfair Display, small), amber subtitle "Create your account"
- **Fields** (existing `InputDecorationTheme` — DM Sans, border outline, 12px radius):
  - First name
  - Email
  - Password (obscured, show/hide toggle)
- **CTA:** `ElevatedButton` "Create account" — amber, full-width
- **Error state:** inline error text below relevant field in `AppTheme.sienna`
- **Footer:** "Already have an account? Log in" → `context.go('/login')`
- **On success:** Supabase `signUp()` → navigate to `/email-confirm?email=<email>`

---

## Email Confirmation Screen (`/email-confirm`)

- No AppBar — centred content on `AppTheme.page`
- **Icon:** `Icons.mail_outline`, size 72, `AppTheme.amber`
- **Headline:** "Check your inbox." — Playfair Display, 28px, `AppTheme.ink`
- **Body:** "We sent a confirmation link to **<email>**" — DM Sans, 16px, `AppTheme.tobacco`; email in bold
- **Resend:** `TextButton` "Resend email" — amber — calls Supabase `resend()`; shows inline "Sent!" state change (no toast library)
- **Footer:** "Already confirmed? Log in" → `context.go('/login')`
- **Auto-advance:** Supabase auth listener detects new session when user clicks email link → router redirects to `/onboarding` automatically

---

## Onboarding Screen (`/onboarding`)

Vertical `PageView` with `viewportFraction: 0.88` — ~12% of the next card peeks at the bottom, mirroring the reader experience.

**Three cards, each on `AppTheme.surface` with `AppTheme.border` stroke, 16px corner radius, 32px padding:**

| Card | Icon | Headline | Body |
|---|---|---|---|
| 1 | 📖 | *Read in chunks.* | Skip doomscrolling, read great books one passage at a time. No pressure to finish, just read. |
| 2 | 🔥 | *Build a streak.* | Open the App instead of doomscrolling, watch your streak grow. |
| 3 | 🏛️ | *The classics, free.* | Six of the greatest books ever written. Yours, at no cost. |

**Card styling:**
- Headline: Playfair Display, 32px, w700, `AppTheme.ink`
- Body: DM Sans, 16px, `AppTheme.tobacco`
- Screen background: `AppTheme.page` so cards float with visual depth

**Navigation:**
- Dot indicator: 3 dots on right side, `AppTheme.amber` for active, `AppTheme.fog` for inactive
- Card 3 only: `ElevatedButton` "Start reading →" pinned to bottom of card, amber, full-width
- CTA action: sets `onboarding_completed = true` in `shared_preferences`, then `context.go('/app/library')`

---

## Profile Replay Entry Point

In `ProfileScreen`, add a `ListTile` above the sign-out button:
- Label: "How Scroll Books works" — DM Sans, `AppTheme.ink`
- Trailing: chevron icon in `AppTheme.pewter`
- Separator: `AppTheme.borderSoft` divider above
- On tap: `context.push('/onboarding')`
- CTA on last onboarding card always calls `context.go('/app/library')`

---

## State Persistence

- Key: `onboarding_completed` (bool) in `shared_preferences`
- Loaded into `AppProvider` at init (alongside `library`, `progress`, `readDays`)
- `AppProvider.completeOnboarding()`: sets flag in shared_preferences, calls `notifyListeners()`
- Router redirect: authenticated + `!onboardingCompleted` → `/onboarding`

---

## What Changes

| File | Change |
|---|---|
| Create: `lib/screens/signup_screen.dart` | Name, email, password form → Supabase `signUp()` → `/email-confirm` |
| Create: `lib/screens/email_confirm_screen.dart` | "Check your inbox" screen with email, resend button, login link |
| Create: `lib/screens/onboarding_screen.dart` | Vertical `PageView` (viewportFraction 0.88), 3 cards, dot indicator, "Start reading →" CTA |
| Modify: `lib/core/router.dart` | Wire `/signup`, `/email-confirm` routes; add redirect for `!onboardingCompleted` |
| Modify: `lib/providers/app_provider.dart` | Add `onboardingCompleted`, `completeOnboarding()`, load from `shared_preferences` |
| Modify: `lib/screens/profile_screen.dart` | Add "How Scroll Books works" `ListTile` |
| Create: `test/screens/signup_screen_test.dart` | Form renders, validation, success navigates to email confirm |
| Create: `test/screens/email_confirm_screen_test.dart` | Screen renders with email, resend button, login link |
| Create: `test/screens/onboarding_screen_test.dart` | 3 cards render, dot indicator, CTA navigates to library |

## What Does Not Change

- Landing screen (Sign Up button route already defined)
- Login screen
- Library, Reader, Stats screens
- `AppTheme`
- Supabase tables (onboarding flag is local via `shared_preferences`)
