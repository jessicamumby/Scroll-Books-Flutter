import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _GenreBadge {
  final String name;
  final String emoji;
  final Color color;
  final int booksRead;
  final bool unlocked;
  const _GenreBadge(this.name, this.emoji, this.color, this.booksRead, this.unlocked);
}

const _badges = [
  _GenreBadge('Adventure', '⛵', Color(0xFF4A90D9), 3, true),
  _GenreBadge('Romance', '💌', Color(0xFFD94F7A), 1, true),
  _GenreBadge('Gothic', '🏚', Color(0xFF6B4C6E), 0, false),
  _GenreBadge('Philosophy', '🪶', Color(0xFF8B7355), 0, false),
  _GenreBadge('Satire', '🎭', Color(0xFFC4762B), 2, true),
  _GenreBadge('Sci-Fi', '🔭', Color(0xFF3D7A8A), 0, false),
];

class GenreBadgesGrid extends StatelessWidget {
  const GenreBadgesGrid({super.key});

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
          itemCount: _badges.length,
          itemBuilder: (_, i) => _BadgeCard(badge: _badges[i]),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final _GenreBadge badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.only(top: 18, bottom: 12, left: 8, right: 8),
        decoration: BoxDecoration(
          color: badge.unlocked
              ? badge.color.withValues(alpha: 0.06)
              : AppTheme.cream,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: badge.unlocked
              ? Border.all(color: badge.color.withValues(alpha: 0.20))
              : Border.all(
                  color: AppTheme.inkLight.withValues(alpha: 0.15),
                  // Simulating dashed border with a subtle style
                ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: badge.unlocked ? badge.color.withValues(alpha: 0.12) : AppTheme.parchment,
                boxShadow: badge.unlocked
                    ? [
                        BoxShadow(
                          color: badge.color.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter: badge.unlocked
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
            const SizedBox(height: 10),
            Text(
              badge.name,
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
              badge.unlocked
                  ? '${badge.booksRead} ${badge.booksRead == 1 ? 'book' : 'books'} read'
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
