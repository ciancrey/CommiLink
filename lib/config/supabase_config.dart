/// NEW FILE · Supabase connection settings.
///
/// Get these from your Supabase project:
///   Project Settings -> API -> "Project URL" and "anon public" key.
///
/// Option A: paste them below (replace the PASTE_... text).
/// Option B: keep them out of the code and run with
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// The anon key is safe to ship in the app. NEVER put the "service_role"
/// key here.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cqvpjmrlxfbfjgacoogn.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxdnBqbXJseGZiZmpnYWNvb2duIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUyNDI5NTYsImV4cCI6MjExMDgxODk1Nn0.B7X5L5i39GIZoUg-cGuk3e6a6ivygFrp11Zf7UsIgkA',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && !anonKey.startsWith('PASTE_');
}
