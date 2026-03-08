String streakTierEmoji(int streak) {
  if (streak == 0) return '🪵';
  if (streak < 7) return '🔥';
  if (streak < 30) return '🔥🔥';
  if (streak < 90) return '🔥🔥🔥';
  return '🔥🔥🔥🔥';
}
