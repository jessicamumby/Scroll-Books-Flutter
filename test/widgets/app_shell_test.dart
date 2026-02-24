import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/app_shell.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AppShell renders 3 navigation destinations', (tester) async {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/app/library', builder: (_, __) => const SizedBox()),
            GoRoute(path: '/app/stats', builder: (_, __) => const SizedBox()),
            GoRoute(path: '/app/profile', builder: (_, __) => const SizedBox()),
          ],
        ),
      ],
      initialLocation: '/app/library',
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
