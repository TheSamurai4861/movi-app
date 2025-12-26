// FILE #49
// lib/src/core/supabase/supabase_module.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/config/models/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase module:
/// - Validates config (URL / anon key) to ensure the app targets the right project.
/// - Initializes Supabase exactly once (idempotent).
/// - Registers a SINGLE SupabaseClient in GetIt so auth + repositories share the same client.
///
/// This directly addresses:
/// - "I see profiles in Supabase, but the app can't read them" (wrong URL/project).
/// - "auth OK but repos see currentUser null / empty results" (client mismatch).
class SupabaseModule {
  SupabaseModule._();

  static bool _initialized = false;

  static Future<void> register(GetIt sl) async {
    final sw = Stopwatch()..start();
    debugPrint('[DEBUG][Startup] SupabaseModule.register: START');
    
    final config = SupabaseConfig.fromEnvironment;
    
    // Vérifier si Supabase est configuré avant de valider
    if (!config.isConfigured) {
      debugPrint(
        '[SupabaseModule] Not configured. '
        'Provide --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... to enable.',
      );
      debugPrint('[DEBUG][Startup] SupabaseModule.register: SKIPPED (not configured) (${sw.elapsedMilliseconds}ms)');
      sw.stop();
      return;
    }

    // Valider la configuration
    try {
      config.ensureValid();
      debugPrint('[DEBUG][Startup] SupabaseModule.register: config validated (${sw.elapsedMilliseconds}ms)');
    } catch (e, st) {
      sw.stop();
      debugPrint('[DEBUG][Startup] SupabaseModule.register: ERROR - config validation failed after ${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[DEBUG][Startup] SupabaseModule.register: Stack trace: $st');
      rethrow;
    }

    if (kDebugMode) {
      debugPrint('[SupabaseModule] ${config.toString()}');
      debugPrint(
        '[SupabaseModule] NOTE: Ensure SUPABASE_URL matches the project where you see your profiles.',
      );
    }

    // Initialize Supabase once (idempotent guard).
    if (!_initialized) {
      debugPrint('[DEBUG][Startup] SupabaseModule.register: initializing Supabase');
      try {
        await Supabase.initialize(
          url: config.supabaseUrl.trim(),
          anonKey: config.supabaseAnonKey.trim(),
        );
        _initialized = true;
        debugPrint('[DEBUG][Startup] SupabaseModule.register: Supabase.initialize DONE (${sw.elapsedMilliseconds}ms)');
        debugPrint('[Supabase] Initialized.');
      } catch (e, st) {
        sw.stop();
        debugPrint('[DEBUG][Startup] SupabaseModule.register: ERROR - Supabase.initialize failed after ${sw.elapsedMilliseconds}ms: $e');
        debugPrint('[DEBUG][Startup] SupabaseModule.register: Stack trace: $st');
        debugPrint('[Supabase] Initialization failed: $e\n$st');
        rethrow;
      }
    } else {
      debugPrint('[DEBUG][Startup] SupabaseModule.register: Supabase already initialized, skipping (${sw.elapsedMilliseconds}ms)');
    }

    // Register a SINGLE SupabaseClient into GetIt.
    debugPrint('[DEBUG][Startup] SupabaseModule.register: registering SupabaseClient in GetIt');
    final client = Supabase.instance.client;

    if (sl.isRegistered<SupabaseClient>()) {
      final existing = sl<SupabaseClient>();

      // Hard guarantee: everyone must use the same instance.
      if (!identical(existing, client)) {
        // Replace to enforce single client rule and avoid "auth uses A, repos use B".
        sl.unregister<SupabaseClient>();
        sl.registerSingleton<SupabaseClient>(client);

        if (kDebugMode) {
          debugPrint(
            '[SupabaseModule] SupabaseClient mismatch detected. Replaced GetIt client with Supabase.instance.client.',
          );
        }
      } else {
        debugPrint('[DEBUG][Startup] SupabaseModule.register: SupabaseClient already registered and identical (${sw.elapsedMilliseconds}ms)');
      }
    } else {
      sl.registerSingleton<SupabaseClient>(client);
      debugPrint('[DEBUG][Startup] SupabaseModule.register: SupabaseClient registered in GetIt (${sw.elapsedMilliseconds}ms)');
    }

    // Optional: sanity ping (cheap) to detect wrong project early.
    // We do NOT fetch user data here, just a lightweight auth/session check.
    if (kDebugMode) {
      final session = client.auth.currentSession;
      debugPrint(
        '[SupabaseModule] session=${session == null ? "null" : "present"} userId=${session?.user.id ?? "n/a"}',
      );
    }
    
    sw.stop();
    debugPrint('[DEBUG][Startup] SupabaseModule.register: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
  }
}
