import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/onboarding_screen.dart';

Widget _wrapWithCallback({Future<void> Function(String)? onStyleSelected}) =>
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => OnboardingScreen(
              onComplete: () async {},
              onStyleSelected: onStyleSelected ?? (style) async {},
            ),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
          ),
        ],
      ),
    );

Widget _wrap() => _wrapWithCallback();

Future<void> _scrollToStyleCard(WidgetTester tester) async {
  final pageView = find.byType(PageView);
  final size = tester.getSize(pageView);
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
}

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
      await _scrollToStyleCard(tester);
      expect(find.text('How do you like to read?'), findsOneWidget);
    });

    testWidgets('Start reading is disabled before style selected', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _scrollToStyleCard(tester);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start reading →'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping style tile enables Start reading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _scrollToStyleCard(tester);
      await tester.tap(find.text('Swipe down'));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start reading →'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Start reading passes correct style and navigates to library',
        (tester) async {
      String? capturedStyle;
      await tester.pumpWidget(_wrapWithCallback(
        onStyleSelected: (style) async { capturedStyle = style; },
      ));
      await tester.pumpAndSettle();
      await _scrollToStyleCard(tester);
      await tester.tap(find.text('Swipe down'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start reading →'));
      await tester.pumpAndSettle();
      expect(capturedStyle, 'vertical');
      expect(find.text('library'), findsOneWidget);
    });

    testWidgets('tapping Tap across passes horizontal style', (tester) async {
      String? capturedStyle;
      await tester.pumpWidget(_wrapWithCallback(onStyleSelected: (s) async => capturedStyle = s));
      await tester.pumpAndSettle();
      await _scrollToStyleCard(tester);
      await tester.tap(find.text('Tap across'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start reading →'));
      await tester.pumpAndSettle();
      expect(capturedStyle, 'horizontal');
    });
  });
}
