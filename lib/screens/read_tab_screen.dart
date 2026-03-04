import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../providers/app_provider.dart';

class ReadTabScreen extends StatefulWidget {
  const ReadTabScreen({super.key});

  @override
  State<ReadTabScreen> createState() => _ReadTabScreenState();
}

class _ReadTabScreenState extends State<ReadTabScreen> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigated) return;

    final provider = context.read<AppProvider>();
    // Find the most recently read book (highest progress)
    String? lastBookId;
    int maxProgress = 0;
    for (final entry in provider.progress.entries) {
      if (entry.value > maxProgress) {
        maxProgress = entry.value;
        lastBookId = entry.key;
      }
    }

    if (lastBookId != null) {
      final book = getBookById(lastBookId);
      if (book != null && book.hasChunks) {
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/read/$lastBookId');
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📜', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                Text(
                  'Start Reading',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pick a book from your Library to begin',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    color: AppTheme.inkMid,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/app/library'),
                  child: const Text('Go to Library'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
