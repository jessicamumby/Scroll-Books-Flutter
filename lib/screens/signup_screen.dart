import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../services/user_data_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // Username availability state: null=unchecked, 'checking', 'available', 'taken', 'invalid'
  String? _usernameStatus;
  String _lastCheckedUsername = '';

  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String value) async {
    final trimmed = value.trim().toLowerCase();
    if (trimmed == _lastCheckedUsername) return;
    _lastCheckedUsername = trimmed;

    if (!_usernameRegex.hasMatch(trimmed)) {
      setState(() => _usernameStatus = 'invalid');
      return;
    }
    setState(() => _usernameStatus = 'checking');

    final available = await UserDataService.isUsernameAvailable(trimmed);
    if (!mounted || _lastCheckedUsername != trimmed) return;
    setState(() => _usernameStatus = available ? 'available' : 'taken');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameStatus != 'available') {
      setState(() => _error = 'Please choose a valid available username.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final response = await supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'display_name': _name.text.trim()},
        emailRedirectTo: 'scrollbooks://auth-callback',
      );
      final userId = response.user?.id;
      if (userId != null) {
        await UserDataService.saveUsername(userId, _username.text.trim().toLowerCase());
      }
      if (mounted) {
        context.go('/email-confirm?email=${Uri.encodeComponent(_email.text.trim())}');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateUsername(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final trimmed = v.trim().toLowerCase();
    if (!_usernameRegex.hasMatch(trimmed)) {
      return 'Use lowercase letters, numbers and underscores (3–20 chars)';
    }
    return null;
  }

  Widget _usernameStatusIcon() {
    switch (_usernameStatus) {
      case 'checking':
        return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case 'available':
        return Icon(Icons.check_circle_outline, color: AppTheme.sage, size: 20);
      case 'taken':
        return Icon(Icons.cancel_outlined, color: AppTheme.sienna, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              Text(
                'Scroll Books',
                style: GoogleFonts.lora(
                  fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account',
                style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.tobacco),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'First name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _username,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g. jessreads',
                        prefixText: '@',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _usernameStatusIcon(),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (v) {
                        if (v.trim().length >= 3) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted) _checkUsernameAvailability(v);
                          });
                        } else {
                          setState(() => _usernameStatus = null);
                        }
                      },
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: AppTheme.sienna, fontSize: 14)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Already have an account? Log in',
                    style: TextStyle(color: AppTheme.brand)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
