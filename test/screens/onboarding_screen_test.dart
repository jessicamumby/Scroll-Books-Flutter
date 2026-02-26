import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Drag to card 2 then card 3 using exact viewport height
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      expect(find.text('Start reading →'), findsOneWidget);
      await tester.tap(find.text('Start reading →'));
      await tester.pumpAndSettle();
      expect(find.text('library'), findsOneWidget);
    });
  });
}
