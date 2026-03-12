import 'dart:math';

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
  final Future<void> Function(String text, int chunkIndex) onShare;
  final Future<void> Function(String text, int chunkIndex) onSave;
  final ValueChanged<bool>? onActionsVisibleChanged;
  final String? chapterTitle;
  final int? chapterNumber;

  const PassageActionOverlay({
    super.key,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
    required this.bookId,
    required this.isSaved,
    required this.onShare,
    required this.onSave,
    this.onActionsVisibleChanged,
    this.chapterTitle,
    this.chapterNumber,
  });

  @override
  State<PassageActionOverlay> createState() => _PassageActionOverlayState();
}

class _PassageActionOverlayState extends State<PassageActionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _shrinkController;
  late final Animation<double> _shrinkScale;
  late final AnimationController _restoreController;
  late final Animation<double> _restoreScale;

  OverlayEntry? _overlayEntry;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();

    // Shake: side-to-side damped oscillation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _shrinkController.forward();
        _showOverlay();
      }
    });

    // Shrink: scale down with elastic bounce
    _shrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shrinkScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.elasticOut),
    );

    // Restore: scale back to 1.0
    _restoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _restoreScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _restoreController, curve: Curves.easeOutCubic),
    );
    _restoreController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isActive = false);
        _shakeController.reset();
        _shrinkController.reset();
        _restoreController.reset();
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _shakeController.dispose();
    _shrinkController.dispose();
    _restoreController.dispose();
    super.dispose();
  }

  void _onLongPress() {
    if (_isActive) return;
    setState(() => _isActive = true);
    _shakeController.forward();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (_) => _OverlayContent(
        isSaved: widget.isSaved,
        onShare: () => _onAction(widget.onShare),
        onSave: () => _onAction(widget.onSave),
        onDismiss: _dismiss,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    widget.onActionsVisibleChanged?.call(true);
  }

  Future<void> _onAction(
      Future<void> Function(String, int) callback) async {
    await Future.wait([
      callback(widget.text, widget.chunkIndex),
      Future<void>.delayed(const Duration(milliseconds: 500)),
    ]);
    if (mounted) _dismiss();
  }

  void _dismiss() {
    _removeOverlay();
    widget.onActionsVisibleChanged?.call(false);
    _restoreController.forward();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  double get _currentScale {
    if (_restoreController.isAnimating) return _restoreScale.value;
    if (_shrinkController.isAnimating ||
        _shrinkController.status == AnimationStatus.completed) {
      return _shrinkScale.value;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _onLongPress,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_shakeController, _shrinkController, _restoreController]),
        builder: (context, child) {
          // Damped sinusoidal shake: 3 oscillations, amplitude decays
          final shakeValue = _shakeController.value;
          final shakeOffset =
              sin(shakeValue * 3 * pi) * 3.0 * (1.0 - shakeValue);

          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: Transform.scale(
              scale: _currentScale,
              child: child,
            ),
          );
        },
        child: ReaderCard(
          text: widget.text,
          chunkIndex: widget.chunkIndex,
          totalChunks: widget.totalChunks,
          chapterTitle: widget.chapterTitle,
          chapterNumber: widget.chapterNumber,
        ),
      ),
    );
  }
}

/// Overlay content: scrim + action buttons with slide-in animation.
/// Rendered via OverlayEntry, completely outside the PageView tree.
class _OverlayContent extends StatefulWidget {
  final bool isSaved;
  final Future<void> Function() onShare;
  final Future<void> Function() onSave;
  final VoidCallback onDismiss;

  const _OverlayContent({
    required this.isSaved,
    required this.onShare,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  State<_OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<_OverlayContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<double> _slideOffset;
  late final Animation<double> _opacity;
  String? _loadingButton;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideOffset = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleTap(String button, Future<void> Function() action) async {
    if (_loadingButton != null) return;
    setState(() => _loadingButton = button);
    await action();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: _loadingButton == null ? widget.onDismiss : null,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black12),
            ),
          ),
          // Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) => Opacity(
                opacity: _opacity.value,
                child: Transform.translate(
                  offset: Offset(0, _slideOffset.value),
                  child: child,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionPill(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      isLoading: _loadingButton == 'share',
                      onTap: () => _handleTap('share', widget.onShare),
                    ),
                    const SizedBox(width: 16),
                    _ActionPill(
                      icon: widget.isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      label: widget.isSaved ? 'Saved' : 'Save',
                      isLoading: _loadingButton == 'save',
                      onTap: () => _handleTap('save', widget.onSave),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.brand,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.warmShadow(blur: 16, spread: 2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.surface,
                  ),
                )
              : Row(
                  key: ValueKey(label),
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
      ),
    );
  }
}
