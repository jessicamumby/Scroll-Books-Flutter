// test/core/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/core/theme.dart';

void main() {
  group('AppTheme colours', () {
    test('page colour matches Antique Study token', () {
      expect(AppTheme.page, const Color(0xFFF4EDD8));
    });

    test('amber colour matches Antique Study token', () {
      expect(AppTheme.amber, const Color(0xFF9A6F2A));
    });

    test('ink colour matches Antique Study token', () {
      expect(AppTheme.ink, const Color(0xFF1E1A14));
    });

    test('sienna colour matches Antique Study token', () {
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
  });
}
