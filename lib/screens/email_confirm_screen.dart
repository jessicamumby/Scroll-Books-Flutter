import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';

class EmailConfirmScreen extends StatefulWidget {
  final String email;
  const EmailConfirmScreen({super.key, required this.email});

  @override
  State<EmailConfirmScreen> createState() => _EmailConfirmScreenState();
}

class _EmailConfirmScreenState extends State<EmailConfirmScreen> {
  bool _resent = false;
  bool _loading = false;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null && mounted) {
        context.go('/app/library');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (mounted) setState(() { _resent = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                Icon(Icons.mail_outline, size: 72, color: AppTheme.amber),
                const SizedBox(height: 32),
                Text(
                  'Check your inbox.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: AppTheme.tobacco,
                    ),
                    children: [
                      const TextSpan(
                        text: 'We sent a confirmation link to\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_resent)
                  Text(
                    'Sent!',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppTheme.forest,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _loading ? null : _resend,
                    child: Text(
                      'Resend email',
                      style: TextStyle(color: AppTheme.amber),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Already confirmed? Log in',
                    style: TextStyle(color: AppTheme.amber),
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
