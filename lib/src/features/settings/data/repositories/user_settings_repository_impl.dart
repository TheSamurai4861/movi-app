import 'package:movi/src/core/storage/storage_failures.dart';

import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/data/datasources/user_settings_local_data_source.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  UserSettingsRepositoryImpl(this._local);
  final UserSettingsLocalDataSource _local;

  @override
  Future<void> save(UserProfile profile) async {
    try {
      await _local.save(profile);
    } catch (e) {
      throw const StorageWriteFailure();
    }
  }

  @override
  Future<UserProfile?> load() async {
    try {
      return await _local.load();
    } catch (e) {
      throw const StorageReadFailure();
    }
  }
}
