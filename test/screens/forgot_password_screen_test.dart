import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/forgot_password_screen.dart';

class _NoOpAsyncStorage extends GotrueAsyncStorage {
  const _NoOpAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/change-password',
            builder: (_, __) => const Scaffold(body: Text('change-password')),
          ),
        ],
      ),
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _NoOpAsyncStorage(),
      ),
    );
  });

  group('ForgotPasswordScreen', () {
    testWidgets('shows email field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    });

    testWidgets('shows Send Reset Email button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Send Reset Email'), findsOneWidget);
    });
  });
}
