import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';
import '../widgets/continue_reading_shelf.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _sections = ['Free Books', 'Trending', 'New'];
  static const _labels = {
    'Free Books': 'FREE BOOKS',
    'Trending': 'TRENDING',
    'New': 'NEW',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Library')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ContinueReadingShelf(),
                for (final section in _sections) ...[
                  _SectionHeader(label: _labels[section]!),
                  for (final book in catalogue.where((b) => b.sections.contains(section)))
                    _BookCard(book: book, inLibrary: provider.library.contains(book.id)),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppTheme.brand,
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final bool inLibrary;
  const _BookCard({required this.book, required this.inLibrary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.push('/app/library/${book.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/covers/${book.id}.jpg',
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        final gradient = coverGradients[book.id] ??
                            [AppTheme.coverDeep, AppTheme.coverRich];
                        return Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: GoogleFonts.lora(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${book.author} · ${book.year}',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppTheme.tobacco,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              book.blurb,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.pewter,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: inLibrary
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.forestPale,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'In Library',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        color: AppTheme.forest,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () {
                                      final userId = Supabase.instance.client
                                              .auth.currentUser?.id ??
                                          '';
                                      Provider.of<AppProvider>(context,
                                              listen: false)
                                          .addToLibrary(userId, book.id);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Add to Library',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: AppTheme.brand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
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
