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
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(find.text('Frankenstein'), findsOneWidget);
    });

    testWidgets('shows In Library badge for saved books', (tester) async {
      await tester.pumpWidget(_wrap(library: ['moby-dick']));
      await tester.pumpAndSettle();
      expect(find.text('In Library'), findsOneWidget);
    });

    testWidgets('shows Add to Library for unsaved books', (tester) async {
      await tester.pumpWidget(_wrap(library: []));
      await tester.pumpAndSettle();
      expect(find.text('Add to Library'), findsWidgets);
    });
  });
}
