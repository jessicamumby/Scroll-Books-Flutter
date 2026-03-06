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
        borderRadius: BorderRadius.circular(16),
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
