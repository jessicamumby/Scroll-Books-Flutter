import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class BookmarkCard extends StatelessWidget {
  final int bookmarksRemaining;
  final String? bookmarkResetAt;
  final VoidCallback onUseBookmark;

  const BookmarkCard({
    super.key,
    required this.bookmarksRemaining,
    this.bookmarkResetAt,
    required this.onUseBookmark,
  });

  void _handleUse(BuildContext context) {
    onUseBookmark();
    _showBookmarkToast(context);
  }

  String _emptyLabel() {
    if (bookmarkResetAt == null) return 'No Bookmarks Left';
    final today = DateTime.now();
    final resetDate = DateTime.parse(bookmarkResetAt!);
    final days = resetDate.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (days <= 1) return 'Resets tomorrow';
    return 'Resets in $days days';
  }

  double _tokenFillProgress(int tokenIndex) {
    // Returns 0.0 (empty) to 1.0 (full)
    if (bookmarkResetAt == null) return 1.0;
    final now = DateTime.now();
    final resetDate = DateTime.parse(bookmarkResetAt!);
    const totalMs = 7 * 24 * 60 * 60 * 1000; // 7 days in ms
    final elapsedMs = now.millisecondsSinceEpoch -
        (resetDate.millisecondsSinceEpoch - totalMs);
    final progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
    final filled = tokenIndex < bookmarksRemaining;
    if (filled) return 1.0;
    return progress;
  }

  int _daysLeft() {
    if (bookmarkResetAt == null) return 0;
    final today = DateTime.now();
    final resetDate = DateTime.parse(bookmarkResetAt!);
    return resetDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays
        .clamp(0, 7);
  }

  void _showBookmarkToast(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _BookmarkToast(
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final hasBookmarks = bookmarksRemaining > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.amberLight, AppTheme.cream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.amber.withValues(alpha: 0.20),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookmarks',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Freeze your streak for up to 2 days',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12,
                        color: AppTheme.inkMid,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PennantToken(
                        filled: bookmarksRemaining >= 1,
                        fillProgress: _tokenFillProgress(0),
                      ),
                      const SizedBox(width: 4),
                      _PennantToken(
                        filled: bookmarksRemaining >= 2,
                        fillProgress: _tokenFillProgress(1),
                      ),
                    ],
                  ),
                  if (bookmarkResetAt != null && bookmarksRemaining < 2) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_daysLeft()} days left',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        color: AppTheme.inkLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action button
          GestureDetector(
            onTap: hasBookmarks ? () => _handleUse(context) : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: hasBookmarks ? AppTheme.amber : AppTheme.parchment,
                borderRadius: BorderRadius.circular(10),
                boxShadow: hasBookmarks
                    ? [
                        BoxShadow(
                          color: AppTheme.amber.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  hasBookmarks
                      ? 'Use Bookmark ($bookmarksRemaining remaining)'
                      : _emptyLabel(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasBookmarks ? Colors.white : AppTheme.inkLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PennantToken extends StatelessWidget {
  final bool filled;
  final double fillProgress; // 0.0 = empty, 1.0 = full

  const _PennantToken({required this.filled, this.fillProgress = 1.0});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ClipPath(
        clipper: _PennantClipper(),
        child: Container(
          width: 22,
          height: 30,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.amber, AppTheme.tomato],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    // Refilling: liquid fill from bottom up
    return ClipPath(
      clipper: _PennantClipper(),
      child: SizedBox(
        width: 22,
        height: 30,
        child: Stack(
          children: [
            // Empty background
            Container(
              width: 22,
              height: 30,
              color: AppTheme.inkLight.withValues(alpha: 0.15),
            ),
            // Liquid fill from bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 30 * fillProgress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.amber, AppTheme.tomato],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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

class _PennantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.75)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BookmarkToast extends StatefulWidget {
  final VoidCallback onDismiss;
  const _BookmarkToast({required this.onDismiss});

  @override
  State<_BookmarkToast> createState() => _BookmarkToastState();
}

class _BookmarkToastState extends State<_BookmarkToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.warmShadow(blur: 16),
              ),
              child: Row(
                children: [
                  const Text('🔖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bookmark activated! Your streak is safe for 1 day.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
