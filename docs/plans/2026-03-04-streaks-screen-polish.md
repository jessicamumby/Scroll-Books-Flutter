# Streaks Screen Polish — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace all mocked data in the Streaks screen with live calculations, implement bookmark token reset, add backend persistence for bookmark state, and fix the StreakCounter visual issues.

**Architecture:** Eight independent tasks in dependency order. Tasks 1–5 are purely local (no backend). Task 6–7 are the bookmark reset (local logic then UI). Task 8 adds Supabase persistence for bookmark state. All tasks follow TDD: write failing test → implement → verify green → commit.

**Tech Stack:** Flutter/Dart, `shared_preferences`, `supabase_flutter`, `google_fonts`, `provider`, `flutter_test`

**Design doc:** `docs/plans/2026-03-04-streaks-screen-polish-design.md`

**Test count baseline:** Run `flutter test --no-pub` before starting. Note the passing count — each task should increase it.

---

### Task 1: Fix milestone thresholds + weekly frozen days

Two one-line fixes. No new tests — the changes are so small that existing tests cover them.

**Files:**
- Modify: `lib/providers/app_provider.dart:55`
- Modify: `lib/screens/streaks_screen.dart:57-63`

**Step 1: Fix milestone list**

In `lib/providers/app_provider.dart`, find `_checkMilestone` (around line 55). Change:

```dart
const milestones = [7, 30, 100];
```

To:

```dart
const milestones = [7, 30, 90, 365];
```

**Step 2: Fix weekly dots to include frozen days**

In `lib/screens/streaks_screen.dart`, `_StreaksTab._getWeeklyCompletion` currently takes only `readDays`. Add `frozenDays` parameter and check both:

Replace the method signature and body:

```dart
List<bool> _getWeeklyCompletion(
  List<String> readDays,
  List<String> frozenDays,
) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return List.generate(7, (i) {
    final day = monday.add(Duration(days: i));
    final dayStr = day.toIso8601String().substring(0, 10);
    return readDays.contains(dayStr) || frozenDays.contains(dayStr);
  });
}
```

Then update the call site inside `build` — currently:

```dart
final weeklyCompletion = _getWeeklyCompletion(provider.readDays);
```

Change to:

```dart
final weeklyCompletion = _getWeeklyCompletion(
  provider.readDays,
  provider.frozenDays,
);
```

**Step 3: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all existing tests pass, 0 failures.

**Step 4: Commit**

```bash
git add lib/providers/app_provider.dart lib/screens/streaks_screen.dart
git commit -m "fix: milestone thresholds [7,30,90,365] and weekly dots include frozen days"
```

---

### Task 2: Add genres to Book model and catalogue

**Files:**
- Modify: `lib/data/catalogue.dart`
- Modify: `test/data/catalogue_test.dart`

**Step 1: Write a failing test**

In `test/data/catalogue_test.dart`, inside the `group('catalogue', ...)` block, add after the existing tests:

```dart
    test('every book has a non-empty genres list', () {
      for (final book in catalogue) {
        expect(
          book.genres,
          isNotEmpty,
          reason: '${book.id} has no genres',
        );
      }
    });

    test('moby-dick genres are Adventure and Gothic', () {
      final book = getBookById('moby-dick')!;
      expect(book.genres, containsAll(['Adventure', 'Gothic']));
    });
```

**Step 2: Run to verify it fails**

```bash
flutter test test/data/catalogue_test.dart --no-pub
```

Expected: FAIL — `getter 'genres' isn't defined`.

**Step 3: Add genres to Book model**

In `lib/data/catalogue.dart`, add `genres` to `Book`:

```dart
class Book {
  final String id;
  final String title;
  final String author;
  final int year;
  final String blurb;
  final String price;
  final bool isFree;
  final bool hasChunks;
  final String cover;
  final List<String> sections;
  final List<String> genres;  // ← ADD

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.blurb,
    required this.price,
    required this.isFree,
    required this.hasChunks,
    required this.cover,
    required this.sections,
    required this.genres,     // ← ADD
  });
}
```

**Step 4: Add genres to each book in catalogue**

Update each `Book(...)` entry in the `catalogue` list:

```dart
  Book(
    id: 'moby-dick',
    // ... existing fields unchanged ...
    sections: ['Free Books', 'Trending'],
    genres: ['Adventure', 'Gothic'],
  ),
  Book(
    id: 'pride-and-prejudice',
    // ... existing fields unchanged ...
    sections: ['Free Books', 'New'],
    genres: ['Romance'],
  ),
  Book(
    id: 'jane-eyre',
    // ... existing fields unchanged ...
    sections: ['Free Books', 'Trending'],
    genres: ['Gothic', 'Romance'],
  ),
  Book(
    id: 'don-quixote',
    // ... existing fields unchanged ...
    sections: ['Free Books', 'New'],
    genres: ['Adventure', 'Satire'],
  ),
  Book(
    id: 'great-gatsby',
    // ... existing fields unchanged ...
    sections: ['New', 'Trending'],
    genres: ['Satire'],
  ),
  Book(
    id: 'frankenstein',
    // ... existing fields unchanged ...
    sections: ['Free Books', 'Trending'],
    genres: ['Gothic', 'Sci-Fi'],
  ),
```

**Step 5: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass. If any other file constructs a `Book(...)` manually without `genres:`, add `genres: []` to it.

**Step 6: Commit**

```bash
git add lib/data/catalogue.dart test/data/catalogue_test.dart
git commit -m "feat: add genres field to Book model with mappings for all 6 catalogue books"
```

---

### Task 3: genreCounts getter in AppProvider

**Files:**
- Modify: `test/providers/app_provider_test.dart`
- Modify: `lib/providers/app_provider.dart`

**Step 1: Write failing tests**

In `test/providers/app_provider_test.dart`, add a new group after the existing `AppProvider local stats` group:

```dart
  group('AppProvider.genreCounts', () {
    test('returns empty map when no progress', () {
      final provider = AppProvider();
      expect(provider.genreCounts, isEmpty);
    });

    test('counts genres for books with progress > 0', () {
      final provider = AppProvider();
      provider.progress = {'moby-dick': 1}; // genres: Adventure, Gothic
      expect(provider.genreCounts['Adventure'], 1);
      expect(provider.genreCounts['Gothic'], 1);
      expect(provider.genreCounts.containsKey('Romance'), isFalse);
    });

    test('does not count books with progress == 0', () {
      final provider = AppProvider();
      provider.progress = {'moby-dick': 0};
      expect(provider.genreCounts, isEmpty);
    });

    test('counts multiple books in same genre', () {
      final provider = AppProvider();
      // pride-and-prejudice: Romance; jane-eyre: Gothic, Romance
      provider.progress = {
        'pride-and-prejudice': 3,
        'jane-eyre': 1,
      };
      expect(provider.genreCounts['Romance'], 2);
      expect(provider.genreCounts['Gothic'], 1);
    });
  });
```

**Step 2: Run to verify failing**

```bash
flutter test test/providers/app_provider_test.dart --no-pub
```

Expected: FAIL — `getter 'genreCounts' isn't defined`.

**Step 3: Add genreCounts getter to AppProvider**

In `lib/providers/app_provider.dart`, add this import at the top if not already present:

```dart
import '../data/catalogue.dart';
```

Then add the getter anywhere in the class body (e.g., after `bookTotalChunks`):

```dart
  Map<String, int> get genreCounts {
    final counts = <String, int>{};
    for (final book in catalogue) {
      final p = progress[book.id];
      if (p != null && p > 0) {
        for (final g in book.genres) {
          counts[g] = (counts[g] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
```

**Step 4: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/providers/app_provider.dart test/providers/app_provider_test.dart
git commit -m "feat: add genreCounts computed getter to AppProvider"
```

---

### Task 4: Wire GenreBadgesGrid to real data

**Files:**
- Modify: `lib/widgets/genre_badges_grid.dart`
- Modify: `lib/screens/streaks_screen.dart`
- Create: `test/widgets/genre_badges_grid_test.dart`

**Step 1: Write failing tests**

Create `test/widgets/genre_badges_grid_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/genre_badges_grid.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap(Map<String, int> genreCounts) => MaterialApp(
        home: Scaffold(
          body: GenreBadgesGrid(genreCounts: genreCounts),
        ),
      );

  testWidgets('all badges locked when genreCounts is empty', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsNWidgets(6));
  });

  testWidgets('Adventure badge shows as unlocked with 1 book', (tester) async {
    await tester.pumpWidget(_wrap({'Adventure': 1}));
    await tester.pumpAndSettle();
    expect(find.text('1 book read'), findsOneWidget);
    expect(find.text('Locked'), findsNWidgets(5));
  });

  testWidgets('Gothic shows 3 books read when count is 3', (tester) async {
    await tester.pumpWidget(_wrap({'Gothic': 3}));
    await tester.pumpAndSettle();
    expect(find.text('3 books read'), findsOneWidget);
  });
}
```

**Step 2: Run to verify failing**

```bash
flutter test test/widgets/genre_badges_grid_test.dart --no-pub
```

Expected: FAIL — `GenreBadgesGrid` constructor doesn't accept `genreCounts`.

**Step 3: Rewrite GenreBadgesGrid**

Replace the full content of `lib/widgets/genre_badges_grid.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _GenreBadgeSpec {
  final String name;
  final String emoji;
  final Color color;
  const _GenreBadgeSpec(this.name, this.emoji, this.color);
}

const _specs = [
  _GenreBadgeSpec('Adventure',  '⛵', Color(0xFF4A90D9)),
  _GenreBadgeSpec('Romance',    '💌', Color(0xFFD94F7A)),
  _GenreBadgeSpec('Gothic',     '🏚', Color(0xFF6B4C6E)),
  _GenreBadgeSpec('Philosophy', '🪶', Color(0xFF8B7355)),
  _GenreBadgeSpec('Satire',     '🎭', Color(0xFFC4762B)),
  _GenreBadgeSpec('Sci-Fi',     '🔭', Color(0xFF3D7A8A)),
];

class GenreBadgesGrid extends StatelessWidget {
  final Map<String, int> genreCounts;

  const GenreBadgesGrid({super.key, required this.genreCounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENRE BADGES',
          style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: _specs.length,
          itemBuilder: (_, i) {
            final spec = _specs[i];
            final count = genreCounts[spec.name] ?? 0;
            final unlocked = count > 0;
            return _BadgeCard(spec: spec, booksRead: count, unlocked: unlocked);
          },
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final _GenreBadgeSpec spec;
  final int booksRead;
  final bool unlocked;
  const _BadgeCard({required this.spec, required this.booksRead, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.only(top: 18, bottom: 12, left: 8, right: 8),
        decoration: BoxDecoration(
          color: unlocked
              ? spec.color.withValues(alpha: 0.06)
              : AppTheme.cream,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: unlocked
              ? Border.all(color: spec.color.withValues(alpha: 0.20))
              : Border.all(color: AppTheme.inkLight.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: unlocked ? spec.color.withValues(alpha: 0.12) : AppTheme.parchment,
                boxShadow: unlocked
                    ? [BoxShadow(
                        color: spec.color.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )]
                    : null,
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter: unlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                  child: Text(spec.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              spec.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              unlocked
                  ? '$booksRead ${booksRead == 1 ? 'book' : 'books'} read'
                  : 'Locked',
              style: AppTheme.monoLabel(
                fontSize: 10,
                color: AppTheme.inkLight,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Wire in _BadgesTab**

In `lib/screens/streaks_screen.dart`, inside `_BadgesTab.build`, change:

```dart
const GenreBadgesGrid(),
```

To:

```dart
GenreBadgesGrid(genreCounts: provider.genreCounts),
```

**Step 5: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/widgets/genre_badges_grid.dart lib/screens/streaks_screen.dart test/widgets/genre_badges_grid_test.dart
git commit -m "feat: wire GenreBadgesGrid to real genreCounts from AppProvider"
```

---

### Task 5: StreakCounter — animated fire emoji + overflow fix

**Files:**
- Modify: `lib/widgets/streak_counter.dart`
- Create: `test/widgets/streak_counter_test.dart`

**Step 1: Write failing tests**

Create `test/widgets/streak_counter_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/streak_counter.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap() => const MaterialApp(
        home: Scaffold(body: Center(child: StreakCounter(streakCount: 7))),
      );

  testWidgets('displays the streak count', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('uses a 150x150 circle container', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.any((c) =>
          c.constraints?.maxWidth == 150 && c.constraints?.maxHeight == 150),
      isTrue,
      reason: 'Expected a 150x150 Container for the streak circle',
    );
  });

  testWidgets('fire emoji is wrapped in FadeTransition and ScaleTransition', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.byType(FadeTransition), findsOneWidget);
    expect(find.byType(ScaleTransition), findsOneWidget);
  });

  testWidgets('renders without overflow', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

**Step 2: Run to verify failing**

```bash
flutter test test/widgets/streak_counter_test.dart --no-pub
```

Expected: `'uses a 150x150 circle container'` fails (currently 130), `'fire emoji is wrapped in FadeTransition...'` fails (no animation yet).

**Step 3: Rewrite StreakCounter**

Replace the full content of `lib/widgets/streak_counter.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StreakCounter extends StatefulWidget {
  final int streakCount;
  const StreakCounter({super.key, required this.streakCount});

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.tomato.withValues(alpha: 0.08),
            AppTheme.amber.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: AppTheme.tomato.withValues(alpha: 0.20),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: const Text('🔥', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.streakCount}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -1.5,
            ),
          ),
          Text(
            'DAY STREAK',
            style: AppTheme.monoLabel(
              fontSize: 10,
              color: AppTheme.inkLight,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/widgets/streak_counter.dart test/widgets/streak_counter_test.dart
git commit -m "feat: animate fire emoji in StreakCounter and fix circle overflow"
```

---

### Task 6: Bookmark reset logic in AppProvider

**Files:**
- Modify: `test/providers/app_provider_test.dart`
- Modify: `lib/providers/app_provider.dart`

**Step 1: Write failing tests**

In `test/providers/app_provider_test.dart`, add a new group:

```dart
  group('AppProvider.bookmarkResetAt', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('bookmarkResetAt is null initially', () {
      final provider = AppProvider();
      expect(provider.bookmarkResetAt, isNull);
    });

    test('useBookmarkToken sets bookmarkResetAt 7 days from today on first use', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await provider.useBookmarkToken();
      final expected = DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10);
      expect(provider.bookmarkResetAt, expected);
      expect(provider.bookmarkTokens, 1);
    });

    test('useBookmarkToken on second use does not change bookmarkResetAt', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await provider.useBookmarkToken(); // first use — sets resetAt
      final resetAt = provider.bookmarkResetAt;
      await provider.useBookmarkToken(); // second use
      expect(provider.bookmarkResetAt, resetAt); // unchanged
      expect(provider.bookmarkTokens, 0);
    });

    test('resetBookmarksIfExpired resets tokens when date has passed', () async {
      final pastDate = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'bookmark_tokens': 0,
        'bookmark_reset_at': pastDate,
      });
      final provider = AppProvider();
      await provider.resetBookmarksIfExpired();
      expect(provider.bookmarkTokens, 2);
      expect(provider.bookmarkResetAt, isNull);
    });

    test('resetBookmarksIfExpired does nothing when date is in the future', () async {
      final futureDate = DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String()
          .substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'bookmark_tokens': 0,
        'bookmark_reset_at': futureDate,
      });
      final provider = AppProvider();
      await provider.resetBookmarksIfExpired();
      expect(provider.bookmarkTokens, 0);
      expect(provider.bookmarkResetAt, futureDate);
    });
  });
```

**Step 2: Run to verify failing**

```bash
flutter test test/providers/app_provider_test.dart --no-pub
```

Expected: FAIL — `getter 'bookmarkResetAt' isn't defined`, `getter 'resetBookmarksIfExpired' isn't defined`.

**Step 3: Implement in AppProvider**

In `lib/providers/app_provider.dart`, make these changes:

**3a. Add field** after `List<String> frozenDays = [];`:

```dart
String? bookmarkResetAt;
```

**3b. Update `_loadLocalStats`** to load and apply `bookmarkResetAt`:

After loading `bookmarkTokens` (the existing line), add:

```dart
      bookmarkResetAt = prefs.getString('bookmark_reset_at');
```

**3c. Add public `resetBookmarksIfExpired` method** (public so tests can call it directly):

```dart
  Future<void> resetBookmarksIfExpired() async {
    if (bookmarkResetAt == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (today.compareTo(bookmarkResetAt!) >= 0) {
      bookmarkTokens = 2;
      bookmarkResetAt = null;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('bookmark_tokens', 2);
        await prefs.remove('bookmark_reset_at');
      } catch (e, st) {
        debugPrint('AppProvider.resetBookmarksIfExpired error: $e\n$st');
      }
    }
  }
```

**3d. Call `resetBookmarksIfExpired` from `_loadLocalStats`** after loading `bookmarkResetAt`:

```dart
      bookmarkResetAt = prefs.getString('bookmark_reset_at');
      await resetBookmarksIfExpired();
```

**3e. Update `useBookmarkToken`** to set `bookmarkResetAt` on first use:

The current method body:

```dart
  Future<void> useBookmarkToken() async {
    if (bookmarkTokens <= 0) return;
    bookmarkTokens--;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    frozenDays = [...frozenDays, today];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bookmark_tokens', bookmarkTokens);
      await prefs.setString('frozen_days', jsonEncode(frozenDays));
    } catch (e, st) {
      debugPrint('AppProvider.useBookmarkToken error: $e\n$st');
    }
  }
```

Replace with:

```dart
  Future<void> useBookmarkToken() async {
    if (bookmarkTokens <= 0) return;
    final isFirstUse = bookmarkTokens == 2;
    bookmarkTokens--;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    frozenDays = [...frozenDays, today];
    if (isFirstUse) {
      bookmarkResetAt = DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bookmark_tokens', bookmarkTokens);
      await prefs.setString('frozen_days', jsonEncode(frozenDays));
      if (isFirstUse) {
        await prefs.setString('bookmark_reset_at', bookmarkResetAt!);
      }
    } catch (e, st) {
      debugPrint('AppProvider.useBookmarkToken error: $e\n$st');
    }
  }
```

**Step 4: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/providers/app_provider.dart test/providers/app_provider_test.dart
git commit -m "feat: bookmark reset logic — 7-day timer from first use"
```

---

### Task 7: BookmarkCard "Resets in X days" UI

**Files:**
- Modify: `lib/widgets/bookmark_card.dart`
- Modify: `lib/screens/streaks_screen.dart`
- Create: `test/widgets/bookmark_card_test.dart`

**Step 1: Write failing tests**

Create `test/widgets/bookmark_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/bookmark_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({required int remaining, String? resetAt}) => MaterialApp(
        home: Scaffold(
          body: BookmarkCard(
            bookmarksRemaining: remaining,
            bookmarkResetAt: resetAt,
            onUseBookmark: () {},
          ),
        ),
      );

  testWidgets('shows use button when bookmarks remain', (tester) async {
    await tester.pumpWidget(_wrap(remaining: 2, resetAt: null));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use Bookmark'), findsOneWidget);
  });

  testWidgets('shows Resets in X days when tokens = 0 and resetAt is set', (tester) async {
    final futureDate = DateTime.now()
        .add(const Duration(days: 5))
        .toIso8601String()
        .substring(0, 10);
    await tester.pumpWidget(_wrap(remaining: 0, resetAt: futureDate));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resets in 5'), findsOneWidget);
  });

  testWidgets('shows Resets tomorrow when 1 day remains', (tester) async {
    final tomorrowDate = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    await tester.pumpWidget(_wrap(remaining: 0, resetAt: tomorrowDate));
    await tester.pumpAndSettle();
    expect(find.text('Resets tomorrow'), findsOneWidget);
  });

  testWidgets('shows No Bookmarks Left when tokens = 0 and resetAt is null', (tester) async {
    await tester.pumpWidget(_wrap(remaining: 0, resetAt: null));
    await tester.pumpAndSettle();
    expect(find.text('No Bookmarks Left'), findsOneWidget);
  });
}
```

**Step 2: Run to verify failing**

```bash
flutter test test/widgets/bookmark_card_test.dart --no-pub
```

Expected: FAIL — `BookmarkCard` constructor doesn't accept `bookmarkResetAt`.

**Step 3: Update BookmarkCard**

In `lib/widgets/bookmark_card.dart`, add `bookmarkResetAt` parameter and update the button label:

**3a. Add parameter** to constructor:

```dart
class BookmarkCard extends StatelessWidget {
  final int bookmarksRemaining;
  final String? bookmarkResetAt;   // ← ADD
  final VoidCallback onUseBookmark;

  const BookmarkCard({
    super.key,
    required this.bookmarksRemaining,
    this.bookmarkResetAt,           // ← ADD (optional, defaults null)
    required this.onUseBookmark,
  });
```

**3b. Add a helper method** to compute the button label:

```dart
  String _emptyLabel() {
    if (bookmarkResetAt == null) return 'No Bookmarks Left';
    final today = DateTime.now();
    final resetDate = DateTime.parse(bookmarkResetAt!);
    final days = resetDate.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (days <= 1) return 'Resets tomorrow';
    return 'Resets in $days days';
  }
```

**3c. Update the button label** in `build`. The current ternary:

```dart
                  hasBookmarks
                      ? 'Use Bookmark ($bookmarksRemaining remaining)'
                      : 'No Bookmarks Left',
```

Change to:

```dart
                  hasBookmarks
                      ? 'Use Bookmark ($bookmarksRemaining remaining)'
                      : _emptyLabel(),
```

**Step 4: Update call site in streaks_screen.dart**

In `lib/screens/streaks_screen.dart`, `_StreaksTab.build`, the current call:

```dart
                BookmarkCard(
                  bookmarksRemaining: provider.bookmarkTokens,
                  onUseBookmark: () => provider.useBookmarkToken(),
                ),
```

Change to:

```dart
                BookmarkCard(
                  bookmarksRemaining: provider.bookmarkTokens,
                  bookmarkResetAt: provider.bookmarkResetAt,
                  onUseBookmark: () => provider.useBookmarkToken(),
                ),
```

**Step 5: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/widgets/bookmark_card.dart lib/screens/streaks_screen.dart test/widgets/bookmark_card_test.dart
git commit -m "feat: show bookmark reset countdown in BookmarkCard"
```

---

### Task 8: Backend persistence for bookmark state

This task syncs bookmark state to Supabase so it follows users across devices.

**Files:**
- Supabase: run SQL migration
- Modify: `lib/services/user_data_service.dart`
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/services/user_data_service_test.dart`

**Step 1: Run Supabase migration**

In the Supabase dashboard → SQL editor, run:

```sql
ALTER TABLE user_preferences
  ADD COLUMN IF NOT EXISTS bookmark_tokens     INTEGER  NOT NULL DEFAULT 2,
  ADD COLUMN IF NOT EXISTS bookmark_reset_at   TEXT,
  ADD COLUMN IF NOT EXISTS frozen_days         JSONB    NOT NULL DEFAULT '[]';
```

No app code changes yet. Verify the columns appear in the table editor.

**Step 2: Write failing tests**

In `test/services/user_data_service_test.dart`, update the existing `UserData` group to add the new fields:

```dart
  group('UserData', () {
    test('holds library, progress, readDays fields', () {
      final data = UserData(
        library: ['moby-dick'],
        progress: {'moby-dick': 42},
        readDays: ['2026-02-25'],
      );
      expect(data.library, ['moby-dick']);
      expect(data.progress['moby-dick'], 42);
      expect(data.readDays, ['2026-02-25']);
    });

    test('readingStyle is null when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.readingStyle, isNull);
    });

    test('readingStyle can be set to horizontal', () {
      final data = UserData(
        library: [], progress: {}, readDays: [], readingStyle: 'horizontal',
      );
      expect(data.readingStyle, 'horizontal');
    });

    // NEW TESTS:
    test('bookmarkTokens defaults to 2 when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.bookmarkTokens, 2);
    });

    test('bookmarkResetAt is null when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.bookmarkResetAt, isNull);
    });

    test('frozenDays defaults to empty list when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.frozenDays, isEmpty);
    });

    test('bookmark fields are stored when provided', () {
      final data = UserData(
        library: [], progress: {}, readDays: [],
        bookmarkTokens: 1,
        bookmarkResetAt: '2026-03-11',
        frozenDays: ['2026-03-04'],
      );
      expect(data.bookmarkTokens, 1);
      expect(data.bookmarkResetAt, '2026-03-11');
      expect(data.frozenDays, ['2026-03-04']);
    });
  });
```

**Step 3: Run to verify failing**

```bash
flutter test test/services/user_data_service_test.dart --no-pub
```

Expected: FAIL — `UserData` has no `bookmarkTokens` getter.

**Step 4: Update UserData model**

In `lib/services/user_data_service.dart`, update `UserData`:

```dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class UserData {
  final List<String> library;
  final Map<String, int> progress;
  final List<String> readDays;
  final String? readingStyle;
  final int bookmarkTokens;
  final String? bookmarkResetAt;
  final List<String> frozenDays;

  const UserData({
    required this.library,
    required this.progress,
    required this.readDays,
    this.readingStyle,
    this.bookmarkTokens = 2,
    this.bookmarkResetAt,
    this.frozenDays = const [],
  });
}
```

**Step 5: Update fetchAll to return bookmark fields**

In `UserDataService.fetchAll`, `user_preferences` already returns one row. Update parsing to extract new columns:

```dart
    final prefs = results[3] as Map<String, dynamic>?;
    final readingStyle = prefs?['reading_style'] as String?;
    final bookmarkTokens = (prefs?['bookmark_tokens'] as int?) ?? 2;
    final bookmarkResetAt = prefs?['bookmark_reset_at'] as String?;
    final frozenDaysRaw = prefs?['frozen_days'];
    final frozenDays = frozenDaysRaw == null
        ? <String>[]
        : (frozenDaysRaw is List
            ? frozenDaysRaw.cast<String>()
            : (jsonDecode(frozenDaysRaw as String) as List).cast<String>());

    return UserData(
      library: library,
      progress: progress,
      readDays: readDays,
      readingStyle: readingStyle,
      bookmarkTokens: bookmarkTokens,
      bookmarkResetAt: bookmarkResetAt,
      frozenDays: frozenDays,
    );
```

Note: Supabase returns JSONB as a `List` directly (not a JSON string), hence the type check.

**Step 6: Add saveBookmarkState method**

At the end of `UserDataService`, add:

```dart
  static Future<void> saveBookmarkState(
    String userId, {
    required int bookmarkTokens,
    required String? bookmarkResetAt,
    required List<String> frozenDays,
  }) async {
    await supabase.from('user_preferences').upsert(
      {
        'user_id': userId,
        'bookmark_tokens': bookmarkTokens,
        'bookmark_reset_at': bookmarkResetAt,
        'frozen_days': frozenDays,
      },
      onConflict: 'user_id',
    );
  }
```

**Step 7: Update AppProvider.load() to use backend bookmark values**

In `lib/providers/app_provider.dart`, inside `load(String userId)`, after the `data` fetch and before the `reading_style` handling, add:

```dart
      // Bookmark state — backend is source of truth, overrides local
      bookmarkTokens = data.bookmarkTokens;
      bookmarkResetAt = data.bookmarkResetAt;
      frozenDays = data.frozenDays;
      await resetBookmarksIfExpired();
```

**Step 8: Update useBookmarkToken to sync backend**

`useBookmarkToken` needs `userId` to sync. Add `userId` parameter:

```dart
  Future<void> useBookmarkToken(String userId) async {
    if (bookmarkTokens <= 0) return;
    final isFirstUse = bookmarkTokens == 2;
    bookmarkTokens--;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    frozenDays = [...frozenDays, today];
    if (isFirstUse) {
      bookmarkResetAt = DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bookmark_tokens', bookmarkTokens);
      await prefs.setString('frozen_days', jsonEncode(frozenDays));
      if (isFirstUse) {
        await prefs.setString('bookmark_reset_at', bookmarkResetAt!);
      }
    } catch (e, st) {
      debugPrint('AppProvider.useBookmarkToken local error: $e\n$st');
    }
    UserDataService.saveBookmarkState(
      userId,
      bookmarkTokens: bookmarkTokens,
      bookmarkResetAt: bookmarkResetAt,
      frozenDays: frozenDays,
    ).catchError((Object e, StackTrace st) {
      debugPrint('AppProvider.useBookmarkToken remote error: $e\n$st');
    });
  }
```

**Step 9: Update call site in streaks_screen.dart**

The existing call to `useBookmarkToken()` needs a `userId`. The `_StreaksTab` is a `StatelessWidget` with `Consumer<AppProvider>`. The `userId` comes from Supabase auth.

In `lib/screens/streaks_screen.dart`, update the `BookmarkCard` call:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
// (add import at top if not present)

                BookmarkCard(
                  bookmarksRemaining: provider.bookmarkTokens,
                  bookmarkResetAt: provider.bookmarkResetAt,
                  onUseBookmark: () {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id ?? '';
                    provider.useBookmarkToken(userId);
                  },
                ),
```

**Step 10: Run full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass. The `useBookmarkToken` signature changed — check if any existing tests call it without `userId` and add `''` as argument.

**Step 11: Commit**

```bash
git add lib/services/user_data_service.dart lib/providers/app_provider.dart lib/screens/streaks_screen.dart test/services/user_data_service_test.dart
git commit -m "feat: persist bookmark state to Supabase for cross-device sync"
```

---

## Summary

| Task | Change | Tests added |
|---|---|---|
| 1 | Fix milestones [7,30,90,365] + weekly frozen days | 0 |
| 2 | Add genres to Book + catalogue | 2 |
| 3 | genreCounts getter in AppProvider | 4 |
| 4 | GenreBadgesGrid real data | 3 |
| 5 | StreakCounter animation + overflow fix | 4 |
| 6 | Bookmark reset logic in AppProvider | 5 |
| 7 | BookmarkCard "Resets in X days" | 4 |
| 8 | Backend persistence (Supabase + UserDataService) | 4 |

Expected final test count: current baseline + **26** new tests.
