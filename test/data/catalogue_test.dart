import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/data/catalogue.dart';

void main() {
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
  });
}
