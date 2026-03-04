import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/app_shell.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() => GoRouter(
  routes: [
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/app/read', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/app/streaks', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/app/library', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/app/profile', builder: (_, __) => const SizedBox()),
      ],
    ),
  ],
  initialLocation: '/app/read',
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AppShell renders 4 navigation tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _buildRouter(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Streaks'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('AppShell wraps scaffold in PopScope', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _buildRouter(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is PopScope),
      findsOneWidget,
    );
  });
}
