import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalogue.dart';
import '../services/user_data_service.dart';
import '../utils/streak_calculator.dart';

class AppProvider extends ChangeNotifier {
  List<String> library = [];
  Map<String, int> progress = {};
  List<String> readDays = [];
  bool loading = false;
  String readingStyle = 'vertical';
  int passagesRead = 0;
  int longestStreak = 0;
  Map<String, int> dailyPassages = {};
  Map<String, int> bookTotalChunks = {};
  int? pendingMilestone;
  int dailyGoal = 10;
  int bookmarkTokens = 2;
  List<String> frozenDays = [];
  String? bookmarkResetAt;
  String? lastReadBookId;

  Future<void> _loadLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      passagesRead = prefs.getInt('passages_read') ?? 0;
      longestStreak = prefs.getInt('longest_streak') ?? 0;
      dailyGoal = prefs.getInt('daily_goal') ?? 10;
      bookmarkTokens = prefs.getInt('bookmark_tokens') ?? 2;
      bookmarkResetAt = prefs.getString('bookmark_reset_at');
      lastReadBookId = prefs.getString('last_read_book_id');
      await resetBookmarksIfExpired();
      final frozenJson = prefs.getString('frozen_days');
      if (frozenJson != null) {
        frozenDays = (jsonDecode(frozenJson) as List).cast<String>();
      }
      final dailyJson = prefs.getString('daily_passages');
      if (dailyJson != null) {
        final decoded = jsonDecode(dailyJson) as Map<String, dynamic>;
        dailyPassages = decoded.map((k, v) => MapEntry(k, v as int));
      }
    } catch (e, st) {
      debugPrint('AppProvider._loadLocalStats error: $e\n$st');
    }
  }

  Future<void> _saveLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('passages_read', passagesRead);
      await prefs.setInt('longest_streak', longestStreak);
      await prefs.setString('daily_passages', jsonEncode(dailyPassages));
    } catch (e, st) {
      debugPrint('AppProvider._saveLocalStats error: $e\n$st');
    }
  }

  Future<void> _checkMilestone(int currentStreak) async {
    const milestones = [7, 30, 90, 365];
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCelebrated = prefs.getInt('last_celebrated_milestone') ?? 0;
      int? next;
      for (final m in milestones) {
        if (currentStreak >= m && m > lastCelebrated) next = m;
      }
      if (next != null) {
        pendingMilestone = next;
        await prefs.setInt('last_celebrated_milestone', next);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('AppProvider._checkMilestone error: $e\n$st');
    }
  }

  Future<void> load(String userId) async {
    await _loadLocalStats();
    loading = true;
    notifyListeners();
    try {
      final data = await UserDataService.fetchAll(userId);
      library = data.library;
      progress = data.progress;
      readDays = data.readDays;
      // Bookmark state — backend is source of truth, overrides local
      bookmarkTokens = data.bookmarkTokens;
      bookmarkResetAt = data.bookmarkResetAt;
      frozenDays = data.frozenDays;
      await resetBookmarksIfExpired();
      // Hydrate total chunks from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, int> chunks = {};
        for (final id in library) {
          final total = prefs.getInt('total_chunks_$id');
          if (total != null) chunks[id] = total;
        }
        bookTotalChunks = chunks;
      } catch (e, st) {
        debugPrint('AppProvider.load bookTotalChunks error: $e\n$st');
      }
      if (data.readingStyle != null) {
        readingStyle = data.readingStyle!;
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final pending = prefs.getString('pending_reading_style');
          if (pending != null) {
            readingStyle = pending;
            await prefs.remove('pending_reading_style');
            UserDataService.saveReadingStyle(userId, pending).catchError((e, st) {
              debugPrint('saveReadingStyle error: $e\n$st');
            }); // fire-and-forget
          }
        } catch (e, st) {
          debugPrint('AppProvider.load pending_reading_style error: $e\n$st');
        }
      }
      final current = calculateStreak(readDays);
      if (current > longestStreak) {
        longestStreak = current;
        await _saveLocalStats();
      }
      await _checkMilestone(current);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addToLibrary(String userId, String bookId) async {
    await UserDataService.addToLibrary(userId, bookId);
    library = [...library, bookId];
    notifyListeners();
  }

  Future<void> updateProgress(String userId, String bookId, int chunkIndex) async {
    progress = {...progress, bookId: chunkIndex};
    notifyListeners();
    await UserDataService.syncProgress(userId, bookId, chunkIndex);
  }

  Future<void> markReadToday(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!readDays.contains(today)) {
      readDays = [...readDays, today];
      notifyListeners();
    }
    await UserDataService.markReadToday(userId);
    final current = calculateStreak(readDays);
    if (current > longestStreak) {
      longestStreak = current;
      await _saveLocalStats();
      notifyListeners();
    }
    await _checkMilestone(current);
  }

  Future<void> setReadingStyle(String userId, String style) async {
    readingStyle = style;
    notifyListeners();
    await UserDataService.saveReadingStyle(userId, style);
  }

  void incrementPassagesRead(String dateStr) {
    passagesRead++;
    dailyPassages = {
      ...dailyPassages,
      dateStr: (dailyPassages[dateStr] ?? 0) + 1,
    };
    notifyListeners();
    _saveLocalStats();
  }

  void clearMilestone() {
    pendingMilestone = null;
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    dailyGoal = goal;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_goal', goal);
    } catch (e, st) {
      debugPrint('AppProvider.setDailyGoal error: $e\n$st');
    }
  }

  Future<void> useBookmarkToken([String userId = '']) async {
    if (bookmarkTokens <= 0) return;
    final isFirstUse = bookmarkTokens == 2;
    bookmarkTokens--;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    frozenDays = [...frozenDays, today];
    if (isFirstUse) {
      bookmarkResetAt = DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bookmark_tokens', bookmarkTokens);
      await prefs.setString('frozen_days', jsonEncode(frozenDays));
      if (isFirstUse) {
        await prefs.setString('bookmark_reset_at', bookmarkResetAt!);
      }
    } catch (e, st) {
      debugPrint('AppProvider.useBookmarkToken error: $e\n$st');
    }
    if (userId.isNotEmpty) {
      UserDataService.saveBookmarkState(
        userId,
        bookmarkTokens: bookmarkTokens,
        bookmarkResetAt: bookmarkResetAt,
        frozenDays: frozenDays,
      ).catchError((Object e, StackTrace st) {
        debugPrint('AppProvider.useBookmarkToken remote error: $e\n$st');
      });
    }
  }

  Future<void> resetBookmarksIfExpired() async {
    if (bookmarkResetAt == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (today.compareTo(bookmarkResetAt!) >= 0) {
      bookmarkTokens = 2;
      bookmarkResetAt = null;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('bookmark_tokens', 2);
        await prefs.remove('bookmark_reset_at');
      } catch (e, st) {
        debugPrint('AppProvider.resetBookmarksIfExpired error: $e\n$st');
      }
    }
  }

  Map<String, int> get genreCounts {
    final counts = <String, int>{};
    for (final book in catalogue) {
      final p = progress[book.id];
      if (p != null && p > 0) {
        for (final g in book.genres) {
          counts[g] = (counts[g] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  void setBookTotalChunks(String bookId, int total) {
    bookTotalChunks = {...bookTotalChunks, bookId: total};
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('total_chunks_$bookId', total),
    ).catchError((Object e, StackTrace st) {
      debugPrint('AppProvider.setBookTotalChunks error: $e\n$st');
    });
  }

  void setLastReadBook(String bookId) {
    lastReadBookId = bookId;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('last_read_book_id', bookId),
    ).catchError((Object e, StackTrace st) {
      debugPrint('AppProvider.setLastReadBook error: $e\n$st');
    });
  }
}
