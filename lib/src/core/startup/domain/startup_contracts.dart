// Contracts and data model for the `core/startup` L1 bootstrap.
//
// This file is intentionally framework-agnostic: no Flutter, no GetIt, no SDKs.

enum StartupPhase {
  init,
  loadFlavor,
  registerConfig,
  initDependencies,
  exposeAppState,
  loggingReady,
  iptvSyncSetup,
  done,
}

enum StartupOutcomeKind {
  /// Normal nominal path: the app can continue its launch flow.
  ready,

  /// Degraded safe path: startup succeeded enough to keep the app running, but
  /// the app must remain in a reduced capability mode (fail-safe).
  safeMode,
}

enum StartupFailureCode {
  unknown,
  flavorLoadFailed,
  configInvalid,
  configTimeout,
  dependenciesInitFailed,
  dependenciesInitTimeout,
  appStateExposureFailed,
  loggingInitFailed,
  iptvSyncSetupFailed,
}

extension StartupFailureCodeReasonCode on StartupFailureCode {
  String get reasonCode => switch (this) {
    StartupFailureCode.unknown => 'startup_unknown_failure',
    StartupFailureCode.flavorLoadFailed => 'startup_flavor_load_failed',
    StartupFailureCode.configInvalid => 'startup_config_invalid',
    StartupFailureCode.configTimeout => 'startup_config_timeout',
    StartupFailureCode.dependenciesInitFailed =>
      'startup_dependencies_init_failed',
    StartupFailureCode.dependenciesInitTimeout =>
      'startup_dependencies_init_timeout',
    StartupFailureCode.appStateExposureFailed =>
      'startup_app_state_exposure_failed',
    StartupFailureCode.loggingInitFailed => 'startup_logging_init_failed',
    StartupFailureCode.iptvSyncSetupFailed => 'startup_iptv_sync_setup_failed',
  };
}

final class StartupFailure {
  StartupFailure({
    required this.code,
    required this.phase,
    required this.message,
    required this.original,
    String? reasonCode,
  }) : reasonCode = reasonCode ?? code.reasonCode;

  final StartupFailureCode code;
  final StartupPhase phase;
  final String message;
  final Object original;
  final String reasonCode;
}

final class StartupResult {
  const StartupResult._({
    required this.kind,
    required this.durationMs,
    required this.reasonCode,
    this.failure,
  });

  factory StartupResult.ready({
    required int durationMs,
    String reasonCode = 'startup_ready',
  }) {
    return StartupResult._(
      kind: StartupOutcomeKind.ready,
      durationMs: durationMs,
      reasonCode: reasonCode,
    );
  }

  factory StartupResult.safeMode({
    required int durationMs,
    required StartupFailure failure,
    String? reasonCode,
  }) {
    return StartupResult._(
      kind: StartupOutcomeKind.safeMode,
      durationMs: durationMs,
      reasonCode: reasonCode ?? failure.reasonCode,
      failure: failure,
    );
  }

  final StartupOutcomeKind kind;
  final int durationMs;
  final String reasonCode;

  /// Present only when `kind == safeMode`.
  final StartupFailure? failure;
}

abstract interface class StartupTelemetryPort {
  void info(String message);
  void warn(String message);
  void error(String message, {Object? error, StackTrace? stackTrace});
}

abstract interface class FlavorPort {
  /// Returns an opaque flavor object. The orchestrator treats it as data.
  Object loadFlavor();
}

abstract interface class ConfigPort {
  /// Register config and return an opaque config object.
  Future<Object> registerConfig({
    required Object flavor,
    required bool requireTmdbKey,
  });
}

abstract interface class DependenciesPort {
  Future<void> initDependencies({
    required Object appConfig,
    required String Function() localeProvider,
  });
}

abstract interface class AppStateExposurePort {
  void exposeAppStateController(Object controller);
}

abstract interface class AppStateControllerPort {
  Object get controller;
}

abstract interface class LoggingPort {
  void register();
  void logStartupProgress(String message);
  void logStartupSuccess({required int durationMs, required String reasonCode});
  void logStartupFailure({
    required StartupFailureCode code,
    required StartupPhase phase,
    required String message,
    required String reasonCode,
  });
}

abstract interface class IptvSyncPort {
  void setupIntervalFromPreferences();
  void bindIntervalUpdates();
  void stopOnDispose(void Function(void Function()) onDispose);
}
