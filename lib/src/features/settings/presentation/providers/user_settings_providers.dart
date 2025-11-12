import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/domain/usecases/load_user_profile.dart';
import 'package:movi/src/features/settings/domain/usecases/save_user_profile.dart';

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) => sl<UserSettingsRepository>());

class UserSettingsState {
  const UserSettingsState({this.profile, this.isSaving = false, this.error});
  final UserProfile? profile;
  final bool isSaving;
  final String? error;

  UserSettingsState copyWith({UserProfile? profile, bool? isSaving, String? error}) {
    return UserSettingsState(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class UserSettingsController extends StateNotifier<UserSettingsState> {
  UserSettingsController(this._repo) : super(const UserSettingsState()) {
    _load();
  }

  final UserSettingsRepository _repo;

  Future<void> _load() async {
    try {
      final profile = await LoadUserProfile(_repo)();
      state = state.copyWith(profile: profile);
    } catch (_) {
      // Profil optionnel → silent failure
    }
  }

  Future<bool> save(UserProfile profile) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await SaveUserProfile(_repo)(profile);
      state = state.copyWith(profile: profile, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Échec de la sauvegarde');
      return false;
    }
  }
}



final userSettingsControllerProvider = StateNotifierProvider<UserSettingsController, UserSettingsState>((ref) {
  return UserSettingsController(ref.read(userSettingsRepositoryProvider));
});