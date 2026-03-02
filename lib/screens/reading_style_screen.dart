import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class ReadingStyleScreen extends StatelessWidget {
  const ReadingStyleScreen({super.key});

  Future<void> _select(BuildContext context, String style) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await Provider.of<AppProvider>(context, listen: false)
        .setReadingStyle(userId, style);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Reading style')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final current = provider.readingStyle;
          return Column(
            children: [
              ListTile(
                title: Text(
                  'Scroll Style',
                  style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15),
                ),
                subtitle: Text(
                  'Swipe down',
                  style: GoogleFonts.dmSans(color: AppTheme.tobacco),
                ),
                trailing: current == 'vertical'
                    ? const Icon(Icons.check, color: AppTheme.brand)
                    : null,
                onTap: () => _select(context, 'vertical'),
              ),
              ListTile(
                title: Text(
                  'Stories Style',
                  style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15),
                ),
                subtitle: Text(
                  'Tap across',
                  style: GoogleFonts.dmSans(color: AppTheme.tobacco),
                ),
                trailing: current == 'horizontal'
                    ? const Icon(Icons.check, color: AppTheme.brand)
                    : null,
                onTap: () => _select(context, 'horizontal'),
              ),
            ],
          );
        },
      ),
    );
  }
}
