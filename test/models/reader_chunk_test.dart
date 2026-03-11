import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/models/reader_chunk.dart';

void main() {
  group('ReaderChunk', () {
    test('stores text, type, and chapter', () {
      const chunk = ReaderChunk(text: 'Call me Ishmael.', type: 'sentence', chapter: 1);
      expect(chunk.text, 'Call me Ishmael.');
      expect(chunk.type, 'sentence');
      expect(chunk.chapter, 1);
    });

    test('isChapterHeader returns true for chapter_header type', () {
      const chunk = ReaderChunk(text: 'Chapter 1. Loomings', type: 'chapter_header', chapter: 1);
      expect(chunk.isChapterHeader, isTrue);
      expect(chunk.isSentence, isFalse);
    });

    test('isSentence returns true for sentence type', () {
      const chunk = ReaderChunk(text: 'Call me Ishmael.', type: 'sentence', chapter: 1);
      expect(chunk.isSentence, isTrue);
      expect(chunk.isChapterHeader, isFalse);
    });
  });

  group('stripChapterPrefix', () {
    test('strips "Chapter N. " prefix', () {
      expect(stripChapterPrefix('Chapter 1. Loomings'), 'Loomings');
    });

    test('strips multi-digit chapter numbers', () {
      expect(stripChapterPrefix('Chapter 135. Epilogue'), 'Epilogue');
    });

    test('returns full text when no ". " separator exists', () {
      expect(stripChapterPrefix('Prologue'), 'Prologue');
    });

    test('handles ". " in chapter title by only stripping first occurrence', () {
      expect(stripChapterPrefix('Chapter 5. The Dr. visits'), 'The Dr. visits');
    });
  });

  group('ChapterInfo', () {
    test('stores chapter metadata', () {
      const info = ChapterInfo(
        chapterNumber: 1,
        title: 'Chapter 1. Loomings',
        startIndex: 1,
        sentenceCount: 3,
      );
      expect(info.chapterNumber, 1);
      expect(info.title, 'Chapter 1. Loomings');
      expect(info.startIndex, 1);
      expect(info.sentenceCount, 3);
    });
  });

  group('buildChapterInfoList', () {
    test('builds chapters from chunks with headers', () {
      final chunks = [
        const ReaderChunk(text: 'Chapter 1. Loomings', type: 'chapter_header', chapter: 1),
        const ReaderChunk(text: 'Call me Ishmael.', type: 'sentence', chapter: 1),
        const ReaderChunk(text: 'Some years ago.', type: 'sentence', chapter: 1),
        const ReaderChunk(text: 'Chapter 2. The Carpet-Bag', type: 'chapter_header', chapter: 2),
        const ReaderChunk(text: 'I stuffed a shirt.', type: 'sentence', chapter: 2),
      ];
      final chapters = buildChapterInfoList(chunks);
      expect(chapters.length, 2);
      expect(chapters[0].chapterNumber, 1);
      expect(chapters[0].title, 'Chapter 1. Loomings');
      expect(chapters[0].startIndex, 1);
      expect(chapters[0].sentenceCount, 2);
      expect(chapters[1].chapterNumber, 2);
      expect(chapters[1].startIndex, 4);
      expect(chapters[1].sentenceCount, 1);
    });

    test('returns empty list for legacy chunks (no chapter_header)', () {
      final chunks = [
        const ReaderChunk(text: 'Call me Ishmael.', type: 'sentence', chapter: 0),
        const ReaderChunk(text: 'Some years ago.', type: 'sentence', chapter: 0),
      ];
      final chapters = buildChapterInfoList(chunks);
      expect(chapters, isEmpty);
    });

    test('handles chapter with no sentences', () {
      final chunks = [
        const ReaderChunk(text: 'Chapter 1. Empty', type: 'chapter_header', chapter: 1),
        const ReaderChunk(text: 'Chapter 2. Has Content', type: 'chapter_header', chapter: 2),
        const ReaderChunk(text: 'Content here.', type: 'sentence', chapter: 2),
      ];
      final chapters = buildChapterInfoList(chunks);
      expect(chapters.length, 2);
      expect(chapters[0].sentenceCount, 0);
      expect(chapters[1].sentenceCount, 1);
    });
  });

  group('DisplayItem types', () {
    test('SentenceItem stores text, rawIndex, chapter info', () {
      const item = SentenceItem(
        text: 'Call me Ishmael.',
        rawIndex: 1,
        chapterNumber: 1,
        chapterTitle: 'Loomings',
        sentenceOrdinal: 1,
      );
      expect(item.text, 'Call me Ishmael.');
      expect(item.rawIndex, 1);
      expect(item.isChapterOpener, isTrue);
      expect(item.chapterTitle, 'Loomings');
      expect(item.sentenceOrdinal, 1);
    });

    test('SentenceItem without chapterTitle is not a chapter opener', () {
      const item = SentenceItem(
        text: 'Some years ago.',
        rawIndex: 2,
        chapterNumber: 1,
        sentenceOrdinal: 2,
      );
      expect(item.isChapterOpener, isFalse);
    });

    test('ChapterCompleteItem computes book progress percent', () {
      const item = ChapterCompleteItem(
        completedChapterNumber: 1,
        completedChapterTitle: 'Loomings',
        passagesInChapter: 100,
        totalChapters: 10,
        sentencesReadSoFar: 100,
        totalSentences: 1000,
      );
      expect(item.bookProgressPercent, 10);
    });

    test('ChapterCompleteItem returns 0% when totalSentences is 0', () {
      const item = ChapterCompleteItem(
        completedChapterNumber: 1,
        completedChapterTitle: 'Empty',
        passagesInChapter: 0,
        totalChapters: 1,
        sentencesReadSoFar: 0,
        totalSentences: 0,
      );
      expect(item.bookProgressPercent, 0);
    });
  });

  group('buildDisplayList', () {
    final chunks = [
      const ReaderChunk(text: 'Chapter 1. Loomings', type: 'chapter_header', chapter: 1),
      const ReaderChunk(text: 'Call me Ishmael.', type: 'sentence', chapter: 1),
      const ReaderChunk(text: 'Some years ago.', type: 'sentence', chapter: 1),
      const ReaderChunk(text: 'Chapter 2. The Carpet-Bag', type: 'chapter_header', chapter: 2),
      const ReaderChunk(text: 'I stuffed a shirt.', type: 'sentence', chapter: 2),
      const ReaderChunk(text: 'It was cold.', type: 'sentence', chapter: 2),
      const ReaderChunk(text: 'Chapter 3. The Spouter-Inn', type: 'chapter_header', chapter: 3),
      const ReaderChunk(text: 'Entering the inn.', type: 'sentence', chapter: 3),
    ];

    test('excludes chapter_header entries from display list', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final headerTexts = display
          .whereType<SentenceItem>()
          .where((s) => s.text.startsWith('Chapter '))
          .toList();
      expect(headerTexts, isEmpty);
    });

    test('first sentence of each chapter is a chapter opener', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final openers = display.whereType<SentenceItem>().where((s) => s.isChapterOpener).toList();
      expect(openers.length, 3);
      expect(openers[0].chapterTitle, 'Loomings');
      expect(openers[1].chapterTitle, 'The Carpet-Bag');
      expect(openers[2].chapterTitle, 'The Spouter-Inn');
    });

    test('inserts completion card after each chapter except the last', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final completions = display.whereType<ChapterCompleteItem>().toList();
      expect(completions.length, 2);
      expect(completions[0].completedChapterNumber, 1);
      expect(completions[0].completedChapterTitle, 'Loomings');
      expect(completions[0].passagesInChapter, 2);
      expect(completions[1].completedChapterNumber, 2);
      expect(completions[1].completedChapterTitle, 'The Carpet-Bag');
      expect(completions[1].passagesInChapter, 2);
    });

    test('sentence ordinals are sequential across chapters', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final sentences = display.whereType<SentenceItem>().toList();
      expect(sentences.map((s) => s.sentenceOrdinal).toList(), [1, 2, 3, 4, 5]);
    });

    test('rawIndex maps back to position in original chunk list', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final sentences = display.whereType<SentenceItem>().toList();
      expect(sentences[0].rawIndex, 1);
      expect(sentences[1].rawIndex, 2);
      expect(sentences[2].rawIndex, 4);
    });

    test('returns flat sentence list for legacy chunks (no chapters)', () {
      final legacyChunks = [
        const ReaderChunk(text: 'First.', type: 'sentence', chapter: 0),
        const ReaderChunk(text: 'Second.', type: 'sentence', chapter: 0),
      ];
      final chapters = buildChapterInfoList(legacyChunks);
      final display = buildDisplayList(legacyChunks, chapters);
      expect(display.length, 2);
      expect(display.every((d) => d is SentenceItem), isTrue);
      final sentences = display.cast<SentenceItem>();
      expect(sentences.first.isChapterOpener, isFalse);
      expect(sentences.first.rawIndex, 0);
    });

    test('completion card has correct cumulative stats', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final completions = display.whereType<ChapterCompleteItem>().toList();
      expect(completions[0].sentencesReadSoFar, 2);
      expect(completions[0].totalSentences, 5);
      expect(completions[0].totalChapters, 3);
      expect(completions[1].sentencesReadSoFar, 4);
      expect(completions[1].totalSentences, 5);
    });

    test('display list order is: ch1 sentences, completion, ch2 sentences, completion, ch3 sentences', () {
      final chapters = buildChapterInfoList(chunks);
      final display = buildDisplayList(chunks, chapters);
      final types = display.map((d) => d is SentenceItem ? 'S' : 'C').toList();
      expect(types, ['S', 'S', 'C', 'S', 'S', 'C', 'S']);
    });
  });
}
