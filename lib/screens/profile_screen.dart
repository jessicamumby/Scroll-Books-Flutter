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

class _SavedPassageCard extends StatelessWidget {
  final SavedPassage passage;
  final int? totalChunks;
  final VoidCallback onDelete;

  const _SavedPassageCard({
    required this.passage,
    required this.totalChunks,
    required this.onDelete,
  });

  String get _percentage {
    if (totalChunks == null || totalChunks == 0) return '';
    return '${((passage.chunkIndex + 1) / totalChunks! * 100).round()}%';
  }

  String get _formattedDate {
    final d = passage.savedAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final book = getBookById(passage.bookId);
    final title = book?.title ?? passage.bookId;
    final author = book?.author ?? '';

    return Dismissible(
      key: ValueKey(passage.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.brand,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.brandPale, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              passage.passageText,
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
    );
  }
}
