import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppProvider.genreCounts', () {
    test('returns empty map when no progress', () {
      final provider = AppProvider();
      expect(provider.genreCounts, isEmpty);
    });

    test('counts genres for books with progress > 0', () {
      final provider = AppProvider();
      provider.progress = {'moby-dick': 1}; // genres: Adventure, Gothic
      expect(provider.genreCounts['Adventure'], 1);
      expect(provider.genreCounts['Gothic'], 1);
      expect(provider.genreCounts.containsKey('Romance'), isFalse);
    });

    test('does not count books with progress == 0', () {
      final provider = AppProvider();
      provider.progress = {'moby-dick': 0};
      expect(provider.genreCounts, isEmpty);
    });

    test('counts multiple books in same genre', () {
      final provider = AppProvider();
      // pride-and-prejudice: Romance; jane-eyre: Gothic, Romance
      provider.progress = {
        'pride-and-prejudice': 3,
        'jane-eyre': 1,
      };
      expect(provider.genreCounts['Romance'], 2);
      expect(provider.genreCounts['Gothic'], 1);
    });
  });

  group('AppProvider.bookTotalChunks', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts empty', () {
      final provider = AppProvider();
      expect(provider.bookTotalChunks, isEmpty);
    });

    test('setBookTotalChunks updates the map', () {
      final provider = AppProvider();
      provider.setBookTotalChunks('moby-dick', 4710);
      expect(provider.bookTotalChunks['moby-dick'], 4710);
    });

    test('setBookTotalChunks overwrites an existing entry', () {
      final provider = AppProvider();
      provider.setBookTotalChunks('moby-dick', 100);
      provider.setBookTotalChunks('moby-dick', 4710);
      expect(provider.bookTotalChunks['moby-dick'], 4710);
    });
  });
}
