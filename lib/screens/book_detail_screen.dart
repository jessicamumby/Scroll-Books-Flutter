import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

Future<void> _showRemoveDialog(
  BuildContext context,
  AppProvider provider,
  Book book,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove from library?'),
      content: Text(
        'This will remove ${book.title} from your library. '
        'Your reading progress will be kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.tomato),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) provider.removeFromLibrary(userId, book.id);
  }
}

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final book = getBookById(bookId);

    if (book == null) {
      return Scaffold(
        backgroundColor: AppTheme.page,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final inLibrary = provider.library.contains(book.id);

        return Scaffold(
          backgroundColor: AppTheme.page,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/covers/${book.id}.jpg',
                        width: 150,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          final gradient = coverGradients[book.id] ??
                              [AppTheme.coverDeep, AppTheme.coverRich];
                          return Container(
                            width: 150,
                            height: 220,
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
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  book.title,
                  style: GoogleFonts.lora(
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
                  child: inLibrary
                      ? OutlinedButton(
                          onPressed: () => _showRemoveDialog(context, provider, book),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.tomato,
                            side: const BorderSide(color: AppTheme.tomato),
                          ),
                          child: const Text('Remove from Library'),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            final userId = supabase.auth.currentUser?.id;
                            if (userId != null) provider.addToLibrary(userId, book.id);
                          },
                          child: const Text('Add to Library'),
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
