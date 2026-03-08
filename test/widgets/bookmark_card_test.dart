import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/bookmark_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap({required int remaining, String? resetAt}) => MaterialApp(
        home: Scaffold(
          body: BookmarkCard(
            bookmarksRemaining: remaining,
            bookmarkResetAt: resetAt,
            onUseBookmark: () {},
          ),
        ),
      );

  testWidgets('shows use button when bookmarks remain', (tester) async {
    await tester.pumpWidget(_wrap(remaining: 2, resetAt: null));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use Bookmark'), findsOneWidget);
  });

  testWidgets('shows Resets in X days when tokens = 0 and resetAt is set', (tester) async {
    final futureDate = DateTime.now()
        .add(const Duration(days: 5))
        .toIso8601String()
        .substring(0, 10);
    await tester.pumpWidget(_wrap(remaining: 0, resetAt: futureDate));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resets in 5'), findsOneWidget);
  });

  testWidgets('shows Resets tomorrow when 1 day remains', (tester) async {
    final tomorrowDate = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    await tester.pumpWidget(_wrap(remaining: 0, resetAt: tomorrowDate));
    await tester.pumpAndSettle();
    expect(find.text('Resets tomorrow'), findsOneWidget);
  });

  testWidgets('shows No Bookmarks Left when tokens = 0 and resetAt is null', (tester) async {
    await tester.pumpWidget(_wrap(remaining: 0, resetAt: null));
    await tester.pumpAndSettle();
    expect(find.text('No Bookmarks Left'), findsOneWidget);
  });

  testWidgets('shows days left label when token is being refilled', (tester) async {
    final resetDate = DateTime.now().add(const Duration(days: 5));
    final resetStr = resetDate.toIso8601String().substring(0, 10);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BookmarkCard(
          bookmarksRemaining: 1,
          bookmarkResetAt: resetStr,
          onUseBookmark: () {},
        ),
      ),
    ));
    expect(find.textContaining('days left'), findsOneWidget);
  });

  testWidgets('does not show days left when all tokens full', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BookmarkCard(
          bookmarksRemaining: 2,
          bookmarkResetAt: null,
          onUseBookmark: () {},
        ),
      ),
    ));
    expect(find.textContaining('days left'), findsNothing);
  });
}
