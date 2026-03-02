import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/change_password_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/change-password',
        routes: [
          GoRoute(
            path: '/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
          ),
        ],
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ChangePasswordScreen', () {
    testWidgets('shows New password field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'New password'), findsOneWidget);
    });

    testWidgets('shows Confirm password field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Confirm password'), findsOneWidget);
    });

    testWidgets('shows Update Password button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('shows Required errors when submitted empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows mismatch error when passwords differ', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'New password'), 'password123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'), 'different');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
