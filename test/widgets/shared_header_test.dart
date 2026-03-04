import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scroll_books/widgets/shared_header.dart';

class _NoOpAsyncStorage extends GotrueAsyncStorage {
  const _NoOpAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _NoOpAsyncStorage(),
      ),
    );
  });

  Widget _wrap(String heading) {
    return MaterialApp(
      home: Scaffold(body: SharedHeader(heading: heading)),
    );
  }

  testWidgets('shows SCROLL BOOKS label', (tester) async {
    await tester.pumpWidget(_wrap('Your Library'));
    expect(find.text('SCROLL BOOKS'), findsOneWidget);
  });

  testWidgets('shows heading text', (tester) async {
    await tester.pumpWidget(_wrap('Your Reading'));
    expect(find.text('Your Reading'), findsOneWidget);
  });

  testWidgets('shows different heading text', (tester) async {
    await tester.pumpWidget(_wrap('My Library'));
    expect(find.text('My Library'), findsOneWidget);
  });

  testWidgets('renders avatar circle', (tester) async {
    await tester.pumpWidget(_wrap('Test'));
    // The avatar is a 40x40 container — the "?" fallback should appear
    // since there's no authenticated user
    expect(find.text('?'), findsOneWidget);
  });
}
