// test/screens/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/settings_screen.dart';

Widget _wrap() {
  return ChangeNotifierProvider<AppProvider>.value(
    value: AppProvider(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/app/profile/reading-style',
            builder: (_, __) => const Scaffold(body: Text('reading-style')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const Scaffold(body: Text('onboarding')),
          ),
          GoRoute(
            path: '/change-password',
            builder: (_, __) => const Scaffold(body: Text('change-password')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SettingsScreen', () {
    testWidgets('shows sign out button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('shows How Scroll Books works tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('How Scroll Books works'), findsOneWidget);
    });

    testWidgets('shows Reading style tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Reading style'), findsOneWidget);
    });

    testWidgets('shows Reset onboarding tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Reset onboarding'), findsOneWidget);
    });

    testWidgets('shows Change password tile', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Change password'), findsOneWidget);
    });

    testWidgets('tapping Change password navigates to /change-password',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();
      expect(find.text('change-password'), findsOneWidget);
    });
  });
}
