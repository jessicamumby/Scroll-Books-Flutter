import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class WeeklyProgressDots extends StatelessWidget {
  final List<bool> completedDays; // length 7, Mon=0 .. Sun=6
  final List<bool> frozenDays;    // length 7, amber bookmark dots
  final int todayIndex;

  const WeeklyProgressDots({
    super.key,
    required this.completedDays,
    required this.todayIndex,
    this.frozenDays = const [false, false, false, false, false, false, false],
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final completed = i < completedDays.length && completedDays[i];
        final frozen = i < frozenDays.length && frozenDays[i];
        final isToday = i == todayIndex;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotCircle(
                completed: completed,
                frozen: frozen && !completed,
                isToday: isToday,
              ),
              const SizedBox(height: 6),
              Text(
                _dayLabels[i],
                style: AppTheme.monoLabel(
                  fontSize: 10,
                  color: AppTheme.inkLight,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DotCircle extends StatelessWidget {
  final bool completed;
  final bool frozen;
  final bool isToday;

  const _DotCircle({
    required this.completed,
    required this.frozen,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.tomato, AppTheme.amber],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tomato.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      );
    }

    if (frozen) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.amber.withValues(alpha: 0.25),
          border: Border.all(
            color: AppTheme.amber.withValues(alpha: 0.60),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Text('🔖', style: TextStyle(fontSize: 14)),
        ),
      );
    }

    if (isToday) {
      return CustomPaint(
        painter: _DashedCirclePainter(
          color: AppTheme.inkLight.withValues(alpha: 0.30),
          strokeWidth: 1.5,
          dashLength: 4,
          gapLength: 3,
        ),
        child: const SizedBox(width: 34, height: 34),
      );
    }

    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.parchment,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final dashAngle = (dashLength / circumference) * 2 * pi;
    final gapAngle = (gapLength / circumference) * 2 * pi;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle) - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
