import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/auth/application/services/local_data_cleanup_service.dart';
import 'package:movi/src/core/auth/data/repositories/stub_auth_repository.dart';
import 'package:movi/src/core/auth/data/repositories/supabase_auth_repository.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/config/config.dart';

/// DI registration for authentication.
class AuthModule {
  static void register(GetIt sl) {
    if (sl.isRegistered<AuthRepository>()) return;

    // Keep DI aligned with what the UI considers "auth enabled".
    const config = SupabaseConfig.fromEnvironment;
    final isAuthEnabled = config.isConfigured;

    if (!isAuthEnabled) {
      sl.registerLazySingleton<AuthRepository>(() => StubAuthRepository());
      return;
    }

    // Auth is enabled by config, so we expect a SupabaseClient.
    // If it's missing, we still fallback to Stub to avoid crashes,
    // but this indicates a composition-root registration issue.
    if (!sl.isRegistered<SupabaseClient>()) {
      sl.registerLazySingleton<AuthRepository>(() => StubAuthRepository());
      return;
    }

    sl.registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(sl<SupabaseClient>()),
    );

    // Register local data cleanup service
    if (!sl.isRegistered<LocalDataCleanupService>()) {
      sl.registerLazySingleton<LocalDataCleanupService>(
        () => LocalDataCleanupService(db: sl<Database>(), sl: sl),
      );
    }
  }
}
