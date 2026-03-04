import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
