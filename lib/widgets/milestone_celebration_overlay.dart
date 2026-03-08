import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _MilestoneData {
  final String name;
  final String emoji;
  final String subtitle;

  const _MilestoneData({
    required this.name,
    required this.emoji,
    required this.subtitle,
  });
}

_MilestoneData _dataFor(int milestone) {
  switch (milestone) {
    case 7:
      return const _MilestoneData(
        name: 'Week Worm', emoji: '🪱', subtitle: '7 day streak!',
      );
    case 30:
      return const _MilestoneData(
        name: 'Page Turner', emoji: '📖', subtitle: '30 day streak!',
      );
    case 90:
      return const _MilestoneData(
        name: 'Bibliophile', emoji: '📚', subtitle: '90 day streak!',
      );
    default:
      return const _MilestoneData(
        name: 'Literary Legend', emoji: '🏆', subtitle: '365 day streak!',
      );
  }
}

class MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _spawnParticles();
  }

  void _spawnParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.5,
        color: [
          AppTheme.tomato,
          AppTheme.amber,
          AppTheme.sage,
          AppTheme.warmGold,
        ][_rng.nextInt(4)],
        size: 6 + _rng.nextDouble() * 6,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _dataFor(widget.milestone);
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Stack(
          children: [
            // Confetti particles
            ...(_particles.map((p) => _ParticleWidget(
                  particle: p,
                  animation: _controller,
                ))),
            // Badge card
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Opacity(
                  opacity: _opacity.value,
                  child: ScaleTransition(scale: _scale, child: child),
                ),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.warmShadow(blur: 32, spread: 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data.emoji,
                          style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(
                        data.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: AppTheme.inkMid,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tap to continue',
                        style: AppTheme.monoLabel(
                          fontSize: 11,
                          color: AppTheme.inkLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x;    // horizontal position 0.0–1.0
  final double delay; // animation delay 0.0–0.5
  final Color color;
  final double size;

  const _Particle({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
  });
}

class _ParticleWidget extends StatelessWidget {
  final _Particle particle;
  final Animation<double> animation;

  const _ParticleWidget({required this.particle, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = ((animation.value - particle.delay) / (1 - particle.delay))
            .clamp(0.0, 1.0);
        final screenH = MediaQuery.of(context).size.height;
        final screenW = MediaQuery.of(context).size.width;
        final top = -40.0 + screenH * 0.6 * t;
        final left = particle.x * screenW - particle.size / 2;
        return Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: BoxDecoration(
                color: particle.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
