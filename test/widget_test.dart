import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/data/catalogue.dart';

/// Smoke tests for core app models and state.
void main() {
  test('AppProvider initializes with sensible defaults', () {
    final provider = AppProvider();
    expect(provider.library, isEmpty);
    expect(provider.progress, isEmpty);
    expect(provider.readDays, isEmpty);
    expect(provider.loading, isFalse);
    expect(provider.readingStyle, 'vertical');
    expect(provider.passagesRead, 0);
    expect(provider.longestStreak, 0);
    expect(provider.dailyGoal, 10);
    expect(provider.bookmarkTokens, 2);
    expect(provider.frozenDays, isEmpty);
    expect(provider.bookmarkResetAt, isNull);
    expect(provider.lastReadBookId, isNull);
    expect(provider.pendingMilestone, isNull);
  });

  test('catalogue is non-empty and all books have IDs', () {
    expect(catalogue, isNotEmpty);
    for (final book in catalogue) {
      expect(book.id, isNotEmpty);
      expect(book.title, isNotEmpty);
      expect(book.genres, isNotEmpty);
    }
  });
}
