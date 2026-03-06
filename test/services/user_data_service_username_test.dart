import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/services/user_data_service.dart';

void main() {
  group('UserData', () {
    test('defaults username to null', () {
      const data = UserData(
        library: [],
        progress: {},
        readDays: [],
      );
      expect(data.username, isNull);
    });

    test('defaults isPrivate to false', () {
      const data = UserData(
        library: [],
        progress: {},
        readDays: [],
      );
      expect(data.isPrivate, isFalse);
    });

    test('holds username when set', () {
      const data = UserData(
        library: [],
        progress: {},
        readDays: [],
        username: 'jessicamumby',
      );
      expect(data.username, 'jessicamumby');
    });
  });
}
