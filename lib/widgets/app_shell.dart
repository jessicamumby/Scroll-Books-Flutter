import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/app/library')) return 0;
    if (loc.startsWith('/app/stats')) return 1;
    if (loc.startsWith('/app/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final onHome = _selectedIndex(context) == 0;
    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/app/library');
      },
      child: Scaffold(
        backgroundColor: AppTheme.page,
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex(context),
          onDestinationSelected: (index) {
            switch (index) {
              case 0: context.go('/app/library'); break;
              case 1: context.go('/app/stats'); break;
              case 2: context.go('/app/profile'); break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
