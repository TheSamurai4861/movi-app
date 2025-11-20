import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';

class FakeUserSettingsRepository implements UserSettingsRepository {
  UserProfile? stored;
  Object? saveError;
  Object? loadError;

  @override
  Future<void> save(UserProfile profile) async {
    if (saveError != null) throw saveError!;
    stored = profile;
  }

  @override
  Future<UserProfile?> load() async {
    if (loadError != null) throw loadError!;
    return stored;
  }
}

void main() {
  group('UserSettingsController', () {
    test('load sets profile and clears error', () async {
      final repo = FakeUserSettingsRepository();
      final profile = UserProfile(
        firstName: FirstName.tryParse('Ber')!,
        languageCode: LanguageCode.tryParse('fr')!,
      );
      repo.stored = profile;

      final container = ProviderContainer(
        overrides: [
          userSettingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(userSettingsControllerProvider.notifier);
      await controller.load();

      final state = container.read(userSettingsControllerProvider);
      expect(state.profile, isNotNull);
      expect(state.profile!.firstName.value, 'Ber');
      expect(state.error, isNull);
    });

    test('load on repository error sets readable error, no throw', () async {
      final repo = FakeUserSettingsRepository()..loadError = Exception('read');
      final container = ProviderContainer(
        overrides: [
          userSettingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(userSettingsControllerProvider.notifier);
      await controller.load();

      final state = container.read(userSettingsControllerProvider);
      expect(state.error, isNotNull);
      expect(state.error, 'Impossible de charger le profil');
    });

    test('save sets isSaving, updates profile on success', () async {
      final repo = FakeUserSettingsRepository();
      final container = ProviderContainer(
        overrides: [
          userSettingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(userSettingsControllerProvider.notifier);
      final profile = UserProfile(
        firstName: FirstName.tryParse('Matt')!,
        languageCode: LanguageCode.tryParse('en')!,
      );

      final ok = await controller.save(profile);
      expect(ok, isTrue);

      final state = container.read(userSettingsControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
      expect(state.profile?.firstName.value, 'Matt');
    });

    test('save on repository error sets error and returns false', () async {
      final repo = FakeUserSettingsRepository()..saveError = Exception('write');
      final container = ProviderContainer(
        overrides: [
          userSettingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(userSettingsControllerProvider.notifier);
      final profile = UserProfile(
        firstName: FirstName.tryParse('Manu')!,
        languageCode: LanguageCode.tryParse('es')!,
      );

      final ok = await controller.save(profile);
      expect(ok, isFalse);

      final state = container.read(userSettingsControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, 'Échec de la sauvegarde');
    });
  });
}