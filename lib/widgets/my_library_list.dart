import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _LibraryBook {
  final String title;
  final String author;
  final Color color;
  final String lastRead;
  final int progress; // 0-100

  const _LibraryBook({
    required this.title,
    required this.author,
    required this.color,
    required this.lastRead,
    required this.progress,
  });
}

const _mockBooks = [
  _LibraryBook(title: 'Moby Dick', author: 'Herman Melville', color: Color(0xFF4A6FA5), lastRead: 'Today', progress: 72),
  _LibraryBook(title: 'Pride and Prejudice', author: 'Jane Austen', color: Color(0xFF9B6B8E), lastRead: 'Yesterday', progress: 45),
  _LibraryBook(title: 'Frankenstein', author: 'Mary Shelley', color: Color(0xFF5A7A5A), lastRead: '3 days ago', progress: 88),
  _LibraryBook(title: 'The Odyssey', author: 'Homer', color: Color(0xFFC4762B), lastRead: '1 week ago', progress: 23),
  _LibraryBook(title: 'Dracula', author: 'Bram Stoker', color: Color(0xFF6B4152), lastRead: '2 weeks ago', progress: 100),
  _LibraryBook(title: '1984', author: 'George Orwell', color: Color(0xFF7A8B99), lastRead: '2 weeks ago', progress: 100),
  _LibraryBook(title: 'Jane Eyre', author: 'Charlotte Brontë', color: Color(0xFFA0785A), lastRead: '1 month ago', progress: 56),
  _LibraryBook(title: 'Don Quixote', author: 'Miguel de Cervantes', color: Color(0xFFB85C3A), lastRead: '1 month ago', progress: 12),
];

class MyLibraryList extends StatelessWidget {
  const MyLibraryList({super.key});

  int get _totalBooks => _mockBooks.length;
  int get _finishedBooks => _mockBooks.where((b) => b.progress == 100).length;
  int get _readingBooks => _mockBooks.where((b) => b.progress > 0 && b.progress < 100).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.warmWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats bar
            Row(
              children: [
                _StatCard(value: _totalBooks, label: 'BOOKS'),
                const SizedBox(width: 10),
                _StatCard(value: _finishedBooks, label: 'FINISHED'),
                const SizedBox(width: 10),
                _StatCard(value: _readingBooks, label: 'READING'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'RECENTLY READ',
              style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
            ),
            const SizedBox(height: 12),
            ...List.generate(_mockBooks.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i < _mockBooks.length - 1 ? 10 : 0),
                child: _BookCard(book: _mockBooks[i]),
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
  final _LibraryBook book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final isComplete = book.progress == 100;
    final progressFraction = book.progress / 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: book.color.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book spine
          Container(
            width: 38,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  book.color,
                  book.color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Spine line
                Positioned(
                  left: 3,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.5,
                    color: AppTheme.warmGold.withValues(alpha: 0.40),
                  ),
                ),
                // Checkmark if complete
                if (isComplete)
                  const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Book info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
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
                  book.author,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11.5,
                    color: AppTheme.inkMid,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar row
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
                                        colors: [AppTheme.tomato, AppTheme.amber],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${book.progress}%',
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
          const SizedBox(width: 10),
          // Last read
          Text(
            book.lastRead,
            style: AppTheme.monoLabel(
              fontSize: 10,
              color: AppTheme.inkLight,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
