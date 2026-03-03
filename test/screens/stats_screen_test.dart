import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/stats_screen.dart';

Widget _wrap({List<String> readDays = const [], int passagesRead = 0, int longestStreak = 0}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final provider = AppProvider()
    ..library = []
    ..progress = {}
    ..readDays = readDays
    ..passagesRead = passagesRead
    ..longestStreak = longestStreak;
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('StatsScreen', () {
    testWidgets('shows streak count', (tester) async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await tester.pumpWidget(_wrap(readDays: [today]));
      expect(find.textContaining('day streak'), findsOneWidget);
    });

    testWidgets('shows 0 streak when no read days', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('day streak'), findsOneWidget);
    });

    // Task 6 tests
    testWidgets('shows passages read count', (tester) async {
      await tester.pumpWidget(_wrap(passagesRead: 42));
      expect(find.textContaining('42'), findsWidgets);
      expect(find.textContaining('passages'), findsOneWidget);
    });

    testWidgets('shows longest streak label', (tester) async {
      await tester.pumpWidget(_wrap(longestStreak: 30));
      expect(find.textContaining('best'), findsOneWidget);
    });

    testWidgets('shows share streak button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.textContaining('Share'), findsOneWidget);
    });

    // Task 7 tests
    testWidgets('shows milestone overlay when pendingMilestone set', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final provider = AppProvider()
        ..readDays = []
        ..pendingMilestone = 7;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
        ),
      );
      await tester.pump();
      expect(find.textContaining('7 days'), findsOneWidget);
    });

    testWidgets('dismissing milestone clears pendingMilestone', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final provider = AppProvider()
        ..readDays = []
        ..pendingMilestone = 30;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(provider.pendingMilestone, isNull);
    });
  });
}
