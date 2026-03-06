import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/onboarding_state.dart';
import 'core/theme.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  assert(dotenv.env['SUPABASE_URL'] != null, 'SUPABASE_URL missing from .env');
  assert(dotenv.env['SUPABASE_ANON_KEY'] != null, 'SUPABASE_ANON_KEY missing from .env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await loadOnboardingCompleted();

  runApp(const ScrollBooksApp());
}

class ScrollBooksApp extends StatelessWidget {
  const ScrollBooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const _AppWithAuth(),
    );
  }
}

class _AppWithAuth extends StatefulWidget {
  const _AppWithAuth();

  @override
  State<_AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends State<_AppWithAuth> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        context.read<AppProvider>().load(event.session!.user.id);
      }
    });
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppProvider>().load(session.user.id);
      });
    }
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    final appLinks = AppLinks();
    // Cold start: app was opened via the deep link
    appLinks.getInitialLink().then((uri) async {
      if (uri == null) return;
      final handled = await _handleProfileLink(uri);
      if (!handled) {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
    // Warm start: app was already running when the link arrived
    appLinks.uriLinkStream.listen((uri) async {
      final handled = await _handleProfileLink(uri);
      if (!handled) {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
  }

  Future<bool> _handleProfileLink(Uri uri) async {
    // Handle scrollbooks://profile/username
    if (uri.scheme == 'scrollbooks' && uri.host == 'profile') {
      final username = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (username != null && username.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.push('/app/profile/view/$username');
        });
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scroll Books',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
