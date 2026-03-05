import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../core/onboarding_state.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppTheme.borderSoft),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'How Scroll Books works',
                style: GoogleFonts.nunito(
                  color: AppTheme.ink,
                  fontSize: 15,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
              onTap: () => context.push('/onboarding'),
            ),
            const Divider(color: AppTheme.borderSoft),
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Reading style',
                    style: GoogleFonts.nunito(
                      color: AppTheme.ink,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.readingStyle == 'horizontal'
                            ? 'Stories Style'
                            : 'Scroll Style',
                        style: TextStyle(color: AppTheme.pewter),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.pewter),
                    ],
                  ),
                  onTap: () => context.push('/app/profile/reading-style'),
                );
              },
            ),
            const Divider(color: AppTheme.borderSoft),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Change password',
                style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15),
              ),
              trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
              onTap: () => context.push('/change-password'),
            ),
            const Divider(color: AppTheme.borderSoft),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Reset onboarding',
                style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15),
              ),
              trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
              onTap: () async {
                await resetOnboarding();
              },
            ),
            const Divider(color: AppTheme.borderSoft),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sienna),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
