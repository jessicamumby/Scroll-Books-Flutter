import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _currentEmail() {
    try {
      return supabase.auth.currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentEmail();

    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(color: AppTheme.tobacco, fontSize: 15),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppTheme.borderSoft),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'How Scroll Books works',
                style: GoogleFonts.dmSans(
                  color: AppTheme.ink,
                  fontSize: 15,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
              onTap: () => context.push('/onboarding'),
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
