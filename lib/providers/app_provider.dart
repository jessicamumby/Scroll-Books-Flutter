import 'package:flutter/material.dart';
import '../services/user_data_service.dart';

class AppProvider extends ChangeNotifier {
  List<String> library = [];
  Map<String, int> progress = {};
  List<String> readDays = [];
  bool loading = false;

  Future<void> load(String userId) async {
    loading = true;
    notifyListeners();
    final data = await UserDataService.fetchAll(userId);
    library = data.library;
    progress = data.progress;
    readDays = data.readDays;
    loading = false;
    notifyListeners();
  }

  Future<void> addToLibrary(String userId, String bookId) async {
    await UserDataService.addToLibrary(userId, bookId);
    library = [...library, bookId];
    notifyListeners();
  }

  void updateProgress(String bookId, int chunkIndex) {
    progress = {...progress, bookId: chunkIndex};
    notifyListeners();
  }

  void markReadToday(String date) {
    if (!readDays.contains(date)) {
      readDays = [...readDays, date];
      notifyListeners();
    }
  }
}
