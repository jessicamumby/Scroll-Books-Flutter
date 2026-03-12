import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/models/reader_chunk.dart';
import 'package:scroll_books/widgets/reader/chapter_list_drawer.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final chapters = [
    const ChapterInfo(chapterNumber: 1, title: 'Chapter 1. Loomings', startIndex: 1, sentenceCount: 50),
    const ChapterInfo(chapterNumber: 2, title: 'Chapter 2. The Carpet-Bag', startIndex: 52, sentenceCount: 30),
    const ChapterInfo(chapterNumber: 3, title: 'Chapter 3. The Spouter-Inn', startIndex: 83, sentenceCount: 40),
  ];

  Widget wrap({
    required int currentChapter,
    required int currentRawIndex,
    void Function(int chapterNumber)? onChapterSelected,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showChapterListDrawer(
              context: context,
              chapters: chapters,
              currentChapterNumber: currentChapter,
              currentRawIndex: currentRawIndex,
              onChapterSelected: onChapterSelected ?? (_) {},
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('ChapterListDrawer', () {
    testWidgets('renders all chapter titles', (tester) async {
      await tester.pumpWidget(wrap(currentChapter: 1, currentRawIndex: 5));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('CHAPTERS'), findsOneWidget);
      expect(find.textContaining('Loomings'), findsOneWidget);
      expect(find.textContaining('The Carpet-Bag'), findsOneWidget);
      expect(find.textContaining('The Spouter-Inn'), findsOneWidget);
    });

    testWidgets('shows "Reading" for current chapter', (tester) async {
      await tester.pumpWidget(wrap(currentChapter: 2, currentRawIndex: 55));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Reading'), findsOneWidget);
    });

    testWidgets('shows checkmark for completed chapters', (tester) async {
      await tester.pumpWidget(wrap(currentChapter: 2, currentRawIndex: 55));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('\u{2713}'), findsOneWidget);
    });

    testWidgets('current chapter row has tomatoLight background', (tester) async {
      await tester.pumpWidget(wrap(currentChapter: 1, currentRawIndex: 5));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final highlighted = containers.where((c) =>
        c.decoration is BoxDecoration &&
        (c.decoration as BoxDecoration).color == AppTheme.tomatoLight
      ).toList();
      expect(highlighted, isNotEmpty, reason: 'Current chapter row should have tomatoLight background');
    });

    testWidgets('shows footer text when more than 8 chapters', (tester) async {
      final manyChapters = List.generate(10, (i) => ChapterInfo(
        chapterNumber: i + 1,
        title: 'Chapter ${i + 1}. Title $i',
        startIndex: i * 10 + 1,
        sentenceCount: 8,
      ));
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showChapterListDrawer(
                context: context,
                chapters: manyChapters,
                currentChapterNumber: 1,
                currentRawIndex: 5,
                onChapterSelected: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Scroll for more chapters'), findsOneWidget);
    });

    testWidgets('does not show footer text when 8 or fewer chapters', (tester) async {
      await tester.pumpWidget(wrap(currentChapter: 1, currentRawIndex: 5));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Scroll for more chapters'), findsNothing);
    });

    testWidgets('renders 3-digit chapter number and title without overlap', (tester) async {
      final highNumberChapters = [
        const ChapterInfo(chapterNumber: 100, title: 'Chapter 100. The Grand Armada', startIndex: 1, sentenceCount: 50),
        const ChapterInfo(chapterNumber: 101, title: 'Chapter 101. Knights and Squires', startIndex: 52, sentenceCount: 30),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showChapterListDrawer(
                context: context,
                chapters: highNumberChapters,
                currentChapterNumber: 100,
                currentRawIndex: 3,
                onChapterSelected: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
      expect(find.text('101'), findsOneWidget);
      expect(find.textContaining('The Grand Armada'), findsOneWidget);
      expect(find.textContaining('Knights and Squires'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a chapter row calls onChapterSelected', (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(wrap(
        currentChapter: 1,
        currentRawIndex: 5,
        onChapterSelected: (ch) => selectedChapter = ch,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('The Carpet-Bag'));
      await tester.pumpAndSettle();
      expect(selectedChapter, 2);
    });
  });
}
