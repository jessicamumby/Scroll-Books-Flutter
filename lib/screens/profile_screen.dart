import 'package:flutter/material.dart';
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
            Text(email, style: TextStyle(color: AppTheme.tobacco, fontSize: 15)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.sienna),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
