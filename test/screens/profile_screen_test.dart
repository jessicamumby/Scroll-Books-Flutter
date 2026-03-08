// test/screens/profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/models/saved_passage.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppProvider _provider({List<SavedPassage>? savedPassages}) {
  final provider = AppProvider();
  if (savedPassages != null) {
    provider.savedPassages = savedPassages;
  }
  return provider;
}

Widget _wrap({AppProvider? provider}) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider ?? _provider(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/app/profile/settings',
            builder: (_, __) => const Scaffold(body: Text('settings')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileScreen', () {
    testWidgets('shows Profile app bar title', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows settings cog button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('⚙️'), findsOneWidget);
    });

    testWidgets('tapping settings cog navigates to settings', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚙️'));
      await tester.pumpAndSettle();
      expect(find.text('settings'), findsOneWidget);
    });

    testWidgets('shows Saved Passages header', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Saved Passages'), findsOneWidget);
    });

    testWidgets('shows empty state when no passages saved', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('No saved passages yet'), findsOneWidget);
      expect(
        find.text('Long press any passage while reading to save it'),
        findsOneWidget,
      );
    });

    testWidgets('shows passage text preview when passages exist',
        (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      provider.bookTotalChunks = {'moby-dick': 100};
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('Call me Ishmael.'), findsOneWidget);
    });

    testWidgets('shows book title and author for saved passage',
        (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('Moby Dick'), findsOneWidget);
      expect(find.text('Herman Melville'), findsOneWidget);
    });

    testWidgets('shows saved date', (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('Mar 5, 2026'), findsOneWidget);
    });

    testWidgets('shows passage count badge', (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
        SavedPassage(
          id: 'p2',
          bookId: 'frankenstein',
          chunkIndex: 1,
          passageText: 'Beware.',
          savedAt: DateTime(2026, 3, 4),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('swipe left reveals delete icon, tap confirms deletion',
        (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('Call me Ishmael.'), findsOneWidget);
      // Swipe left to reveal delete button
      await tester.drag(
        find.text('Call me Ishmael.'),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      // Delete icon should be in the tree
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      // Tap delete icon to confirm
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      // Passage should be removed from the provider
      expect(provider.savedPassages, isEmpty);
    });

    testWidgets('swipe back closes action without deleting',
        (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      // Swipe left to reveal
      await tester.drag(
        find.text('Call me Ishmael.'),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      // Tap the card to close
      await tester.tap(find.text('Call me Ishmael.'));
      await tester.pumpAndSettle();
      // Passage should still exist
      expect(provider.savedPassages, hasLength(1));
    });

    testWidgets('swipe right reveals share icon', (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      // Swipe right to reveal share button
      await tester.drag(
        find.text('Call me Ishmael.'),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();
      // Share icon should be in the tree
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      // Passage should still exist (not deleted)
      expect(provider.savedPassages, hasLength(1));
    });

    testWidgets('shows percentage when totalChunks available',
        (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 49,
          passageText: 'Some passage.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      provider.bookTotalChunks = {'moby-dick': 100};
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('does not show empty state when passages exist',
        (tester) async {
      final provider = _provider(savedPassages: [
        SavedPassage(
          id: 'p1',
          bookId: 'moby-dick',
          chunkIndex: 0,
          passageText: 'Call me Ishmael.',
          savedAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.text('No saved passages yet'), findsNothing);
    });

    testWidgets('shows @username in user info row when username is set',
        (tester) async {
      final provider = _provider();
      provider.username = 'jessreads';
      await tester.pumpWidget(_wrap(provider: provider));
      // ProfileShareCard is positioned off-screen (left: -1000) but still in
      // the widget tree, so both the body text and the hidden card render
      // '@jessreads', giving 2 matches. findsAtLeastNWidgets(1) is used
      // intentionally here.
      expect(find.text('@jessreads'), findsAtLeastNWidgets(1));
    });

    testWidgets('share icon is visible when username is set',
        (tester) async {
      final provider = _provider();
      provider.username = 'jessreads';
      await tester.pumpWidget(_wrap(provider: provider));
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('no email address text is rendered on the profile screen',
        (tester) async {
      final provider = _provider();
      provider.username = 'jessreads';
      await tester.pumpWidget(_wrap(provider: provider));
      // ProfileShareCard is off-screen but in the tree — 2 matches expected.
      expect(find.text('@jessreads'), findsAtLeastNWidgets(1));
      final emailTexts = find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.contains('@') &&
          widget.data!.contains('.'));
      expect(emailTexts, findsNothing,
          reason: 'Email address must not be rendered on the profile screen');
    });

    testWidgets('share icon is present but disabled when username is null',
        (tester) async {
      await tester.pumpWidget(_wrap()); // no username set, provider.username == null
      final button = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.share));
      expect(button.onPressed, isNull);
    });
  });
}
