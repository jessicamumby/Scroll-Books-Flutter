import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/longevity_badges_list.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({required int currentStreak}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LongevityBadgesList(currentStreak: currentStreak),
        ),
      ),
    );
  }

  testWidgets('shows LONGEVITY BADGES header', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('LONGEVITY BADGES'), findsOneWidget);
  });

  testWidgets('shows all 4 badge names', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('Week Worm'), findsOneWidget);
    expect(find.text('Page Turner'), findsOneWidget);
    expect(find.text('Bibliophile'), findsOneWidget);
    expect(find.text('Literary Legend'), findsOneWidget);
  });

  testWidgets('shows streak requirement text', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('7 day reading streak'), findsOneWidget);
    expect(find.text('30 day reading streak'), findsOneWidget);
    expect(find.text('90 day reading streak'), findsOneWidget);
    expect(find.text('365 day reading streak'), findsOneWidget);
  });

  testWidgets('unlocked badges show EARNED label', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 31));
    // Week Worm (7) and Page Turner (30) are unlocked
    expect(find.text('✓ EARNED'), findsNWidgets(2));
  });

  testWidgets('locked badges do not show EARNED label', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('✓ EARNED'), findsNothing);
  });

  testWidgets('locked badges have 0.55 opacity', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    for (final o in opacities) {
      expect(o.opacity, 0.55);
    }
  });

  testWidgets('unlocked badges have full opacity', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 400));
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    for (final o in opacities) {
      expect(o.opacity, 1.0);
    }
  });
}
