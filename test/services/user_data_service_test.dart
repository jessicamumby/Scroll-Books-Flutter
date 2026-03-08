import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/models/saved_passage.dart';
import 'package:scroll_books/services/user_data_service.dart';

void main() {
  group('UserData', () {
    test('holds library, progress, readDays fields', () {
      final data = UserData(
        library: ['moby-dick'],
        progress: {'moby-dick': 42},
        readDays: ['2026-02-25'],
      );
      expect(data.library, ['moby-dick']);
      expect(data.progress['moby-dick'], 42);
      expect(data.readDays, ['2026-02-25']);
    });

    test('readingStyle is null when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.readingStyle, isNull);
    });

    test('readingStyle can be set to horizontal', () {
      final data = UserData(
        library: [], progress: {}, readDays: [], readingStyle: 'horizontal',
      );
      expect(data.readingStyle, 'horizontal');
    });

    test('bookmarkTokens defaults to 2 when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.bookmarkTokens, 2);
    });

    test('bookmarkResetAt is null when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.bookmarkResetAt, isNull);
    });

    test('frozenDays defaults to empty list when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.frozenDays, isEmpty);
    });

    test('bookmark fields are stored when provided', () {
      final data = UserData(
        library: [], progress: {}, readDays: [],
        bookmarkTokens: 1,
        bookmarkResetAt: '2026-03-11',
        frozenDays: ['2026-03-04'],
      );
      expect(data.bookmarkTokens, 1);
      expect(data.bookmarkResetAt, '2026-03-11');
      expect(data.frozenDays, ['2026-03-04']);
    });

    test('multiple books in library', () {
      final data = UserData(
        library: ['moby-dick', 'frankenstein', 'jane-eyre'],
        progress: {'moby-dick': 10, 'frankenstein': 5},
        readDays: ['2026-03-01', '2026-03-02'],
      );
      expect(data.library.length, 3);
      expect(data.progress.length, 2);
      expect(data.readDays.length, 2);
    });

    test('empty library and progress', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.library, isEmpty);
      expect(data.progress, isEmpty);
      expect(data.readDays, isEmpty);
    });

    test('readingStyle can be set to vertical', () {
      final data = UserData(
        library: [], progress: {}, readDays: [], readingStyle: 'vertical',
      );
      expect(data.readingStyle, 'vertical');
    });

    test('all fields set simultaneously', () {
      final data = UserData(
        library: ['moby-dick'],
        progress: {'moby-dick': 100},
        readDays: ['2026-03-04'],
        readingStyle: 'horizontal',
        bookmarkTokens: 0,
        bookmarkResetAt: '2026-03-11',
        frozenDays: ['2026-03-03', '2026-03-04'],
      );
      expect(data.library, ['moby-dick']);
      expect(data.progress['moby-dick'], 100);
      expect(data.readDays, ['2026-03-04']);
      expect(data.readingStyle, 'horizontal');
      expect(data.bookmarkTokens, 0);
      expect(data.bookmarkResetAt, '2026-03-11');
      expect(data.frozenDays.length, 2);
    });
  });

  group('UserData model contract', () {
    // NOTE: Testing static UserDataService methods (fetchAll, addToLibrary, etc.)
    // requires a live or mocked Supabase client. The `supabase` getter in
    // core/supabase_client.dart accesses Supabase.instance.client directly.
    //
    // To properly test these methods, consider one of:
    // 1. Using mocktail to mock SupabaseClient and inject it
    // 2. Refactoring UserDataService to accept a SupabaseClient parameter
    //
    // For now, these tests validate the UserData model contract thoroughly.
    // Service-level integration tests should be added when mocking is set up.

    test('can represent a new user with no data', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.library, isEmpty);
      expect(data.progress, isEmpty);
      expect(data.readDays, isEmpty);
      expect(data.readingStyle, isNull);
      expect(data.bookmarkTokens, 2);
      expect(data.bookmarkResetAt, isNull);
      expect(data.frozenDays, isEmpty);
    });

    test('can represent an active user with full state', () {
      final data = UserData(
        library: ['moby-dick', 'pride-and-prejudice'],
        progress: {'moby-dick': 42, 'pride-and-prejudice': 10},
        readDays: ['2026-03-01', '2026-03-02', '2026-03-03'],
        readingStyle: 'horizontal',
        bookmarkTokens: 1,
        bookmarkResetAt: '2026-03-08',
        frozenDays: ['2026-03-02'],
      );
      expect(data.library.length, 2);
      expect(data.progress['moby-dick'], 42);
      expect(data.readDays.length, 3);
      expect(data.readingStyle, 'horizontal');
      expect(data.bookmarkTokens, 1);
      expect(data.frozenDays, ['2026-03-02']);
    });

    test('bookmarkTokens of 0 is preserved — not coerced to default 2', () {
      final data = UserData(
        library: [],
        progress: {},
        readDays: [],
        bookmarkTokens: 0,
      );
      expect(data.bookmarkTokens, 0,
          reason: 'A user who spent both tokens must not see them reset to 2');
    });

    test('fetchAll select string includes all bookmark fields', () {
      expect(UserDataService.prefsSelectFields.contains('bookmark_tokens'), isTrue);
      expect(UserDataService.prefsSelectFields.contains('bookmark_reset_at'), isTrue);
      expect(UserDataService.prefsSelectFields.contains('frozen_days'), isTrue);
    });
  });

  group('UserData.savedPassages', () {
    test('defaults to empty list when not provided', () {
      final data = UserData(library: [], progress: {}, readDays: []);
      expect(data.savedPassages, isEmpty);
    });

    test('holds saved passages when provided', () {
      final passages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 10,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.utc(2026, 3, 5),
        ),
      ];
      final data = UserData(
        library: ['moby-dick'],
        progress: {'moby-dick': 10},
        readDays: ['2026-03-05'],
        savedPassages: passages,
      );
      expect(data.savedPassages.length, 1);
      expect(data.savedPassages.first.bookId, 'moby-dick');
      expect(data.savedPassages.first.passageText, 'Call me Ishmael.');
    });

    test('can hold multiple saved passages', () {
      final passages = [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 10,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime.utc(2026, 3, 5),
        ),
        SavedPassage(
          id: 'p2',
          bookId: 'frankenstein',
          chunkIndex: 0,
          passageText: 'Beware.',
          savedAt: DateTime.utc(2026, 3, 4),
        ),
      ];
      final data = UserData(
        library: [],
        progress: {},
        readDays: [],
        savedPassages: passages,
      );
      expect(data.savedPassages.length, 2);
    });
  });
}
