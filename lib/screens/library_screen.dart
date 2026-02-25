import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
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
              return _BookRow(book: book, inLibrary: inLibrary);
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

  const _BookRow({required this.book, required this.inLibrary});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/app/library/${book.id}'),
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
                  colors: [AppTheme.coverDeep, AppTheme.coverRich],
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
                  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  Provider.of<AppProvider>(context, listen: false).addToLibrary(userId, book.id);
                },
                child: const Text('Add to Library'),
              ),
          ],
        ),
      ),
    );
  }
}
