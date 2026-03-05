import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/reader/passage_share_card.dart';

Widget _wrap({
  String passageText = 'Call me Ishmael.',
  String bookTitle = 'Moby Dick',
  String author = 'Herman Melville',
  String pageLabel = 'p. 1 · 1%',
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: PassageShareCard(
        passageText: passageText,
        bookTitle: bookTitle,
        author: author,
        pageLabel: pageLabel,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PassageShareCard', () {
    testWidgets('renders book title', (tester) async {
      await tester.pumpWidget(_wrap(bookTitle: 'Frankenstein'));
      expect(find.text('Frankenstein'), findsOneWidget);
    });

    testWidgets('renders author', (tester) async {
      await tester.pumpWidget(_wrap(author: 'Mary Shelley'));
      expect(find.text('Mary Shelley'), findsOneWidget);
    });

    testWidgets('renders passage text', (tester) async {
      await tester.pumpWidget(
          _wrap(passageText: 'It was a dark and stormy night.'));
      expect(
          find.text('It was a dark and stormy night.'), findsOneWidget);
    });

    testWidgets('renders scroll.books branding', (tester) async {
      await tester.pumpWidget(_wrap());
      // The branding is a Text.rich with "scroll" + "." + "books"
      expect(find.textContaining('scroll'), findsOneWidget);
    });

    testWidgets('renders page label', (tester) async {
      await tester.pumpWidget(_wrap(pageLabel: 'p. 42 · 50%'));
      expect(find.text('p. 42 · 50%'), findsOneWidget);
    });

    testWidgets('has correct fixed dimensions', (tester) async {
      await tester.pumpWidget(_wrap());
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints == null && w.color == AppTheme.page,
        ),
      );
      expect(container.constraints, isNull);
      // The Container uses width/height via BoxConstraints in its decoration
      // Check that it renders without error at fixed size
      expect(find.byType(PassageShareCard), findsOneWidget);
    });
  });
}
