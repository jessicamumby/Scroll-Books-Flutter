int calculateStreak(List<String> readDays, {List<String> frozenDays = const []}) {
  // Merge frozen days with read days for streak continuity
  final allDays = {...readDays, ...frozenDays}.toList();
  if (allDays.isEmpty) return 0;

  final today = DateTime.now();
  final todayStr = today.toIso8601String().substring(0, 10);
  final yesterdayStr = today
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  final sorted = allDays.toSet().toList()..sort((a, b) => b.compareTo(a));

  // Streak must end today or yesterday to be active
  if (sorted.first != todayStr && sorted.first != yesterdayStr) return 0;

  int streak = 0;
  DateTime? prev;

  for (final dateStr in sorted) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) continue;
    if (prev == null) {
      streak = 1;
      prev = date;
    } else {
      final diff = prev.difference(date).inDays;
      if (diff == 1) {
        streak++;
        prev = date;
      } else {
        break;
      }
    }
  }

  return streak;
}
