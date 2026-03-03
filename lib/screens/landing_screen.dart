import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _passages = [
    '"Call me Ishmael."',
    '"It is not down in any map;\ntrue places never are."',
    '"I am tormented with an everlasting itch\nfor things remote."',
  ];

  int _passageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _passageIndex = (_passageIndex + 1) % _passages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
                const SizedBox(height: 8),
                Text(
                  'The great books. One page at a time.',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: AppTheme.tobacco,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _PassagePreview(
                    key: ValueKey(_passageIndex),
                    text: _passages[_passageIndex],
                  ),
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 16),
                Text(
                  'Join 1,200+ readers',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.pewter,
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

class _PassagePreview extends StatelessWidget {
  final String text;
  const _PassagePreview({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.lora(
          fontSize: 16,
          height: 1.7,
          color: AppTheme.ink,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
