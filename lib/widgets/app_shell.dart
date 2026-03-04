import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(emoji: '📜', label: 'Read',    route: '/app/read'),
    _TabItem(emoji: '🔥', label: 'Streaks', route: '/app/streaks'),
    _TabItem(emoji: '📚', label: 'Library', route: '/app/library'),
    _TabItem(emoji: '👤', label: 'Profile', route: '/app/profile'),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/app/read')) return 0;
    if (loc.startsWith('/app/streaks')) return 1;
    if (loc.startsWith('/app/library')) return 2;
    if (loc.startsWith('/app/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    final onHome = selected == 0;
    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/app/read');
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.cream,
            border: Border(
              top: BorderSide(
                color: AppTheme.inkLight.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final isActive = i == selected;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context.go(tab.route),
                      behavior: HitTestBehavior.opaque,
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.45,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tab.label,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? AppTheme.tomato
                                    : AppTheme.inkMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String emoji;
  final String label;
  final String route;
  const _TabItem({
    required this.emoji,
    required this.label,
    required this.route,
  });
}
