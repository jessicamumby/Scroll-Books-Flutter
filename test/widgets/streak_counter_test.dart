import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/streak_counter.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({int streak = 0, bool isAtRisk = false}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StreakCounter(streakCount: streak, isAtRisk: isAtRisk),
          ),
        ),
      );

  group('StreakCounter', () {
    testWidgets('shows wood emoji when streak is 0', (tester) async {
      await tester.pumpWidget(_wrap(streak: 0));
      await tester.pump();
      expect(find.text('🪵'), findsOneWidget);
    });

    testWidgets('shows fire emoji when streak >= 1', (tester) async {
      await tester.pumpWidget(_wrap(streak: 1));
      await tester.pump();
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('displays the streak count', (tester) async {
      await tester.pumpWidget(_wrap(streak: 7));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('fire emoji is larger for streak 7 than streak 1', (tester) async {
      await tester.pumpWidget(_wrap(streak: 1));
      await tester.pump();
      final small = tester.widget<Text>(find.text('🔥')).style!.fontSize!;

      await tester.pumpWidget(_wrap(streak: 7));
      await tester.pump();
      final medium = tester.widget<Text>(find.text('🔥')).style!.fontSize!;

      expect(medium, greaterThan(small));
    });

    testWidgets('isAtRisk wraps content in Opacity < 1', (tester) async {
      await tester.pumpWidget(_wrap(streak: 3, isAtRisk: true));
      await tester.pump();
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.any((o) => o.opacity < 1.0), isTrue);
    });

    testWidgets('isAtRisk false does not add dim Opacity', (tester) async {
      await tester.pumpWidget(_wrap(streak: 3, isAtRisk: false));
      await tester.pump();
      // No Opacity widget wrapping the content with opacity < 1
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.any((o) => o.opacity == 0.6), isFalse);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(_wrap(streak: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping emoji does not throw', (tester) async {
      await tester.pumpWidget(_wrap(streak: 5));
      await tester.pump();
      await tester.tap(find.text('🔥'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('updating streakCount disposes old controller without error', (tester) async {
      await tester.pumpWidget(_wrap(streak: 3));
      await tester.pump();
      await tester.pumpWidget(_wrap(streak: 7));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('7'), findsOneWidget);
    });
  });
}
