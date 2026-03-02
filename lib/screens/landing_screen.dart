import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.lora(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                    children: [
                      const TextSpan(text: 'Scroll'),
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: AppTheme.brand),
                      ),
                      const TextSpan(text: 'Books'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The classic library, one chunk at a time.',
                  style: TextStyle(fontSize: 16, color: AppTheme.tobacco),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      color: AppTheme.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
