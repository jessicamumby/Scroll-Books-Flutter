import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class UserData {
  final List<String> library;
  final Map<String, int> progress;
  final List<String> readDays;
  final String? readingStyle;
  final int bookmarkTokens;
  final String? bookmarkResetAt;
  final List<String> frozenDays;

  const UserData({
    required this.library,
    required this.progress,
    required this.readDays,
    this.readingStyle,
    this.bookmarkTokens = 2,
    this.bookmarkResetAt,
    this.frozenDays = const [],
  });
}

class UserDataService {
  static Future<UserData> fetchAll(String userId) async {
    final results = await Future.wait(<Future<dynamic>>[
      supabase.from('library').select('book_id').eq('user_id', userId),
      supabase.from('progress').select('book_id, chunk_index').eq('user_id', userId),
      supabase.from('read_days').select('date').eq('user_id', userId),
      supabase
          .from('user_preferences')
          .select('reading_style')
          .eq('user_id', userId)
          .maybeSingle(),
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

    final prefs = results[3] as Map<String, dynamic>?;
    final readingStyle = prefs?['reading_style'] as String?;
    final bookmarkTokens = (prefs?['bookmark_tokens'] as int?) ?? 2;
    final bookmarkResetAt = prefs?['bookmark_reset_at'] as String?;
    final frozenDaysRaw = prefs?['frozen_days'];
    final frozenDays = frozenDaysRaw == null
        ? <String>[]
        : (frozenDaysRaw is List
            ? frozenDaysRaw.cast<String>()
            : (jsonDecode(frozenDaysRaw as String) as List).cast<String>());

    return UserData(
      library: library,
      progress: progress,
      readDays: readDays,
      readingStyle: readingStyle,
      bookmarkTokens: bookmarkTokens,
      bookmarkResetAt: bookmarkResetAt,
      frozenDays: frozenDays,
    );
  }

  static Future<void> addToLibrary(String userId, String bookId) async {
    await supabase
        .from('library')
        .upsert({'user_id': userId, 'book_id': bookId}, onConflict: 'user_id,book_id');
  }

  static Future<void> removeFromLibrary(String userId, String bookId) async {
    await supabase
        .from('library')
        .delete()
        .eq('user_id', userId)
        .eq('book_id', bookId);
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

  static Future<void> saveReadingStyle(String userId, String style) async {
    await supabase.from('user_preferences').upsert(
      {'user_id': userId, 'reading_style': style},
      onConflict: 'user_id',
    );
  }

  static Future<void> saveBookmarkState(
    String userId, {
    required int bookmarkTokens,
    required String? bookmarkResetAt,
    required List<String> frozenDays,
  }) async {
    await supabase.from('user_preferences').upsert(
      {
        'user_id': userId,
        'bookmark_tokens': bookmarkTokens,
        'bookmark_reset_at': bookmarkResetAt,
        'frozen_days': frozenDays,
      },
      onConflict: 'user_id',
    );
  }
}
