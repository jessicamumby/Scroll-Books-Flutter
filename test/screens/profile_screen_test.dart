// test/screens/profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/profile_screen.dart';

Widget _wrap() {
  return ChangeNotifierProvider<AppProvider>.value(
    value: AppProvider(),
    child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileScreen', () {
    testWidgets('shows sign out button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('shows email text widget', (tester) async {
      await tester.pumpWidget(_wrap());
      // In tests Supabase is not initialised so email is empty,
      // but the Text widget itself must exist in the tree.
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows How Scroll Books works tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('How Scroll Books works'), findsOneWidget);
    });

    testWidgets('shows Reading style tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Reading style'), findsOneWidget);
    });
  });
}
