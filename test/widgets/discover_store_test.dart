import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/discover_store.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('DiscoverStore', () {
    testWidgets('shows only production books', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DiscoverStore())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Wuthering Heights'), findsAtLeastNWidgets(1));
      expect(find.text('Romeo & Juliet'), findsOneWidget);
      expect(find.text('Jane Eyre'), findsNothing);
      expect(find.text('Don Quixote'), findsNothing);
      expect(find.text('The Odyssey'), findsNothing);
      expect(find.text('Dracula'), findsNothing);
    });

    testWidgets('does not show Epic filter tag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DiscoverStore())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Epic'), findsNothing);
    });
  });
}
