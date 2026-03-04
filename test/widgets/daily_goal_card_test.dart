import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/daily_goal_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  int? changedGoal;

  Widget _wrap({int goal = 10, int passagesReadToday = 0}) {
    changedGoal = null;
    return MaterialApp(
      home: Scaffold(
        body: DailyGoalCard(
          goal: goal,
          passagesReadToday: passagesReadToday,
          onGoalChanged: (v) => changedGoal = v,
        ),
      ),
    );
  }

  testWidgets('shows Today\'s Goal title', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text("Today's Goal"), findsOneWidget);
  });

  testWidgets('shows passages progress text', (tester) async {
    await tester.pumpWidget(_wrap(goal: 10, passagesReadToday: 3));
    expect(find.text('3 of 10 passages'), findsOneWidget);
  });

  testWidgets('shows percentage complete', (tester) async {
    await tester.pumpWidget(_wrap(goal: 10, passagesReadToday: 5));
    expect(find.text('50% complete'), findsOneWidget);
  });

  testWidgets('shows 100% when passagesReadToday >= goal', (tester) async {
    await tester.pumpWidget(_wrap(goal: 5, passagesReadToday: 7));
    expect(find.text('100% complete'), findsOneWidget);
  });

  testWidgets('shows 0% when no passages read', (tester) async {
    await tester.pumpWidget(_wrap(goal: 10, passagesReadToday: 0));
    expect(find.text('0% complete'), findsOneWidget);
  });

  testWidgets('Edit Goal button toggles goal picker', (tester) async {
    await tester.pumpWidget(_wrap(goal: 10));
    await tester.pumpAndSettle();

    // Goal picker is hidden initially
    expect(find.text('PASSAGES PER DAY'), findsNothing);

    // Tap Edit Goal
    await tester.tap(find.text('Edit Goal'));
    await tester.pumpAndSettle();

    // Goal picker is now visible
    expect(find.text('PASSAGES PER DAY'), findsOneWidget);
    // Shows goal options
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('tapping goal option calls onGoalChanged', (tester) async {
    await tester.pumpWidget(_wrap(goal: 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    expect(changedGoal, 20);
  });

  testWidgets('tapping goal option closes picker', (tester) async {
    await tester.pumpWidget(_wrap(goal: 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Goal'));
    await tester.pumpAndSettle();
    expect(find.text('PASSAGES PER DAY'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('PASSAGES PER DAY'), findsNothing);
  });
}
