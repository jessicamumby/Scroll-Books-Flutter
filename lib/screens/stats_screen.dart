import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../utils/streak_calculator.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _shareCardKey = GlobalKey();

  Future<void> _shareStreak(int streak) async {
    try {
      final boundary = _shareCardKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/streak_card.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🔥 $streak day reading streak on Scroll Books!',
      );
    } catch (e, st) {
      debugPrint('Share streak error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final streak = calculateStreak(provider.readDays);
        final now = DateTime.now();
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

        final scaffold = Scaffold(
          backgroundColor: AppTheme.page,
          appBar: AppBar(title: const Text('Stats')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Text(
                            '🔥 $streak',
                            style: GoogleFonts.lora(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.brand,
                            ),
                          ),
                          Text(
                            'day streak',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.tobacco,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '${provider.longestStreak}',
                            style: GoogleFonts.lora(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.pewter,
                            ),
                          ),
                          Text(
                            'best',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.fog,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${provider.passagesRead} passages read',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: AppTheme.tobacco,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _shareStreak(streak),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Streak'),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '${_monthName(now.month)} ${now.year}',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (_, i) {
                      final day = i + 1;
                      final dateStr =
                          '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                      final read = provider.readDays.contains(dateStr);
                      final count = provider.dailyPassages[dateStr] ?? 0;
                      double opacity = 0;
                      if (read) {
                        if (count >= 16) {
                          opacity = 1.0;
                        } else if (count >= 6) {
                          opacity = 0.6;
                        } else {
                          opacity = 0.3;
                        }
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: read
                              ? AppTheme.brand.withValues(alpha: opacity)
                              : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              color: read
                                  ? AppTheme.surface
                                  : AppTheme.pewter,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  RepaintBoundary(
                    key: _shareCardKey,
                    child: _StreakShareCard(streak: streak),
                  ),
                ],
              ),
            ),
          ),
        );

        if (provider.pendingMilestone == null) return scaffold;

        return Stack(
          children: [
            scaffold,
            Positioned.fill(
              child: _MilestoneOverlay(
                milestone: provider.pendingMilestone!,
                onDismiss: provider.clearMilestone,
                onShare: () {
                  final m = provider.pendingMilestone ?? streak;
                  provider.clearMilestone();
                  _shareStreak(m);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}

class _StreakShareCard extends StatelessWidget {
  final int streak;
  const _StreakShareCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      color: AppTheme.page,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 4),
              Text(
                '$streak',
                style: GoogleFonts.lora(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brand,
                ),
              ),
              Text(
                'days reading streak',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppTheme.tobacco,
                ),
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
              children: [
                const TextSpan(text: 'scroll'),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: AppTheme.brand),
                ),
                const TextSpan(text: 'books'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;
  final VoidCallback onShare;
  const _MilestoneOverlay({
    required this.milestone,
    required this.onDismiss,
    required this.onShare,
  });

  @override
  State<_MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<_MilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _message {
    if (widget.milestone >= 100) return 'Legendary. Keep reading.';
    if (widget.milestone >= 30) return "You're on fire. Keep going.";
    return 'One week down. Keep going.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: AppTheme.page.withValues(alpha: 0.95),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: const Text('🔥', style: TextStyle(fontSize: 96)),
              ),
              const SizedBox(height: 24),
              Text(
                '${widget.milestone} days',
                style: GoogleFonts.lora(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _message,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: AppTheme.tobacco,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: widget.onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share this moment'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: AppTheme.pewter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
