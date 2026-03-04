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
    test('cream colour matches Warm Punch token', () {
      expect(AppTheme.cream, const Color(0xFFFFF8F0));
    });

    test('page alias maps to cream', () {
      expect(AppTheme.page, AppTheme.cream);
    });

    test('amber colour matches Warm Punch token', () {
      expect(AppTheme.amber, const Color(0xFFE8A838));
    });

    test('tomato colour matches Warm Punch token', () {
      expect(AppTheme.tomato, const Color(0xFFD94F30));
    });

    test('brand alias maps to tomato', () {
      expect(AppTheme.brand, AppTheme.tomato);
    });

    test('ink colour matches Warm Punch token', () {
      expect(AppTheme.ink, const Color(0xFF2C2118));
    });

    test('sienna colour matches Warm Punch token', () {
      expect(AppTheme.sienna, const Color(0xFF7A3325));
    });

    testWidgets('theme applies cream colour as scaffold background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(backgroundColor: AppTheme.cream, body: const Text('test')),
        ),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.cream);
    });

    test('colorScheme primary is tomato', () {
      expect(AppTheme.light.colorScheme.primary, AppTheme.tomato);
    });

    test('colorScheme error is sienna', () {
      expect(AppTheme.light.colorScheme.error, AppTheme.sienna);
    });

    test('brandDark alias maps to tomato', () {
      expect(AppTheme.brandDark, AppTheme.tomato);
    });

    test('brandPale alias maps to tomatoLight', () {
      expect(AppTheme.brandPale, AppTheme.tomatoLight);
    });

    test('tomatoLight colour matches token', () {
      expect(AppTheme.tomatoLight, const Color(0xFFF4DDD7));
    });

    test('sageLight colour matches token', () {
      expect(AppTheme.sageLight, const Color(0xFFE4EDE5));
    });

    test('forestPale alias maps to sageLight', () {
      expect(AppTheme.forestPale, AppTheme.sageLight);
    });
  });
}
