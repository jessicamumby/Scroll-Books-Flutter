import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Library')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: catalogue.length,
            itemBuilder: (context, index) {
              final book = catalogue[index];
              final inLibrary = provider.library.contains(book.id);
              return _BookRow(book: book, inLibrary: inLibrary, provider: provider);
            },
          );
        },
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final Book book;
  final bool inLibrary;
  final AppProvider provider;

  const _BookRow({required this.book, required this.inLibrary, required this.provider});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/app/library/${book.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF4A1942)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(book.author, style: TextStyle(color: AppTheme.tobacco, fontSize: 13)),
                ],
              ),
            ),
            if (inLibrary)
              Text('In Library', style: TextStyle(color: AppTheme.forest, fontSize: 12, fontWeight: FontWeight.w500))
            else
              TextButton(
                onPressed: () {
                  final userId = supabase.auth.currentUser?.id;
                  if (userId != null) provider.addToLibrary(userId, book.id);
                },
                child: const Text('Add to Library'),
              ),
          ],
        ),
      ),
    );
  }
}
