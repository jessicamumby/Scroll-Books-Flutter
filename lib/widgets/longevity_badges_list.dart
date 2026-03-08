import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../utils/share_streak_badge_image.dart';
import '../widgets/streak_badge_share_card.dart';

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
  final String? username;

  const LongevityBadgesList({
    super.key,
    required this.currentStreak,
    this.username,
  });

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
              key: ValueKey(badge.days),
              badge: badge,
              unlocked: unlocked,
              username: username,
            ),
          );
        }),
      ],
    );
  }
}

class _LongevityCard extends StatefulWidget {
  final _LongevityBadge badge;
  final bool unlocked;
  final String? username;

  const _LongevityCard({
    super.key,
    required this.badge,
    required this.unlocked,
    this.username,
  });

  @override
  State<_LongevityCard> createState() => _LongevityCardState();
}

class _LongevityCardState extends State<_LongevityCard> {
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.unlocked && widget.username != null)
          Positioned(
            left: -1000,
            top: -1000,
            child: RepaintBoundary(
              key: _shareCardKey,
              child: StreakBadgeShareCard(
                username: widget.username!,
                badgeName: widget.badge.name,
                badgeEmoji: widget.badge.emoji,
                streakDays: widget.badge.days,
              ),
            ),
          ),
        Opacity(
          opacity: widget.unlocked ? 1.0 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: widget.unlocked
                  ? const LinearGradient(
                      colors: [AppTheme.amberLight, AppTheme.cream],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.unlocked ? null : AppTheme.cream,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: widget.unlocked
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
                    gradient: widget.unlocked
                        ? const LinearGradient(
                            colors: [AppTheme.amber, AppTheme.warmGold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: widget.unlocked ? null : AppTheme.parchment,
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: widget.unlocked
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                      child: Text(widget.badge.emoji,
                          style: const TextStyle(fontSize: 24)),
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
                        widget.badge.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.badge.days} day reading streak',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          color: AppTheme.inkMid,
                        ),
                      ),
                    ],
                  ),
                ),
                // Earned label + share icon
                if (widget.unlocked) ...[
                  Text(
                    '✓ EARNED',
                    style: AppTheme.monoLabel(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.amber,
                    ),
                  ),
                  if (widget.username != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await shareStreakBadgeImage(
                          repaintKey: _shareCardKey,
                          badgeName: widget.badge.name,
                          username: widget.username!,
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      color: AppTheme.amber,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Share badge',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
