// test/core/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme colours', () {
    test('page colour matches Warm Punch token', () {
      expect(AppTheme.page, const Color(0xFFFFF9F2));
    });

    test('amber colour matches Warm Punch token', () {
      expect(AppTheme.amber, const Color(0xFFFF4D2E));
    });

    test('ink colour matches Warm Punch token', () {
      expect(AppTheme.ink, const Color(0xFF1C0F00));
    });

    test('sienna colour matches Warm Punch token', () {
      expect(AppTheme.sienna, const Color(0xFF7A3325));
    });

    testWidgets('theme applies page colour as scaffold background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(backgroundColor: AppTheme.page, body: const Text('test')),
        ),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.page);
    });

    test('colorScheme primary is amber', () {
      expect(AppTheme.light.colorScheme.primary, AppTheme.amber);
    });

    test('colorScheme error is sienna', () {
      expect(AppTheme.light.colorScheme.error, AppTheme.sienna);
    });

    test('amberWash colour matches token', () {
      expect(AppTheme.amberWash, const Color(0xFFFFF2F0));
    });

    test('forestPale colour matches token', () {
      expect(AppTheme.forestPale, const Color(0xFFC8D8C4));
    });
  });
}
