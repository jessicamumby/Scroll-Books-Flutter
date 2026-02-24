import 'package:flutter_test/flutter_test.dart';
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
  });
}
