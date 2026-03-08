import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StreakBadgeShareCard extends StatelessWidget {
  final String username;
  final String badgeName;
  final String badgeEmoji;
  final int streakDays;

  const StreakBadgeShareCard({
    super.key,
    required this.username,
    required this.badgeName,
    required this.badgeEmoji,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.warmShadow(blur: 24, spread: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badgeEmoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            badgeName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$streakDays day reading streak',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              color: AppTheme.inkMid,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '@$username · SCROLL BOOKS',
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
