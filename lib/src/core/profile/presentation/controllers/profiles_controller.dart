import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_auth_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_di_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';

/// Exception explicite: permet de distinguer "pas loggÃƒÂ©" dÃ¢â‚¬â„¢un vrai "0 profil".
class ProfilesNotAuthenticatedException implements Exception {
  const ProfilesNotAuthenticatedException();

  @override
  String toString() => 'ProfilesNotAuthenticatedException: user not logged in';
}

/// Exception explicite: le client/repo nÃ¢â‚¬â„¢est pas prÃƒÂªt (init/DI/env).
class ProfilesNotInitializedException implements Exception {
  const ProfilesNotInitializedException();

  @override
  String toString() =>
      'ProfilesNotInitializedException: Supabase client/repository not ready';
}

/// Controller des profils (liste + CRUD).
///
/// - UI consomme `profilesControllerProvider` (`AsyncValue<List<Profile>>`).
/// - DÃƒÂ©pend du contrat `ProfileRepository` via DI.
/// - Utilise `supabaseAuthStatusProvider` uniquement pour distinguer
///   "pas loggÃƒÂ©" vs "0 profil".
class ProfilesController extends AsyncNotifier<List<Profile>> {
  @override
  FutureOr<List<Profile>> build() async {
    final authStatus = ref.watch(supabaseAuthStatusProvider);

    if (authStatus == SupabaseAuthStatus.uninitialized) {
      throw const ProfilesNotInitializedException();
    }
    if (authStatus == SupabaseAuthStatus.unauthenticated) {
      throw const ProfilesNotAuthenticatedException();
    }

    final repo = ref.watch(profileRepositoryProvider);
    final profiles = await repo.getProfiles();

    await _ensureValidSelection(profiles);
    return profiles;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authStatus = ref.read(supabaseAuthStatusProvider);

      if (authStatus == SupabaseAuthStatus.uninitialized) {
        throw const ProfilesNotInitializedException();
      }
      if (authStatus == SupabaseAuthStatus.unauthenticated) {
        throw const ProfilesNotAuthenticatedException();
      }

      final repo = ref.read(profileRepositoryProvider);
      final profiles = await repo.getProfiles();

      await _ensureValidSelection(profiles);
      return profiles;
    });
  }

  Future<void> _ensureValidSelection(List<Profile> profiles) async {
    if (profiles.isEmpty) return;

    final selectedId = ref.read(selectedProfileControllerProvider);
    final hasValidSelection =
        selectedId != null && profiles.any((p) => p.id == selectedId);

    if (!hasValidSelection) {
      await ref
          .read(selectedProfileControllerProvider.notifier)
          .selectProfile(profiles.first.id);
    }
  }

  Future<Profile?> createProfile({
    required String name,
    required int color,
  }) async {
    final authStatus = ref.read(supabaseAuthStatusProvider);
    if (authStatus != SupabaseAuthStatus.authenticated) return null;

    final repo = ref.read(profileRepositoryProvider);

    try {
      final created = await repo.createProfile(name: name, color: color);

      final current = state.asData?.value ?? const <Profile>[];
      final next = [...current, created];
      state = AsyncValue.data(next);

      // Select the newly created profile (better UX).
      await ref
          .read(selectedProfileControllerProvider.notifier)
          .selectProfile(created.id);
      return created;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProfilesController] createProfile failed: $e\n$st');
      }
      return null;
    }
  }

  Future<bool> updateProfile({
    required String profileId,
    String? name,
    int? color,
    String? avatarUrl,
    bool? isKid,
    Object? pegiLimit = ProfileRepository.noChange,
  }) async {
    final authStatus = ref.read(supabaseAuthStatusProvider);
    if (authStatus != SupabaseAuthStatus.authenticated) return false;

    final repo = ref.read(profileRepositoryProvider);

    try {
      final updated = await repo.updateProfile(
        profileId: profileId,
        name: name,
        color: color,
        avatarUrl: avatarUrl,
        isKid: isKid,
        pegiLimit: pegiLimit,
      );

      final current = state.asData?.value;
      if (current == null) {
        await refresh();
        return true;
      }

      final next = [
        for (final p in current) if (p.id == profileId) updated else p,
      ];
      state = AsyncValue.data(next);
      
      // Si le profil modifié est un enfant et qu'il est actuellement sélectionné,
      // verrouiller sa session pour maintenir les restrictions
      final selectedId = ref.read(selectedProfileControllerProvider);
      if (selectedId == profileId && (updated.isKid || updated.pegiLimit != null)) {
        final locator = ref.read(slProvider);
        if (locator.isRegistered<ParentalSessionService>()) {
          await locator<ParentalSessionService>().lock(profileId);
        }
      }
      
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProfilesController] updateProfile failed: $e\n$st');
      }
      return false;
    }
  }

  Future<bool> deleteProfile(String profileId) async {
    final authStatus = ref.read(supabaseAuthStatusProvider);
    if (authStatus != SupabaseAuthStatus.authenticated) return false;

    final repo = ref.read(profileRepositoryProvider);

    try {
      await repo.deleteProfile(profileId);

      final current = state.asData?.value ?? const <Profile>[];
      final next = current.where((p) => p.id != profileId).toList(growable: false);
      state = AsyncValue.data(next);

      final selectedId = ref.read(selectedProfileControllerProvider);
      if (selectedId == profileId) {
        if (next.isEmpty) {
          await ref.read(selectedProfileControllerProvider.notifier).clear();
        } else {
          await ref
              .read(selectedProfileControllerProvider.notifier)
              .selectProfile(next.first.id);
        }
      }

      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProfilesController] deleteProfile failed: $e\n$st');
      }
      return false;
    }
  }

  Future<void> selectProfile(String profileId) async {
    await ref.read(selectedProfileControllerProvider.notifier).selectProfile(profileId);
  }
}
