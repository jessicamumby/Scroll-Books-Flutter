import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StreakCounter extends StatefulWidget {
  final int streakCount;
  const StreakCounter({super.key, required this.streakCount});

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: const Text('🔥', style: TextStyle(fontSize: 30)),
            ),
          ),
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
