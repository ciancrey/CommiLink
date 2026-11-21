import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/app_state.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _SetupRequiredApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // If the user was already signed in, load their data before showing Home.
  await AppState.instance.init();

  runApp(const CommiLinkApp());
}

class CommiLinkApp extends StatelessWidget {
  const CommiLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = AppState.instance.isSignedIn;

    return MaterialApp(
      title: 'CommiLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: signedIn ? const MainShell() : const WelcomeScreen(),
    );
  }
}

/// Shown only when lib/config/supabase_config.dart has not been filled in.
class _SetupRequiredApp extends StatelessWidget {
  const _SetupRequiredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'CommiLink is not connected to its database yet.\n\n'
                'Open lib/config/supabase_config.dart and paste your '
                'Supabase Project URL and anon key, then restart the app.',
                textAlign: TextAlign.center,
                style: AppText.body14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
