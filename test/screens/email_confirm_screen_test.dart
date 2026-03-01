import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/email_confirm_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoOpAsyncStorage extends GotrueAsyncStorage {
  const _NoOpAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

Widget _wrap({String email = 'test@example.com'}) => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/email-confirm',
        routes: [
          GoRoute(
            path: '/email-confirm',
            builder: (_, __) => EmailConfirmScreen(email: email),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
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

  group('EmailConfirmScreen', () {
    testWidgets('shows Check your inbox heading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Check your inbox.'), findsOneWidget);
    });

    testWidgets('shows the email address', (tester) async {
      await tester.pumpWidget(_wrap(email: 'jane@example.com'));
      await tester.pumpAndSettle();
      expect(find.textContaining('jane@example.com'), findsOneWidget);
    });

    testWidgets('shows Resend email button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Resend email'), findsOneWidget);
    });

    testWidgets('shows Already confirmed link', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Already confirmed? Log in'), findsOneWidget);
    });

    testWidgets('tapping Already confirmed navigates to login', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Already confirmed? Log in'));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });
  });
}
