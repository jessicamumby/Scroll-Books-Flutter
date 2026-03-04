import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/streak_counter.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap() => const MaterialApp(
        home: Scaffold(body: Center(child: StreakCounter(streakCount: 7))),
      );

  testWidgets('displays the streak count', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('uses a 150x150 circle container', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.any((c) =>
          c.constraints?.maxWidth == 150 && c.constraints?.maxHeight == 150),
      isTrue,
      reason: 'Expected a 150x150 Container for the streak circle',
    );
  });

  testWidgets('fire emoji is wrapped in FadeTransition and ScaleTransition', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ScaleTransition), findsWidgets);
  });

  testWidgets('renders without overflow', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
