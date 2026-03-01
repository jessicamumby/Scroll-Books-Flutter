import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/login_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const Scaffold(body: Text('forgot'))),
        GoRoute(path: '/signup', builder: (_, __) => const Scaffold(body: Text('signup'))),
      ]),
    );

void main() {
  setUpAll(() { GoogleFonts.config.allowRuntimeFetching = false; });

  group('LoginScreen', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('shows Log In button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('shows forgot password link', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('Forgot'), findsOneWidget);
    });

    testWidgets('tapping Forgot navigates to /forgot-password', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.textContaining('Forgot'));
      await tester.pumpAndSettle();
      expect(find.text('forgot'), findsOneWidget);
    });

    testWidgets('shows sign up link', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('Sign up'), findsOneWidget);
    });

    testWidgets('tapping sign up navigates to /signup', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.textContaining('Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('signup'), findsOneWidget);
    });
  });
}
