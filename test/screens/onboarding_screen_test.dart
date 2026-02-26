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
            builder: (_, __) => OnboardingScreen(
              onComplete: () async {},
              onStyleSelected: (style) async {},
            ),
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

    testWidgets('4th card shows style picker headline', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      expect(find.text('How do you like to read?'), findsOneWidget);
    });

    testWidgets('Start reading is disabled before style selected', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start reading →'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping style tile enables Start reading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swipe down'));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start reading →'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Start reading after selection navigates to library',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swipe down'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start reading →'));
      await tester.pumpAndSettle();
      expect(find.text('library'), findsOneWidget);
    });
  });
}
