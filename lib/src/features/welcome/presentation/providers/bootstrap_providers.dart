// lib/src/features/welcome/presentation/providers/bootstrap_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/entry_journey_contracts.dart';
import 'package:movi/src/core/startup/entry_journey_orchestrator.dart';
import 'package:movi/src/core/startup/entry_journey_shadow_bridge.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/core/utils/unawaited.dart';

typedef AppLaunchRunner = Future<AppLaunchResult> Function(String reason);

final appLaunchOrchestratorProvider =
    NotifierProvider<AppLaunchOrchestrator, AppLaunchState>(
      AppLaunchOrchestrator.new,
    );

final appLaunchStateProvider = Provider<AppLaunchState>((ref) {
  return ref.watch(appLaunchOrchestratorProvider);
});

final appLaunchRunnerProvider = Provider<AppLaunchRunner>((ref) {
  return (String reason) async {
    final ts = DateTime.now().toIso8601String();
    unawaited(
      LoggingService.log('[AppLaunch] ts=$ts action=run reason=$reason'),
    );
    return ref.read(appLaunchOrchestratorProvider.notifier).run();
  };
});

final entryJourneyShadowEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).enableEntryJourneyStateModelV2;
});

final entryJourneyShadowOrchestratorProvider =
    Provider<EntryJourneyOrchestrator>((ref) {
      final sl = ref.watch(slProvider);
      final authRepository = sl<AuthRepository>();
      final profileRepository = sl<ProfileRepository>();
      final selectedProfilePreferences = sl<SelectedProfilePreferences>();
      final selectedSourcePreferences = sl<SelectedIptvSourcePreferences>();
      final iptvLocalRepository = sl<IptvLocalRepository>();
      final remoteSourcesRepository =
          sl.isRegistered<SupabaseIptvSourcesRepository>()
          ? sl<SupabaseIptvSourcesRepository>()
          : null;

      return EntryJourneyOrchestrator(
        enabled: ref.watch(entryJourneyShadowEnabledProvider),
        bridge: const LegacyTunnelStateBridge(),
        sessionContract: _SessionAuthContractAdapter(authRepository),
        profilesContract: _ProfilesContractAdapter(
          repository: profileRepository,
          selectedProfilePreferences: selectedProfilePreferences,
          accountIdProvider: () => authRepository.currentSession?.userId,
        ),
        sourcesContract: _SourcesContractAdapter(
          localRepository: iptvLocalRepository,
          selectedSourcePreferences: selectedSourcePreferences,
          remoteRepository: remoteSourcesRepository,
          accountIdProvider: () => authRepository.currentSession?.userId,
        ),
      );
    });

final entryJourneyShadowSnapshotProvider =
    FutureProvider<EntryJourneyShadowSnapshot>((ref) async {
      final legacyState = ref.watch(appLaunchStateProvider);
      final orchestrator = ref.watch(entryJourneyShadowOrchestratorProvider);
      return orchestrator.evaluate(legacyState: legacyState);
    });

final class _SessionAuthContractAdapter implements SessionAuthContract {
  const _SessionAuthContractAdapter(this._repository);

  final AuthRepository _repository;

  @override
  Future<SessionContractSnapshot> read() async {
    final session = _repository.currentSession;
    if (session == null) {
      return const SessionContractSnapshot(
        status: SessionContractStatus.unauthenticated,
        reasonCode: 'session_absent',
      );
    }
    return SessionContractSnapshot(
      status: SessionContractStatus.authenticated,
      userId: session.userId,
      reasonCode: 'session_authenticated',
    );
  }
}

final class _ProfilesContractAdapter implements ProfilesContract {
  const _ProfilesContractAdapter({
    required this.repository,
    required this.selectedProfilePreferences,
    required this.accountIdProvider,
  });

  final ProfileRepository repository;
  final SelectedProfilePreferences selectedProfilePreferences;
  final String? Function() accountIdProvider;

  @override
  Future<ProfilesContractSnapshot> read() async {
    try {
      final profiles = await repository.getProfiles(
        accountId: accountIdProvider(),
      );
      final selectedId = selectedProfilePreferences.selectedProfileId?.trim();
      final hasValidSelection =
          selectedId != null &&
          selectedId.isNotEmpty &&
          profiles.any((profile) => profile.id == selectedId);
      return ProfilesContractSnapshot(
        count: profiles.length,
        hasValidSelection: hasValidSelection,
        selectedProfileId: selectedId,
        reasonCode: profiles.isEmpty
            ? 'profile_required'
            : hasValidSelection
            ? 'profiles_ready'
            : 'profile_selection_required',
      );
    } catch (_) {
      return const ProfilesContractSnapshot(
        count: 0,
        hasValidSelection: false,
        reasonCode: 'profiles_unreadable',
      );
    }
  }
}

final class _SourcesContractAdapter implements SourcesContract {
  const _SourcesContractAdapter({
    required this.localRepository,
    required this.selectedSourcePreferences,
    required this.accountIdProvider,
    required this.remoteRepository,
  });

  final IptvLocalRepository localRepository;
  final SelectedIptvSourcePreferences selectedSourcePreferences;
  final String? Function() accountIdProvider;
  final SupabaseIptvSourcesRepository? remoteRepository;

  @override
  Future<SourcesContractSnapshot> read() async {
    try {
      final localAccounts = await localRepository.getAccounts();
      final localStalkerAccounts = await localRepository.getStalkerAccounts();
      final localIds = <String>{
        ...localAccounts.map((account) => account.id),
        ...localStalkerAccounts.map((account) => account.id),
      };

      var remoteCount = 0;
      final accountId = accountIdProvider()?.trim();
      if (localIds.isEmpty &&
          remoteRepository != null &&
          accountId != null &&
          accountId.isNotEmpty) {
        try {
          remoteCount = (await remoteRepository!.getSources(
            accountId: accountId,
          )).length;
        } catch (_) {
          remoteCount = 0;
        }
      }

      final selectedId = selectedSourcePreferences.selectedSourceId?.trim();
      final hasValidSelection =
          selectedId != null &&
          selectedId.isNotEmpty &&
          localIds.contains(selectedId);
      final totalCount = localIds.isNotEmpty ? localIds.length : remoteCount;
      final requiresManualSelection = totalCount > 1 && !hasValidSelection;

      return SourcesContractSnapshot(
        localCount: localIds.length,
        remoteCount: remoteCount,
        hasValidSelection: totalCount == 1 ? true : hasValidSelection,
        requiresManualSelection: requiresManualSelection,
        selectedSourceId: selectedId,
        reasonCode: totalCount == 0
            ? 'source_required'
            : requiresManualSelection
            ? 'source_selection_required'
            : 'sources_ready',
      );
    } catch (_) {
      return const SourcesContractSnapshot(
        localCount: 0,
        remoteCount: 0,
        hasValidSelection: false,
        requiresManualSelection: false,
        reasonCode: 'sources_unreadable',
      );
    }
  }
}
