import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/library_screen.dart';

AppProvider _provider({List<String> library = const []}) {
  final p = AppProvider();
  p.library = library;
  p.progress = {};
  p.readDays = [];
  return p;
}

Widget _wrap({List<String> library = const []}) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: _provider(library: library),
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const LibraryScreen()),
          GoRoute(
            path: '/app/library/:id',
            builder: (_, __) => const Scaffold(body: Text('detail')),
          ),
        ]),
      ),
    );

void main() {
  setUpAll(() { GoogleFonts.config.allowRuntimeFetching = false; });

  group('LibraryScreen', () {
    testWidgets('shows all 6 catalogue books', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsWidgets);
      expect(find.text('Pride and Prejudice'), findsWidgets);
      expect(find.text('Jane Eyre'), findsWidgets);
      expect(find.text('Don Quixote'), findsWidgets);
      expect(find.text('The Great Gatsby'), findsWidgets);
      expect(find.text('Frankenstein'), findsWidgets);
    });

    testWidgets('shows In Library badge for saved books', (tester) async {
      await tester.pumpWidget(_wrap(library: ['moby-dick']));
      await tester.pumpAndSettle();
      expect(find.text('In Library'), findsNWidgets(2));
    });

    testWidgets('shows Add to Library for unsaved books', (tester) async {
      await tester.pumpWidget(_wrap(library: []));
      await tester.pumpAndSettle();
      expect(find.text('Add to Library'), findsWidgets);
    });

    testWidgets('tapping a book navigates to book detail', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moby Dick').first);
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets('shows section headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('FREE BOOKS'), findsOneWidget);
      expect(find.text('TRENDING'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('book cards use image assets with color filter', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(ColorFiltered), findsWidgets);
    });
  });
}
