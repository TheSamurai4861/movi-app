import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_di_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';

/// Controller Riverpod qui reflÃƒÆ'Ã‚Â¨te en UI le profil sÃƒÆ'Ã‚Â©lectionnÃƒÆ'Ã‚Â©.
///
/// Il ÃƒÆ'Ã‚Â©coute le stream du service pour synchroniser l'ÃƒÆ'Ã‚Â©tat,
/// et expose des mÃƒÆ'Ã‚Â©thodes d'intent (select/clear).
class SelectedProfileController extends Notifier<String?> {
  StreamSubscription<String?>? _sub;

  Future<void> _lockPreviousProfileSession(String? previousId, String? nextId) async {
    final prev = previousId?.trim();
    final next = nextId?.trim();
    if (prev == null || prev.isEmpty) return;
    if (next != null && next.isNotEmpty && prev == next) return;

    final locator = ref.read(slProvider);
    if (!locator.isRegistered<ParentalSessionService>()) return;

    await locator<ParentalSessionService>().lock(prev);
  }

  /// Verrouille la session d'un profil enfant s'il est sélectionné.
  Future<void> _ensureChildProfileLocked(String? profileId) async {
    if (profileId == null || profileId.trim().isEmpty) return;

    final locator = ref.read(slProvider);
    if (!locator.isRegistered<ParentalSessionService>()) return;

    final profilesAsync = ref.read(profilesControllerProvider);
    final profiles = profilesAsync.asData?.value;
    if (profiles == null) return;

    final profile = profiles.where((p) => p.id == profileId).firstOrNull;
    if (profile == null) return;

    // Si c'est un profil enfant, verrouiller sa session
    if (profile.isKid || profile.pegiLimit != null) {
      await locator<ParentalSessionService>().lock(profileId);
    }
  }

  Future<void> _restoreActiveIptvSourceIfMissing() async {
    final appState = ref.read(appStateControllerProvider);
    if (appState.activeIptvSourceIds.isNotEmpty) return;

    final locator = ref.read(slProvider);
    if (!locator.isRegistered<IptvLocalRepository>()) return;

    final local = locator<IptvLocalRepository>();
    final accounts = await local.getAccounts();
    if (accounts.isEmpty) return;

    String? preferredId;
    if (locator.isRegistered<SelectedIptvSourcePreferences>()) {
      preferredId = locator<SelectedIptvSourcePreferences>()
          .selectedSourceId
          ?.trim();
    }

    String? nextId;
    if (preferredId != null &&
        preferredId.isNotEmpty &&
        accounts.any((a) => a.id == preferredId)) {
      nextId = preferredId;
    } else if (accounts.length == 1) {
      nextId = accounts.first.id;
    }

    if (nextId == null || nextId.trim().isEmpty) return;

    appState.setActiveIptvSources({nextId});
    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
  }

  @override
  String? build() {
    final service = ref.watch(selectedProfileServiceProvider);

    _sub?.cancel();
    _sub = service.selectedProfileIdStream.listen((id) {
      final previous = state;
      state = id;
      unawaited(_lockPreviousProfileSession(previous, id));
      // Verrouiller la session si le nouveau profil est un enfant
      unawaited(_ensureChildProfileLocked(id));
      unawaited(_restoreActiveIptvSourceIfMissing());
    });

    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    final currentId = service.selectedProfileId;
    // Vérifier et verrouiller au démarrage si le profil actuel est un enfant
    unawaited(_ensureChildProfileLocked(currentId));

    return currentId;
  }

  Future<void> selectProfile(String? profileId) async {
    final service = ref.read(selectedProfileServiceProvider);
    final previous = state;
    await service.setSelectedProfileId(profileId);
    state = service.selectedProfileId;
    await _lockPreviousProfileSession(previous, state);
    // Verrouiller la session si le nouveau profil est un enfant
    await _ensureChildProfileLocked(state);
    await _restoreActiveIptvSourceIfMissing();
  }

  Future<void> clear() => selectProfile(null);
}
