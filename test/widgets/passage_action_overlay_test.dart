import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/reader/passage_action_overlay.dart';

Widget _wrap({
  String text = 'Call me Ishmael.',
  int chunkIndex = 0,
  int totalChunks = 100,
  String bookId = 'moby-dick',
  bool isSaved = false,
  void Function(String, int)? onShare,
  void Function(String, int)? onSave,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: PassageActionOverlay(
        text: text,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        bookId: bookId,
        isSaved: isSaved,
        onShare: onShare ?? (_, __) {},
        onSave: onSave ?? (_, __) {},
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PassageActionOverlay', () {
    testWidgets('renders passage text from ReaderCard', (tester) async {
      await tester.pumpWidget(_wrap(text: 'Some passage text here'));
      expect(find.text('Some passage text here'), findsOneWidget);
    });

    testWidgets('shows page label', (tester) async {
      await tester.pumpWidget(
          _wrap(text: 'Text', chunkIndex: 4, totalChunks: 100));
      expect(find.text('p. 5 · 5%'), findsOneWidget);
    });

    testWidgets('does not show action buttons initially', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Share'), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('long press shows Share and Save buttons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.longPress(find.text('Call me Ishmael.'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('tapping Share calls onShare with correct args',
        (tester) async {
      String? sharedText;
      int? sharedIndex;
      await tester.pumpWidget(_wrap(
        text: 'Test passage',
        chunkIndex: 5,
        onShare: (text, index) {
          sharedText = text;
          sharedIndex = index;
        },
      ));
      await tester.longPress(find.text('Test passage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(sharedText, 'Test passage');
      expect(sharedIndex, 5);
    });

    testWidgets('tapping Save calls onSave with correct args',
        (tester) async {
      String? savedText;
      int? savedIndex;
      await tester.pumpWidget(_wrap(
        text: 'Save me',
        chunkIndex: 3,
        onSave: (text, index) {
          savedText = text;
          savedIndex = index;
        },
      ));
      await tester.longPress(find.text('Save me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(savedText, 'Save me');
      expect(savedIndex, 3);
    });

    testWidgets('shows "Saved" label when isSaved is true', (tester) async {
      await tester.pumpWidget(_wrap(isSaved: true));
      await tester.longPress(find.text('Call me Ishmael.'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('shows "Save" label when isSaved is false', (tester) async {
      await tester.pumpWidget(_wrap(isSaved: false));
      await tester.longPress(find.text('Call me Ishmael.'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('buttons disappear after tapping Share', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.longPress(find.text('Call me Ishmael.'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsNothing);
    });
  });
}
