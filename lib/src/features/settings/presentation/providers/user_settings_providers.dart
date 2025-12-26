import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:movi/src/features/settings/domain/usecases/load_user_profile.dart';
import 'package:movi/src/features/settings/domain/usecases/save_user_profile.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';

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
  const UserSettingsState({
    this.profile,
    this.isSaving = false,
    this.errorKey,
  });

  final UserSettings? profile;
  final bool isSaving;
  final UserSettingsError? errorKey;

  UserSettingsState copyWith({
    UserSettings? profile,
    bool? isSaving,
    UserSettingsError? errorKey,
  }) {
    return UserSettingsState(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      errorKey: errorKey,
    );
  }
}

enum UserSettingsError {
  loadFailed,
  saveFailed,
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
      state = state.copyWith(profile: profile, errorKey: null);
    } catch (e, st) {
      assert(() {
        debugPrint('[UserSettingsController] load() failed: $e\n$st');
        return true;
      }());
      state = state.copyWith(errorKey: UserSettingsError.loadFailed);
    }
  }

  /// Sauvegarde un profil et met à jour l'état de manière déterministe.
  /// - Retourne true si succès, false si échec (aucune exception propagée).
  /// - Évite les sauvegardes concurrentes.
  Future<bool> save(UserSettings profile) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, errorKey: null);
    try {
      await SaveUserProfile(_repo)(profile);
      state = state.copyWith(
        profile: profile,
        isSaving: false,
        errorKey: null,
      );
      return true;
    } catch (e, st) {
      assert(() {
        debugPrint('[UserSettingsController] save() failed: $e\n$st');
        return true;
      }());
      state = state.copyWith(
        isSaving: false,
        errorKey: UserSettingsError.saveFailed,
      );
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

/// Provider pour obtenir l'ID utilisateur actuel.
///
/// Cet ID sert de clé logique pour les données \"scopées profil\" (favoris,
/// historique, playlists, etc.).
///
/// Règles :
/// - si un [selectedProfileId] explicite est disponible → on l'utilise tel quel
///   (trimé / normalisé) afin d'être cohérent avec le futur `profiles.id`
///   côté Supabase ;
/// - sinon on retombe sur un identifiant dérivé du profil local (firstName)
///   pour rester compatible avec les données déjà persistées ;
/// - en dernier recours on utilise 'default'.
final currentUserIdProvider = Provider<String>((ref) {
  final selectedProfileId = ref.watch(selectedProfileIdProvider);
  if (selectedProfileId != null && selectedProfileId.trim().isNotEmpty) {
    // On conserve l'ID de profil tel quel (après trim) afin de l'aligner
    // sur l'identifiant primaire de la future table `profiles` côté Supabase.
    return selectedProfileId.trim();
  }

  final state = ref.watch(userSettingsControllerProvider);
  final profile = state.profile;
  if (profile == null) return 'default';
  final firstName = profile.firstName.value.trim().toLowerCase();
  return firstName.isNotEmpty ? firstName : 'default';
});
