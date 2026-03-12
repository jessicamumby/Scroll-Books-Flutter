import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/models/reader_chunk.dart';
import 'package:scroll_books/widgets/reader/chapter_complete_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const item = ChapterCompleteItem(
    completedChapterNumber: 1,
    completedChapterTitle: 'Loomings',
    passagesInChapter: 102,
    totalChapters: 135,
    sentencesReadSoFar: 102,
    totalSentences: 10000,
  );

  Widget wrap({String readingStyle = 'vertical'}) => MaterialApp(
        home: Scaffold(
          body: ChapterCompleteCard(item: item, readingStyle: readingStyle),
        ),
      );

  group('ChapterCompleteCard', () {
    testWidgets('renders trophy emoji', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('\u{1F3C6}'), findsOneWidget);
    });

    testWidgets('renders "Chapter Complete!" label', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('Chapter Complete!'), findsOneWidget);
    });

    testWidgets('renders chapter title', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('Loomings'), findsOneWidget);
    });

    testWidgets('renders chapter progress label', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('CHAPTER 1 OF 135'), findsOneWidget);
    });

    testWidgets('renders passage count stat', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('102'), findsOneWidget);
      expect(find.text('PASSAGES READ'), findsOneWidget);
    });

    testWidgets('renders book progress stat', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('1%'), findsOneWidget);
      expect(find.text('BOOK PROGRESS'), findsOneWidget);
    });

    testWidgets('shows right arrow for horizontal reading style', (tester) async {
      await tester.pumpWidget(wrap(readingStyle: 'horizontal'));
      await tester.pump();
      expect(find.text('Swipe to continue \u{2192}'), findsOneWidget);
    });

    testWidgets('shows down arrow for vertical reading style', (tester) async {
      await tester.pumpWidget(wrap(readingStyle: 'vertical'));
      await tester.pump();
      expect(find.text('Swipe to continue \u{2193}'), findsOneWidget);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows share button when onShare is provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChapterCompleteCard(
            item: item,
            readingStyle: 'vertical',
            onShare: () => tapped = true,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('SHARE'), findsOneWidget);
      await tester.tap(find.text('SHARE'));
      expect(tapped, isTrue);
    });

    testWidgets('does not show share button when onShare is null', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.text('SHARE'), findsNothing);
    });
  });
}
