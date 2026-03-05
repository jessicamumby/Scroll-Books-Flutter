import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/models/saved_passage.dart';
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
      // pride-and-prejudice: Romance; romeo-and-juliet: Romance, Tragedy
      provider.progress = {
        'pride-and-prejudice': 3,
        'romeo-and-juliet': 1,
      };
      expect(provider.genreCounts['Romance'], 2);
      expect(provider.genreCounts['Tragedy'], 1);
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

  // Note: the SharedPreferences load path (_loadLocalStats) is not tested here
  // because _loadLocalStats is private and load() requires Supabase.
  // Integration coverage of the load path is provided by the ReadTabScreen widget tests.
  group('AppProvider.lastReadBookId', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('is null initially', () {
      final provider = AppProvider();
      expect(provider.lastReadBookId, isNull);
    });

    test('setLastReadBook sets the field', () {
      final provider = AppProvider();
      provider.setLastReadBook('moby-dick');
      expect(provider.lastReadBookId, 'moby-dick');
    });

    test('setLastReadBook overwrites previous value', () {
      final provider = AppProvider();
      provider.setLastReadBook('moby-dick');
      provider.setLastReadBook('frankenstein');
      expect(provider.lastReadBookId, 'frankenstein');
    });
  });

  group('AppProvider.removeFromLibrary', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('removes book from library list', () async {
      final provider = AppProvider();
      provider.library = ['moby-dick', 'frankenstein'];
      await provider.removeFromLibrary('', 'moby-dick');
      expect(provider.library, ['frankenstein']);
      expect(provider.library.contains('moby-dick'), isFalse);
    });

    test('is a no-op if book not in library', () async {
      final provider = AppProvider();
      provider.library = ['moby-dick'];
      await provider.removeFromLibrary('', 'frankenstein');
      expect(provider.library, ['moby-dick']);
    });
  });

  group('AppProvider.setDailyGoal', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('updates dailyGoal field', () async {
      final provider = AppProvider();
      await provider.setDailyGoal(20);
      expect(provider.dailyGoal, 20);
    });

    test('persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await provider.setDailyGoal(15);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('daily_goal'), 15);
    });
  });

  group('AppProvider.useBookmarkToken edge cases', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('is a no-op when tokens are 0', () async {
      final provider = AppProvider();
      provider.bookmarkTokens = 0;
      await provider.useBookmarkToken();
      expect(provider.bookmarkTokens, 0);
      expect(provider.frozenDays, isEmpty);
    });

    test('adds today to frozenDays', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      await provider.useBookmarkToken();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(provider.frozenDays, contains(today));
    });

    test('decrements tokens from 1 to 0 without changing resetAt', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      // Simulate state after first use
      provider.bookmarkTokens = 1;
      provider.bookmarkResetAt = '2099-12-31';
      await provider.useBookmarkToken();
      expect(provider.bookmarkTokens, 0);
      expect(provider.bookmarkResetAt, '2099-12-31'); // unchanged
    });
  });

  group('AppProvider.incrementPassagesRead', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('accumulates across multiple calls', () {
      final provider = AppProvider();
      provider.incrementPassagesRead('2026-03-04');
      provider.incrementPassagesRead('2026-03-04');
      provider.incrementPassagesRead('2026-03-04');
      expect(provider.passagesRead, 3);
      expect(provider.dailyPassages['2026-03-04'], 3);
    });

    test('tracks separate days independently', () {
      final provider = AppProvider();
      provider.incrementPassagesRead('2026-03-03');
      provider.incrementPassagesRead('2026-03-03');
      provider.incrementPassagesRead('2026-03-04');
      expect(provider.passagesRead, 3);
      expect(provider.dailyPassages['2026-03-03'], 2);
      expect(provider.dailyPassages['2026-03-04'], 1);
    });
  });

  group('AppProvider.genreCounts edge cases', () {
    test('ignores unknown book IDs not in catalogue', () {
      final provider = AppProvider();
      provider.progress = {'nonexistent-book-id': 5};
      expect(provider.genreCounts, isEmpty);
    });

    test('counts multiple genres from single book', () {
      final provider = AppProvider();
      // moby-dick has genres: Adventure, Gothic
      provider.progress = {'moby-dick': 1};
      expect(provider.genreCounts.length, 2);
    });
  });

  group('AppProvider.setLastReadBook edge cases', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('is a no-op when setting same book ID', () {
      final provider = AppProvider();
      provider.lastReadBookId = 'moby-dick';
      provider.setLastReadBook('moby-dick');
      expect(provider.lastReadBookId, 'moby-dick');
    });

    test('updates when setting different book ID', () {
      final provider = AppProvider();
      provider.setLastReadBook('moby-dick');
      provider.setLastReadBook('frankenstein');
      expect(provider.lastReadBookId, 'frankenstein');
    });
  });

  group('AppProvider.clearMilestone', () {
    test('clears pendingMilestone', () {
      final provider = AppProvider();
      provider.pendingMilestone = 30;
      provider.clearMilestone();
      expect(provider.pendingMilestone, isNull);
    });
  });

  group('AppProvider.savedPassages', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts as empty list', () {
      final provider = AppProvider();
      expect(provider.savedPassages, isEmpty);
    });

    test('isPassageSaved returns false when no passages saved', () {
      final provider = AppProvider();
      expect(provider.isPassageSaved('moby-dick', 0), isFalse);
    });

    test('isPassageSaved returns true for matching bookId and chunkIndex', () {
      final provider = AppProvider();
      provider.savedPassages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 5,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.now(),
        ),
      ];
      expect(provider.isPassageSaved('moby-dick', 5), isTrue);
    });

    test('isPassageSaved returns false for different chunkIndex', () {
      final provider = AppProvider();
      provider.savedPassages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 5,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.now(),
        ),
      ];
      expect(provider.isPassageSaved('moby-dick', 10), isFalse);
    });

    test('isPassageSaved returns false for different bookId', () {
      final provider = AppProvider();
      provider.savedPassages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 5,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.now(),
        ),
      ];
      expect(provider.isPassageSaved('frankenstein', 5), isFalse);
    });

    test('savePassage adds to local list', () async {
      final provider = AppProvider();
      await provider.savePassage('', 'moby-dick', 3, 'Test passage');
      expect(provider.savedPassages.length, 1);
      expect(provider.savedPassages.first.bookId, 'moby-dick');
      expect(provider.savedPassages.first.chunkIndex, 3);
      expect(provider.savedPassages.first.passageText, 'Test passage');
    });

    test('savePassage does not create duplicate', () async {
      final provider = AppProvider();
      await provider.savePassage('', 'moby-dick', 3, 'Test passage');
      await provider.savePassage('', 'moby-dick', 3, 'Test passage');
      expect(provider.savedPassages.length, 1);
    });

    test('savePassage allows different chunks from same book', () async {
      final provider = AppProvider();
      await provider.savePassage('', 'moby-dick', 3, 'Passage A');
      await provider.savePassage('', 'moby-dick', 7, 'Passage B');
      expect(provider.savedPassages.length, 2);
    });

    test('deleteSavedPassage removes by id', () async {
      final provider = AppProvider();
      provider.savedPassages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 5,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.now(),
        ),
        SavedPassage(
          id: 'p2',
          bookId: 'frankenstein',
          chunkIndex: 0,
          passageText: 'Beware.',
          savedAt: DateTime.now(),
        ),
      ];
      await provider.deleteSavedPassage('', 'p1');
      expect(provider.savedPassages.length, 1);
      expect(provider.savedPassages.first.id, 'p2');
    });

    test('deleteSavedPassage handles non-existent id gracefully', () async {
      final provider = AppProvider();
      provider.savedPassages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 5,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.now(),
        ),
      ];
      await provider.deleteSavedPassage('', 'non-existent');
      expect(provider.savedPassages.length, 1);
    });

    test('savePassage prepends to list (newest first)', () async {
      final provider = AppProvider();
      await provider.savePassage('', 'moby-dick', 1, 'First');
      await provider.savePassage('', 'moby-dick', 2, 'Second');
      expect(provider.savedPassages.first.passageText, 'Second');
      expect(provider.savedPassages.last.passageText, 'First');
    });
  });
}
