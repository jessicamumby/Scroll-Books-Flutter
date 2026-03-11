# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Scroll Books is a Flutter reading app — "the classic library, one chunk at a time." Users read paginated book chunks from cloud storage, track daily reading streaks, earn milestone badges, and share achievements. Backend is Supabase (auth + database). Flutter SDK >=3.7.0 <4.0.0.

## Build & Development Commands

```bash
# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/providers/app_provider_test.dart

# Run tests matching a name pattern
flutter test --name "streak"

# Analyze code (linting)
flutter analyze

# Get dependencies
flutter pub get
```

## Architecture

### State Management: Provider + ChangeNotifier

Single `AppProvider` in `lib/providers/app_provider.dart` holds all app state: user library, reading progress, read days, streaks, bookmarks, saved passages, profile data. It uses `SharedPreferences` for offline caching and syncs with Supabase via `UserDataService`.

### Routing: GoRouter

Defined in `lib/core/router.dart`. Auth-based redirects send unauthenticated users to `/login` and first-time users to `/onboarding`. Authenticated routes live under `/app/*` with a bottom-nav shell (`AppShell` widget). The reader is a standalone route at `/read/:bookId`.

### Data Flow

`UserDataService` (`lib/services/user_data_service.dart`) fetches all user data from Supabase in parallel batches. `AppProvider` calls this on init, caches results in `SharedPreferences`, and applies optimistic updates (UI updates immediately, backend syncs async).

### Key Directories

- `lib/core/` — Router, theme (`AppTheme` with "Warm Punch" palette), onboarding state, Supabase client
- `lib/providers/` — `AppProvider` (single ChangeNotifier for all state)
- `lib/services/` — `UserDataService` (all Supabase queries)
- `lib/models/` — `SavedPassage`, `UserPublicProfile`
- `lib/data/` — Static book catalogue
- `lib/screens/` — All screen widgets
- `lib/widgets/` — Reusable components; `widgets/reader/` for reader-specific widgets
- `lib/utils/` — Streak calculation, image sharing utilities

### Design System

`lib/core/theme.dart` defines the "Warm Punch" palette: Tomato primary (#D94F30), Cream/Parchment neutrals, Amber/Sage accents. Typography uses PlayfairDisplay via Google Fonts. Standard card radius is 16px, button radius 12px.

### Environment Configuration

Uses `flutter_dotenv` with a `.env` file containing `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `BOOKS_BUCKET_BASE_URL`.

## Workflow

Every code change must be committed on a feature branch and submitted as a PR. Never commit directly to `main`.

## Testing

Tests use `flutter_test` with `mocktail` for mocking. Test files mirror the lib structure under `test/` (e.g., `test/providers/`, `test/screens/`, `test/utils/`).

## Platform Notes

- **iOS**: Target iOS 11.0+, deep link scheme `scrollbooks://profile/*`
- **Android**: Deep link intent filter for `scrollbooks://auth-callback`
