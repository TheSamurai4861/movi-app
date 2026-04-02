import 'package:movi/src/core/startup/domain/startup_contracts.dart';

/// Pure orchestrator: runs the startup sequence using ports.
final class AppStartupOrchestrator {
  AppStartupOrchestrator({
    required StartupTelemetryPort telemetry,
    required FlavorPort flavorPort,
    required ConfigPort configPort,
    required DependenciesPort dependenciesPort,
    required AppStateControllerPort appStateControllerPort,
    required AppStateExposurePort appStateExposurePort,
    required LoggingPort loggingPort,
    required IptvSyncPort iptvSyncPort,
    required bool requireTmdbKey,
    Duration configTimeout = const Duration(seconds: 30),
    Duration dependenciesTimeout = const Duration(seconds: 45),
  }) : _telemetry = telemetry,
       _flavorPort = flavorPort,
       _configPort = configPort,
       _dependenciesPort = dependenciesPort,
       _appStateControllerPort = appStateControllerPort,
       _appStateExposurePort = appStateExposurePort,
       _loggingPort = loggingPort,
       _iptvSyncPort = iptvSyncPort,
       _requireTmdbKey = requireTmdbKey,
       _configTimeout = configTimeout,
       _dependenciesTimeout = dependenciesTimeout;

  final StartupTelemetryPort _telemetry;
  final FlavorPort _flavorPort;
  final ConfigPort _configPort;
  final DependenciesPort _dependenciesPort;
  final AppStateControllerPort _appStateControllerPort;
  final AppStateExposurePort _appStateExposurePort;
  final LoggingPort _loggingPort;
  final IptvSyncPort _iptvSyncPort;
  final bool _requireTmdbKey;
  final Duration _configTimeout;
  final Duration _dependenciesTimeout;

  Future<StartupResult> run({
    required String Function() localeProvider,
    required void Function(void Function()) onDispose,
  }) async {
    final sw = Stopwatch()..start();
    var phase = StartupPhase.init;
    try {
      _telemetry.info('feature=startup action=bootstrap result=progress phase=init');

      phase = StartupPhase.loadFlavor;
      final flavor = _flavorPort.loadFlavor();
      _telemetry.info(
        'feature=startup action=bootstrap result=progress phase=loadFlavor',
      );

      phase = StartupPhase.registerConfig;
      final config = await _configPort
          .registerConfig(flavor: flavor, requireTmdbKey: _requireTmdbKey)
          .timeout(
            _configTimeout,
            onTimeout: () => throw const _StartupTimeout(StartupPhase.registerConfig),
          );
      _telemetry.info(
        'feature=startup action=bootstrap result=progress phase=registerConfig',
      );

      phase = StartupPhase.initDependencies;
      await _dependenciesPort
          .initDependencies(appConfig: config, localeProvider: localeProvider)
          .timeout(
            _dependenciesTimeout,
            onTimeout: () => throw const _StartupTimeout(StartupPhase.initDependencies),
          );
      _telemetry.info(
        'feature=startup action=bootstrap result=progress phase=initDependencies',
      );

      phase = StartupPhase.exposeAppState;
      _appStateExposurePort.exposeAppStateController(
        _appStateControllerPort.controller,
      );
      _telemetry.info(
        'feature=startup action=bootstrap result=progress phase=exposeAppState',
      );

      phase = StartupPhase.loggingReady;
      _loggingPort.register();
      _loggingPort.logStartupProgress('logging_ready');

      phase = StartupPhase.iptvSyncSetup;
      _iptvSyncPort.setupIntervalFromPreferences();
      _iptvSyncPort.bindIntervalUpdates();
      _iptvSyncPort.stopOnDispose(onDispose);

      phase = StartupPhase.done;
      sw.stop();
      _loggingPort.logStartupSuccess(durationMs: sw.elapsedMilliseconds);
      _telemetry.info(
        'feature=startup action=bootstrap result=success durationMs=${sw.elapsedMilliseconds}',
      );
      return StartupResult.ready(durationMs: sw.elapsedMilliseconds);
    } catch (e, st) {
      sw.stop();

      final failure = StartupFailure(
        code: _mapFailureCode(phase, e),
        phase: phase,
        message: 'startup_failed phase=${phase.name} type=${e.runtimeType}',
        original: e,
      );

      _telemetry.error(
        'feature=startup action=bootstrap result=failure phase=${phase.name} '
        'code=${failure.code.name}',
        error: e,
        stackTrace: st,
      );

      // Logging port may or may not be ready; it must be safe to call.
      _loggingPort.logStartupFailure(
        code: failure.code,
        phase: failure.phase,
        message: failure.message,
      );

      // SafeMode is our fail-safe path: keep the app alive and actionable.
      return StartupResult.safeMode(durationMs: sw.elapsedMilliseconds, failure: failure);
    }
  }

  StartupFailureCode _mapFailureCode(StartupPhase phase, Object error) {
    if (error is _StartupTimeout) {
      switch (error.phase) {
        case StartupPhase.registerConfig:
          return StartupFailureCode.configTimeout;
        case StartupPhase.initDependencies:
          return StartupFailureCode.dependenciesInitTimeout;
        case StartupPhase.init:
        case StartupPhase.loadFlavor:
        case StartupPhase.exposeAppState:
        case StartupPhase.loggingReady:
        case StartupPhase.iptvSyncSetup:
        case StartupPhase.done:
          return StartupFailureCode.unknown;
      }
    }
    switch (phase) {
      case StartupPhase.loadFlavor:
        return StartupFailureCode.flavorLoadFailed;
      case StartupPhase.registerConfig:
        return StartupFailureCode.configInvalid;
      case StartupPhase.initDependencies:
        return StartupFailureCode.dependenciesInitFailed;
      case StartupPhase.iptvSyncSetup:
        return StartupFailureCode.iptvSyncSetupFailed;
      case StartupPhase.init:
      case StartupPhase.exposeAppState:
      case StartupPhase.loggingReady:
      case StartupPhase.done:
        return StartupFailureCode.unknown;
    }
  }
}

final class _StartupTimeout implements Exception {
  const _StartupTimeout(this.phase);
  final StartupPhase phase;
}

