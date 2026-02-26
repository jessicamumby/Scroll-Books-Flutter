import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class ReadingStyleScreen extends StatelessWidget {
  const ReadingStyleScreen({super.key});

  void _select(BuildContext context, String style) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
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
                title: const Text('Scroll Style'),
                subtitle: const Text('Swipe down'),
                trailing: current == 'vertical'
                    ? const Icon(Icons.check, color: AppTheme.amber)
                    : null,
                onTap: () => _select(context, 'vertical'),
              ),
              ListTile(
                title: const Text('Stories Style'),
                subtitle: const Text('Tap across'),
                trailing: current == 'horizontal'
                    ? const Icon(Icons.check, color: AppTheme.amber)
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
