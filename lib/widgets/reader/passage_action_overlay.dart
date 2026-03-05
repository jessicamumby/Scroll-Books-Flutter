import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'reader_card.dart';

class PassageActionOverlay extends StatefulWidget {
  final String text;
  final int chunkIndex;
  final int totalChunks;
  final String bookId;
  final bool isSaved;
  final void Function(String text, int chunkIndex) onShare;
  final void Function(String text, int chunkIndex) onSave;

  const PassageActionOverlay({
    super.key,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
    required this.bookId,
    required this.isSaved,
    required this.onShare,
    required this.onSave,
  });

  @override
  State<PassageActionOverlay> createState() => _PassageActionOverlayState();
}

class _PassageActionOverlayState extends State<PassageActionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _liftController;
  late final Animation<double> _liftOffset;
  late final Animation<double> _scale;
  late final AnimationController _fadeController;
  late final Animation<double> _buttonOpacity;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _liftOffset = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _liftController, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _liftController, curve: Curves.easeOutCubic),
    );
    _liftController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showActions = true);
        _fadeController.forward();
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _liftController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onLongPress() {
    _liftController.forward();
  }

  void _dismiss() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _showActions = false);
        _liftController.reverse();
      }
    });
  }

  void _onShareTap() {
    _dismiss();
    widget.onShare(widget.text, widget.chunkIndex);
  }

  void _onSaveTap() {
    _dismiss();
    widget.onSave(widget.text, widget.chunkIndex);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _onLongPress,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _liftController,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _liftOffset.value),
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
            child: ReaderCard(
              text: widget.text,
              chunkIndex: widget.chunkIndex,
              totalChunks: widget.totalChunks,
            ),
          ),
          if (_showActions) ...[
            // Scrim
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismiss,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Action buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: FadeTransition(
                opacity: _buttonOpacity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionPill(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: _onShareTap,
                    ),
                    const SizedBox(width: 16),
                    _ActionPill(
                      icon: widget.isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      label: widget.isSaved ? 'Saved' : 'Save',
                      onTap: _onSaveTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.brand,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.warmShadow(blur: 16, spread: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.surface),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
