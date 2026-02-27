import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scroll_books/core/router.dart';

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await loadOnboardingCompleted();
  });

  test('router is a GoRouter instance', () {
    expect(router, isA<GoRouter>());
  });

  test('loadOnboardingCompleted defaults to false when prefs are empty', () async {
    SharedPreferences.setMockInitialValues({});
    await loadOnboardingCompleted();
    expect(isOnboardingCompleted, isFalse);
  });

  group('resetOnboarding', () {
    test('clears SharedPreferences flag and resets isOnboardingCompleted', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      await loadOnboardingCompleted();
      expect(isOnboardingCompleted, true);

      await resetOnboarding();

      expect(isOnboardingCompleted, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isNull);
    });
  });
}
