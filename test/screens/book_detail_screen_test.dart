import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/book_detail_screen.dart';

Widget _wrap(String bookId) {
  final provider = AppProvider()..library = []..progress = {}..readDays = [];
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => BookDetailScreen(bookId: bookId)),
        GoRoute(path: '/read/:bookId', builder: (_, __) => const Scaffold(body: Text('reader'))),
      ]),
    ),
  );
}

void main() {
  setUpAll(() { GoogleFonts.config.allowRuntimeFetching = false; });

  group('BookDetailScreen', () {
    testWidgets('shows book title and author', (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Herman Melville'), findsOneWidget);
    });

    testWidgets('shows Start Reading button', (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      expect(find.text('Start Reading'), findsOneWidget);
    });

    testWidgets('Start Reading navigates to /read/:bookId', (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Reading'));
      await tester.pumpAndSettle();
      expect(find.text('reader'), findsOneWidget);
    });

    testWidgets('shows not found for unknown book', (tester) async {
      await tester.pumpWidget(_wrap('unknown-book'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not found'), findsOneWidget);
    });

    testWidgets('shows cover image as 150x220 portrait thumbnail', (tester) async {
      await tester.pumpWidget(_wrap('moby-dick'));
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(
        images.any((img) => img.width == 150 && img.height == 220),
        isTrue,
        reason: 'Expected a 150×220 Image widget for the book cover thumbnail',
      );
    });
  });
}
