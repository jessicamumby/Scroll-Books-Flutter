import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/app/profile/settings'),
            icon: const Text('⚙️', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(color: AppTheme.tobacco, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
