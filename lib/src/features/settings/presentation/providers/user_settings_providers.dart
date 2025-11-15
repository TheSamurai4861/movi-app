import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/domain/usecases/load_user_profile.dart';
import 'package:movi/src/features/settings/domain/usecases/save_user_profile.dart';

/// Fournit le repository de réglages utilisateur depuis l'injecteur.
/// Responsabilité : composition DI uniquement (aucune logique métier ici).
final userSettingsRepositoryProvider = Provider<UserSettingsRepository>(
  (ref) => ref.watch(slProvider)<UserSettingsRepository>(),
);

/// État immuable des réglages utilisateur.
/// - [profile] : profil courant (nullable tant que non chargé)
/// - [isSaving] : vrai pendant une opération de sauvegarde
/// - [error] : message d'erreur lisible pour l'UI (nul si pas d'erreur)
@immutable
class UserSettingsState {
  const UserSettingsState({this.profile, this.isSaving = false, this.error});

  final UserProfile? profile;
  final bool isSaving;
  final String? error;

  UserSettingsState copyWith({
    UserProfile? profile,
    bool? isSaving,
    String? error, // passer explicitement null pour effacer l'erreur
  }) {
    return UserSettingsState(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// Contrôleur des réglages utilisateur basé sur Riverpod.
/// Responsabilités claires :
/// - Charger le profil au démarrage (lecture seule)
/// - Sauvegarder un profil fourni (écriture atomique, état déterministe)
/// - Exposer des transitions d'état explicites (loading/success/error)
class UserSettingsController extends Notifier<UserSettingsState> {
  late final UserSettingsRepository _repo;

  @override
  UserSettingsState build() {
    _repo = ref.watch(userSettingsRepositoryProvider);
    return const UserSettingsState();
  }

  /// Charge le profil utilisateur.
  /// - Émet une erreur lisible en cas d'échec (pas d'exception silencieuse).
  Future<void> load() async {
    try {
      final profile = await LoadUserProfile(_repo)();
      state = state.copyWith(profile: profile, error: null);
    } catch (e, st) {
      assert(() {
        debugPrint('[UserSettingsController] load() failed: $e\n$st');
        return true;
      }());
      state = state.copyWith(error: 'Impossible de charger le profil');
    }
  }

  /// Sauvegarde un profil et met à jour l'état de manière déterministe.
  /// - Retourne true si succès, false si échec (aucune exception propagée).
  /// - Évite les sauvegardes concurrentes.
  Future<bool> save(UserProfile profile) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, error: null);
    try {
      await SaveUserProfile(_repo)(profile);
      state = state.copyWith(profile: profile, isSaving: false, error: null);
      return true;
    } catch (e, st) {
      assert(() {
        debugPrint('[UserSettingsController] save() failed: $e\n$st');
        return true;
      }());
      state = state.copyWith(isSaving: false, error: 'Échec de la sauvegarde');
      return false;
    }
  }
}

/// Provider du contrôleur + état exposé à l'UI.
/// L'UI lit [UserSettingsState] et réagit aux champs [profile], [isSaving], [error].
final userSettingsControllerProvider =
    NotifierProvider<UserSettingsController, UserSettingsState>(
      UserSettingsController.new,
    );
