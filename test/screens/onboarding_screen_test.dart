import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/onboarding_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) =>
                OnboardingScreen(onComplete: () async {}),
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

  group('OnboardingScreen', () {
    testWidgets('shows first card headline', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Read in chunks.'), findsOneWidget);
    });

    testWidgets('shows first card body text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Skip doomscrolling, read great books one passage at a time. '
          'No pressure to finish, just read.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Start reading navigates to library', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Swipe up twice to reach the last card
      await tester.fling(
          find.byType(PageView), const Offset(0, -500), 2000);
      await tester.pumpAndSettle();
      await tester.fling(
          find.byType(PageView), const Offset(0, -500), 2000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start reading →'));
      await tester.pumpAndSettle();
      expect(find.text('library'), findsOneWidget);
    });
  });
}
