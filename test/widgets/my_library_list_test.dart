import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/widgets/my_library_list.dart';

Widget _wrap(AppProvider provider) => ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: '/lib',
          routes: [
            GoRoute(
              path: '/lib',
              builder: (_, __) => const Scaffold(body: MyLibraryList()),
            ),
            GoRoute(
              path: '/app/library/:id',
              builder: (_, __) => const Scaffold(body: Text('detail')),
            ),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MyLibraryList', () {
    testWidgets('shows empty state when library is empty', (tester) async {
      await tester.pumpWidget(_wrap(AppProvider()));
      await tester.pumpAndSettle();
      expect(
        find.text('Your library is empty — discover a book to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('shows books from provider.library', (tester) async {
      final provider = AppProvider();
      provider.library = ['moby-dick', 'frankenstein'];
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Frankenstein'), findsOneWidget);
    });

    testWidgets('tapping a book navigates to /app/library/:id', (tester) async {
      final provider = AppProvider();
      provider.library = ['moby-dick'];
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moby Dick'));
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    });
  });
}
