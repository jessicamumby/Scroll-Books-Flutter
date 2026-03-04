import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/discover_store.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap() {
    return const MaterialApp(
      home: Scaffold(body: DiscoverStore()),
    );
  }

  testWidgets('shows featured banner with Wuthering Heights', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Wuthering Heights'), findsOneWidget);
    expect(find.text('FEATURED THIS WEEK'), findsOneWidget);
  });

  testWidgets('shows Add to Library button in featured banner', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Add to Library — Free'), findsOneWidget);
  });

  testWidgets('shows filter tags', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Epic'), findsOneWidget);
    expect(find.text('Short'), findsOneWidget);
  });

  testWidgets('shows AVAILABLE BOOKS section header', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('AVAILABLE BOOKS'), findsOneWidget);
  });

  testWidgets('shows all 8 books when All filter is selected', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Moby Dick'), findsWidgets);
    expect(find.text('Jane Eyre'), findsWidgets);
  });

  testWidgets('tapping Classic filter shows only Classic books', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classic'));
    await tester.pumpAndSettle();

    // Classic books: Moby Dick, Frankenstein
    expect(find.text('Moby Dick'), findsWidgets);
    expect(find.text('Frankenstein'), findsWidgets);
    expect(find.text('Don Quixote'), findsNothing);
  });

  testWidgets('tapping Epic filter shows only Epic books', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Epic'));
    await tester.pumpAndSettle();

    expect(find.text('Don Quixote'), findsWidgets);
    expect(find.text('The Odyssey'), findsWidgets);
    expect(find.text('Jane Eyre'), findsNothing);
  });

  testWidgets('shows Free — Add button on book cards', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Free — Add'), findsWidgets);
  });
}
