import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _Milestone {
  final int days;
  final String name;
  final String emoji;
  const _Milestone(this.days, this.name, this.emoji);
}

const _milestones = [
  _Milestone(7, 'Week Worm', '🐛'),
  _Milestone(30, 'Page Turner', '📖'),
  _Milestone(90, 'Bibliophile', '📚'),
  _Milestone(365, 'Literary Legend', '🏛'),
];

class MilestonesList extends StatelessWidget {
  final int currentStreak;
  const MilestonesList({super.key, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MILESTONES',
          style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
        ),
        const SizedBox(height: 12),
        ...List.generate(_milestones.length, (i) {
          final m = _milestones[i];
          final unlocked = currentStreak >= m.days;
          final progress = (currentStreak / m.days).clamp(0.0, 1.0);
          return Padding(
            padding: EdgeInsets.only(bottom: i < _milestones.length - 1 ? 10 : 0),
            child: _MilestoneCard(
              milestone: m,
              unlocked: unlocked,
              progress: progress,
              currentStreak: currentStreak,
            ),
          );
        }),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final _Milestone milestone;
  final bool unlocked;
  final double progress;
  final int currentStreak;

  const _MilestoneCard({
    required this.milestone,
    required this.unlocked,
    required this.progress,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.70,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? AppTheme.sageLight : AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? AppTheme.sage.withValues(alpha: 0.30)
                : AppTheme.inkLight.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: unlocked
                        ? LinearGradient(
                            colors: [
                              AppTheme.sage,
                              AppTheme.sage.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: unlocked ? null : AppTheme.parchment,
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: unlocked
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                      child: Text(
                        milestone.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Expanded(
                  child: Text(
                    milestone.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                // Day count
                Text(
                  '${milestone.days} days',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    color: AppTheme.inkLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.parchment,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: unlocked ? AppTheme.sage : AppTheme.inkLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
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
