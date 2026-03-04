import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/milestones_list.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({required int currentStreak}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MilestonesList(currentStreak: currentStreak),
        ),
      ),
    );
  }

  testWidgets('shows MILESTONES header', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('MILESTONES'), findsOneWidget);
  });

  testWidgets('shows all 4 milestone names', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('Week Worm'), findsOneWidget);
    expect(find.text('Page Turner'), findsOneWidget);
    expect(find.text('Bibliophile'), findsOneWidget);
    expect(find.text('Literary Legend'), findsOneWidget);
  });

  testWidgets('shows day counts for each milestone', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('90 days'), findsOneWidget);
    expect(find.text('365 days'), findsOneWidget);
  });

  testWidgets('unlocked milestones have full opacity', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 31));
    // With streak=31: Week Worm (7) and Page Turner (30) are unlocked (opacity 1.0)
    // Bibliophile (90) and Literary Legend (365) are locked (opacity 0.70)
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    // First two should be unlocked (1.0), last two locked (0.70)
    expect(opacities[0].opacity, 1.0);
    expect(opacities[1].opacity, 1.0);
    expect(opacities[2].opacity, 0.70);
    expect(opacities[3].opacity, 0.70);
  });

  testWidgets('all milestones locked when streak is 0', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 0));
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    for (final o in opacities) {
      expect(o.opacity, 0.70);
    }
  });

  testWidgets('all milestones unlocked when streak >= 365', (tester) async {
    await tester.pumpWidget(_wrap(currentStreak: 400));
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    for (final o in opacities) {
      expect(o.opacity, 1.0);
    }
  });
}
