import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/reader_screen.dart';

Widget _wrap({String readingStyle = 'vertical'}) {
  final provider = AppProvider()..readingStyle = readingStyle;
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light,
      home: ReaderScreen(bookId: 'moby-dick'),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReaderScreen', () {
    testWidgets('shows loading indicator on init', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows coming soon for book without chunks', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReaderScreen(bookId: 'pride-and-prejudice'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows back button in header', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('builds with horizontal reading style', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
