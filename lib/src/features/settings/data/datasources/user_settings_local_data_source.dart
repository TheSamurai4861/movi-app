import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';
import 'package:movi/src/features/settings/domain/value_objects/metadata_preference.dart';

class UserSettingsLocalDataSource {
  UserSettingsLocalDataSource(this._cache);
  final ContentCacheRepository _cache;

  static const _type = 'settings';
  static const _key = 'user_profile';

  Future<void> save(UserProfile profile) async {
    final payload = {
      'firstName': profile.firstName.value,
      'languageCode': profile.languageCode.value,
      'metadataPreference': profile.metadataPreference.value,
    };
    await _cache.put(key: _key, type: _type, payload: payload);
  }

  Future<UserProfile?> load() async {
    final map = await _cache.get(_key);
    if (map == null) return null;
    final fn = FirstName.tryParse((map['firstName'] as String?) ?? '');
    final lc = LanguageCode.tryParse((map['languageCode'] as String?) ?? '');
    final mp = MetadataPreference.tryParse(
      (map['metadataPreference'] as String?) ?? 'none',
    );
    if (fn == null || lc == null || mp == null) return null;
    return UserProfile(firstName: fn, languageCode: lc, metadataPreference: mp);
  }
}
