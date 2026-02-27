import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/reader/reader_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReaderCard', () {
    testWidgets('displays chunk text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Call me Ishmael.',
            chunkIndex: 0,
            totalChunks: 100,
          ),
        ),
      );
      expect(find.text('Call me Ishmael.'), findsOneWidget);
    });

    testWidgets('does not render share icon (hoisted to ReaderScreen)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test.',
            chunkIndex: 0,
            totalChunks: 100,
          ),
        ),
      );
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });

    testWidgets('shows page number and percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test.',
            chunkIndex: 49,
            totalChunks: 100,
          ),
        ),
      );
      expect(find.textContaining('p. 50'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });
  });
}
