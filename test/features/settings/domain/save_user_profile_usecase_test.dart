import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/domain/usecases/save_user_profile.dart';
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
  group('SaveUserProfile', () {
    test('persists provided profile into repository', () async {
      final repo = FakeUserSettingsRepository();
      final usecase = SaveUserProfile(repo);

      final firstName = FirstName.tryParse('Matt')!;
      final language = LanguageCode.tryParse('en')!;
      final profile = UserProfile(firstName: firstName, languageCode: language);

      await usecase(profile);

      expect(repo.stored, isNotNull);
      expect(repo.stored!.firstName.value, 'Matt');
      expect(repo.stored!.languageCode.value, 'en');
    });

    test('rethrows repository errors', () async {
      final repo = FakeUserSettingsRepository()..error = Exception('write error');
      final usecase = SaveUserProfile(repo);
      final profile = UserProfile(
        firstName: FirstName.tryParse('Ber')!,
        languageCode: LanguageCode.tryParse('fr')!,
      );

      expect(() => usecase(profile), throwsException);
    });
  });
}