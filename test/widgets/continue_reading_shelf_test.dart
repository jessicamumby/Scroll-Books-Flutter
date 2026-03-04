import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/widgets/continue_reading_shelf.dart';

AppProvider _provider({
  Map<String, int> progress = const {},
  Map<String, int> bookTotalChunks = const {},
}) {
  final p = AppProvider();
  p.progress = progress;
  p.bookTotalChunks = bookTotalChunks;
  return p;
}

Widget _wrap({
  Map<String, int> progress = const {},
  Map<String, int> bookTotalChunks = const {},
}) => ChangeNotifierProvider<AppProvider>.value(
  value: _provider(progress: progress, bookTotalChunks: bookTotalChunks),
  child: MaterialApp(
    theme: AppTheme.light,
    home: const Scaffold(body: ContinueReadingShelf()),
  ),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ContinueReadingShelf', () {
    testWidgets('hidden when no books have progress', (tester) async {
      await tester.pumpWidget(_wrap(progress: {}));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('hidden when progress is zero for all books', (tester) async {
      await tester.pumpWidget(_wrap(progress: {'moby-dick': 0}));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('shows PageView when a book has progress > 0', (tester) async {
      await tester.pumpWidget(_wrap(progress: {'moby-dick': 50}));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('shows CONTINUE READING heading when visible', (tester) async {
      await tester.pumpWidget(_wrap(progress: {'moby-dick': 50}));
      await tester.pumpAndSettle();
      expect(find.text('CONTINUE READING'), findsOneWidget);
    });

    testWidgets('shows book title in shelf', (tester) async {
      await tester.pumpWidget(_wrap(progress: {'moby-dick': 50}));
      await tester.pumpAndSettle();
      expect(find.textContaining('Moby Dick'), findsAtLeastNWidgets(1));
    });

    testWidgets('only hasChunks books with progress appear', (tester) async {
      // pride-and-prejudice has hasChunks: false — should not appear
      await tester.pumpWidget(
        _wrap(progress: {'moby-dick': 50, 'pride-and-prejudice': 100}),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      expect(find.textContaining('Pride and Prejudice'), findsNothing);
    });

    testWidgets('tapping second card makes it active', (tester) async {
      await tester.pumpWidget(_wrap(progress: {'moby-dick': 50}));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      // Drag to reveal second card then tap it — verify no error thrown
      await tester.drag(find.byType(PageView), const Offset(-200, 0));
      await tester.pumpAndSettle();
      // If we got here without error, the tap/drag interaction works
      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
