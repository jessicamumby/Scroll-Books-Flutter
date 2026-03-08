import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/streak_badge_share_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({
    String username = 'jessreads',
    String badgeName = 'Page Turner',
    String badgeEmoji = '📖',
    int streakDays = 30,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: StreakBadgeShareCard(
            username: username,
            badgeName: badgeName,
            badgeEmoji: badgeEmoji,
            streakDays: streakDays,
          ),
        ),
      );

  group('StreakBadgeShareCard', () {
    testWidgets('renders badge emoji', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('📖'), findsOneWidget);
    });

    testWidgets('renders badge name', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Page Turner'), findsOneWidget);
    });

    testWidgets('renders streak days text', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('30 day reading streak'), findsOneWidget);
    });

    testWidgets('renders username and brand', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('@jessreads · SCROLL BOOKS'), findsOneWidget);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
