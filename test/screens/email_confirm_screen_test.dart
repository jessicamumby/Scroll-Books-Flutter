import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/email_confirm_screen.dart';

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
        ],
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
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
