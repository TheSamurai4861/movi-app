import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/catalog_snapshot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';

/// Result of a catalog refresh that was run by an outer orchestration layer.
///
/// This domain value only describes the outcome. It does not start refreshes,
/// read storage, log, or know about provider-specific exception types.
enum CatalogRefreshOutcome {
  notRun,
  succeeded,
  timedOut,
  providerError,
  credentialsInvalid,
  empty,
}

/// Pure input for deciding whether the local catalog can support Home.
final class CatalogReadinessInput {
  const CatalogReadinessInput({
    required this.snapshot,
    this.refreshOutcome = CatalogRefreshOutcome.notRun,
  });

  /// Current local snapshot. If a blocking refresh was run, callers should pass
  /// the snapshot read after that refresh.
  final CatalogSnapshot snapshot;

  /// Optional blocking refresh result, already produced by the orchestrator.
  final CatalogRefreshOutcome refreshOutcome;
}

/// Resolves catalog readiness from local state and an optional refresh result.
///
/// This service is intentionally pure: no Flutter, no Riverpod, no repositories,
/// no storage, no network access and no logs.
final class ResolveCatalogReadiness {
  const ResolveCatalogReadiness();

  HomeReadiness call(CatalogReadinessInput input) {
    final snapshot = input.snapshot;
    if (snapshot.canOpenHome) {
      return _openableSnapshot(snapshot);
    }

    return switch (input.refreshOutcome) {
      CatalogRefreshOutcome.timedOut => SourceRecoveryRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogSyncTimeout,
        actions: <RecoveryAction>[
          RecoveryAction.retry,
          RecoveryAction.chooseSource,
        ],
      ),
      CatalogRefreshOutcome.providerError => SourceRecoveryRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogProviderError,
        actions: <RecoveryAction>[
          RecoveryAction.retry,
          RecoveryAction.chooseSource,
        ],
      ),
      CatalogRefreshOutcome.credentialsInvalid => SourceRecoveryRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogCredentialsInvalid,
        actions: <RecoveryAction>[RecoveryAction.reconnectSource],
      ),
      CatalogRefreshOutcome.succeeded ||
      CatalogRefreshOutcome.empty => SourceRecoveryRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogEmpty,
        actions: <RecoveryAction>[
          RecoveryAction.resyncSource,
          RecoveryAction.chooseSource,
        ],
      ),
      CatalogRefreshOutcome.notRun => _unrefreshedSnapshot(snapshot),
    };
  }

  HomeReadiness _openableSnapshot(CatalogSnapshot snapshot) {
    return switch (snapshot.mode) {
      CatalogMode.fresh => const HomeReady(
        reasonCode: StartupRecoveryReasonCodes.catalogSnapshotFresh,
        catalogMode: CatalogMode.fresh,
      ),
      CatalogMode.cached => HomePartial(
        reasonCode: StartupRecoveryReasonCodes.catalogSnapshotCached,
        catalogMode: CatalogMode.cached,
        actions: <RecoveryAction>[
          RecoveryAction.openHomeCached,
          RecoveryAction.resyncSource,
        ],
      ),
      CatalogMode.stale => HomePartial(
        reasonCode: StartupRecoveryReasonCodes.catalogSnapshotStale,
        catalogMode: CatalogMode.stale,
        actions: <RecoveryAction>[
          RecoveryAction.openHomeCached,
          RecoveryAction.resyncSource,
        ],
      ),
      CatalogMode.missing || CatalogMode.empty || CatalogMode.unavailable =>
        throw StateError('Catalog snapshot is not openable.'),
    };
  }

  HomeReadiness _unrefreshedSnapshot(CatalogSnapshot snapshot) {
    return switch (snapshot.mode) {
      CatalogMode.missing => CatalogPreparationRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogSnapshotMissing,
        catalogMode: CatalogMode.missing,
      ),
      CatalogMode.empty => SourceRecoveryRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogEmpty,
        actions: <RecoveryAction>[
          RecoveryAction.resyncSource,
          RecoveryAction.chooseSource,
        ],
      ),
      CatalogMode.unavailable => SourceRecoveryRequired(
        reasonCode: StartupRecoveryReasonCodes.catalogSnapshotUnavailable,
        actions: <RecoveryAction>[
          RecoveryAction.retry,
          RecoveryAction.exportLogs,
        ],
      ),
      CatalogMode.fresh ||
      CatalogMode.cached ||
      CatalogMode.stale => throw StateError('Catalog snapshot is openable.'),
    };
  }
}
