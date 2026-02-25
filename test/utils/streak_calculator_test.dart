import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/utils/streak_calculator.dart';

void main() {
  group('calculateStreak', () {
    test('empty list returns 0', () {
      expect(calculateStreak([]), 0);
    });

    test('today only returns 1', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(calculateStreak([today]), 1);
    });

    test('3 consecutive days ending today returns 3', () {
      final today = DateTime.now();
      final days = List.generate(3, (i) =>
          today.subtract(Duration(days: i)).toIso8601String().substring(0, 10));
      expect(calculateStreak(days), 3);
    });

    test('gap in streak resets count', () {
      final today = DateTime.now();
      final days = [
        today.toIso8601String().substring(0, 10),
        today.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10),
      ];
      expect(calculateStreak(days), 1);
    });

    test('streak ending yesterday still counts', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final days = List.generate(4, (i) =>
          yesterday.subtract(Duration(days: i)).toIso8601String().substring(0, 10));
      expect(calculateStreak(days), 4);
    });
  });
}
