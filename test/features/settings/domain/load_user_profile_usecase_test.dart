import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/domain/usecases/load_user_profile.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';

class FakeUserSettingsRepository implements UserSettingsRepository {
  UserProfile? stored;
  Object? error;

  @override
  Future<void> save(UserProfile profile) async {
    if (error != null) throw error!;
    stored = profile;
  }

  @override
  Future<UserProfile?> load() async {
    if (error != null) throw error!;
    return stored;
  }
}

void main() {
  group('LoadUserProfile', () {
    test('returns stored profile when available', () async {
      final repo = FakeUserSettingsRepository();
      final firstName = FirstName.tryParse('Ber')!;
      final language = LanguageCode.tryParse('fr')!;
      repo.stored = UserProfile(firstName: firstName, languageCode: language);

      final usecase = LoadUserProfile(repo);
      final result = await usecase();

      expect(result, isNotNull);
      expect(result!.firstName.value, 'Ber');
      expect(result.languageCode.value, 'fr');
    });

    test('rethrows repository errors', () async {
      final repo = FakeUserSettingsRepository()..error = Exception('read error');
      final usecase = LoadUserProfile(repo);

      expect(() => usecase(), throwsException);
    });
  });
}