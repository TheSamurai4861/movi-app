import 'package:flutter/foundation.dart';

import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/entry_journey_contracts.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/core/startup/entry_journey_shadow_bridge.dart';

enum EntryJourneyShadowComparison { disabled, convergent, divergent }

@immutable
final class EntryJourneyShadowSnapshot {
  const EntryJourneyShadowSnapshot({
    required this.enabled,
    required this.legacyState,
    required this.canonicalState,
    required this.session,
    required this.profiles,
    required this.sources,
    required this.comparison,
  });

  final bool enabled;
  final TunnelState legacyState;
  final TunnelState canonicalState;
  final SessionContractSnapshot session;
  final ProfilesContractSnapshot profiles;
  final SourcesContractSnapshot sources;
  final EntryJourneyShadowComparison comparison;

  bool get converges =>
      comparison == EntryJourneyShadowComparison.convergent ||
      comparison == EntryJourneyShadowComparison.disabled;
}

final class EntryJourneyOrchestrator {
  const EntryJourneyOrchestrator({
    required this.enabled,
    required this.bridge,
    required this.sessionContract,
    required this.profilesContract,
    required this.sourcesContract,
  });

  final bool enabled;
  final LegacyTunnelStateBridge bridge;
  final SessionAuthContract sessionContract;
  final ProfilesContract profilesContract;
  final SourcesContract sourcesContract;

  Future<EntryJourneyShadowSnapshot> evaluate({
    required AppLaunchState legacyState,
  }) async {
    final legacyTunnelState = bridge.fromLaunchState(legacyState);
    if (!enabled) {
      return EntryJourneyShadowSnapshot(
        enabled: false,
        legacyState: legacyTunnelState,
        canonicalState: legacyTunnelState.copyWith(isShadowMode: true),
        session: SessionContractSnapshot.unknown,
        profiles: const ProfilesContractSnapshot(
          count: 0,
          hasValidSelection: false,
          reasonCode: 'shadow_disabled',
        ),
        sources: const SourcesContractSnapshot(
          localCount: 0,
          remoteCount: 0,
          hasValidSelection: false,
          requiresManualSelection: false,
          reasonCode: 'shadow_disabled',
        ),
        comparison: EntryJourneyShadowComparison.disabled,
      );
    }

    if (legacyState.status == AppLaunchStatus.idle) {
      return EntryJourneyShadowSnapshot(
        enabled: true,
        legacyState: legacyTunnelState,
        canonicalState: legacyTunnelState.copyWith(isShadowMode: true),
        session: SessionContractSnapshot.unknown,
        profiles: const ProfilesContractSnapshot(
          count: 0,
          hasValidSelection: false,
          reasonCode: 'shadow_idle',
        ),
        sources: const SourcesContractSnapshot(
          localCount: 0,
          remoteCount: 0,
          hasValidSelection: false,
          requiresManualSelection: false,
          reasonCode: 'shadow_idle',
        ),
        comparison: EntryJourneyShadowComparison.convergent,
      );
    }

    final results = await Future.wait<Object>([
      sessionContract.read(),
      profilesContract.read(),
      sourcesContract.read(),
    ]);
    final session = results[0] as SessionContractSnapshot;
    final profiles = results[1] as ProfilesContractSnapshot;
    final sources = results[2] as SourcesContractSnapshot;

    final canonicalState = _deriveCanonicalState(
      legacyState: legacyState,
      legacyTunnelState: legacyTunnelState,
      session: session,
      profiles: profiles,
      sources: sources,
    );

    return EntryJourneyShadowSnapshot(
      enabled: true,
      legacyState: legacyTunnelState,
      canonicalState: canonicalState,
      session: session,
      profiles: profiles,
      sources: sources,
      comparison: canonicalState.stage == legacyTunnelState.stage
          ? EntryJourneyShadowComparison.convergent
          : EntryJourneyShadowComparison.divergent,
    );
  }

  TunnelState _deriveCanonicalState({
    required AppLaunchState legacyState,
    required TunnelState legacyTunnelState,
    required SessionContractSnapshot session,
    required ProfilesContractSnapshot profiles,
    required SourcesContractSnapshot sources,
  }) {
    final executionMode =
        legacyState.recovery?.kind == AppLaunchRecoveryKind.reauthRequired
        ? TunnelExecutionMode.cloud
        : legacyState.recovery?.kind ==
                  AppLaunchRecoveryKind.degradedRetryable ||
              !session.hasSession
        ? TunnelExecutionMode.localFirst
        : TunnelExecutionMode.cloud;

    var stage = legacyTunnelState.stage;
    var reasonCode = legacyTunnelState.reasonCode;

    if (legacyTunnelState.stage == TunnelStage.authRequired ||
        legacyState.recovery?.kind == AppLaunchRecoveryKind.reauthRequired) {
      stage = TunnelStage.authRequired;
      reasonCode = legacyState.recovery?.reasonCode ?? 'auth_required';
    } else if (profiles.requiresProfileSelection) {
      stage = TunnelStage.profileRequired;
      reasonCode = profiles.reasonCode;
    } else if (sources.requiresSourceSelection) {
      stage = TunnelStage.sourceRequired;
      reasonCode = sources.reasonCode;
    } else if (legacyState.criteria.isHomeReady) {
      stage = TunnelStage.readyForHome;
      reasonCode = 'home_ready';
    } else {
      stage = TunnelStage.preloadingHome;
      reasonCode = 'preloading_home';
    }

    return TunnelState(
      stage: stage,
      executionMode: executionMode,
      loadingState: legacyTunnelState.loadingState,
      reasonCode: reasonCode,
      hasSession: session.hasSession || legacyTunnelState.hasSession,
      hasSelectedProfile:
          profiles.hasValidSelection || legacyTunnelState.hasSelectedProfile,
      hasSelectedSource:
          sources.hasValidSelection || legacyTunnelState.hasSelectedSource,
      hasCatalogReady: legacyTunnelState.hasCatalogReady,
      hasHomePreloaded: legacyTunnelState.hasHomePreloaded,
      hasLibraryReady: legacyTunnelState.hasLibraryReady,
      profilesCount: profiles.count,
      sourcesCount: sources.totalCount,
      isShadowMode: true,
      legacyDestination: legacyState.destination,
      selectedProfileId: profiles.selectedProfileId,
      selectedSourceId: sources.selectedSourceId,
    );
  }
}
