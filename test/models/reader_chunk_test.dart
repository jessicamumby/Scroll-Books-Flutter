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
}
