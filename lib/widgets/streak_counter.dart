import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StreakCounter extends StatelessWidget {
  final int streakCount;
  const StreakCounter({super.key, required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
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
          const Text('🔥', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 2),
          Text(
            '$streakCount',
            style: GoogleFonts.playfairDisplay(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -1.5,
            ),
          ),
          Text(
            'DAY STREAK',
            style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
          ),
        ],
      ),
    );
  }
}
