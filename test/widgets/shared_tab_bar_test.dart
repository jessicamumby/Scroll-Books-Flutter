import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/shared_tab_bar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  int? selectedTab;

  Widget _wrap({
    List<String> tabs = const ['Tab A', 'Tab B'],
    int selectedIndex = 0,
  }) {
    selectedTab = null;
    return MaterialApp(
      home: Scaffold(
        body: SharedTabBar(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onTabSelected: (i) => selectedTab = i,
        ),
      ),
    );
  }

  testWidgets('renders provided tab labels', (tester) async {
    await tester.pumpWidget(_wrap(tabs: ['Streaks', 'Badges']));
    expect(find.text('Streaks'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
  });

  testWidgets('tapping a tab calls onTabSelected with correct index', (tester) async {
    await tester.pumpWidget(_wrap(tabs: ['Streaks', 'Badges']));
    await tester.tap(find.text('Badges'));
    expect(selectedTab, 1);
  });

  testWidgets('tapping first tab calls onTabSelected with 0', (tester) async {
    await tester.pumpWidget(_wrap(tabs: ['Streaks', 'Badges'], selectedIndex: 1));
    await tester.tap(find.text('Streaks'));
    expect(selectedTab, 0);
  });

  testWidgets('renders 3 tabs when provided', (tester) async {
    await tester.pumpWidget(_wrap(tabs: ['A', 'B', 'C']));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });
}
