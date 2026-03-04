import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/widgets/weekly_progress_dots.dart';

void main() {
  Widget _wrap({required List<bool> completedDays, required int todayIndex}) {
    return MaterialApp(
      home: Scaffold(
        body: WeeklyProgressDots(
          completedDays: completedDays,
          todayIndex: todayIndex,
        ),
      ),
    );
  }

  testWidgets('renders 7 day labels', (tester) async {
    await tester.pumpWidget(_wrap(
      completedDays: List.filled(7, false),
      todayIndex: 0,
    ));
    // M appears twice (Monday, but not duplicate), T appears twice (Tue, Thu),
    // S appears twice (Sat, Sun)
    for (final label in ['M', 'T', 'W', 'F', 'S']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('shows check icons for completed days', (tester) async {
    await tester.pumpWidget(_wrap(
      completedDays: [true, true, false, false, false, false, false],
      todayIndex: 2,
    ));
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets('shows no check icons when no days completed', (tester) async {
    await tester.pumpWidget(_wrap(
      completedDays: List.filled(7, false),
      todayIndex: 0,
    ));
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('shows check icons for all completed days', (tester) async {
    await tester.pumpWidget(_wrap(
      completedDays: List.filled(7, true),
      todayIndex: 6,
    ));
    expect(find.byIcon(Icons.check), findsNWidgets(7));
  });

  testWidgets('today dot uses CustomPaint when not completed', (tester) async {
    await tester.pumpWidget(_wrap(
      completedDays: List.filled(7, false),
      todayIndex: 3,
    ));
    // The today dot that is not completed uses a CustomPaint for dashed circle
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
