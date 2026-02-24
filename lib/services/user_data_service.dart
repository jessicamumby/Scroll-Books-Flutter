import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class UserData {
  final List<String> library;
  final Map<String, int> progress;
  final List<String> readDays;

  const UserData({
    required this.library,
    required this.progress,
    required this.readDays,
  });
}

class UserDataService {
  static Future<UserData> fetchAll(String userId) async {
    final results = await Future.wait([
      supabase.from('library').select('book_id').eq('user_id', userId),
      supabase.from('progress').select('book_id, chunk_index').eq('user_id', userId),
      supabase.from('read_days').select('date').eq('user_id', userId),
    ]);

    final library = (results[0] as List)
        .map((r) => r['book_id'] as String)
        .toList();

    final progress = Map<String, int>.fromEntries(
      (results[1] as List).map((r) =>
          MapEntry(r['book_id'] as String, r['chunk_index'] as int)),
    );

    final readDays = (results[2] as List)
        .map((r) => r['date'] as String)
        .toList();

    return UserData(library: library, progress: progress, readDays: readDays);
  }

  static Future<void> addToLibrary(String userId, String bookId) async {
    await supabase
        .from('library')
        .insert({'user_id': userId, 'book_id': bookId});
  }

  static Future<void> syncProgress(
      String userId, String bookId, int chunkIndex) async {
    await supabase.from('progress').upsert(
      {
        'user_id': userId,
        'book_id': bookId,
        'chunk_index': chunkIndex,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,book_id',
    );
  }

  static Future<void> markReadToday(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await supabase.from('read_days').upsert(
      {'user_id': userId, 'date': today},
      onConflict: 'user_id,date',
    );
  }
}
