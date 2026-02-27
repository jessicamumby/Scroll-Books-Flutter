import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/library_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/email_confirm_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reading_style_screen.dart';
import '../widgets/app_shell.dart';
import 'onboarding_state.dart';

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthNotifier();

bool get _isAuthenticated =>
    Supabase.instance.client.auth.currentSession != null;

final router = GoRouter(
  refreshListenable: Listenable.merge([_authNotifier, onboardingNotifier]),
  redirect: (context, state) {
    final loc = state.matchedLocation;
    final authed = _isAuthenticated;
    final onboarded = onboardingCompleted;
    final publicOnly = ['/', '/login', '/signup', '/forgot-password'];
    final requiresAuth = loc.startsWith('/app') || loc.startsWith('/read');
    if (!authed && !onboarded && requiresAuth) return '/onboarding';
    if (!authed && requiresAuth) return '/login';
    if (authed && !onboarded && loc != '/onboarding' && loc != '/email-confirm') return '/onboarding';
    if (authed && publicOnly.contains(loc)) return '/app/library';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/email-confirm',
      builder: (_, state) => EmailConfirmScreen(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, __) => OnboardingScreen(
        onComplete: completeOnboarding,
        onStyleSelected: (style) async {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await Provider.of<AppProvider>(context, listen: false)
                .setReadingStyle(userId, style);
          }
        },
      ),
    ),
    GoRoute(
      path: '/read/:bookId',
      builder: (_, state) => ReaderScreen(bookId: state.pathParameters['bookId']!),
    ),
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/app/library', builder: (_, __) => const LibraryScreen()),
        GoRoute(
          path: '/app/library/:id',
          builder: (_, state) => BookDetailScreen(bookId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/app/stats', builder: (_, __) => const StatsScreen()),
        GoRoute(path: '/app/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(
          path: '/app/profile/reading-style',
          builder: (_, __) => const ReadingStyleScreen(),
        ),
      ],
    ),
  ],
  initialLocation: '/app/library',
);
