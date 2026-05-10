import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/catalog_snapshot_contracts.dart';
import 'package:movi/src/core/startup/domain/resolve_catalog_readiness.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';

void main() {
  const resolver = ResolveCatalogReadiness();

  test('maps a fresh snapshot to HomeReady', () {
    final readiness = resolver(
      CatalogReadinessInput(snapshot: _snapshot(CatalogMode.fresh)),
    );

    expect(readiness, isA<HomeReady>());
    final homeReady = readiness as HomeReady;
    expect(
      homeReady.reasonCode,
      StartupRecoveryReasonCodes.catalogSnapshotFresh,
    );
    expect(homeReady.catalogMode, CatalogMode.fresh);
  });

  test('maps a cached snapshot to HomePartial with background resync', () {
    final readiness = resolver(
      CatalogReadinessInput(snapshot: _snapshot(CatalogMode.cached)),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(
      partial.reasonCode,
      StartupRecoveryReasonCodes.catalogSnapshotCached,
    );
    expect(partial.catalogMode, CatalogMode.cached);
    expect(partial.actions, const [
      RecoveryAction.openHomeCached,
      RecoveryAction.resyncSource,
    ]);
  });

  test('maps a stale snapshot to HomePartial with background resync', () {
    final readiness = resolver(
      CatalogReadinessInput(snapshot: _snapshot(CatalogMode.stale)),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(partial.reasonCode, StartupRecoveryReasonCodes.catalogSnapshotStale);
    expect(partial.catalogMode, CatalogMode.stale);
    expect(partial.actions, const [
      RecoveryAction.openHomeCached,
      RecoveryAction.resyncSource,
    ]);
  });

  test('maps a missing snapshot to source recovery before refresh', () {
    final readiness = resolver(
      CatalogReadinessInput(snapshot: _snapshot(CatalogMode.missing)),
    );

    expect(readiness, isA<SourceRecoveryRequired>());
    final recovery = readiness as SourceRecoveryRequired;
    expect(
      recovery.reasonCode,
      StartupRecoveryReasonCodes.catalogSnapshotMissing,
    );
    expect(recovery.actions, const [
      RecoveryAction.resyncSource,
      RecoveryAction.chooseSource,
    ]);
  });

  test('maps an unavailable snapshot to retry and export logs', () {
    final readiness = resolver(
      CatalogReadinessInput(snapshot: _snapshot(CatalogMode.unavailable)),
    );

    expect(readiness, isA<SourceRecoveryRequired>());
    final recovery = readiness as SourceRecoveryRequired;
    expect(
      recovery.reasonCode,
      StartupRecoveryReasonCodes.catalogSnapshotUnavailable,
    );
    expect(recovery.actions, const [
      RecoveryAction.retry,
      RecoveryAction.exportLogs,
    ]);
  });

  test('maps a refresh timeout without snapshot to source recovery', () {
    final readiness = resolver(
      CatalogReadinessInput(
        snapshot: _snapshot(CatalogMode.missing),
        refreshOutcome: CatalogRefreshOutcome.timedOut,
      ),
    );

    expect(readiness, isA<SourceRecoveryRequired>());
    final recovery = readiness as SourceRecoveryRequired;
    expect(recovery.reasonCode, StartupRecoveryReasonCodes.catalogSyncTimeout);
    expect(recovery.actions, const [
      RecoveryAction.retry,
      RecoveryAction.chooseSource,
    ]);
  });

  test('maps a provider error without snapshot to source recovery', () {
    final readiness = resolver(
      CatalogReadinessInput(
        snapshot: _snapshot(CatalogMode.missing),
        refreshOutcome: CatalogRefreshOutcome.providerError,
      ),
    );

    expect(readiness, isA<SourceRecoveryRequired>());
    final recovery = readiness as SourceRecoveryRequired;
    expect(
      recovery.reasonCode,
      StartupRecoveryReasonCodes.catalogProviderError,
    );
    expect(recovery.actions, const [
      RecoveryAction.retry,
      RecoveryAction.chooseSource,
    ]);
  });

  test('maps invalid credentials to reconnect source', () {
    final readiness = resolver(
      CatalogReadinessInput(
        snapshot: _snapshot(CatalogMode.missing),
        refreshOutcome: CatalogRefreshOutcome.credentialsInvalid,
      ),
    );

    expect(readiness, isA<SourceRecoveryRequired>());
    final recovery = readiness as SourceRecoveryRequired;
    expect(
      recovery.reasonCode,
      StartupRecoveryReasonCodes.catalogCredentialsInvalid,
    );
    expect(recovery.actions, const [RecoveryAction.reconnectSource]);
  });

  test('maps successful refresh without useful content to catalog empty', () {
    final readiness = resolver(
      CatalogReadinessInput(
        snapshot: _snapshot(CatalogMode.empty),
        refreshOutcome: CatalogRefreshOutcome.succeeded,
      ),
    );

    expect(readiness, isA<SourceRecoveryRequired>());
    final recovery = readiness as SourceRecoveryRequired;
    expect(recovery.reasonCode, StartupRecoveryReasonCodes.catalogEmpty);
    expect(recovery.actions, const [
      RecoveryAction.resyncSource,
      RecoveryAction.chooseSource,
    ]);
  });

  test('keeps an openable snapshot authoritative over refresh failure', () {
    final readiness = resolver(
      CatalogReadinessInput(
        snapshot: _snapshot(CatalogMode.cached),
        refreshOutcome: CatalogRefreshOutcome.timedOut,
      ),
    );

    expect(readiness, isA<HomePartial>());
    expect(
      readiness.reasonCode,
      StartupRecoveryReasonCodes.catalogSnapshotCached,
    );
  });

  test('keeps a stale snapshot openable even when refresh fails', () {
    final readiness = resolver(
      CatalogReadinessInput(
        snapshot: _snapshot(CatalogMode.stale),
        refreshOutcome: CatalogRefreshOutcome.providerError,
      ),
    );

    expect(readiness, isA<HomePartial>());
    final partial = readiness as HomePartial;
    expect(partial.reasonCode, StartupRecoveryReasonCodes.catalogSnapshotStale);
    expect(partial.catalogMode, CatalogMode.stale);
    expect(partial.actions, contains(RecoveryAction.resyncSource));
  });
}

CatalogSnapshot _snapshot(CatalogMode mode) {
  final canOpenHome = mode.canOpenHome;
  return CatalogSnapshot(
    sourceId: 'source_1',
    exists: canOpenHome || mode == CatalogMode.empty,
    hasPlaylists: canOpenHome || mode == CatalogMode.empty,
    hasItems: canOpenHome,
    mode: mode,
    age: mode == CatalogMode.stale ? const Duration(days: 2) : null,
  );
}
