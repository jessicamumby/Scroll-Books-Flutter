import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/public_profile_screen.dart';

Widget _wrap(String username) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: AppProvider(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/profile/$username',
        routes: [
          GoRoute(
            path: '/profile/:username',
            builder: (_, state) => PublicProfileScreen(
              username: state.pathParameters['username']!,
            ),
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

  group('PublicProfileScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_wrap('jessreads'));
      // Before async resolves, show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without overflow on load', (tester) async {
      await tester.pumpWidget(_wrap('jessreads'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
