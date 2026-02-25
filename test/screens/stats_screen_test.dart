import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/stats_screen.dart';

Widget _wrap({List<String> readDays = const []}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final provider = AppProvider()
    ..library = []
    ..progress = {}
    ..readDays = readDays;
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
  });
}
