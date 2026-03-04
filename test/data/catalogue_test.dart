import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/data/catalogue.dart';

void main() {
  test('every book has a coverGradient entry with 2 colours', () {
    for (final book in catalogue) {
      expect(
        coverGradients.containsKey(book.id),
        isTrue,
        reason: 'Missing gradient for ${book.id}',
      );
      expect(coverGradients[book.id]!.length, equals(2));
    }
  });

  group('catalogue', () {
    test('has 6 books', () {
      expect(catalogue.length, 6);
    });

    test('getBookById returns Moby Dick', () {
      final book = getBookById('moby-dick');
      expect(book, isNotNull);
      expect(book!.title, 'Moby Dick');
      expect(book.author, 'Herman Melville');
      expect(book.hasChunks, isTrue);
    });

    test('getBookById returns null for unknown id', () {
      expect(getBookById('unknown'), isNull);
    });

    test('only moby-dick has chunks', () {
      final withChunks = catalogue.where((b) => b.hasChunks).toList();
      expect(withChunks.length, 1);
      expect(withChunks.first.id, 'moby-dick');
    });

    test('every book has a non-empty genres list', () {
      for (final book in catalogue) {
        expect(
          book.genres,
          isNotEmpty,
          reason: '${book.id} has no genres',
        );
      }
    });

    test('moby-dick genres are Adventure and Gothic', () {
      final book = getBookById('moby-dick')!;
      expect(book.genres, containsAll(['Adventure', 'Gothic']));
    });
  });
}
