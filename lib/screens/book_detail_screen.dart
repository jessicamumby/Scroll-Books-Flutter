import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final book = getBookById(bookId);

    if (book == null) {
      return Scaffold(
        backgroundColor: AppTheme.page,
        appBar: AppBar(),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final inLibrary = provider.library.contains(book.id);

        return Scaffold(
          backgroundColor: AppTheme.page,
          appBar: AppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF4A1942)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  book.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: TextStyle(color: AppTheme.tobacco, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.year}',
                  style: TextStyle(color: AppTheme.tobacco, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  book.blurb,
                  style: TextStyle(color: AppTheme.tobacco, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/read/${book.id}'),
                    child: const Text('Start Reading'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: inLibrary
                        ? null
                        : () {
                            final userId = supabase.auth.currentUser?.id;
                            if (userId != null) provider.addToLibrary(userId, book.id);
                          },
                    child: Text(inLibrary ? 'In Library' : 'Add to Library'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
