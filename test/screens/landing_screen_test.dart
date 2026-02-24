import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/landing_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login'))),
        GoRoute(path: '/signup', builder: (_, __) => const Scaffold(body: Text('signup'))),
      ]),
    );

void main() {
  setUpAll(() { GoogleFonts.config.allowRuntimeFetching = false; });

  group('LandingScreen', () {
    testWidgets('shows Scroll wordmark', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.textContaining('Scroll'), findsWidgets);
    });

    testWidgets('shows Log In and Sign Up buttons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('tapping Sign Up navigates to /signup', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.text('signup'), findsOneWidget);
    });

    testWidgets('tapping Log In navigates to /login', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });
  });
}
