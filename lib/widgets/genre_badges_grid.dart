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
