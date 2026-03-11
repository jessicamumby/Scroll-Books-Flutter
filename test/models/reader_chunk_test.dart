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
}
