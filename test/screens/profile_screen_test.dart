// test/screens/profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/profile_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileScreen', () {
    testWidgets('shows sign out button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      );
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
