import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _LongevityBadge {
  final int days;
  final String name;
  final String emoji;
  const _LongevityBadge(this.days, this.name, this.emoji);
}

const _badges = [
  _LongevityBadge(7, 'Week Worm', '🐛'),
  _LongevityBadge(30, 'Page Turner', '📖'),
  _LongevityBadge(90, 'Bibliophile', '📚'),
  _LongevityBadge(365, 'Literary Legend', '🏛'),
];

class LongevityBadgesList extends StatelessWidget {
  final int currentStreak;
  const LongevityBadgesList({super.key, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LONGEVITY BADGES',
          style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
        ),
        const SizedBox(height: 12),
        ...List.generate(_badges.length, (i) {
          final badge = _badges[i];
          final unlocked = currentStreak >= badge.days;
          return Padding(
            padding: EdgeInsets.only(bottom: i < _badges.length - 1 ? 10 : 0),
            child: _LongevityCard(
              badge: badge,
              unlocked: unlocked,
            ),
          );
        }),
      ],
    );
  }
}

class _LongevityCard extends StatelessWidget {
  final _LongevityBadge badge;
  final bool unlocked;

  const _LongevityCard({
    required this.badge,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: unlocked
              ? const LinearGradient(
                  colors: [AppTheme.amberLight, AppTheme.cream],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: unlocked ? null : AppTheme.cream,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: unlocked
                ? AppTheme.amber.withValues(alpha: 0.25)
                : AppTheme.inkLight.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: unlocked
                    ? const LinearGradient(
                        colors: [AppTheme.amber, AppTheme.warmGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: unlocked ? null : AppTheme.parchment,
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
                  child: Text(badge.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${badge.days} day reading streak',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      color: AppTheme.inkMid,
                    ),
                  ),
                ],
              ),
            ),
            // Earned label
            if (unlocked)
              Text(
                '✓ EARNED',
                style: AppTheme.monoLabel(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.amber,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
