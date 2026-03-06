import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/profile_share_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({
    String username = 'jessreads',
    int streakCount = 7,
    int badgesEarned = 3,
    int passagesSaved = 12,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: ProfileShareCard(
            username: username,
            streakCount: streakCount,
            badgesEarned: badgesEarned,
            passagesSaved: passagesSaved,
          ),
        ),
      );

  group('ProfileShareCard', () {
    testWidgets('shows @username', (tester) async {
      await tester.pumpWidget(_wrap(username: 'jessreads'));
      expect(find.text('@jessreads'), findsOneWidget);
    });

    testWidgets('shows streak count', (tester) async {
      await tester.pumpWidget(_wrap(streakCount: 14));
      expect(find.textContaining('14'), findsWidgets);
    });

    testWidgets('shows badges count', (tester) async {
      await tester.pumpWidget(_wrap(badgesEarned: 5));
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
