import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/reader_chunk.dart';

class ChapterCompleteCard extends StatefulWidget {
  final ChapterCompleteItem item;
  final String readingStyle;
  final VoidCallback? onShare;

  const ChapterCompleteCard({
    super.key,
    required this.item,
    required this.readingStyle,
    this.onShare,
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

  // Total animation budget: 6.5s (max delay 2s + max duration 4.5s)
  static const _totalMs = 6500;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
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
        // Normalise by 6.5s so all emojis complete before controller ends
        delay: _rng.nextDouble() * 2 / 6.5,
        duration: (2.5 + _rng.nextDouble() * 2) / 6.5,
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
            // Main content: centred, with swipe hint pinned at bottom
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                          if (widget.onShare != null) ...[
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: widget.onShare,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.tomato.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.share_outlined, size: 15, color: AppTheme.tomato),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SHARE',
                                      style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.tomato),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Swipe hint pinned at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Text(
                    'Swipe to continue $arrow',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      color: AppTheme.inkLight,
                    ),
                  ),
                ),
              ],
            ),
            // Falling emojis on top of everything
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
        final top = -50.0 + (screenH + 100) * t;
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
