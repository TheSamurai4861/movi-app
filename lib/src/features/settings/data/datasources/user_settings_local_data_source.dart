import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';

class UserSettingsLocalDataSource {
  UserSettingsLocalDataSource(this._cache);
  final ContentCacheRepository _cache;

  static const _type = 'settings';
  static const _key = 'user_profile';

  Future<void> save(UserSettings profile) async {
    final payload = {
      'firstName': profile.firstName.value,
      'languageCode': profile.languageCode.value,
    };
    await _cache.put(key: _key, type: _type, payload: payload);
  }

  Future<UserSettings?> load() async {
    final map = await _cache.get(_key);
    if (map == null) return null;
    final fn = FirstName.tryParse((map['firstName'] as String?) ?? '');
    final lc = LanguageCode.tryParse((map['languageCode'] as String?) ?? '');

    if (fn == null || lc == null) return null;
    return UserSettings(firstName: fn, languageCode: lc);
  }
}
