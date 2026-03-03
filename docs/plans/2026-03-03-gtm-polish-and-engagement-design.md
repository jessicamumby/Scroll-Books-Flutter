# GTM Polish & Engagement Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:writing-plans to write the implementation plan for this design.

**Goal:** Polish the Scroll Books Flutter app to feel premium and shareable for the #BookTok audience, add Duolingo-inspired streak engagement mechanics, and close all testing/code quality gaps — together enabling user growth through organic sharing.

**Target user:** Social/TikTok readers (#BookTok crowd) — want to share quotes, look literary, participate in culture.

**Primary GTM lever:** Every shared screenshot or streak card is organic acquisition. Polish makes sharing feel worth doing; the streak card and quote share mechanics make sharing automatic.

---

## 1. Reader Card Polish

**Problem:** The reader card (`lib/widgets/reader/reader_card.dart`) barely expresses the Warm Punch brand. It's a cream box with italic Lora text — functional but not distinctive.

**Changes:**
- **Brand accent left border** — a 3px vertical brand-red (`AppTheme.brand`) left border on the card container. Small but instantly says "this is Scroll Books."
- **Stronger card/background contrast** — increase border thickness on the card and use a slightly deeper surface shade to make the card feel physically present, like a page sitting on a surface.
- **Better page label** — the "p. 42 · 89%" label should feel like an editorial footnote. Slightly larger (13px), use `AppTheme.tobacco` instead of `AppTheme.pewter`, and add a small brand dot separator instead of the middot.
- **Share hint** — a very subtle one-time tooltip on first open: "Hold to share this passage" (shown once via SharedPreferences flag). Disappears after 3 seconds. Ensures users discover the share mechanic that drives acquisition.

---

## 2. Landing Screen

**Problem:** Currently "Scroll.Books" + subtitle + two buttons. Emotionally flat — no reason for a stranger to care.

**Changes:**
- **Rotating hero passage** — a `PageView` or `AnimatedSwitcher` cycling through 2–3 short passages from Moby Dick, styled identically to the in-app reader card (same font, same cream card). Let the product demo itself from the first screen.
- **Punchy tagline** — e.g. *"The great books. One page at a time."* — emotional promise, not a feature list. Displayed in Lora, brand ink colour.
- **Bold CTA button** — Sign Up button uses brand red (`AppTheme.brand`) as background with white text, styled with rounded corners. Not generic Material grey.
- **Social proof** — a small counter below the CTAs: *"Join 1,200+ readers"* or *"1,247 passages shared this week."* Hardcoded to start, replaced with real data when available.

---

## 3. Book Covers — Real Art with Warm Punch Glaze

**Problem:** Book cards in the library use abstract dark gradients that feel disconnected from the Warm Punch palette and are visually interchangeable.

**Approach:** Source public domain cover art for each of the 6 books. Apply a Warm Punch branded colour overlay using Flutter's `ColorFiltered` widget with `BlendMode.multiply` — this tints the real cover with a warm amber/red tone while preserving the recognisable imagery.

**Per book:**
- Moby Dick — classic Rockwell Kent woodcut cover (public domain)
- Pride and Prejudice — period illustration cover
- Jane Eyre — Victorian-era edition cover
- Don Quixote — Gustave Doré illustrations
- The Great Gatsby — original Cugat painting (1925 edition, public domain)
- Frankenstein — original 1818 edition frontispiece

**Implementation:** `Image.asset` with a `ColorFiltered` overlay:
```dart
ColorFiltered(
  colorFilter: ColorFilter.mode(
    AppTheme.brand.withOpacity(0.25),
    BlendMode.multiply,
  ),
  child: Image.asset('assets/covers/${book.id}.jpg', fit: BoxFit.cover),
)
```

Store images in `assets/covers/` and register in `pubspec.yaml`.

---

## 4. Stats Screen — Duolingo-Inspired Engagement

**Problem:** Stats screen shows streak number and a basic calendar grid. No milestones, no passages counter, no share mechanic.

**Research basis:** Users who hit a 7-day streak are 3.6x more likely to stay engaged. Milestone animations increase 7-day retention by +1.7%. Streaks work — but only if they feel worth protecting and worth showing off.

### 4a. New Metrics

**Passages read counter:**
- Track total passages read in `app_provider.dart` (increment on each `_onPageChanged` event in reader).
- Persist in Supabase `user_preferences` table as `passages_read` integer.
- Display prominently on stats screen: a large number with "passages read" label in Lora.

**Longest streak:**
- Store `longest_streak` in Supabase `user_preferences`.
- Update whenever current streak exceeds stored best.
- Display current streak + all-time best on the stats screen.

### 4b. Heatmap Intensity

Replace binary (read/didn't read) calendar dots with **opacity-based intensity**:
- Track passages read per day in `read_days` table (add a `count` column, or keep a separate `daily_passages` table).
- Render calendar cells with opacity scaled to passage count: 1–5 passages = 30% opacity, 6–15 = 60%, 16+ = 100% brand red.
- Shows heavy reading days at a glance — rewards binge reading sessions.

### 4c. Streak Milestones

At day thresholds **7, 30, 100** — show a full-screen celebration overlay:
- Large animated fire emoji (scale + fade in, then pulse)
- Bold milestone message: *"30 days. You're on fire."*
- Streak count in giant Lora display text
- "Share this moment" button (see 4d)
- Dismissable by tap

Trigger: check on app load whether current streak crosses a milestone threshold that hasn't been celebrated yet. Store `last_celebrated_milestone` in SharedPreferences.

### 4d. Shareable Streak Card

**The viral mechanic.** A "Share streak" button (on stats screen + in milestone celebration) generates a branded image card:

Layout:
```
┌──────────────────────────────────┐
│  🔥                              │
│                                  │
│  42                              │  ← Lora, 96px, brand red
│  days reading streak             │  ← Nunito, 18px, tobacco
│                                  │
│  Moby Dick · Herman Melville     │  ← current book, 13px, pewter
│                                  │
│  scroll.books                    │  ← wordmark, bottom right
└──────────────────────────────────┘
Background: AppTheme.page (#FFF9F2)
Card: 1080×1080px (Instagram square)
```

Implementation: Use Flutter's `RepaintBoundary` + `RenderRepaintBoundary.toImage()` to render the card widget to a PNG, then share via `share_plus` as an `XFile`.

---

## 5. Onboarding Fixes

### 5a. Vertical Centering

**Problem:** Card content sits near the top of each card.

**Fix:** Change `crossAxisAlignment: CrossAxisAlignment.start` and `mainAxisAlignment` to `MainAxisAlignment.center` in each card's Column. Review all 5 cards for consistent vertical centering.

### 5b. Card Animations

Each card gets one animated element that communicates the feature kinetically:

| Card | Animation |
|------|-----------|
| Read in chunks | Book icon with pages "fanning" open (AnimatedBuilder rotating pages) |
| Build a Streak | 🔥 fire emoji with continuous scale pulse + orange glow (Lottie or custom AnimationController) |
| The classics, free | Subtle sparkle/glint sweeping across the title text |
| Long press to share | Existing ripple animation — enhance with a "share" icon rising upward |
| Style picker | Existing scroll preview — keep as-is |

All animations loop continuously on the card. Amplitude is subtle — enough to catch the eye, not distracting.

---

## 6. Code Quality — All Gaps

### 6a. Auth Loading States

**Problem:** Signup, login, and change password buttons have no loading indicator. Users can double-tap and fire multiple Supabase auth requests.

**Fix:** Add `_isLoading` state bool to each auth screen. On submit: `setState(() => _isLoading = true)`. Disable button and show `CircularProgressIndicator` inside it while loading. On completion (success or error): `setState(() => _isLoading = false)`.

Affected screens:
- `lib/screens/signup_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/change_password_screen.dart`
- `lib/screens/forgot_password_screen.dart`

### 6b. Auth Error Display

**Problem:** When Supabase auth fails (email already registered, weak password, wrong credentials), the error is silently swallowed and the user sees nothing.

**Fix:** Catch `AuthException` specifically and display the message in a `Text` widget in brand error colour (`AppTheme.sienna`) above the submit button.

```dart
try {
  await supabase.auth.signUp(...);
} on AuthException catch (e) {
  setState(() => _error = e.message);
} catch (_) {
  setState(() => _error = 'Something went wrong. Please try again.');
}
```

Show `_error` as a red text widget below the form fields when non-null.

### 6c. Silent Error Swallowing

**Problem:** ~12 bare `catch (_) {}` blocks throughout the codebase hide failures during development.

**Fix:** Replace with `catch (e, st)` and `debugPrint('Error: $e\n$st')` in debug builds. Does not show errors to users — only surfaces them during development.

Files to audit:
- `lib/screens/reader_screen.dart` (multiple)
- `lib/screens/signup_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/forgot_password_screen.dart`
- `lib/providers/app_provider.dart`

### 6d. Mock Supabase in Tests

**Problem:** `mocktail` is installed but the Supabase client is never faked. `UserDataService` tests test the model class only — not query logic.

**Fix:** Create a `MockSupabaseClient` using mocktail. Inject it via a test helper. Write tests for:
- `UserDataService.fetchAll()` — verify it calls the right table queries
- `UserDataService.addToLibrary()` — verify upsert is called with correct args
- `UserDataService.syncProgress()` — verify upsert with chunk_index
- `UserDataService.markReadToday()` — verify date string format

### 6e. Test the Share Flow

**Problem:** The long press → `_share()` path in `reader_screen.dart` has zero test coverage.

**Fix:** Add widget tests that:
- Simulate long press on a `ReaderCard` in the reader
- Verify `_share()` is called with the correct text
- Verify the shared text includes "— Read on Scroll Books"

Mock `share_plus` for test isolation.

### 6f. Test the Progress Sync Flow

**Problem:** The 3-second debounce + `markReadToday` path is not tested.

**Fix:** Add tests for `_onPageChanged`:
- Verify debounce timer is set on page change
- Verify `SharedPreferences.setInt` is called after 3 seconds
- Verify `UserDataService.syncProgress` is called when user is authenticated
- Verify `UserDataService.markReadToday` is called on page change

Use `fake_async` package for time-based tests.

---

## Scope Summary

| Area | Items |
|------|-------|
| Reader Card | 4 polish changes |
| Landing Screen | Rotating excerpt + tagline + CTA + social proof |
| Book Covers | 6 public domain covers + glaze overlay |
| Stats Screen | Passages counter + longest streak + intensity heatmap + milestones + shareable card |
| Onboarding | Vertical centering + 4 card animations |
| Code Quality | Loading states (4 screens) + error display (4 screens) + debug logging + 3 test suites |

**What this achieves:** App feels premium enough to share → share mechanic gets discovered → streak cards create organic #BookTok content → new users arrive at a landing screen with social proof → sign up.
