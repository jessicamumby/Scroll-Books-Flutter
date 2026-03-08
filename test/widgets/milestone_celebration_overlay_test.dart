import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/milestone_celebration_overlay.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({required int milestone, VoidCallback? onDismiss, String? username}) =>
      MaterialApp(
        home: Scaffold(
          body: MilestoneCelebrationOverlay(
            milestone: milestone,
            onDismiss: onDismiss ?? () {},
            username: username,
          ),
        ),
      );

  group('MilestoneCelebrationOverlay', () {
    testWidgets('shows milestone day count', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 7));
      await tester.pump();
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets('shows milestone name for 7 days', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 7));
      await tester.pump();
      expect(find.text('Week Worm'), findsOneWidget);
    });

    testWidgets('shows milestone name for 30 days', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 30));
      await tester.pump();
      expect(find.text('Page Turner'), findsOneWidget);
    });

    testWidgets('tapping calls onDismiss', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(_wrap(
        milestone: 7,
        onDismiss: () => dismissed = true,
      ));
      await tester.pump();
      await tester.tap(find.byType(MilestoneCelebrationOverlay));
      expect(dismissed, isTrue);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 90));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows share button when username is provided', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 7, username: 'jessreads'));
      await tester.pump();
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('no share button when username is null', (tester) async {
      await tester.pumpWidget(_wrap(milestone: 7));
      await tester.pump();
      expect(find.byIcon(Icons.share), findsNothing);
    });
  });
}
