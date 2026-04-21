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
    _logDebug('register start');

    final config = SupabaseConfig.fromEnvironment;

    // Vérifier si Supabase est configuré avant de valider
    if (!config.isConfigured) {
      _logWarn(
        action: 'bootstrap',
        result: 'skipped',
        code: 'supabase_not_configured',
        context: 'reason=missing_env',
      );
      _logDebug(
        'register skipped reason=missing_env durationMs=${sw.elapsedMilliseconds}',
      );
      sw.stop();
      return;
    }

    // Valider la configuration
    try {
      config.ensureValid();
      _logDebug(
        'validate_config success durationMs=${sw.elapsedMilliseconds}',
      );
    } catch (e, st) {
      sw.stop();
      _logError(
        action: 'validate_config',
        code: 'supabase_config_invalid',
        context: 'type=${e.runtimeType}',
      );
      _logDebug('validate_config error=$e');
      _logDebug('validate_config stackTrace=$st');
      rethrow;
    }

    if (kDebugMode) {
      _logDebug('config=${config.toString()}');
      _logDebug('note=verify_supabase_url_matches_expected_project');
    }

    // Initialize Supabase once (idempotent guard).
    if (!_initialized) {
      _logDebug('initialize start');
      try {
        await Supabase.initialize(
          url: config.supabaseUrl.trim(),
          anonKey: config.supabaseAnonKey.trim(),
        );
        _initialized = true;
        _logDebug('initialize success durationMs=${sw.elapsedMilliseconds}');
      } catch (e, st) {
        sw.stop();
        _logError(
          action: 'initialize',
          code: 'supabase_initialize_failed',
          context: 'type=${e.runtimeType}',
        );
        _logDebug('initialize error=$e');
        _logDebug('initialize stackTrace=$st');
        rethrow;
      }
    } else {
      _logDebug(
        'initialize skipped reason=already_initialized durationMs=${sw.elapsedMilliseconds}',
      );
    }

    // Register a SINGLE SupabaseClient into GetIt.
    _logDebug('register_client start');
    final client = Supabase.instance.client;

    if (sl.isRegistered<SupabaseClient>()) {
      final existing = sl<SupabaseClient>();

      // Hard guarantee: everyone must use the same instance.
      if (!identical(existing, client)) {
        // Replace to enforce single client rule and avoid "auth uses A, repos use B".
        sl.unregister<SupabaseClient>();
        sl.registerSingleton<SupabaseClient>(client);

        _logWarn(
          action: 'register_client',
          result: 'degraded',
          code: 'supabase_client_mismatch_replaced',
          context: 'strategy=replace_getit_instance',
        );
      } else {
        _logDebug(
          'register_client skipped reason=already_registered_identical '
          'durationMs=${sw.elapsedMilliseconds}',
        );
      }
    } else {
      sl.registerSingleton<SupabaseClient>(client);
      _logDebug(
        'register_client success durationMs=${sw.elapsedMilliseconds}',
      );
    }

    // Optional: sanity ping (cheap) to detect wrong project early.
    // We do NOT fetch user data here, just a lightweight auth/session check.
    if (kDebugMode) {
      final session = client.auth.currentSession;
      _logDebug(
        'session=${session == null ? "null" : "present"} '
        'userId=${session?.user.id ?? "n/a"}',
      );
    }

    sw.stop();
    _logDebug('register complete durationMs=${sw.elapsedMilliseconds}');
  }

  static void _logDebug(String message) {
    if (!kDebugMode) return;
    debugPrint('[Supabase][debug] $message');
  }

  static void _logWarn({
    required String action,
    required String result,
    String? code,
    String? context,
  }) {
    final codePart = (code == null || code.isEmpty) ? '' : ' code=$code';
    final contextPart = (context == null || context.isEmpty)
        ? ''
        : ' context=$context';
    debugPrint(
      '[Supabase] action=$action result=$result$codePart$contextPart',
    );
  }

  static void _logError({
    required String action,
    required String code,
    String? context,
  }) {
    final contextPart = (context == null || context.isEmpty)
        ? ''
        : ' context=$context';
    debugPrint(
      '[Supabase] action=$action result=failure code=$code$contextPart',
    );
  }
}
