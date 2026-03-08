import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/shared_header.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SharedHeader renders heading and brand label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SharedHeader(heading: 'Your Library')),
      ),
    );
    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('SCROLL BOOKS'), findsOneWidget);
  });

  testWidgets('SharedHeader has no avatar circle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SharedHeader(heading: 'Your Library')),
      ),
    );
    final avatarCircle = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    expect(avatarCircle, findsNothing,
        reason: 'The unused gradient avatar circle must be removed');
  });
}
