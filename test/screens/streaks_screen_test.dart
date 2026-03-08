import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/streaks_screen.dart';

class _NoOpAsyncStorage extends GotrueAsyncStorage {
  const _NoOpAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

Widget _wrap({
  List<String> readDays = const [],
  List<String> frozenDays = const [],
  int bookmarkTokens = 2,
  String? bookmarkResetAt,
  int dailyGoal = 10,
  Map<String, int> dailyPassages = const {},
}) {
  final provider = AppProvider()
    ..readDays = readDays
    ..frozenDays = frozenDays
    ..bookmarkTokens = bookmarkTokens
    ..bookmarkResetAt = bookmarkResetAt
    ..dailyGoal = dailyGoal
    ..dailyPassages = dailyPassages
    ..library = []
    ..progress = {};
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.light, home: const StreaksScreen()),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _NoOpAsyncStorage(),
      ),
    );
  });

  group('StreaksScreen', () {
    testWidgets('renders Your Reading heading', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Your Reading'), findsOneWidget);
    });

    testWidgets('shows Streaks and Badges tabs', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Streaks'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
    });

    testWidgets('shows MILESTONES section on streaks tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('MILESTONES'), findsOneWidget);
    });

    testWidgets('shows Today\'s Goal on streaks tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text("Today's Goal"), findsOneWidget);
    });

    testWidgets('switching to Badges tab shows genre badges', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Badges'));
      await tester.pumpAndSettle();

      expect(find.text('LONGEVITY BADGES'), findsOneWidget);
    });

    testWidgets('Badges tab shows genre badges grid header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Badges'));
      await tester.pumpAndSettle();

      // GenreBadgesGrid is rendered — check for genre badge section
      // MILESTONES should NOT be visible on Badges tab
      expect(find.text('MILESTONES'), findsNothing);
    });

    testWidgets('shows streak count reflecting read days', (tester) async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await tester.pumpWidget(_wrap(readDays: [today]));
      await tester.pumpAndSettle();
      // StreakCounter shows the count — with 1 read day (today), streak = 1
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows Personal best when longestStreak > current streak', (tester) async {
      final provider = AppProvider()
        ..readDays = []
        ..frozenDays = []
        ..bookmarkTokens = 2
        ..longestStreak = 21
        ..dailyGoal = 10
        ..dailyPassages = {}
        ..library = []
        ..progress = {};
      await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light, home: const StreaksScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Personal best'), findsOneWidget);
    });

    testWidgets('does not show Personal best when longestStreak equals current', (tester) async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final provider = AppProvider()
        ..readDays = [today]
        ..frozenDays = []
        ..bookmarkTokens = 2
        ..longestStreak = 1
        ..dailyGoal = 10
        ..dailyPassages = {}
        ..library = []
        ..progress = {};
      await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.light, home: const StreaksScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Personal best'), findsNothing);
    });
  });
}
