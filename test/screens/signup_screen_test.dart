import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/signup_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
          GoRoute(
            path: '/email-confirm',
            builder: (_, __) => const Scaffold(body: Text('confirm')),
          ),
        ],
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SignUpScreen', () {
    testWidgets('shows Create your account heading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);
    });

    testWidgets('shows four form fields including username', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('shows Create account button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('shows Already have an account link', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Already have an account? Log in'), findsOneWidget);
    });

    testWidgets('shows validation error when form is empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('tapping login link navigates to login', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Already have an account? Log in'));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('username field shows invalid format error', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'AB', // too short + uppercase — invalid
      );
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('lowercase'), findsOneWidget);
    });

    testWidgets('username field shows length error when too short', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'ab', // too short
      );
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3'), findsWidgets);
    });
  });
}
