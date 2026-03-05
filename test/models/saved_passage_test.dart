import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/models/saved_passage.dart';

void main() {
  group('SavedPassage.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'book_id': 'moby-dick',
        'chunk_index': 42,
        'passage_text': 'Call me Ishmael.',
        'saved_at': '2026-03-05T12:00:00.000Z',
      };
      final passage = SavedPassage.fromJson(json);
      expect(passage.id, 'abc-123');
      expect(passage.bookId, 'moby-dick');
      expect(passage.chunkIndex, 42);
      expect(passage.passageText, 'Call me Ishmael.');
      expect(passage.savedAt, DateTime.utc(2026, 3, 5, 12));
    });

    test('handles ISO date string with timezone offset', () {
      final json = {
        'id': 'def-456',
        'book_id': 'frankenstein',
        'chunk_index': 0,
        'passage_text': 'Test passage.',
        'saved_at': '2026-01-15T08:30:00.000+00:00',
      };
      final passage = SavedPassage.fromJson(json);
      expect(passage.savedAt.year, 2026);
      expect(passage.savedAt.month, 1);
      expect(passage.savedAt.day, 15);
    });
  });

  group('SavedPassage.toJson', () {
    test('includes only book_id, chunk_index, passage_text', () {
      final passage = SavedPassage(
        id: 'abc-123',
        bookId: 'moby-dick',
        chunkIndex: 42,
        passageText: 'Call me Ishmael.',
        savedAt: DateTime.utc(2026, 3, 5),
      );
      final json = passage.toJson();
      expect(json.keys, containsAll(['book_id', 'chunk_index', 'passage_text']));
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('saved_at'), isFalse);
    });

    test('values match source passage', () {
      final passage = SavedPassage(
        id: 'abc-123',
        bookId: 'pride-and-prejudice',
        chunkIndex: 10,
        passageText: 'It is a truth universally acknowledged.',
        savedAt: DateTime.utc(2026, 3, 5),
      );
      final json = passage.toJson();
      expect(json['book_id'], 'pride-and-prejudice');
      expect(json['chunk_index'], 10);
      expect(json['passage_text'], 'It is a truth universally acknowledged.');
    });
  });

  group('SavedPassage round-trip', () {
    test('fromJson preserves toJson data', () {
      final original = SavedPassage(
        id: 'test-id',
        bookId: 'frankenstein',
        chunkIndex: 7,
        passageText: 'Beware; for I am fearless.',
        savedAt: DateTime.utc(2026, 2, 14),
      );
      final json = original.toJson();
      // Add server-set fields for fromJson
      json['id'] = 'server-id';
      json['saved_at'] = '2026-02-14T00:00:00.000Z';
      final restored = SavedPassage.fromJson(json);
      expect(restored.bookId, original.bookId);
      expect(restored.chunkIndex, original.chunkIndex);
      expect(restored.passageText, original.passageText);
    });
  });
}
