import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class _DiscoverBook {
  final String id;
  final String title;
  final String author;
  final Color color;
  final String price;
  final bool isFree;
  final String? tag;

  const _DiscoverBook({
    required this.id,
    required this.title,
    required this.author,
    required this.color,
    required this.price,
    required this.isFree,
    this.tag,
  });
}

const _discoverBooks = [
  _DiscoverBook(id: 'moby-dick', title: 'Moby Dick', author: 'Herman Melville', color: Color(0xFF1A3A5C), price: 'Free', isFree: true, tag: 'Classic'),
  _DiscoverBook(id: 'pride-and-prejudice', title: 'Pride and Prejudice', author: 'Jane Austen', color: Color(0xFF8B5E6E), price: 'Free', isFree: true, tag: 'Popular'),
  _DiscoverBook(id: 'great-gatsby', title: 'The Great Gatsby', author: 'F. Scott Fitzgerald', color: Color(0xFFB8952A), price: 'Free', isFree: true, tag: 'Short'),
  _DiscoverBook(id: 'frankenstein', title: 'Frankenstein', author: 'Mary Shelley', color: Color(0xFF1A3322), price: 'Free', isFree: true, tag: 'Classic'),
  _DiscoverBook(id: 'romeo-and-juliet', title: 'Romeo & Juliet', author: 'William Shakespeare', color: Color(0xFF8B1A2A), price: 'Free', isFree: true, tag: 'Classic'),
  _DiscoverBook(id: 'wuthering-heights', title: 'Wuthering Heights', author: 'Emily Brontë', color: Color(0xFF2D1F3D), price: 'Free', isFree: true, tag: 'Popular'),
];

const _filterTags = ['All', 'Free', 'Classic', 'Popular', 'Short'];

class DiscoverStore extends StatefulWidget {
  const DiscoverStore({super.key});

  @override
  State<DiscoverStore> createState() => _DiscoverStoreState();
}

class _DiscoverStoreState extends State<DiscoverStore> {
  int _selectedFilter = 0;

  List<_DiscoverBook> get _filteredBooks {
    if (_selectedFilter == 0) return _discoverBooks;
    final tag = _filterTags[_selectedFilter];
    if (tag == 'Free') return _discoverBooks.where((b) => b.isFree).toList();
    return _discoverBooks.where((b) => b.tag == tag).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.warmWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured banner
            _FeaturedBanner(),
            const SizedBox(height: 20),

            // Filter tags
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filterTags.length, (i) {
                  final isActive = i == _selectedFilter;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _filterTags.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.ink : AppTheme.cream,
                          borderRadius: BorderRadius.circular(20),
                          border: isActive
                              ? null
                              : Border.all(
                                  color: AppTheme.inkLight.withValues(alpha: 0.15),
                                ),
                        ),
                        child: Text(
                          _filterTags[i],
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isActive ? Colors.white : AppTheme.inkMid,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'AVAILABLE BOOKS',
              style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
            ),
            const SizedBox(height: 12),

            // 2-column grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: _filteredBooks.length,
              itemBuilder: (_, i) => _DiscoverCard(book: _filteredBooks[i]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.ink, Color(0xFF3A2E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Decorative emoji
          Positioned(
            right: -5,
            top: -5,
            child: Transform.rotate(
              angle: -15 * pi / 180,
              child: Opacity(
                opacity: 0.08,
                child: Text('📖', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FEATURED THIS WEEK',
                style: AppTheme.monoLabel(
                  fontSize: 10,
                  color: AppTheme.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wuthering Heights',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.cream,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Emily Brontë · Classic',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12,
                  color: AppTheme.cream.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.tomato,
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.tomato.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Add to Library — Free',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final _DiscoverBook book;
  const _DiscoverCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: book.color.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover area
          SizedBox(
            height: 100,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.asset(
                    'assets/covers/${book.id}.jpg',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
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
                          Positioned(
                            left: 10, top: 0, bottom: 0,
                            child: Container(
                              width: 2,
                              color: AppTheme.warmGold.withValues(alpha: 0.40),
                            ),
                          ),
                          Positioned(
                            left: 14, top: 0, bottom: 0,
                            child: Container(
                              width: 0.5,
                              color: AppTheme.warmGold.withValues(alpha: 0.25),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                book.title.toUpperCase(),
                                style: AppTheme.monoLabel(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (book.tag != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.tag!.toUpperCase(),
                        style: AppTheme.monoLabel(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12.5,
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
                    fontSize: 11,
                    color: AppTheme.inkLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Action button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: book.isFree ? AppTheme.sage : AppTheme.warmWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: book.isFree
                        ? null
                        : Border.all(
                            color: AppTheme.inkLight.withValues(alpha: 0.15),
                          ),
                    boxShadow: book.isFree
                        ? [
                            BoxShadow(
                              color: AppTheme.sage.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      book.isFree ? 'Free — Add' : '${book.price} — Buy',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: book.isFree ? Colors.white : AppTheme.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
