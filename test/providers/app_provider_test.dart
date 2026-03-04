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

  group('AppProvider.bookmarkResetAt', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('bookmarkResetAt is null initially', () {
      final provider = AppProvider();
      expect(provider.bookmarkResetAt, isNull);
    });

    test('useBookmarkToken sets bookmarkResetAt 7 days from today on first use', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await provider.useBookmarkToken();
      final expected = DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10);
      expect(provider.bookmarkResetAt, expected);
      expect(provider.bookmarkTokens, 1);
    });

    test('useBookmarkToken on second use does not change bookmarkResetAt', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await provider.useBookmarkToken(); // first use — sets resetAt
      final resetAt = provider.bookmarkResetAt;
      await provider.useBookmarkToken(); // second use
      expect(provider.bookmarkResetAt, resetAt); // unchanged
      expect(provider.bookmarkTokens, 0);
    });

    test('resetBookmarksIfExpired resets tokens when date has passed', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      final pastDate = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      provider.bookmarkTokens = 0;
      provider.bookmarkResetAt = pastDate;
      await provider.resetBookmarksIfExpired();
      expect(provider.bookmarkTokens, 2);
      expect(provider.bookmarkResetAt, isNull);
    });

    test('resetBookmarksIfExpired does nothing when date is in the future', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      final futureDate = DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String()
          .substring(0, 10);
      provider.bookmarkTokens = 0;
      provider.bookmarkResetAt = futureDate;
      await provider.resetBookmarksIfExpired();
      expect(provider.bookmarkTokens, 0);
      expect(provider.bookmarkResetAt, futureDate);
    });
  });
}
