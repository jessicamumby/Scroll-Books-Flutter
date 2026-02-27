// test/screens/reading_style_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/reading_style_screen.dart';

Widget _wrap({String readingStyle = 'vertical'}) {
  final provider = AppProvider()..readingStyle = readingStyle;
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/reading-style',
        routes: [
          GoRoute(
            path: '/reading-style',
            builder: (_, __) => const ReadingStyleScreen(),
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

  group('ReadingStyleScreen', () {
    testWidgets('shows Scroll Style tile', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Scroll Style'), findsOneWidget);
    });

    testWidgets('shows Stories Style tile', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Stories Style'), findsOneWidget);
    });

    testWidgets('Scroll Style tile has check when readingStyle is vertical', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'vertical'));
      await tester.pump();
      final scrollTile = find.ancestor(
        of: find.text('Scroll Style'),
        matching: find.byType(ListTile),
      );
      final storiesTile = find.ancestor(
        of: find.text('Stories Style'),
        matching: find.byType(ListTile),
      );
      expect(find.descendant(of: scrollTile, matching: find.byIcon(Icons.check)), findsOneWidget);
      expect(find.descendant(of: storiesTile, matching: find.byIcon(Icons.check)), findsNothing);
    });

    testWidgets('Stories Style tile has check when readingStyle is horizontal', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      await tester.pump();
      final scrollTile = find.ancestor(
        of: find.text('Scroll Style'),
        matching: find.byType(ListTile),
      );
      final storiesTile = find.ancestor(
        of: find.text('Stories Style'),
        matching: find.byType(ListTile),
      );
      expect(find.descendant(of: storiesTile, matching: find.byIcon(Icons.check)), findsOneWidget);
      expect(find.descendant(of: scrollTile, matching: find.byIcon(Icons.check)), findsNothing);
    });
  });
}
