import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_contracts.dart';

/// Stable reason codes emitted by startup recovery mapping.
abstract final class StartupRecoveryReasonCodes {
  static const bootConfigTimeout = 'boot_config_timeout';
  static const bootDependenciesTimeout = 'boot_dependencies_timeout';
  static const bootTechnicalFailure = 'boot_technical_failure';
  static const authRequired = 'auth_required';
  static const profileRequired = 'profile_required';
  static const profileSelectionRequired = 'profile_selection_required';
  static const sourceRequired = 'source_required';
  static const sourceSelectionRequired = 'source_selection_required';
  static const catalogSnapshotFresh = 'catalog_snapshot_fresh';
  static const catalogSnapshotCached = 'catalog_snapshot_cached';
  static const catalogSnapshotStale = 'catalog_snapshot_stale';
  static const catalogSnapshotMissing = 'catalog_snapshot_missing';
  static const catalogSnapshotUnavailable = 'catalog_snapshot_unavailable';
  static const catalogSyncTimeout = 'catalog_sync_timeout';
  static const catalogProviderError = 'catalog_provider_error';
  static const catalogCredentialsInvalid = 'catalog_credentials_invalid';
  static const catalogEmpty = 'catalog_empty';
  static const homeReady = 'home_ready';
  static const homeFeedFailed = 'home_feed_failed';
  static const homeIptvSectionsEmpty = 'home_iptv_sections_empty';
  static const homePartial = 'home_partial';
  static const homePreloadInvalidState = 'home_preload_invalid_state';
  static const libraryPreloadTimeout = 'library_preload_timeout';
  static const libraryPreloadFailed = 'library_preload_failed';
}

/// Actionable recovery plan derived from a technical startup failure.
final class StartupRecoveryPlan {
  const StartupRecoveryPlan({
    required this.reasonCode,
    required this.actions,
    this.message,
  }) : assert(reasonCode != ''),
       assert(actions.length > 0);

  /// Stable, log-safe reason. It must not contain secrets or raw identifiers.
  final String reasonCode;

  /// Actions the UI or caller may expose. The mapper only describes intent.
  final List<RecoveryAction> actions;

  /// Optional non-localized diagnostic summary for logs or developer details.
  final String? message;

  bool get hasPrimaryAction => actions.hasPrimaryAction;
}

/// Converts current startup failure signals into stable reason codes and
/// recovery actions.
///
/// This class is intentionally pure: no Flutter UI, no Riverpod, no logging,
/// no storage and no network access.
final class StartupRecoveryMapper {
  const StartupRecoveryMapper();

  StartupRecoveryPlan mapBootFailure(Object error) {
    final code = switch (error) {
      StartupFailure(:final code) => code,
      StartupFailureCode() => error,
      _ => StartupFailureCode.unknown,
    };

    return switch (code) {
      StartupFailureCode.configTimeout => _plan(
        StartupRecoveryReasonCodes.bootConfigTimeout,
        const [RecoveryAction.retry, RecoveryAction.exportLogs],
        message: 'Config registration timed out.',
      ),
      StartupFailureCode.dependenciesInitTimeout => _plan(
        StartupRecoveryReasonCodes.bootDependenciesTimeout,
        const [RecoveryAction.retry, RecoveryAction.exportLogs],
        message: 'Dependency initialization timed out.',
      ),
      StartupFailureCode.configInvalid ||
      StartupFailureCode.dependenciesInitFailed ||
      StartupFailureCode.flavorLoadFailed ||
      StartupFailureCode.appStateExposureFailed ||
      StartupFailureCode.loggingInitFailed ||
      StartupFailureCode.iptvSyncSetupFailed ||
      StartupFailureCode.unknown => _plan(
        StartupRecoveryReasonCodes.bootTechnicalFailure,
        const [RecoveryAction.retry, RecoveryAction.exportLogs],
        message: 'Technical boot failure: ${code.name}.',
      ),
    };
  }

  StartupRecoveryPlan mapLaunchFailure({
    required String step,
    required String? errorCode,
    required Object original,
  }) {
    final normalizedCode = _normalizeCode(errorCode);
    return switch (normalizedCode) {
      'iptvnetworktimeout' => _plan(
        StartupRecoveryReasonCodes.catalogSyncTimeout,
        const [RecoveryAction.retry, RecoveryAction.chooseSource],
        message: 'IPTV catalog sync timed out at step $step.',
      ),
      'iptvprovidererror' => _plan(
        StartupRecoveryReasonCodes.catalogProviderError,
        const [RecoveryAction.retry, RecoveryAction.chooseSource],
        message: 'IPTV provider failed at step $step.',
      ),
      'iptvemptydata' => _plan(
        StartupRecoveryReasonCodes.catalogEmpty,
        const [RecoveryAction.resyncSource, RecoveryAction.chooseSource],
        message: 'IPTV catalog is empty at step $step.',
      ),
      'librarypreloadtimeout' => _plan(
        StartupRecoveryReasonCodes.libraryPreloadTimeout,
        const [RecoveryAction.retryLibrary],
        message: 'Library preload timed out at step $step.',
      ),
      'homepreloadinvalidstate' => mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.homePreloadInvalidState,
        original: original,
      ),
      _ => _plan(
        StartupRecoveryReasonCodes.bootTechnicalFailure,
        const [RecoveryAction.retry, RecoveryAction.exportLogs],
        message: 'Launch failed at step $step.',
      ),
    };
  }

  StartupRecoveryPlan mapHomeFailure({
    required String reasonCode,
    Object? original,
  }) {
    final normalizedReason = _normalizeReason(reasonCode);
    return switch (normalizedReason) {
      StartupRecoveryReasonCodes.homeFeedFailed => _plan(
        StartupRecoveryReasonCodes.homeFeedFailed,
        const [RecoveryAction.retryHomeSections],
        message: 'Home feed failed.',
      ),
      StartupRecoveryReasonCodes.homeIptvSectionsEmpty => _plan(
        StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
        const [RecoveryAction.retryHomeSections, RecoveryAction.resyncSource],
        message: 'Home IPTV sections are empty.',
      ),
      StartupRecoveryReasonCodes.homePartial => _plan(
        StartupRecoveryReasonCodes.homePartial,
        const [RecoveryAction.retryHomeSections, RecoveryAction.retryLibrary],
        message: 'Home is partially degraded.',
      ),
      StartupRecoveryReasonCodes.libraryPreloadTimeout => _plan(
        StartupRecoveryReasonCodes.libraryPreloadTimeout,
        const [RecoveryAction.retryLibrary],
        message: 'Library preload timed out.',
      ),
      StartupRecoveryReasonCodes.libraryPreloadFailed => _plan(
        StartupRecoveryReasonCodes.libraryPreloadFailed,
        const [RecoveryAction.retryLibrary],
        message: 'Library preload failed.',
      ),
      StartupRecoveryReasonCodes.catalogSnapshotMissing => _plan(
        StartupRecoveryReasonCodes.catalogSnapshotMissing,
        const [RecoveryAction.resyncSource, RecoveryAction.chooseSource],
        message: 'Catalog snapshot is missing.',
      ),
      StartupRecoveryReasonCodes.catalogSyncTimeout => _plan(
        StartupRecoveryReasonCodes.catalogSyncTimeout,
        const [RecoveryAction.retry, RecoveryAction.chooseSource],
        message: 'Catalog sync timed out.',
      ),
      StartupRecoveryReasonCodes.catalogProviderError => _plan(
        StartupRecoveryReasonCodes.catalogProviderError,
        const [RecoveryAction.retry, RecoveryAction.chooseSource],
        message: 'Catalog provider failed.',
      ),
      StartupRecoveryReasonCodes.catalogCredentialsInvalid => _plan(
        StartupRecoveryReasonCodes.catalogCredentialsInvalid,
        const [RecoveryAction.reconnectSource],
        message: 'Catalog credentials are invalid.',
      ),
      StartupRecoveryReasonCodes.catalogEmpty => _plan(
        StartupRecoveryReasonCodes.catalogEmpty,
        const [RecoveryAction.resyncSource, RecoveryAction.chooseSource],
        message: 'Catalog is empty.',
      ),
      StartupRecoveryReasonCodes.homePreloadInvalidState ||
      'homepreloadinvalidstate' => _plan(
        StartupRecoveryReasonCodes.homePreloadInvalidState,
        const [RecoveryAction.retry, RecoveryAction.exportLogs],
        message: 'Home preload reached an invalid state.',
      ),
      _ => _plan(StartupRecoveryReasonCodes.homeFeedFailed, const [
        RecoveryAction.retryHomeSections,
      ], message: 'Home failed.'),
    };
  }

  StartupRecoveryPlan _plan(
    String reasonCode,
    List<RecoveryAction> actions, {
    String? message,
  }) {
    return StartupRecoveryPlan(
      reasonCode: reasonCode,
      actions: actions,
      message: message,
    );
  }

  String _normalizeCode(String? value) {
    return (value ?? '').trim().replaceAll('_', '').toLowerCase();
  }

  String _normalizeReason(String value) {
    return value.trim();
  }
}
