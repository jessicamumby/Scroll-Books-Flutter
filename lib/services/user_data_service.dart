import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/saved_passage.dart';
import '../models/user_public_profile.dart';

class UserData {
  final List<String> library;
  final Map<String, int> progress;
  final List<String> readDays;
  final String? readingStyle;
  final int bookmarkTokens;
  final String? bookmarkResetAt;
  final List<String> frozenDays;
  final List<SavedPassage> savedPassages;
  final String? username;
  final bool isPrivate;

  const UserData({
    required this.library,
    required this.progress,
    required this.readDays,
    this.readingStyle,
    this.bookmarkTokens = 2,
    this.bookmarkResetAt,
    this.frozenDays = const [],
    this.savedPassages = const [],
    this.username,
    this.isPrivate = false,
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
          .select('reading_style, bookmark_tokens, bookmark_reset_at, frozen_days')
          .eq('user_id', userId)
          .maybeSingle(),
      supabase
          .from('saved_passages')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false),
      supabase
          .from('profiles')
          .select('username, is_private')
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

    final savedPassages = (results[4] as List)
        .map((r) => SavedPassage.fromJson(r as Map<String, dynamic>))
        .toList();

    final profile = results[5] as Map<String, dynamic>?;
    final username = profile?['username'] as String?;
    final isPrivate = (profile?['is_private'] as bool?) ?? false;

    return UserData(
      library: library,
      progress: progress,
      readDays: readDays,
      readingStyle: readingStyle,
      bookmarkTokens: bookmarkTokens,
      bookmarkResetAt: bookmarkResetAt,
      frozenDays: frozenDays,
      savedPassages: savedPassages,
      username: username,
      isPrivate: isPrivate,
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

  static Future<Map<String, dynamic>> savePassage(
    String userId,
    String bookId,
    int chunkIndex,
    String passageText,
  ) async {
    final result = await supabase
        .from('saved_passages')
        .upsert(
          {
            'user_id': userId,
            'book_id': bookId,
            'chunk_index': chunkIndex,
            'passage_text': passageText,
          },
          onConflict: 'user_id,book_id,chunk_index',
        )
        .select()
        .single();
    return result;
  }

  static Future<void> deleteSavedPassage(
    String userId,
    String passageId,
  ) async {
    await supabase
        .from('saved_passages')
        .delete()
        .eq('id', passageId)
        .eq('user_id', userId);
  }

  static Future<void> saveUsername(String userId, String username) async {
    await supabase.from('profiles').upsert(
      {'user_id': userId, 'username': username.toLowerCase()},
      onConflict: 'user_id',
    );
  }

  static Future<void> saveAccountVisibility(String userId, {required bool isPrivate}) async {
    await supabase.from('profiles').upsert(
      {'user_id': userId, 'is_private': isPrivate},
      onConflict: 'user_id',
    );
  }

  static Future<bool> isUsernameAvailable(String candidate) async {
    try {
      final result = await supabase
          .rpc('is_username_available', params: {'candidate': candidate});
      return result as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<UserPublicProfile?> fetchPublicProfile(String username) async {
    try {
      final profileRow = await supabase
          .from('profiles')
          .select('user_id, username, display_name, is_private')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (profileRow == null) return null;

      final userId = profileRow['user_id'] as String;
      final isPrivate = (profileRow['is_private'] as bool?) ?? false;

      if (isPrivate) {
        return UserPublicProfile(
          userId: userId,
          username: profileRow['username'] as String? ?? username,
          displayName: profileRow['display_name'] as String? ?? '',
          isPrivate: true,
          followerCount: 0,
          followingCount: 0,
          streakCount: 0,
          badgesEarned: 0,
          passagesSaved: 0,
        );
      }

      // Fetch counts in parallel
      final counts = await Future.wait([
        supabase.from('follows').select().eq('following_id', userId),
        supabase.from('follows').select().eq('follower_id', userId),
        supabase.from('read_days').select('date').eq('user_id', userId),
        supabase.from('saved_passages').select('id').eq('user_id', userId),
      ]);

      final followerCount = (counts[0] as List).length;
      final followingCount = (counts[1] as List).length;
      final readDays = (counts[2] as List).map((r) => r['date'] as String).toList();
      final passagesSaved = (counts[3] as List).length;

      // Simple streak calc: count consecutive days from today
      int streak = 0;
      final today = DateTime.now();
      for (int i = 0; i < 400; i++) {
        final d = today.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
        if (readDays.contains(d)) {
          streak++;
        } else if (i > 0) {
          break;
        }
      }

      return UserPublicProfile(
        userId: userId,
        username: profileRow['username'] as String? ?? username,
        displayName: profileRow['display_name'] as String? ?? '',
        isPrivate: false,
        followerCount: followerCount,
        followingCount: followingCount,
        streakCount: streak,
        badgesEarned: 0,
        passagesSaved: passagesSaved,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> followUser(String followerId, String followingId) async {
    await supabase.from('follows').upsert(
      {'follower_id': followerId, 'following_id': followingId},
      onConflict: 'follower_id,following_id',
    );
  }

  static Future<void> unfollowUser(String followerId, String followingId) async {
    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  static Future<bool> isFollowing(String followerId, String followingId) async {
    final result = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return result != null;
  }
}
