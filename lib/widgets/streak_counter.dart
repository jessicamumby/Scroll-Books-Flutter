import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _Tier {
  final String emoji;
  final double emojiSize;
  final double scaleMax;
  final Duration halfCycleDuration;

  const _Tier({
    required this.emoji,
    required this.emojiSize,
    required this.scaleMax,
    required this.halfCycleDuration,
  });
}

_Tier _tierFor(int streak) {
  if (streak == 0) {
    return const _Tier(
      emoji: '🪵', emojiSize: 28, scaleMax: 1.05,
      halfCycleDuration: Duration(milliseconds: 800),
    );
  }
  if (streak < 7) {
    return const _Tier(
      emoji: '🔥', emojiSize: 32, scaleMax: 1.08,
      halfCycleDuration: Duration(milliseconds: 600),
    );
  }
  if (streak < 30) {
    return const _Tier(
      emoji: '🔥', emojiSize: 40, scaleMax: 1.12,
      halfCycleDuration: Duration(milliseconds: 500),
    );
  }
  if (streak < 90) {
    return const _Tier(
      emoji: '🔥', emojiSize: 48, scaleMax: 1.15,
      halfCycleDuration: Duration(milliseconds: 420),
    );
  }
  return const _Tier(
    emoji: '🔥', emojiSize: 56, scaleMax: 1.18,
    halfCycleDuration: Duration(milliseconds: 340),
  );
}

class StreakCounter extends StatefulWidget {
  final int streakCount;
  final bool isAtRisk;

  const StreakCounter({
    super.key,
    required this.streakCount,
    this.isAtRisk = false,
  });

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  // Each "half-cycle" = one forward or one reverse pass.
  // autoLoops * 2 half-cycles = autoLoops full ping-pong loops.
  static const int _autoHalfCycles = 6;  // 3 loops
  static const int _tapHalfCycles = 10;  // 5 loops
  int _halfCyclesLeft = 0;

  @override
  void initState() {
    super.initState();
    _buildController();
    _startLoops(_autoHalfCycles);
  }

  void _buildController() {
    final tier = _tierFor(widget.streakCount);
    _controller = AnimationController(
      vsync: this,
      duration: tier.halfCycleDuration,
    );
    _scale = Tween<double>(begin: 1.0 / tier.scaleMax, end: tier.scaleMax)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.65, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted || _halfCyclesLeft <= 0) return;
    _halfCyclesLeft--;
    if (_halfCyclesLeft > 0) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    }
  }

  void _startLoops(int halfCycles) {
    _controller.stop();
    _halfCyclesLeft = halfCycles;
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(StreakCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streakCount != widget.streakCount) {
      _controller.removeStatusListener(_onStatus);
      _controller.dispose();
      _buildController();
      _startLoops(_autoHalfCycles);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(widget.streakCount);
    Widget emoji = GestureDetector(
      onTap: () => _startLoops(_tapHalfCycles),
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Text(tier.emoji, style: TextStyle(fontSize: tier.emojiSize)),
        ),
      ),
    );

    if (widget.isAtRisk) {
      emoji = Opacity(opacity: 0.6, child: emoji);
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
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
            emoji,
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
      ),
    );
  }
}
