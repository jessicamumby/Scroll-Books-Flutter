// test/screens/reader_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/reader_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReaderScreen', () {
    testWidgets('shows loading indicator on init', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ReaderScreen(bookId: 'moby-dick'),
        ),
      );
      // Before async fetch completes, loading indicator shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows coming soon for book without chunks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ReaderScreen(bookId: 'pride-and-prejudice'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows back button in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ReaderScreen(bookId: 'moby-dick'),
        ),
      );
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });
  });
}
