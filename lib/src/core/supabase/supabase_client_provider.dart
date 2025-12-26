import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/config/config.dart';

/// Single access point to the [SupabaseClient] instance.
///
/// IMPORTANT:
/// - Do not access [Supabase.instance.client] before `Supabase.initialize(...)`.
/// - This provider is registered only when [SupabaseConfig] is configured.
class SupabaseClientProvider {
  const SupabaseClientProvider(this._config);

  final SupabaseConfig _config;

  SupabaseClient get client {
    if (!_config.isConfigured) {
      throw StateError(
        'Supabase is not configured. '
        'Provide --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
    return Supabase.instance.client;
  }
}

