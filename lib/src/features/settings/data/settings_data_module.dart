import 'package:movi/src/features/settings/data/datasources/user_settings_local_data_source.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';

import '../../../core/di/injector.dart';
import '../../../core/storage/repositories/content_cache_repository.dart';
import 'repositories/user_settings_repository_impl.dart';

class SettingsDataModule {
  static void register() {
    if (!sl.isRegistered<UserSettingsLocalDataSource>()) {
      sl.registerLazySingleton<UserSettingsLocalDataSource>(
        () => UserSettingsLocalDataSource(sl<ContentCacheRepository>()),
      );
    }
    if (!sl.isRegistered<UserSettingsRepository>()) {
      sl.registerLazySingleton<UserSettingsRepository>(
        () => UserSettingsRepositoryImpl(sl<UserSettingsLocalDataSource>()),
      );
    }
  }
}