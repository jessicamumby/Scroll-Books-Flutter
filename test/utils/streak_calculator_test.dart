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

  group('calculateStreak with frozenDays', () {
    test('frozen day today counts as streak of 1', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(calculateStreak([], frozenDays: [today]), 1);
    });

    test('frozen day fills a gap in read days', () {
      final today = DateTime.now();
      final day0 = today.toIso8601String().substring(0, 10);
      final day1 = today.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final day2 = today.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
      // Read today and 2 days ago, frozen yesterday -> streak of 3
      expect(calculateStreak([day0, day2], frozenDays: [day1]), 3);
    });

    test('frozen days extend streak beyond read days', () {
      final today = DateTime.now();
      final days = List.generate(5, (i) =>
          today.subtract(Duration(days: i)).toIso8601String().substring(0, 10));
      // Read first 3 days, frozen last 2
      expect(
        calculateStreak(days.sublist(0, 3), frozenDays: days.sublist(3, 5)),
        5,
      );
    });
  });

  group('calculateStreak edge cases', () {
    test('streak older than yesterday returns 0', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final days = [threeDaysAgo.toIso8601String().substring(0, 10)];
      expect(calculateStreak(days), 0);
    });

    test('duplicate dates in input are handled', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(calculateStreak([today, today, today]), 1);
    });

    test('long streak of 30 consecutive days', () {
      final today = DateTime.now();
      final days = List.generate(30, (i) =>
          today.subtract(Duration(days: i)).toIso8601String().substring(0, 10));
      expect(calculateStreak(days), 30);
    });

    test('unsorted input still computes correct streak', () {
      final today = DateTime.now();
      final days = List.generate(5, (i) =>
          today.subtract(Duration(days: i)).toIso8601String().substring(0, 10));
      // Reverse the order (oldest first) — should still work
      expect(calculateStreak(days.reversed.toList()), 5);
    });
  });
}
