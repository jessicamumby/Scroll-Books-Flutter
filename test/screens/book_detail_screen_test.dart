import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/book_detail_screen.dart';

Widget _wrap(String bookId, {bool inLibrary = false}) {
  final provider = AppProvider();
  if (inLibrary) provider.library = [bookId];
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light,
      home: BookDetailScreen(bookId: bookId),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BookDetailScreen', () {
    testWidgets('shows "Add to Library" when book is not in library',
        (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      expect(find.text('Add to Library'), findsOneWidget);
      expect(find.text('Remove from Library'), findsNothing);
    });

    testWidgets('shows "Remove from Library" when book is in library',
        (tester) async {
      await tester.pumpWidget(_wrap('moby-dick', inLibrary: true));
      await tester.pumpAndSettle();
      expect(find.text('Remove from Library'), findsOneWidget);
      expect(find.text('Add to Library'), findsNothing);
    });

    testWidgets('tapping "Remove from Library" shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(_wrap('moby-dick', inLibrary: true));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Remove from Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Library'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from library?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('tapping Cancel closes dialog without removing book',
        (tester) async {
      final provider = AppProvider();
      provider.library = ['moby-dick'];
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const BookDetailScreen(bookId: 'moby-dick'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Remove from Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from library?'), findsNothing);
      expect(provider.library, contains('moby-dick'));
    });

    testWidgets('shows arrow_back_ios back button', (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });
  });
}
