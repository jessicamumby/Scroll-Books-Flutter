import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../data/catalogue.dart';
import '../models/saved_passage.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _currentEmail() {
    try {
      return supabase.auth.currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  String? get _userId {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentEmail();

    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/app/profile/settings'),
            icon: const Text('⚙️', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final passages = provider.savedPassages;

          return CustomScrollView(
            slivers: [
              // User info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    email,
                    style: TextStyle(color: AppTheme.tobacco, fontSize: 15),
                  ),
                ),
              ),
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Row(
                    children: [
                      Text(
                        'Saved Passages',
                        style: GoogleFonts.lora(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (passages.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandPale,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${passages.length}',
                            style: GoogleFonts.dmMono(
                              fontSize: 12,
                              color: AppTheme.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Passages list or empty state
              if (passages.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.bookmark_border,
                            size: 48, color: AppTheme.fog),
                        const SizedBox(height: 12),
                        Text(
                          'No saved passages yet',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            color: AppTheme.pewter,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Long press any passage while reading to save it',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppTheme.tobacco,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) {
                      final passage = passages[index];
                      return _SavedPassageCard(
                        passage: passage,
                        totalChunks:
                            provider.bookTotalChunks[passage.bookId],
                        onDelete: () {
                          final userId = _userId;
                          if (userId != null) {
                            provider.deleteSavedPassage(
                                userId, passage.id);
                          }
                        },
                      );
                    },
                    childCount: passages.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedPassageCard extends StatefulWidget {
  final SavedPassage passage;
  final int? totalChunks;
  final VoidCallback onDelete;

  const _SavedPassageCard({
    required this.passage,
    required this.totalChunks,
    required this.onDelete,
  });

  @override
  State<_SavedPassageCard> createState() => _SavedPassageCardState();
}

class _SavedPassageCardState extends State<_SavedPassageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  bool _revealed = false;

  static const double _deleteButtonWidth = 88.0;

  String get _percentage {
    if (widget.totalChunks == null || widget.totalChunks == 0) return '';
    return '${((widget.passage.chunkIndex + 1) / widget.totalChunks! * 100).round()}%';
  }

  String get _formattedDate {
    final d = widget.passage.savedAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Only allow left swipe (negative dx)
    final delta = details.primaryDelta ?? 0;
    final newValue = _slideController.value - delta / _deleteButtonWidth;
    _slideController.value = newValue.clamp(0.0, 1.0);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Snap open if past halfway or flicked left, otherwise snap closed
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200 || _slideController.value > 0.5) {
      _slideController.forward();
      setState(() => _revealed = true);
    } else {
      _slideController.reverse();
      setState(() => _revealed = false);
    }
  }

  void _close() {
    _slideController.reverse();
    setState(() => _revealed = false);
  }

  void _confirmDelete() {
    // Animate fully off-screen, then delete
    _slideController.animateTo(
      4.0, // slide well past the button width
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    ).then((_) {
      if (mounted) widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = getBookById(widget.passage.bookId);
    final title = book?.title ?? widget.passage.bookId;
    final author = book?.author ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          children: [
            // Delete button revealed behind the card
            Positioned.fill(
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      width: _deleteButtonWidth,
                      color: AppTheme.brand,
                      alignment: Alignment.center,
                      child: Text(
                        'Delete',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Slideable card
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  -_slideController.value * _deleteButtonWidth,
                  0,
                ),
                child: child,
              ),
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onTap: _revealed ? _close : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.cardRadius),
                    border:
                        Border.all(color: AppTheme.brandPale, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.passage.passageText,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.ink,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                if (author.isNotEmpty)
                                  Text(
                                    author,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: AppTheme.tobacco,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_percentage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                _percentage,
                                style: GoogleFonts.dmMono(
                                  fontSize: 12,
                                  color: AppTheme.tobacco,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formattedDate,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppTheme.fog,
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
