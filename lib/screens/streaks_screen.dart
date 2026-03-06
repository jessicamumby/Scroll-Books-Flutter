import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../utils/streak_calculator.dart';
import '../widgets/shared_header.dart';
import '../widgets/shared_tab_bar.dart';
import '../widgets/streak_counter.dart';
import '../widgets/weekly_progress_dots.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/bookmark_card.dart';
import '../widgets/milestones_list.dart';
import '../widgets/genre_badges_grid.dart';
import '../widgets/longevity_badges_list.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
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
      ),
    );
  }
}

class _StreaksTab extends StatelessWidget {
  const _StreaksTab({super.key});

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

  int _getTodayIndex() {
    // weekday: 1=Monday .. 7=Sunday -> 0-based: 0=Monday .. 6=Sunday
    return DateTime.now().weekday - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final streak = calculateStreak(
          provider.readDays,
          frozenDays: provider.frozenDays,
        );
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final passagesToday = provider.dailyPassages[todayStr] ?? 0;
        final weeklyCompletion = _getWeeklyCompletion(
          provider.readDays,
          provider.frozenDays,
        );
        final isAtRisk = !provider.readDays.contains(todayStr) &&
            !provider.frozenDays.contains(todayStr);
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
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final streak = calculateStreak(
          provider.readDays,
          frozenDays: provider.frozenDays,
        );
        return Container(
          color: AppTheme.warmWhite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenreBadgesGrid(genreCounts: provider.genreCounts),
                const SizedBox(height: 28),
                LongevityBadgesList(currentStreak: streak),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
