import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class ReadTabScreen extends StatefulWidget {
  const ReadTabScreen({super.key});

  @override
  State<ReadTabScreen> createState() => _ReadTabScreenState();
}

class _ReadTabScreenState extends State<ReadTabScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lastBookId = provider.lastReadBookId;

    if (!_navigated && lastBookId != null) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/read/$lastBookId');
      });
    }

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
