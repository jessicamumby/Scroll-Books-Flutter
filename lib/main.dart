import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
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
