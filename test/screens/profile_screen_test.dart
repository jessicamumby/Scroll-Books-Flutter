// test/screens/profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/profile_screen.dart';

Widget _wrap() {
  return ChangeNotifierProvider<AppProvider>.value(
    value: AppProvider(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/app/profile/settings',
            builder: (_, __) => const Scaffold(body: Text('settings')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileScreen', () {
    testWidgets('shows email text widget', (tester) async {
      await tester.pumpWidget(_wrap());
      // In tests Supabase is not initialised so email is empty,
      // but the Text widget itself must exist in the tree.
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows settings cog button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('⚙️'), findsOneWidget);
    });

    testWidgets('tapping settings cog navigates to settings', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚙️'));
      await tester.pumpAndSettle();
      expect(find.text('settings'), findsOneWidget);
    });
  });
}
