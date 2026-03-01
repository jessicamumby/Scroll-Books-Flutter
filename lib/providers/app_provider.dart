import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_data_service.dart';

class AppProvider extends ChangeNotifier {
  List<String> library = [];
  Map<String, int> progress = {};
  List<String> readDays = [];
  bool loading = false;
  String readingStyle = 'vertical';

  Future<void> load(String userId) async {
    loading = true;
    notifyListeners();
    try {
      final data = await UserDataService.fetchAll(userId);
      library = data.library;
      progress = data.progress;
      readDays = data.readDays;
      if (data.readingStyle != null) {
        readingStyle = data.readingStyle!;
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final pending = prefs.getString('pending_reading_style');
          if (pending != null) {
            readingStyle = pending;
            await prefs.remove('pending_reading_style');
            UserDataService.saveReadingStyle(userId, pending).catchError((_) {}); // fire-and-forget
          }
        } catch (_) {}
      }
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
  }

  Future<void> setReadingStyle(String userId, String style) async {
    readingStyle = style;
    notifyListeners();
    await UserDataService.saveReadingStyle(userId, style);
  }
}
