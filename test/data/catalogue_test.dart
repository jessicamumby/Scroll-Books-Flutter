import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/data/catalogue.dart';

void main() {
  group('catalogue', () {
    test('contains exactly 6 production books', () {
      expect(catalogue.length, 6);
    });

    test('does not contain removed books', () {
      final ids = catalogue.map((b) => b.id).toSet();
      expect(ids.contains('jane-eyre'), isFalse);
      expect(ids.contains('don-quixote'), isFalse);
    });

    test('contains all production books', () {
      final ids = catalogue.map((b) => b.id).toSet();
      expect(ids, containsAll([
        'moby-dick',
        'frankenstein',
        'great-gatsby',
        'pride-and-prejudice',
        'romeo-and-juliet',
        'wuthering-heights',
      ]));
    });

    test('all books have hasChunks: true', () {
      for (final book in catalogue) {
        expect(book.hasChunks, isTrue,
            reason: '${book.id} should have hasChunks: true');
      }
    });

    test('coverGradients has entry for every book', () {
      for (final book in catalogue) {
        expect(coverGradients.containsKey(book.id), isTrue,
            reason: '${book.id} missing from coverGradients');
        expect(coverGradients[book.id]!.length, equals(2),
            reason: '${book.id} gradient must have exactly 2 colours');
      }
    });

    test('getBookById returns correct book by id', () {
      final book = getBookById('moby-dick');
      expect(book, isNotNull);
      expect(book!.title, 'Moby Dick');
      expect(book.author, 'Herman Melville');
    });

    test('getBookById returns null for unknown id', () {
      expect(getBookById('unknown'), isNull);
    });

    test('every book has a non-empty genres list', () {
      for (final book in catalogue) {
        expect(book.genres, isNotEmpty, reason: '${book.id} has no genres');
      }
    });
  });
}
