import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class ContinueReadingShelf extends StatefulWidget {
  const ContinueReadingShelf({super.key});

  @override
  State<ContinueReadingShelf> createState() => _ContinueReadingShelfState();
}

class _ContinueReadingShelfState extends State<ContinueReadingShelf> {
  late PageController _pageController;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.55);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final books =
            catalogue
                .where((b) => b.hasChunks && (provider.progress[b.id] ?? 0) > 0)
                .toList();

        if (books.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'CONTINUE READING',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.brand,
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: books.length,
                onPageChanged: (index) => setState(() => _activePage = index),
                itemBuilder: (context, index) {
                  final book = books[index];
                  final chunkIndex = provider.progress[book.id] ?? 0;
                  final totalChunks = provider.bookTotalChunks[book.id] ?? 0;
                  final percent =
                      totalChunks > 0
                          ? ((chunkIndex + 1) / totalChunks).clamp(0.0, 1.0)
                          : 0.0;
                  return _ShelfCard(
                    book: book,
                    isActive: index == _activePage,
                    percent: percent,
                    onTap:
                        () => _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShelfCard extends StatelessWidget {
  final Book book;
  final bool isActive;
  final double percent;
  final VoidCallback onTap;

  const _ShelfCard({
    required this.book,
    required this.isActive,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = isActive ? 180.0 : 140.0;
    final coverHeight = cardWidth * (4 / 3);

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: cardWidth,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 1.0 : 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow:
                        isActive
                            ? [
                              BoxShadow(
                                color: AppTheme.brand.withValues(alpha: 0.22),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                            : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/covers/${book.id}.jpg',
                      width: cardWidth,
                      height: coverHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        final gradient =
                            coverGradients[book.id] ??
                            [AppTheme.coverDeep, AppTheme.coverRich];
                        return Container(
                          width: cardWidth,
                          height: coverHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
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
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                _ProgressBar(percent: percent, width: cardWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  final double width;

  const _ProgressBar({required this.percent, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width * percent,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
