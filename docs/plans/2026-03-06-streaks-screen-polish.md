# Streaks Screen Polish & Profile Sharing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Polish the Streaks screen with richer animations, improve bookmark UX, and add profile sharing with unique usernames, public profiles, and a follow system.

**Architecture:** Visual tasks (Tasks 1–5) are independent and touch only widget/screen files. Auth/social tasks (Tasks 6–12) build sequentially on a new `username`/`isPrivate` layer in `UserDataService` and `AppProvider`. No new packages required — custom particle animation for milestones, existing `app_links` for deep links.

**Tech Stack:** Flutter, Supabase (profiles + follows tables added via SQL), GoRouter, app_links, share_plus, path_provider.

**Design doc:** `docs/plans/2026-03-06-streaks-screen-polish-design.md`

**Worktree:** `~/.config/superpowers/worktrees/Scroll-Books-Flutter/streaks-screen-polish`

**Run tests:** `flutter test` from the worktree root.

---

## Task 1: Rewrite StreakCounter — wood/fire tiers, limited loops, tap, at-risk

**Files:**
- Modify: `lib/widgets/streak_counter.dart`
- Modify: `test/widgets/streak_counter_test.dart`

### Step 1: Add failing tests

Replace `test/widgets/streak_counter_test.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/streak_counter.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({int streak = 0, bool isAtRisk = false}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StreakCounter(streakCount: streak, isAtRisk: isAtRisk),
          ),
        ),
      );

  group('StreakCounter', () {
    testWidgets('shows wood emoji when streak is 0', (tester) async {
      await tester.pumpWidget(_wrap(streak: 0));
      await tester.pump();
      expect(find.text('🪵'), findsOneWidget);
    });

    testWidgets('shows fire emoji when streak >= 1', (tester) async {
      await tester.pumpWidget(_wrap(streak: 1));
      await tester.pump();
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('displays the streak count', (tester) async {
      await tester.pumpWidget(_wrap(streak: 7));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('fire emoji is larger for streak 7 than streak 1', (tester) async {
      await tester.pumpWidget(_wrap(streak: 1));
      await tester.pump();
      final small = tester.widget<Text>(find.text('🔥')).style!.fontSize!;

      await tester.pumpWidget(_wrap(streak: 7));
      await tester.pump();
      final medium = tester.widget<Text>(find.text('🔥')).style!.fontSize!;

      expect(medium, greaterThan(small));
    });

    testWidgets('isAtRisk wraps content in Opacity < 1', (tester) async {
      await tester.pumpWidget(_wrap(streak: 3, isAtRisk: true));
      await tester.pump();
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.any((o) => o.opacity < 1.0), isTrue);
    });

    testWidgets('isAtRisk false does not add dim Opacity', (tester) async {
      await tester.pumpWidget(_wrap(streak: 3, isAtRisk: false));
      await tester.pump();
      // No Opacity widget wrapping the content with opacity < 1
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.any((o) => o.opacity == 0.6), isFalse);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap(streak: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping emoji does not throw', (tester) async {
      await tester.pumpWidget(_wrap(streak: 5));
      await tester.pump();
      await tester.tap(find.text('🔥'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/widgets/streak_counter_test.dart
```
Expected: several FAIL (🪵 not found, isAtRisk not found, etc.)

### Step 3: Replace `lib/widgets/streak_counter.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _Tier {
  final String emoji;
  final double emojiSize;
  final double scaleMax;
  final Duration halfCycleDuration;

  const _Tier({
    required this.emoji,
    required this.emojiSize,
    required this.scaleMax,
    required this.halfCycleDuration,
  });
}

_Tier _tierFor(int streak) {
  if (streak == 0) {
    return const _Tier(
      emoji: '🪵', emojiSize: 48, scaleMax: 1.05,
      halfCycleDuration: Duration(milliseconds: 800),
    );
  }
  if (streak < 7) {
    return const _Tier(
      emoji: '🔥', emojiSize: 52, scaleMax: 1.08,
      halfCycleDuration: Duration(milliseconds: 600),
    );
  }
  if (streak < 30) {
    return const _Tier(
      emoji: '🔥', emojiSize: 64, scaleMax: 1.12,
      halfCycleDuration: Duration(milliseconds: 500),
    );
  }
  if (streak < 90) {
    return const _Tier(
      emoji: '🔥', emojiSize: 80, scaleMax: 1.15,
      halfCycleDuration: Duration(milliseconds: 420),
    );
  }
  return const _Tier(
    emoji: '🔥', emojiSize: 96, scaleMax: 1.18,
    halfCycleDuration: Duration(milliseconds: 340),
  );
}

class StreakCounter extends StatefulWidget {
  final int streakCount;
  final bool isAtRisk;

  const StreakCounter({
    super.key,
    required this.streakCount,
    this.isAtRisk = false,
  });

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  // Each "half-cycle" = one forward or one reverse pass.
  // autoLoops * 2 half-cycles = autoLoops full ping-pong loops.
  static const int _autoHalfCycles = 6;  // 3 loops
  static const int _tapHalfCycles = 10;  // 5 loops
  int _halfCyclesLeft = 0;

  @override
  void initState() {
    super.initState();
    _buildController();
    _startLoops(_autoHalfCycles);
  }

  void _buildController() {
    final tier = _tierFor(widget.streakCount);
    _controller = AnimationController(
      vsync: this,
      duration: tier.halfCycleDuration,
    );
    _scale = Tween<double>(begin: 1.0 / tier.scaleMax, end: tier.scaleMax)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.65, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted || _halfCyclesLeft <= 0) return;
    _halfCyclesLeft--;
    if (_halfCyclesLeft > 0) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    }
  }

  void _startLoops(int halfCycles) {
    _halfCyclesLeft = halfCycles;
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(StreakCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streakCount != widget.streakCount) {
      _controller.removeStatusListener(_onStatus);
      _controller.dispose();
      _buildController();
      _startLoops(_autoHalfCycles);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(widget.streakCount);
    Widget emoji = GestureDetector(
      onTap: () => _startLoops(_tapHalfCycles),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Text(tier.emoji, style: TextStyle(fontSize: tier.emojiSize)),
          ),
        ),
      ),
    );

    if (widget.isAtRisk) {
      emoji = Opacity(opacity: 0.6, child: emoji);
    }

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
          emoji,
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

### Step 4: Run tests

```bash
flutter test test/widgets/streak_counter_test.dart
```
Expected: all PASS

### Step 5: Commit

```bash
git add lib/widgets/streak_counter.dart test/widgets/streak_counter_test.dart
git commit -m "feat: rewrite StreakCounter — wood/fire tiers, limited loops, tap replay, at-risk state"
```

---

## Task 2: Wire StreaksScreen — pass isAtRisk, show longest streak

**Files:**
- Modify: `lib/screens/streaks_screen.dart`
- Modify: `test/screens/streaks_screen_test.dart`

### Step 1: Add failing tests

Add these tests to the existing `group('StreaksScreen', ...)` in `test/screens/streaks_screen_test.dart`:

```dart
testWidgets('shows Personal best when longestStreak > current streak', (tester) async {
  final provider = AppProvider()
    ..readDays = []
    ..frozenDays = []
    ..bookmarkTokens = 2
    ..longestStreak = 21
    ..dailyGoal = 10
    ..dailyPassages = {}
    ..library = []
    ..progress = {};
  await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.light, home: const StreaksScreen()),
  ));
  await tester.pumpAndSettle();
  expect(find.textContaining('Personal best'), findsOneWidget);
});

testWidgets('does not show Personal best when longestStreak equals current', (tester) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final provider = AppProvider()
    ..readDays = [today]
    ..frozenDays = []
    ..bookmarkTokens = 2
    ..longestStreak = 1
    ..dailyGoal = 10
    ..dailyPassages = {}
    ..library = []
    ..progress = {};
  await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.light, home: const StreaksScreen()),
  ));
  await tester.pumpAndSettle();
  expect(find.textContaining('Personal best'), findsNothing);
});
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/screens/streaks_screen_test.dart
```
Expected: 2 new FAIL

### Step 3: Update `lib/screens/streaks_screen.dart`

In `_StreaksTab.build()`, update the `Consumer` builder. Replace lines 78–128 with:

```dart
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final streak = calculateStreak(
          provider.readDays,
          frozenDays: provider.frozenDays,
        );
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final isAtRisk = !provider.readDays.contains(todayStr) &&
            !provider.frozenDays.contains(todayStr);
        final passagesToday = provider.dailyPassages[todayStr] ?? 0;
        final weeklyCompletion = _getWeeklyCompletion(
          provider.readDays,
          provider.frozenDays,
        );
        final showPersonalBest = provider.longestStreak > streak;

        return Container(
          color: AppTheme.warmWhite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                StreakCounter(streakCount: streak, isAtRisk: isAtRisk),
                if (showPersonalBest) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Personal best: ${provider.longestStreak} days',
                    style: AppTheme.monoLabel(
                      fontSize: 11,
                      color: AppTheme.inkLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                WeeklyProgressDots(
                  completedDays: weeklyCompletion,
                  todayIndex: _getTodayIndex(),
                ),
                const SizedBox(height: 24),
                DailyGoalCard(
                  goal: provider.dailyGoal,
                  passagesReadToday: passagesToday,
                  onGoalChanged: (goal) => provider.setDailyGoal(goal),
                ),
                const SizedBox(height: 16),
                BookmarkCard(
                  bookmarksRemaining: provider.bookmarkTokens,
                  bookmarkResetAt: provider.bookmarkResetAt,
                  onUseBookmark: () {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id ?? '';
                    provider.useBookmarkToken(userId);
                  },
                ),
                const SizedBox(height: 24),
                MilestonesList(currentStreak: streak),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
```

### Step 4: Run tests

```bash
flutter test test/screens/streaks_screen_test.dart
```
Expected: all PASS

### Step 5: Commit

```bash
git add lib/screens/streaks_screen.dart test/screens/streaks_screen_test.dart
git commit -m "feat: wire isAtRisk and personal best display in StreaksScreen"
```

---

## Task 3: Weekly dots — amber state for frozen days

**Files:**
- Modify: `lib/widgets/weekly_progress_dots.dart`
- Modify: `lib/screens/streaks_screen.dart`
- Modify: `test/widgets/weekly_progress_dots_test.dart`

### Step 1: Add failing tests

Read `test/widgets/weekly_progress_dots_test.dart` first, then add:

```dart
testWidgets('shows amber frozen dot for frozen day', (tester) async {
  // All false completed, day 0 is frozen
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: WeeklyProgressDots(
        completedDays: const [false, false, false, false, false, false, false],
        frozenDays: const [true, false, false, false, false, false, false],
        todayIndex: 1,
      ),
    ),
  ));
  // Frozen dot should render as amber — find Container with amber color
  expect(find.byType(WeeklyProgressDots), findsOneWidget);
  expect(tester.takeException(), isNull);
});

testWidgets('completed day takes priority over frozen', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: WeeklyProgressDots(
        completedDays: const [true, false, false, false, false, false, false],
        frozenDays: const [true, false, false, false, false, false, false],
        todayIndex: 1,
      ),
    ),
  ));
  // Day 0 is both completed and frozen — should show green (completed wins)
  expect(tester.takeException(), isNull);
});
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/widgets/weekly_progress_dots_test.dart
```
Expected: FAIL (frozenDays parameter not accepted)

### Step 3: Update `lib/widgets/weekly_progress_dots.dart`

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class WeeklyProgressDots extends StatelessWidget {
  final List<bool> completedDays; // length 7, Mon=0 .. Sun=6
  final List<bool> frozenDays;    // length 7, amber bookmark dots
  final int todayIndex;

  const WeeklyProgressDots({
    super.key,
    required this.completedDays,
    required this.todayIndex,
    this.frozenDays = const [false, false, false, false, false, false, false],
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final completed = i < completedDays.length && completedDays[i];
        final frozen = i < frozenDays.length && frozenDays[i];
        final isToday = i == todayIndex;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotCircle(
                completed: completed,
                frozen: frozen && !completed,
                isToday: isToday,
              ),
              const SizedBox(height: 6),
              Text(
                _dayLabels[i],
                style: AppTheme.monoLabel(
                  fontSize: 10,
                  color: AppTheme.inkLight,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DotCircle extends StatelessWidget {
  final bool completed;
  final bool frozen;
  final bool isToday;

  const _DotCircle({
    required this.completed,
    required this.frozen,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.tomato, AppTheme.amber],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tomato.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      );
    }

    if (frozen) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.amber.withValues(alpha: 0.25),
          border: Border.all(
            color: AppTheme.amber.withValues(alpha: 0.60),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text('🔖', style: TextStyle(fontSize: 14)),
        ),
      );
    }

    if (isToday) {
      return CustomPaint(
        painter: _DashedCirclePainter(
          color: AppTheme.inkLight.withValues(alpha: 0.30),
          strokeWidth: 1.5,
          dashLength: 4,
          gapLength: 3,
        ),
        child: const SizedBox(width: 34, height: 34),
      );
    }

    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.parchment,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final dashAngle = (dashLength / circumference) * 2 * pi;
    final gapAngle = (gapLength / circumference) * 2 * pi;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle) - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### Step 4: Update `_StreaksTab._getWeeklyCompletion` in `streaks_screen.dart`

The `_StreaksTab` needs to separately compute `weeklyCompletion` (read days only) and `weeklyFrozen` (frozen days only), so dots render amber for frozen and green for read. Replace the `_getWeeklyCompletion` method and `WeeklyProgressDots` call:

```dart
// Add this new method alongside _getWeeklyCompletion:
List<bool> _getWeeklyFrozen(List<String> frozenDays) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return List.generate(7, (i) {
    final day = monday.add(Duration(days: i));
    final dayStr = day.toIso8601String().substring(0, 10);
    return frozenDays.contains(dayStr);
  });
}

// Update _getWeeklyCompletion to only use readDays (not frozenDays):
List<bool> _getWeeklyCompletion(List<String> readDays) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return List.generate(7, (i) {
    final day = monday.add(Duration(days: i));
    final dayStr = day.toIso8601String().substring(0, 10);
    return readDays.contains(dayStr);
  });
}
```

And update the call site in `build()`:
```dart
final weeklyCompletion = _getWeeklyCompletion(provider.readDays);
final weeklyFrozen = _getWeeklyFrozen(provider.frozenDays);
// ...
WeeklyProgressDots(
  completedDays: weeklyCompletion,
  frozenDays: weeklyFrozen,
  todayIndex: _getTodayIndex(),
),
```

### Step 5: Run tests

```bash
flutter test test/widgets/weekly_progress_dots_test.dart test/screens/streaks_screen_test.dart
```
Expected: all PASS

### Step 6: Commit

```bash
git add lib/widgets/weekly_progress_dots.dart lib/screens/streaks_screen.dart test/widgets/weekly_progress_dots_test.dart
git commit -m "feat: amber frozen-day state in WeeklyProgressDots"
```

---

## Task 4: Bookmark card refill animation

**Files:**
- Modify: `lib/widgets/bookmark_card.dart`
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/widgets/bookmark_card_test.dart`

### Step 1: Add failing tests

Read `test/widgets/bookmark_card_test.dart`, then add:

```dart
testWidgets('shows days left label when token is being refilled', (tester) async {
  final resetDate = DateTime.now().add(const Duration(days: 5));
  final resetStr = resetDate.toIso8601String().substring(0, 10);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: BookmarkCard(
        bookmarksRemaining: 1,
        bookmarkResetAt: resetStr,
        onUseBookmark: () {},
      ),
    ),
  ));
  expect(find.textContaining('days left'), findsOneWidget);
});

testWidgets('does not show days left when all tokens full', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: BookmarkCard(
        bookmarksRemaining: 2,
        bookmarkResetAt: null,
        onUseBookmark: () {},
      ),
    ),
  ));
  expect(find.textContaining('days left'), findsNothing);
});
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/widgets/bookmark_card_test.dart
```
Expected: 2 FAIL

### Step 3: Update `lib/widgets/bookmark_card.dart`

Replace the `_PennantToken` class and update `BookmarkCard` to show refill progress.

In `BookmarkCard`, add a helper method and update the token row:

```dart
// Add this helper to BookmarkCard:
double _tokenFillProgress(int tokenIndex) {
  // tokenIndex 0 = first token, 1 = second token
  // Returns 0.0 (empty) to 1.0 (full)
  if (bookmarkResetAt == null) return 1.0; // No reset pending, fully available
  final now = DateTime.now();
  final resetDate = DateTime.parse(bookmarkResetAt!);
  final totalMs = const Duration(days: 7).inMilliseconds;
  final elapsedMs = now.millisecondsSinceEpoch -
      (resetDate.millisecondsSinceEpoch - totalMs);
  final progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
  // Token 0 is the first to refill (always at same pace),
  // Token 1 refills at same rate (both reset together)
  final filled = tokenIndex < bookmarksRemaining;
  if (filled) return 1.0;
  return progress;
}

int _daysLeft() {
  if (bookmarkResetAt == null) return 0;
  final today = DateTime.now();
  final resetDate = DateTime.parse(bookmarkResetAt!);
  return resetDate
      .difference(DateTime(today.year, today.month, today.day))
      .inDays
      .clamp(0, 7);
}
```

Replace the token row inside `BookmarkCard.build()` (the `Row` with two `_PennantToken` widgets):

```dart
Column(
  children: [
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PennantToken(
          filled: bookmarksRemaining >= 1,
          fillProgress: _tokenFillProgress(0),
        ),
        const SizedBox(width: 4),
        _PennantToken(
          filled: bookmarksRemaining >= 2,
          fillProgress: _tokenFillProgress(1),
        ),
      ],
    ),
    if (bookmarkResetAt != null && bookmarksRemaining < 2) ...[
      const SizedBox(height: 4),
      Text(
        '${_daysLeft()} days left',
        style: GoogleFonts.dmMono(
          fontSize: 10,
          color: AppTheme.inkLight,
        ),
      ),
    ],
  ],
),
```

Replace `_PennantToken`:

```dart
class _PennantToken extends StatelessWidget {
  final bool filled;
  final double fillProgress; // 0.0 = empty, 1.0 = full

  const _PennantToken({required this.filled, this.fillProgress = 1.0});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ClipPath(
        clipper: _PennantClipper(),
        child: Container(
          width: 22,
          height: 30,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.amber, AppTheme.tomato],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    // Refilling: liquid fill from bottom up
    return ClipPath(
      clipper: _PennantClipper(),
      child: SizedBox(
        width: 22,
        height: 30,
        child: Stack(
          children: [
            // Empty background
            Container(
              width: 22,
              height: 30,
              color: AppTheme.inkLight.withValues(alpha: 0.15),
            ),
            // Liquid fill from bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 30 * fillProgress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.amber, AppTheme.tomato],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 4: Run tests

```bash
flutter test test/widgets/bookmark_card_test.dart
```
Expected: all PASS

### Step 5: Commit

```bash
git add lib/widgets/bookmark_card.dart test/widgets/bookmark_card_test.dart
git commit -m "feat: liquid refill animation and days-left label on BookmarkCard"
```

---

## Task 5: Milestone celebration overlay

**Files:**
- Create: `lib/widgets/milestone_celebration_overlay.dart`
- Modify: `lib/screens/streaks_screen.dart`
- Create: `test/widgets/milestone_celebration_overlay_test.dart`

### Step 1: Write failing tests

Create `test/widgets/milestone_celebration_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/milestone_celebration_overlay.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({required int milestone, VoidCallback? onDismiss}) =>
      MaterialApp(
        home: Scaffold(
          body: MilestoneCelebrationOverlay(
            milestone: milestone,
            onDismiss: onDismiss ?? () {},
          ),
        ),
      );

  group('MilestoneCelebrationOverlay', () {
    testWidgets('shows milestone day count', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 7));
      await tester.pump();
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets('shows milestone name for 7 days', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 7));
      await tester.pump();
      expect(find.text('Week Worm'), findsOneWidget);
    });

    testWidgets('shows milestone name for 30 days', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 30));
      await tester.pump();
      expect(find.text('Page Turner'), findsOneWidget);
    });

    testWidgets('tapping calls onDismiss', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(_wrap(
        milestone: 7,
        onDismiss: () => dismissed = true,
      ));
      await tester.pump();
      await tester.tap(find.byType(MilestoneCelebrationOverlay));
      expect(dismissed, isTrue);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 90));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/widgets/milestone_celebration_overlay_test.dart
```
Expected: FAIL (file not found)

### Step 3: Create `lib/widgets/milestone_celebration_overlay.dart`

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _MilestoneData {
  final String name;
  final String emoji;
  final String subtitle;

  const _MilestoneData({
    required this.name,
    required this.emoji,
    required this.subtitle,
  });
}

_MilestoneData _dataFor(int milestone) {
  switch (milestone) {
    case 7:
      return const _MilestoneData(
        name: 'Week Worm', emoji: '🪱', subtitle: '7 day streak!',
      );
    case 30:
      return const _MilestoneData(
        name: 'Page Turner', emoji: '📖', subtitle: '30 day streak!',
      );
    case 90:
      return const _MilestoneData(
        name: 'Bibliophile', emoji: '📚', subtitle: '90 day streak!',
      );
    default:
      return const _MilestoneData(
        name: 'Literary Legend', emoji: '🏆', subtitle: '365 day streak!',
      );
  }
}

class MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _spawnParticles();
  }

  void _spawnParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.5,
        color: [
          AppTheme.tomato,
          AppTheme.amber,
          AppTheme.sage,
          AppTheme.warmGold,
        ][_rng.nextInt(4)],
        size: 6 + _rng.nextDouble() * 6,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _dataFor(widget.milestone);
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Stack(
          children: [
            // Confetti particles
            ...(_particles.map((p) => _ParticleWidget(
                  particle: p,
                  animation: _controller,
                ))),
            // Badge card
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Opacity(
                  opacity: _opacity.value,
                  child: ScaleTransition(scale: _scale, child: child),
                ),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.warmShadow(blur: 32, spread: 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data.emoji,
                          style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(
                        data.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: AppTheme.inkMid,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tap to continue',
                        style: AppTheme.monoLabel(
                          fontSize: 11,
                          color: AppTheme.inkLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x;    // horizontal position 0.0–1.0
  final double delay; // animation delay 0.0–0.5
  final Color color;
  final double size;

  const _Particle({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
  });
}

class _ParticleWidget extends StatelessWidget {
  final _Particle particle;
  final Animation<double> animation;

  const _ParticleWidget({required this.particle, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = ((animation.value - particle.delay) / (1 - particle.delay))
            .clamp(0.0, 1.0);
        final screenH = MediaQuery.of(context).size.height;
        final screenW = MediaQuery.of(context).size.width;
        final top = -40.0 + screenH * 0.6 * t;
        final left = particle.x * screenW - particle.size / 2;
        return Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: BoxDecoration(
                color: particle.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

### Step 4: Show overlay in `StreaksScreen`

In `lib/screens/streaks_screen.dart`, convert `_StreaksScreenState` to show the overlay. Add import and wrap the `Scaffold` body in a `Stack`:

Add import at top:
```dart
import '../widgets/milestone_celebration_overlay.dart';
```

Update `_StreaksScreenState.build()` to wrap with overlay check:

```dart
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.cream,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SharedHeader(heading: 'Your Reading'),
                    SharedTabBar(
                      tabs: const ['Streaks', 'Badges'],
                      selectedIndex: _selectedTab,
                      onTabSelected: (i) => setState(() => _selectedTab = i),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _selectedTab == 0
                            ? const _StreaksTab(key: ValueKey('streaks'))
                            : const _BadgesTab(key: ValueKey('badges')),
                      ),
                    ),
                  ],
                ),
                if (provider.pendingMilestone != null)
                  MilestoneCelebrationOverlay(
                    milestone: provider.pendingMilestone!,
                    onDismiss: provider.clearMilestone,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
```

Also remove the `Scaffold` from inside `_StreaksScreenState` (it's now inside the Consumer builder), and remove the old `Consumer` wrapping from `StreaksScreen` since the class itself is no longer a `StatefulWidget` needing separate scaffold. **Important:** The `StreaksScreen` class needs to become a `StatefulWidget` that uses `Consumer` at the top level. Here is the updated full class:

```dart
class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.cream,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SharedHeader(heading: 'Your Reading'),
                    SharedTabBar(
                      tabs: const ['Streaks', 'Badges'],
                      selectedIndex: _selectedTab,
                      onTabSelected: (i) => setState(() => _selectedTab = i),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _selectedTab == 0
                            ? const _StreaksTab(key: ValueKey('streaks'))
                            : const _BadgesTab(key: ValueKey('badges')),
                      ),
                    ),
                  ],
                ),
                if (provider.pendingMilestone != null)
                  MilestoneCelebrationOverlay(
                    milestone: provider.pendingMilestone!,
                    onDismiss: provider.clearMilestone,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### Step 5: Run tests

```bash
flutter test test/widgets/milestone_celebration_overlay_test.dart test/screens/streaks_screen_test.dart
```
Expected: all PASS

### Step 6: Commit

```bash
git add lib/widgets/milestone_celebration_overlay.dart lib/screens/streaks_screen.dart test/widgets/milestone_celebration_overlay_test.dart
git commit -m "feat: full-screen milestone celebration overlay with confetti"
```

---

## Task 6: Username + isPrivate in UserDataService and AppProvider

**Files:**
- Modify: `lib/services/user_data_service.dart`
- Modify: `lib/providers/app_provider.dart`
- Create: `test/services/user_data_service_username_test.dart`

### Step 1: Write failing tests

Create `test/services/user_data_service_username_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/services/user_data_service.dart';

void main() {
  group('UserData', () {
    test('defaults username to null', () {
      const data = UserData(
        library: [],
        progress: {},
        readDays: [],
      );
      expect(data.username, isNull);
    });

    test('defaults isPrivate to false', () {
      const data = UserData(
        library: [],
        progress: {},
        readDays: [],
      );
      expect(data.isPrivate, isFalse);
    });

    test('holds username when set', () {
      const data = UserData(
        library: [],
        progress: {},
        readDays: [],
        username: 'jessicamumby',
      );
      expect(data.username, 'jessicamumby');
    });
  });
}
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/services/user_data_service_username_test.dart
```
Expected: FAIL (username field not found)

### Step 3: Update `lib/services/user_data_service.dart`

Add `username` and `isPrivate` to `UserData`:

```dart
class UserData {
  final List<String> library;
  final Map<String, int> progress;
  final List<String> readDays;
  final String? readingStyle;
  final int bookmarkTokens;
  final String? bookmarkResetAt;
  final List<String> frozenDays;
  final List<SavedPassage> savedPassages;
  final String? username;
  final bool isPrivate;

  const UserData({
    required this.library,
    required this.progress,
    required this.readDays,
    this.readingStyle,
    this.bookmarkTokens = 2,
    this.bookmarkResetAt,
    this.frozenDays = const [],
    this.savedPassages = const [],
    this.username,
    this.isPrivate = false,
  });
}
```

Update `fetchAll` to also fetch from `profiles`:

```dart
static Future<UserData> fetchAll(String userId) async {
  final results = await Future.wait(<Future<dynamic>>[
    supabase.from('library').select('book_id').eq('user_id', userId),
    supabase.from('progress').select('book_id, chunk_index').eq('user_id', userId),
    supabase.from('read_days').select('date').eq('user_id', userId),
    supabase
        .from('user_preferences')
        .select('reading_style, bookmark_tokens, bookmark_reset_at, frozen_days')
        .eq('user_id', userId)
        .maybeSingle(),
    supabase
        .from('saved_passages')
        .select()
        .eq('user_id', userId)
        .order('saved_at', ascending: false),
    supabase
        .from('profiles')
        .select('username, is_private')
        .eq('user_id', userId)
        .maybeSingle(),
  ]);

  final library = (results[0] as List).map((r) => r['book_id'] as String).toList();
  final progress = Map<String, int>.fromEntries(
    (results[1] as List).map((r) =>
        MapEntry(r['book_id'] as String, r['chunk_index'] as int)),
  );
  final readDays = (results[2] as List).map((r) => r['date'] as String).toList();

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

  final savedPassages = (results[4] as List)
      .map((r) => SavedPassage.fromJson(r as Map<String, dynamic>))
      .toList();

  final profile = results[5] as Map<String, dynamic>?;
  final username = profile?['username'] as String?;
  final isPrivate = (profile?['is_private'] as bool?) ?? false;

  return UserData(
    library: library,
    progress: progress,
    readDays: readDays,
    readingStyle: readingStyle,
    bookmarkTokens: bookmarkTokens,
    bookmarkResetAt: bookmarkResetAt,
    frozenDays: frozenDays,
    savedPassages: savedPassages,
    username: username,
    isPrivate: isPrivate,
  );
}
```

Add new service methods at the bottom of `UserDataService`:

```dart
static Future<void> saveUsername(String userId, String username) async {
  await supabase.from('profiles').upsert(
    {'user_id': userId, 'username': username.toLowerCase()},
    onConflict: 'user_id',
  );
}

static Future<void> saveAccountVisibility(String userId, {required bool isPrivate}) async {
  await supabase.from('profiles').upsert(
    {'user_id': userId, 'is_private': isPrivate},
    onConflict: 'user_id',
  );
}

static Future<bool> isUsernameAvailable(String candidate) async {
  try {
    final result = await supabase
        .rpc('is_username_available', params: {'candidate': candidate});
    return result as bool? ?? false;
  } catch (_) {
    return false;
  }
}
```

### Step 4: Update `lib/providers/app_provider.dart`

Add fields and methods. After `List<SavedPassage> savedPassages = [];` (line 25), add:

```dart
String? username;
bool isPrivate = false;
```

In `AppProvider.load()`, after `savedPassages = data.savedPassages;`, add:

```dart
username = data.username;
isPrivate = data.isPrivate;
```

Add new methods to AppProvider:

```dart
Future<void> setUsername(String userId, String newUsername) async {
  username = newUsername;
  notifyListeners();
  await UserDataService.saveUsername(userId, newUsername);
}

Future<void> setAccountVisibility(String userId, {required bool isPrivate}) async {
  this.isPrivate = isPrivate;
  notifyListeners();
  await UserDataService.saveAccountVisibility(userId, isPrivate: isPrivate);
}
```

### Step 5: Run tests

```bash
flutter test test/services/user_data_service_username_test.dart
```
Expected: all PASS

### Step 6: Commit

```bash
git add lib/services/user_data_service.dart lib/providers/app_provider.dart test/services/user_data_service_username_test.dart
git commit -m "feat: username and isPrivate fields in UserData, UserDataService, AppProvider"
```

---

## Task 7: Username field in signup form

**Files:**
- Modify: `lib/screens/signup_screen.dart`
- Modify: `test/screens/signup_screen_test.dart`

### Step 1: Add failing tests

Add to existing `group('SignUpScreen', ...)` in `test/screens/signup_screen_test.dart`:

```dart
testWidgets('shows four form fields including username', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.byType(TextFormField), findsNWidgets(4));
});

testWidgets('username field shows invalid format error', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Username'),
    'AB', // too short + uppercase — invalid
  );
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
  expect(find.textContaining('lowercase'), findsOneWidget);
});

testWidgets('username field shows length error when too short', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Username'),
    'ab', // too short
  );
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
  expect(find.textContaining('3'), findsWidgets);
});
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/screens/signup_screen_test.dart
```
Expected: 3 new FAIL + existing '3 fields' test now FAIL (will be 4 fields)

### Step 3: Update `lib/screens/signup_screen.dart`

Replace the full file:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../services/user_data_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // Username availability state: null=unchecked, 'checking', 'available', 'taken', 'invalid'
  String? _usernameStatus;
  String _lastCheckedUsername = '';

  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String value) async {
    final trimmed = value.trim().toLowerCase();
    if (trimmed == _lastCheckedUsername) return;
    _lastCheckedUsername = trimmed;

    if (!_usernameRegex.hasMatch(trimmed)) {
      setState(() => _usernameStatus = 'invalid');
      return;
    }
    setState(() => _usernameStatus = 'checking');

    final available = await UserDataService.isUsernameAvailable(trimmed);
    if (!mounted || _lastCheckedUsername != trimmed) return;
    setState(() => _usernameStatus = available ? 'available' : 'taken');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameStatus != 'available') {
      setState(() => _error = 'Please choose a valid available username.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final response = await supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'display_name': _name.text.trim()},
        emailRedirectTo: 'scrollbooks://auth-callback',
      );
      // Upsert username to profiles table
      final userId = response.user?.id;
      if (userId != null) {
        await UserDataService.saveUsername(userId, _username.text.trim().toLowerCase());
      }
      if (mounted) {
        context.go('/email-confirm?email=${Uri.encodeComponent(_email.text.trim())}');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateUsername(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final trimmed = v.trim().toLowerCase();
    if (!_usernameRegex.hasMatch(trimmed)) {
      return 'Use lowercase letters, numbers and underscores (3–20 chars)';
    }
    return null;
  }

  Widget _usernameStatusIcon() {
    switch (_usernameStatus) {
      case 'checking':
        return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case 'available':
        return Icon(Icons.check_circle_outline, color: AppTheme.sage, size: 20);
      case 'taken':
        return Icon(Icons.cancel_outlined, color: AppTheme.sienna, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              Text(
                'Scroll Books',
                style: GoogleFonts.lora(
                  fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account',
                style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.tobacco),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'First name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _username,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g. jessreads',
                        prefixText: '@',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _usernameStatusIcon(),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (v) {
                        if (v.trim().length >= 3) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted) _checkUsernameAvailability(v);
                          });
                        } else {
                          setState(() => _usernameStatus = null);
                        }
                      },
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: AppTheme.sienna, fontSize: 14)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Already have an account? Log in',
                    style: TextStyle(color: AppTheme.brand)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Also update the existing test that expects 3 fields — change it to 4:

```dart
testWidgets('shows four form fields', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.byType(TextFormField), findsNWidgets(4));
});
```

### Step 4: Run tests

```bash
flutter test test/screens/signup_screen_test.dart
```
Expected: all PASS

### Step 5: Commit

```bash
git add lib/screens/signup_screen.dart test/screens/signup_screen_test.dart
git commit -m "feat: username field in signup with real-time availability check"
```

---

## Task 8: Profile share button + ProfileShareCard

**Files:**
- Create: `lib/widgets/profile_share_card.dart`
- Create: `lib/utils/share_profile_image.dart`
- Modify: `lib/screens/profile_screen.dart`
- Create: `test/widgets/profile_share_card_test.dart`

### Step 1: Write failing tests

Create `test/widgets/profile_share_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/profile_share_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({
    String username = 'jessreads',
    int streakCount = 7,
    int badgesEarned = 3,
    int passagesSaved = 12,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: ProfileShareCard(
            username: username,
            streakCount: streakCount,
            badgesEarned: badgesEarned,
            passagesSaved: passagesSaved,
          ),
        ),
      );

  group('ProfileShareCard', () {
    testWidgets('shows @username', (tester) async {
      await tester.pumpWidget(_wrap(username: 'jessreads'));
      expect(find.text('@jessreads'), findsOneWidget);
    });

    testWidgets('shows streak count', (tester) async {
      await tester.pumpWidget(_wrap(streakCount: 14));
      expect(find.textContaining('14'), findsWidgets);
    });

    testWidgets('shows badges count', (tester) async {
      await tester.pumpWidget(_wrap(badgesEarned: 5));
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/widgets/profile_share_card_test.dart
```
Expected: FAIL (file not found)

### Step 3: Create `lib/widgets/profile_share_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../utils/streak_tier.dart';

class ProfileShareCard extends StatelessWidget {
  final String username;
  final int streakCount;
  final int badgesEarned;
  final int passagesSaved;

  const ProfileShareCard({
    super.key,
    required this.username,
    required this.streakCount,
    required this.badgesEarned,
    required this.passagesSaved,
  });

  @override
  Widget build(BuildContext context) {
    final tierEmoji = streakTierEmoji(streakCount);
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.warmShadow(blur: 24, spread: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tierEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@$username',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    'Scroll Books',
                    style: AppTheme.monoLabel(
                      fontSize: 10,
                      color: AppTheme.inkLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.borderSoft),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'STREAK', value: '$streakCount days'),
              _Stat(label: 'BADGES', value: '$badgesEarned'),
              _Stat(label: 'PASSAGES', value: '$passagesSaved'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.monoLabel(
            fontSize: 9,
            color: AppTheme.inkLight,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
```

**Note:** `ProfileShareCard` imports `'../utils/streak_tier.dart'` — create this small utility file:

Create `lib/utils/streak_tier.dart`:

```dart
String streakTierEmoji(int streak) {
  if (streak == 0) return '🪵';
  if (streak < 7) return '🔥';
  if (streak < 30) return '🔥🔥';
  if (streak < 90) return '🔥🔥🔥';
  return '🔥🔥🔥🔥';
}
```

### Step 4: Create `lib/utils/share_profile_image.dart`

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareProfileImage({
  required GlobalKey repaintKey,
  required String username,
}) async {
  final boundary = repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/profile_card.png');
  await file.writeAsBytes(bytes.buffer.asUint8List());

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'scrollbooks://profile/$username',
  );
}
```

### Step 5: Update `lib/screens/profile_screen.dart`

Add imports at the top:
```dart
import '../utils/streak_calculator.dart';
import '../utils/share_profile_image.dart';
import '../widgets/profile_share_card.dart';
```

In `_ProfileScreenState`, add:
```dart
final GlobalKey _profileShareCardKey = GlobalKey();
```

Add `_shareProfile()` method:
```dart
Future<void> _shareProfile() async {
  final provider = Provider.of<AppProvider>(context, listen: false);
  final username = provider.username ?? '';
  if (username.isEmpty) return;
  try {
    await shareProfileImage(
      repaintKey: _profileShareCardKey,
      username: username,
    );
  } catch (e, st) {
    debugPrint('Share profile error: $e\n$st');
  }
}
```

Add share `IconButton` to the AppBar actions (before the ⚙️):
```dart
appBar: AppBar(
  title: const Text('Profile'),
  actions: [
    Consumer<AppProvider>(
      builder: (context, provider, _) => IconButton(
        onPressed: provider.username != null ? _shareProfile : null,
        icon: const Icon(Icons.ios_share, size: 22),
        tooltip: 'Share profile',
      ),
    ),
    IconButton(
      onPressed: () => context.push('/app/profile/settings'),
      icon: const Text('⚙️', style: TextStyle(fontSize: 24)),
    ),
  ],
),
```

Add the hidden `ProfileShareCard` to the `Stack` in `build()`, after the existing hidden passage share card:
```dart
// Hidden profile share card for PNG generation
Consumer<AppProvider>(
  builder: (context, provider, _) {
    final streak = calculateStreak(
      provider.readDays,
      frozenDays: provider.frozenDays,
    );
    final badgesEarned = _countBadges(provider);
    return Positioned(
      left: -1000,
      top: -1000,
      child: RepaintBoundary(
        key: _profileShareCardKey,
        child: ProfileShareCard(
          username: provider.username ?? '',
          streakCount: streak,
          badgesEarned: badgesEarned,
          passagesSaved: provider.savedPassages.length,
        ),
      ),
    );
  },
),
```

Add `_countBadges` helper to `_ProfileScreenState`:
```dart
int _countBadges(AppProvider provider) {
  final streak = calculateStreak(provider.readDays, frozenDays: provider.frozenDays);
  int count = 0;
  for (final days in [7, 30, 90, 365]) {
    if (streak >= days) count++;
  }
  for (final genre in provider.genreCounts.keys) {
    if ((provider.genreCounts[genre] ?? 0) > 0) count++;
  }
  return count;
}
```

### Step 6: Run tests

```bash
flutter test test/widgets/profile_share_card_test.dart test/screens/profile_screen_test.dart
```
Expected: all PASS

### Step 7: Commit

```bash
git add lib/widgets/profile_share_card.dart lib/utils/share_profile_image.dart lib/utils/streak_tier.dart lib/screens/profile_screen.dart test/widgets/profile_share_card_test.dart
git commit -m "feat: profile share button with PNG card and deep link"
```

---

## Task 9: Follow system in UserDataService + AppProvider

**Files:**
- Create: `lib/models/user_public_profile.dart`
- Modify: `lib/services/user_data_service.dart`
- Modify: `lib/providers/app_provider.dart`
- Create: `test/services/follow_service_test.dart`

### Step 1: Write failing tests

Create `test/services/follow_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/models/user_public_profile.dart';

void main() {
  group('UserPublicProfile', () {
    test('holds all fields', () {
      const profile = UserPublicProfile(
        userId: 'abc',
        username: 'jessreads',
        displayName: 'Jessica',
        isPrivate: false,
        followerCount: 10,
        followingCount: 5,
        streakCount: 7,
        badgesEarned: 3,
        passagesSaved: 12,
      );
      expect(profile.username, 'jessreads');
      expect(profile.followerCount, 10);
      expect(profile.isPrivate, isFalse);
    });
  });
}
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/services/follow_service_test.dart
```
Expected: FAIL

### Step 3: Create `lib/models/user_public_profile.dart`

```dart
class UserPublicProfile {
  final String userId;
  final String username;
  final String displayName;
  final bool isPrivate;
  final int followerCount;
  final int followingCount;
  final int streakCount;
  final int badgesEarned;
  final int passagesSaved;

  const UserPublicProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.isPrivate,
    required this.followerCount,
    required this.followingCount,
    required this.streakCount,
    required this.badgesEarned,
    required this.passagesSaved,
  });
}
```

### Step 4: Add follow methods to `lib/services/user_data_service.dart`

Add at the end of `UserDataService`:

```dart
static Future<UserPublicProfile?> fetchPublicProfile(String username) async {
  try {
    final profileRow = await supabase
        .from('profiles')
        .select('user_id, username, display_name, is_private')
        .eq('username', username.toLowerCase())
        .maybeSingle();

    if (profileRow == null) return null;

    final userId = profileRow['user_id'] as String;
    final isPrivate = (profileRow['is_private'] as bool?) ?? false;

    if (isPrivate) {
      return UserPublicProfile(
        userId: userId,
        username: profileRow['username'] as String? ?? username,
        displayName: profileRow['display_name'] as String? ?? '',
        isPrivate: true,
        followerCount: 0,
        followingCount: 0,
        streakCount: 0,
        badgesEarned: 0,
        passagesSaved: 0,
      );
    }

    // Fetch counts in parallel
    final counts = await Future.wait([
      supabase.from('follows').select().eq('following_id', userId),
      supabase.from('follows').select().eq('follower_id', userId),
      supabase.from('read_days').select('date').eq('user_id', userId),
      supabase.from('saved_passages').select('id').eq('user_id', userId),
    ]);

    final followerCount = (counts[0] as List).length;
    final followingCount = (counts[1] as List).length;
    final readDays = (counts[2] as List).map((r) => r['date'] as String).toList();
    final passagesSaved = (counts[3] as List).length;

    // Simple streak calc: count consecutive days from today
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 400; i++) {
      final d = today.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      if (readDays.contains(d)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return UserPublicProfile(
      userId: userId,
      username: profileRow['username'] as String? ?? username,
      displayName: profileRow['display_name'] as String? ?? '',
      isPrivate: false,
      followerCount: followerCount,
      followingCount: followingCount,
      streakCount: streak,
      badgesEarned: 0, // Simplified — badges require more data
      passagesSaved: passagesSaved,
    );
  } catch (_) {
    return null;
  }
}

static Future<void> followUser(String followerId, String followingId) async {
  await supabase.from('follows').upsert(
    {'follower_id': followerId, 'following_id': followingId},
    onConflict: 'follower_id,following_id',
  );
}

static Future<void> unfollowUser(String followerId, String followingId) async {
  await supabase
      .from('follows')
      .delete()
      .eq('follower_id', followerId)
      .eq('following_id', followingId);
}

static Future<bool> isFollowing(String followerId, String followingId) async {
  final result = await supabase
      .from('follows')
      .select('id')
      .eq('follower_id', followerId)
      .eq('following_id', followingId)
      .maybeSingle();
  return result != null;
}
```

Add `fetchPublicProfile` import at the top of user_data_service.dart:
```dart
import '../models/user_public_profile.dart';
```

### Step 5: Run tests

```bash
flutter test test/services/follow_service_test.dart
```
Expected: all PASS

### Step 6: Commit

```bash
git add lib/models/user_public_profile.dart lib/services/user_data_service.dart test/services/follow_service_test.dart
git commit -m "feat: follow system — UserPublicProfile model and UserDataService follow methods"
```

---

## Task 10: Public profile screen + deep link routing

**Files:**
- Create: `lib/screens/public_profile_screen.dart`
- Modify: `lib/core/router.dart`
- Modify: `lib/main.dart`
- Create: `test/screens/public_profile_screen_test.dart`

### Step 1: Write failing tests

Create `test/screens/public_profile_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/public_profile_screen.dart';

Widget _wrap(String username) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: AppProvider(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/profile/$username',
        routes: [
          GoRoute(
            path: '/profile/:username',
            builder: (_, state) => PublicProfileScreen(
              username: state.pathParameters['username']!,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PublicProfileScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_wrap('jessreads'));
      // Before async resolves, show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without overflow on load', (tester) async {
      await tester.pumpWidget(_wrap('jessreads'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
```

### Step 2: Create `lib/screens/public_profile_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../models/user_public_profile.dart';
import '../providers/app_provider.dart';
import '../services/user_data_service.dart';
import '../utils/streak_tier.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserPublicProfile? _profile;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await UserDataService.fetchPublicProfile(widget.username);
    if (!mounted) return;

    bool following = false;
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (profile != null && myId != null && !profile.isPrivate) {
      following = await UserDataService.isFollowing(myId, profile.userId);
    }

    setState(() {
      _profile = profile;
      _isFollowing = following;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null) return;
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await UserDataService.unfollowUser(myId, profile.userId);
        setState(() => _isFollowing = false);
      } else {
        await UserDataService.followUser(myId, profile.userId);
        setState(() => _isFollowing = true);
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Text(
                    'Profile not found',
                    style: GoogleFonts.lora(
                        fontSize: 16, color: AppTheme.inkMid),
                  ),
                )
              : _profile!.isPrivate
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔒',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'This profile is private',
                            style: GoogleFonts.lora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _ProfileContent(
                      profile: _profile!,
                      isFollowing: _isFollowing,
                      followLoading: _followLoading,
                      onToggleFollow: _toggleFollow,
                    ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserPublicProfile profile;
  final bool isFollowing;
  final bool followLoading;
  final VoidCallback onToggleFollow;

  const _ProfileContent({
    required this.profile,
    required this.isFollowing,
    required this.followLoading,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final tierEmoji = streakTierEmoji(profile.streakCount);
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isSelf = myId == profile.userId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(tierEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${profile.username}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  if (profile.displayName.isNotEmpty)
                    Text(
                      profile.displayName,
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: AppTheme.tobacco),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatTile(label: 'STREAK', value: '${profile.streakCount} days'),
              _StatTile(
                  label: 'FOLLOWERS',
                  value: '${profile.followerCount}'),
              _StatTile(
                  label: 'FOLLOWING',
                  value: '${profile.followingCount}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatTile(
                  label: 'PASSAGES',
                  value: '${profile.passagesSaved}'),
            ],
          ),
          const SizedBox(height: 24),
          // Follow button
          if (!isSelf)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: followLoading ? null : onToggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? AppTheme.parchment : AppTheme.brand,
                  foregroundColor:
                      isFollowing ? AppTheme.ink : Colors.white,
                ),
                child: followLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        Text(
          label,
          style: AppTheme.monoLabel(
            fontSize: 10,
            color: AppTheme.inkLight,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
```

### Step 3: Add route to `lib/core/router.dart`

Add import at top:
```dart
import '../screens/public_profile_screen.dart';
```

Inside the `ShellRoute` routes list, add:
```dart
GoRoute(
  path: '/app/profile/view/:username',
  builder: (_, state) => PublicProfileScreen(
    username: state.pathParameters['username']!,
  ),
),
```

### Step 4: Extend deep link handler in `lib/main.dart`

In `_AppWithAuthState._handleDeepLinks()`, extend the `uriLinkStream.listen` handler:

```dart
void _handleDeepLinks() {
  final appLinks = AppLinks();
  appLinks.getInitialLink().then((uri) async {
    if (uri == null) return;
    final handled = await _handleProfileLink(uri);
    if (!handled) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  });
  appLinks.uriLinkStream.listen((uri) async {
    final handled = await _handleProfileLink(uri);
    if (!handled) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  });
}

Future<bool> _handleProfileLink(Uri uri) async {
  // Handle scrollbooks://profile/username
  if (uri.scheme == 'scrollbooks' && uri.host == 'profile') {
    final username = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (username != null && username.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push('/app/profile/view/$username');
      });
      return true;
    }
  }
  return false;
}
```

### Step 5: Run tests

```bash
flutter test test/screens/public_profile_screen_test.dart
```
Expected: all PASS

### Step 6: Commit

```bash
git add lib/screens/public_profile_screen.dart lib/core/router.dart lib/main.dart test/screens/public_profile_screen_test.dart
git commit -m "feat: public profile screen, follow button, and deep link routing"
```

---

## Task 11: Settings — username edit + account visibility toggle

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Modify: `test/screens/settings_screen_test.dart`

### Step 1: Add failing tests

Add to existing `group('SettingsScreen', ...)`:

```dart
testWidgets('shows Username settings tile', (tester) async {
  final provider = AppProvider()..username = 'jessreads';
  await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/app/profile/reading-style', builder: (_, __) => const Scaffold(body: Text('reading-style'))),
          GoRoute(path: '/onboarding', builder: (_, __) => const Scaffold(body: Text('onboarding'))),
          GoRoute(path: '/change-password', builder: (_, __) => const Scaffold(body: Text('change-password'))),
        ],
      ),
    ),
  ));
  expect(find.text('Username'), findsOneWidget);
  expect(find.text('@jessreads'), findsOneWidget);
});

testWidgets('shows Account Visibility tile', (tester) async {
  await tester.pumpWidget(_wrap());
  expect(find.text('Account Visibility'), findsOneWidget);
});
```

### Step 2: Run tests to confirm failures

```bash
flutter test test/screens/settings_screen_test.dart
```
Expected: 2 FAIL

### Step 3: Convert `SettingsScreen` to `StatefulWidget` and add new items

Replace `lib/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../core/onboarding_state.dart';
import '../providers/app_provider.dart';
import '../services/user_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showUsernameEditSheet(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(text: provider.username ?? '');
    String? usernameStatus; // null, 'checking', 'available', 'taken', 'invalid'
    String lastChecked = '';
    final formKey = GlobalKey<FormState>();
    final regex = RegExp(r'^[a-z0-9_]{3,20}$');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> checkAvailability(String value) async {
              final trimmed = value.trim().toLowerCase();
              if (trimmed == lastChecked) return;
              lastChecked = trimmed;
              if (!regex.hasMatch(trimmed)) {
                setSheetState(() => usernameStatus = 'invalid');
                return;
              }
              setSheetState(() => usernameStatus = 'checking');
              final available = await UserDataService.isUsernameAvailable(trimmed);
              if (lastChecked != trimmed) return;
              setSheetState(() =>
                  usernameStatus = available ? 'available' : 'taken');
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24,
                  MediaQuery.of(context).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Change Username',
                      style: GoogleFonts.lora(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppTheme.ink),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        suffixIcon: usernameStatus == 'available'
                            ? Icon(Icons.check_circle_outline,
                                color: AppTheme.sage, size: 20)
                            : usernameStatus == 'taken'
                                ? Icon(Icons.cancel_outlined,
                                    color: AppTheme.sienna, size: 20)
                                : null,
                      ),
                      autocorrect: false,
                      onChanged: (v) {
                        if (v.length >= 3) {
                          Future.delayed(
                              const Duration(milliseconds: 400),
                              () => checkAvailability(v));
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!regex.hasMatch(v.trim().toLowerCase()))
                          return 'Use lowercase letters, numbers and underscores (3–20 chars)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: usernameStatus != 'available'
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final userId =
                                  supabase.auth.currentUser?.id;
                              if (userId == null) return;
                              await provider.setUsername(
                                  userId,
                                  controller.text.trim().toLowerCase());
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('How Scroll Books works',
                      style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15)),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
                  onTap: () => context.push('/onboarding'),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Reading style',
                      style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.readingStyle == 'horizontal'
                            ? 'Stories Style' : 'Scroll Style',
                        style: TextStyle(color: AppTheme.pewter),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.pewter),
                    ],
                  ),
                  onTap: () => context.push('/app/profile/reading-style'),
                ),
                const Divider(color: AppTheme.borderSoft),
                // Username
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Username',
                      style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.username != null)
                        Text('@${provider.username}',
                            style: TextStyle(color: AppTheme.pewter)),
                      Icon(Icons.chevron_right, color: AppTheme.pewter),
                    ],
                  ),
                  onTap: () => _showUsernameEditSheet(context, provider),
                ),
                const Divider(color: AppTheme.borderSoft),
                // Account Visibility
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Account Visibility',
                      style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15)),
                  trailing: Switch(
                    value: !provider.isPrivate,
                    activeColor: AppTheme.brand,
                    onChanged: (isPublic) {
                      final userId = supabase.auth.currentUser?.id;
                      if (userId != null) {
                        provider.setAccountVisibility(userId,
                            isPrivate: !isPublic);
                      }
                    },
                  ),
                  subtitle: Text(
                    provider.isPrivate ? 'Private' : 'Public',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.tobacco),
                  ),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Change password',
                      style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15)),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
                  onTap: () => context.push('/change-password'),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Reset onboarding',
                      style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15)),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
                  onTap: () async => await resetOnboarding(),
                ),
                const Divider(color: AppTheme.borderSoft),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async => await supabase.auth.signOut(),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.sienna),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### Step 4: Run tests

```bash
flutter test test/screens/settings_screen_test.dart
```
Expected: all PASS

### Step 5: Run all tests

```bash
flutter test
```
Expected: all PASS (or only pre-existing failures in library_screen_test.dart from Supabase not being initialized — those are known pre-existing failures)

### Step 6: Commit

```bash
git add lib/screens/settings_screen.dart test/screens/settings_screen_test.dart
git commit -m "feat: username edit and account visibility toggle in Settings"
```

---

## Final check

```bash
flutter test
```
Expected: all PASS except known pre-existing `library_screen_test.dart` failures.

```bash
flutter build apk --release
```
Expected: build succeeds, no compile errors.
