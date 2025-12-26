import 'package:movi/src/features/settings/data/datasources/user_settings_local_data_source.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/settings/data/repositories/user_settings_repository_impl.dart';

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
