import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/domain/app_startup_orchestrator.dart';
import 'package:movi/src/core/startup/domain/startup_contracts.dart';

final class _TelemetryFake implements StartupTelemetryPort {
  final List<String> events = [];

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    events.add('error:$message');
  }

  @override
  void info(String message) {
    events.add('info:$message');
  }

  @override
  void warn(String message) {
    events.add('warn:$message');
  }
}

final class _FlavorFake implements FlavorPort {
  _FlavorFake([this.throwOnLoad]);
  final Object? throwOnLoad;

  @override
  Object loadFlavor() {
    final t = throwOnLoad;
    if (t != null) throw t;
    return Object();
  }
}

final class _ConfigFake implements ConfigPort {
  _ConfigFake([this.throwOnRegister]);
  final Object? throwOnRegister;
  Duration? delay;

  @override
  Future<Object> registerConfig({
    required Object flavor,
    required bool requireTmdbKey,
  }) async {
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    final t = throwOnRegister;
    if (t != null) throw t;
    return Object();
  }
}

final class _DepsFake implements DependenciesPort {
  _DepsFake({this.throwOnInit});
  final Object? throwOnInit;
  Duration? delay;

  @override
  Future<void> initDependencies({
    required Object appConfig,
    required String Function() localeProvider,
  }) async {
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    final t = throwOnInit;
    if (t != null) throw t;
  }
}

final class _AppStateControllerFake implements AppStateControllerPort {
  @override
  Object get controller => Object();
}

final class _ExposeFake implements AppStateExposurePort {
  int calls = 0;

  @override
  void exposeAppStateController(Object controller) {
    calls += 1;
  }
}

final class _LoggingFake implements LoggingPort {
  final List<String> events = [];
  Object? throwOnRegister;

  @override
  void register() {
    events.add('register');
    final t = throwOnRegister;
    if (t != null) throw t;
  }

  @override
  void logStartupFailure({
    required StartupFailureCode code,
    required StartupPhase phase,
    required String message,
  }) {
    events.add('failure:${code.name}:${phase.name}');
  }

  @override
  void logStartupProgress(String message) {
    events.add('progress:$message');
  }

  @override
  void logStartupSuccess({required int durationMs}) {
    events.add('success');
  }
}

final class _IptvSyncFake implements IptvSyncPort {
  bool intervalSetup = false;
  bool bound = false;
  bool stopHooked = false;
  Object? throwOnSetup;

  @override
  void bindIntervalUpdates() {
    bound = true;
  }

  @override
  void setupIntervalFromPreferences() {
    intervalSetup = true;
    final t = throwOnSetup;
    if (t != null) throw t;
  }

  @override
  void stopOnDispose(void Function(void Function()) onDispose) {
    stopHooked = true;
    onDispose(() {});
  }
}

void main() {
  test('returns ready on nominal path', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake();

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(),
      configPort: _ConfigFake(),
      dependenciesPort: _DepsFake(),
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.ready);
    expect(result.failure, isNull);
    expect(exposure.calls, 1);
    expect(logging.events, contains('success'));
    expect(iptv.intervalSetup, isTrue);
    expect(iptv.bound, isTrue);
    expect(iptv.stopHooked, isTrue);
  });

  test('returns safeMode when flavor loading fails', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake();

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(StateError('flavor broken')),
      configPort: _ConfigFake(),
      dependenciesPort: _DepsFake(),
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.safeMode);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, StartupFailureCode.flavorLoadFailed);
    expect(result.failure!.phase, StartupPhase.loadFlavor);
  });

  test('returns safeMode when config registration fails', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake();

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(),
      configPort: _ConfigFake(StateError('config broken')),
      dependenciesPort: _DepsFake(),
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.safeMode);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, StartupFailureCode.configInvalid);
    expect(result.failure!.phase, StartupPhase.registerConfig);
  });

  test('returns safeMode when dependencies init fails', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake();

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(),
      configPort: _ConfigFake(),
      dependenciesPort: _DepsFake(throwOnInit: StateError('deps broken')),
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.safeMode);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, StartupFailureCode.dependenciesInitFailed);
    expect(result.failure!.phase, StartupPhase.initDependencies);
    // Should not proceed to sync setup if deps are broken.
    expect(iptv.intervalSetup, isFalse);
    expect(exposure.calls, 0);
    expect(logging.events.any((e) => e.startsWith('failure:')), isTrue);
  });

  test('returns safeMode when IPTV setup fails', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake()..throwOnSetup = StateError('iptv broken');

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(),
      configPort: _ConfigFake(),
      dependenciesPort: _DepsFake(),
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.safeMode);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, StartupFailureCode.iptvSyncSetupFailed);
    expect(result.failure!.phase, StartupPhase.iptvSyncSetup);
  });

  test('returns safeMode when config times out', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake();
    final config = _ConfigFake()..delay = const Duration(milliseconds: 50);

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(),
      configPort: config,
      dependenciesPort: _DepsFake(),
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
      configTimeout: const Duration(milliseconds: 1),
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.safeMode);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, StartupFailureCode.configTimeout);
    expect(result.failure!.phase, StartupPhase.registerConfig);
  });

  test('returns safeMode when dependencies init times out', () async {
    final telemetry = _TelemetryFake();
    final exposure = _ExposeFake();
    final logging = _LoggingFake();
    final iptv = _IptvSyncFake();
    final deps = _DepsFake()..delay = const Duration(milliseconds: 50);

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: _FlavorFake(),
      configPort: _ConfigFake(),
      dependenciesPort: deps,
      appStateControllerPort: _AppStateControllerFake(),
      appStateExposurePort: exposure,
      loggingPort: logging,
      iptvSyncPort: iptv,
      requireTmdbKey: false,
      dependenciesTimeout: const Duration(milliseconds: 1),
    );

    final result = await orchestrator.run(
      localeProvider: () => 'en-US',
      onDispose: (_) {},
    );

    expect(result.kind, StartupOutcomeKind.safeMode);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, StartupFailureCode.dependenciesInitTimeout);
    expect(result.failure!.phase, StartupPhase.initDependencies);
  });
}

