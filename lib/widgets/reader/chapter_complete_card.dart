import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/reader_chunk.dart';

class ChapterCompleteCard extends StatefulWidget {
  final ChapterCompleteItem item;
  final String readingStyle;

  const ChapterCompleteCard({
    super.key,
    required this.item,
    required this.readingStyle,
  });

  @override
  State<ChapterCompleteCard> createState() => _ChapterCompleteCardState();
}

class _ChapterCompleteCardState extends State<ChapterCompleteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_FallingEmoji> _emojis = [];
  final Random _rng = Random();

  static const _emojiSet = ['\u{1F389}', '\u{1F38A}', '\u{2728}', '\u{2B50}', '\u{1F525}', '\u{1F4D6}', '\u{1F4DA}', '\u{1F31F}', '\u{1F4AB}', '\u{1F3C5}'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _spawnEmojis();
    _controller.forward();
  }

  void _spawnEmojis() {
    for (int i = 0; i < 30; i++) {
      _emojis.add(_FallingEmoji(
        emoji: _emojiSet[_rng.nextInt(_emojiSet.length)],
        x: _rng.nextDouble() * 0.9 + 0.05,
        size: 16 + _rng.nextDouble() * 16,
        delay: _rng.nextDouble() * 2 / 4.5,
        duration: (2.5 + _rng.nextDouble() * 2) / 4.5,
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
    final item = widget.item;
    final isHorizontal = widget.readingStyle == 'horizontal';
    final arrow = isHorizontal ? '\u{2192}' : '\u{2193}';

    return Container(
      color: AppTheme.page,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('\u{1F3C6}', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text(
                      'Chapter Complete!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tomato,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.completedChapterTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CHAPTER ${item.completedChapterNumber} OF ${item.totalChapters}',
                      style: AppTheme.monoLabel(
                        fontSize: 9,
                        letterSpacing: 2,
                        color: AppTheme.sage,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatPill(
                          value: '${item.passagesInChapter}',
                          label: 'PASSAGES READ',
                          color: AppTheme.amberLight,
                        ),
                        const SizedBox(width: 10),
                        _StatPill(
                          value: '${item.bookProgressPercent}%',
                          label: 'BOOK PROGRESS',
                          color: AppTheme.sageLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Swipe to continue $arrow',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        color: AppTheme.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ..._emojis.map((e) => _FallingEmojiWidget(
                  emoji: e,
                  animation: _controller,
                )),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.monoLabel(fontSize: 8, color: AppTheme.inkLight),
          ),
        ],
      ),
    );
  }
}

class _FallingEmoji {
  final String emoji;
  final double x;
  final double size;
  final double delay;
  final double duration;

  const _FallingEmoji({
    required this.emoji,
    required this.x,
    required this.size,
    required this.delay,
    required this.duration,
  });
}

class _FallingEmojiWidget extends StatelessWidget {
  final _FallingEmoji emoji;
  final Animation<double> animation;

  const _FallingEmojiWidget({required this.emoji, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = ((animation.value - emoji.delay) / emoji.duration).clamp(0.0, 1.0);
        if (t == 0) return const SizedBox.shrink();
        final screenH = MediaQuery.of(context).size.height;
        final screenW = MediaQuery.of(context).size.width;
        final top = -50.0 + (screenH + 50) * t;
        final left = emoji.x * screenW;
        final opacity = t < 0.7 ? 1.0 : (1.0 - ((t - 0.7) / 0.3)).clamp(0.0, 1.0);
        final rotation = t * 2 * pi;

        return Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Text(emoji.emoji, style: TextStyle(fontSize: emoji.size)),
            ),
          ),
        );
      },
    );
  }
}
