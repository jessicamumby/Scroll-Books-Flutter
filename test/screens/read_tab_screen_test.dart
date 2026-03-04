import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/read_tab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppProvider _provider({String? lastReadBookId}) {
  final p = AppProvider();
  p.lastReadBookId = lastReadBookId;
  return p;
}

Widget _wrap({String? lastReadBookId}) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: _provider(lastReadBookId: lastReadBookId),
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: '/read-tab',
          routes: [
            GoRoute(
              path: '/read-tab',
              builder: (_, __) => const ReadTabScreen(),
            ),
            GoRoute(
              path: '/read/:bookId',
              builder: (_, __) => const Scaffold(body: Text('reader')),
            ),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReadTabScreen', () {
    testWidgets('shows empty state when lastReadBookId is null', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Start Reading'), findsOneWidget);
      expect(find.text('Go to Library'), findsOneWidget);
    });

    testWidgets('navigates to reader when lastReadBookId is set', (tester) async {
      await tester.pumpWidget(_wrap(lastReadBookId: 'moby-dick'));
      await tester.pumpAndSettle();
      expect(find.text('reader'), findsOneWidget);
      expect(find.text('Start Reading'), findsNothing);
    });

    testWidgets('navigates when lastReadBookId is set after initial build', (tester) async {
      final provider = _provider();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: GoRouter(
              initialLocation: '/read-tab',
              routes: [
                GoRoute(
                  path: '/read-tab',
                  builder: (_, __) => const ReadTabScreen(),
                ),
                GoRoute(
                  path: '/read/:bookId',
                  builder: (_, __) => const Scaffold(body: Text('reader')),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Start Reading'), findsOneWidget);
      provider.setLastReadBook('moby-dick');
      await tester.pumpAndSettle();
      expect(find.text('reader'), findsOneWidget);
    });
  });
}
