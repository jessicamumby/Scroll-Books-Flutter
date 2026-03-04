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
    testWidgets('shows My Library and Discover tabs', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('My Library'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('shows Your Library header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Your Library'), findsOneWidget);
    });

    testWidgets('My Library tab shows mock books', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Pride and Prejudice'), findsOneWidget);
    });

    testWidgets('My Library tab shows stats bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('BOOKS'), findsOneWidget);
      expect(find.text('FINISHED'), findsOneWidget);
      expect(find.text('READING'), findsOneWidget);
    });

    testWidgets('shows RECENTLY READ label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('RECENTLY READ'), findsOneWidget);
    });
  });
}
