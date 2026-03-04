import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/genre_badges_grid.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap(Map<String, int> genreCounts) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GenreBadgesGrid(genreCounts: genreCounts),
          ),
        ),
      );

  testWidgets('all badges locked when genreCounts is empty', (tester) async {
    await tester.pumpWidget(_wrap({}));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsNWidgets(6));
  });

  testWidgets('Adventure badge shows as unlocked with 1 book', (tester) async {
    await tester.pumpWidget(_wrap({'Adventure': 1}));
    await tester.pumpAndSettle();
    expect(find.text('1 book read'), findsOneWidget);
    expect(find.text('Locked'), findsNWidgets(5));
  });

  testWidgets('Gothic shows 3 books read when count is 3', (tester) async {
    await tester.pumpWidget(_wrap({'Gothic': 3}));
    await tester.pumpAndSettle();
    expect(find.text('3 books read'), findsOneWidget);
  });
}
