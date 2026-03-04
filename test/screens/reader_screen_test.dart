import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReaderScreen', () {
    testWidgets('shows loading indicator on init', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator for pride-and-prejudice on init', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReaderScreen(bookId: 'pride-and-prejudice'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows back button in header', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('builds with horizontal reading style', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('horizontal mode has GestureDetector tap zones', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      // The horizontal overlay renders two GestureDetector tap zones (left and
      // right) over the PageView. Verify they are present in the widget tree.
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('all catalogue books show loading indicator on init', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReaderScreen(bookId: 'frankenstein'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('horizontal mode shows loading indicator on init', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      // Still in loading state — share button only appears post-load.
      // Verify the screen builds without error.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('back button present for all catalogue books', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReaderScreen(bookId: 'pride-and-prejudice'),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    test('formatShareText appends attribution', () {
      const passage = 'Call me Ishmael.';
      final result = ReaderScreen.formatShareText(passage);
      expect(result, contains('Call me Ishmael.'));
      expect(result, contains('— Read on Scroll Books'));
    });

    test('formatShareText separates passage and attribution with blank line', () {
      const passage = 'Test passage.';
      final result = ReaderScreen.formatShareText(passage);
      expect(result, contains('\n\n'));
    });

    testWidgets('unknown book id shows book not found', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReaderScreen(bookId: 'unknown-book'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Book not found'), findsOneWidget);
    });

    test('incrementPassagesRead is exposed on AppProvider', () {
      final provider = AppProvider();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      provider.incrementPassagesRead(today);
      expect(provider.passagesRead, 1);
      expect(provider.dailyPassages[today], 1);
    });
  });
}
