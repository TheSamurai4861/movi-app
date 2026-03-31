import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/auth/application/services/local_data_cleanup_service.dart';
import 'package:movi/src/core/auth/data/repositories/stub_auth_repository.dart';
import 'package:movi/src/core/auth/data/repositories/supabase_auth_repository.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/logging/logger.dart';

/// DI registration for authentication.
class AuthModule {
  static void register(GetIt sl) {
    if (sl.isRegistered<AuthRepository>()) return;

    final authRepository = _buildAuthRepository(sl);
    sl.registerLazySingleton<AuthRepository>(() => authRepository);

    if (authRepository is SupabaseAuthRepository) {
      _registerLocalDataCleanupService(sl);
    }
  }

  static AuthRepository _buildAuthRepository(GetIt sl) {
    const supabaseConfig = SupabaseConfig.fromEnvironment;
    final isAuthEnabled = supabaseConfig.isConfigured;

    if (!isAuthEnabled) {
      return StubAuthRepository();
    }

    if (sl.isRegistered<SupabaseClient>()) {
      return SupabaseAuthRepository(sl<SupabaseClient>());
    }

    final allowStubFallback = _allowAuthStubFallback(sl);
    final message =
        'Supabase is configured but SupabaseClient is missing. '
        'AuthModule cannot register AuthRepository. '
        'Check SupabaseModule.register() and dependency initialization order.';

    if (!allowStubFallback) {
      throw StateError(message);
    }

    _logWarning(
      sl,
      '$message Falling back to StubAuthRepository because '
      'featureFlags.allowAuthStubFallback is enabled.',
    );
    return StubAuthRepository();
  }

  static bool _allowAuthStubFallback(GetIt sl) {
    if (!sl.isRegistered<AppConfig>()) {
      return false;
    }
    return sl<AppConfig>().featureFlags.allowAuthStubFallback;
  }

  static void _registerLocalDataCleanupService(GetIt sl) {
    if (sl.isRegistered<LocalDataCleanupService>()) return;
    if (!sl.isRegistered<Database>()) return;

    sl.registerLazySingleton<LocalDataCleanupService>(
      () => LocalDataCleanupService(db: sl<Database>(), sl: sl),
    );
  }

  static void _logWarning(GetIt sl, String message) {
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().warn(message, category: 'auth');
      return;
    }
    debugPrint('[AuthModule][WARN] $message');
  }
}
