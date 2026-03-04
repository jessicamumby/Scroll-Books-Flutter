import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/shared_header.dart';
import '../widgets/shared_tab_bar.dart';
import '../widgets/my_library_list.dart';
import '../widgets/discover_store.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            const SharedHeader(heading: 'Your Library'),
            SharedTabBar(
              tabs: const ['My Library', 'Discover'],
              selectedIndex: _selectedTab,
              onTabSelected: (i) => setState(() => _selectedTab = i),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedTab == 0
                    ? const MyLibraryList(key: ValueKey('mylib'))
                    : const DiscoverStore(key: ValueKey('discover')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
