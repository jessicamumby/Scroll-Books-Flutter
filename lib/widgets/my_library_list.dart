import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class MyLibraryList extends StatelessWidget {
  const MyLibraryList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final libraryIds = provider.library;

    if (libraryIds.isEmpty) {
      return Container(
        color: AppTheme.warmWhite,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Your library is empty — discover a book to get started.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                color: AppTheme.inkMid,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final books = libraryIds.map(getBookById).whereType<Book>().toList();

    int finished = 0;
    int reading = 0;
    for (final book in books) {
      final p = provider.progress[book.id] ?? 0;
      final t = provider.bookTotalChunks[book.id] ?? 0;
      if (t > 0 && p >= t - 1) {
        finished++;
      } else if (p > 0) {
        reading++;
      }
    }

    return Container(
      color: AppTheme.warmWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatCard(value: books.length, label: 'BOOKS'),
                const SizedBox(width: 10),
                _StatCard(value: finished, label: 'FINISHED'),
                const SizedBox(width: 10),
                _StatCard(value: reading, label: 'READING'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'MY BOOKS',
              style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
            ),
            const SizedBox(height: 12),
            ...books.asMap().entries.map((entry) {
              final i = entry.key;
              final book = entry.value;
              final p = provider.progress[book.id] ?? 0;
              final t = provider.bookTotalChunks[book.id] ?? 0;
              final pct = t > 0 ? (p / t * 100).clamp(0.0, 100.0).round() : 0;
              final color = (coverGradients[book.id] ??
                      [AppTheme.coverDeep, AppTheme.coverRich])
                  .first;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i < books.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => context.push('/app/library/${book.id}'),
                  child: _BookCard(
                    bookId: book.id,
                    title: book.title,
                    author: book.author,
                    color: color,
                    progressPct: pct,
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String bookId;
  final String title;
  final String author;
  final Color color;
  final int progressPct;
  const _BookCard({
    required this.bookId,
    required this.title,
    required this.author,
    required this.color,
    required this.progressPct,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = progressPct == 100;
    final progressFraction = progressPct / 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/covers/$bookId.jpg',
              width: 38,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 38,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: isComplete
                    ? const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 18),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  author,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11.5,
                    color: AppTheme.inkMid,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.parchment,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progressFraction,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: isComplete
                                    ? const LinearGradient(
                                        colors: [AppTheme.sage, AppTheme.sage],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          AppTheme.tomato,
                                          AppTheme.amber,
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progressPct%',
                      style: AppTheme.monoLabel(
                        fontSize: 10,
                        color: AppTheme.inkLight,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
