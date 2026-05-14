import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/presentation/boot_action_executor.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MemoryLogger logger;

  setUp(() {
    logger = _MemoryLogger();
    final locator = GetIt.instance;
    if (locator.isRegistered<AppLogger>()) {
      locator.unregister<AppLogger>();
    }
    locator.registerSingleton<AppLogger>(logger);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'launchRun action resets and starts orchestrator before showing loading route',
    (tester) async {
      final orchestrator = _FakeLaunchOrchestrator();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const _BootActionTestPage(),
          ),
          GoRoute(
            path: AppRoutePaths.welcomeSourceLoading,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Catalog loading'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLaunchOrchestratorProvider.overrideWith(() => orchestrator),
            featureFlagsProvider.overrideWithValue(
              const FeatureFlags(
                enableTelemetry: true,
                enableEntryJourneyTelemetryV2: true,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.byKey(const Key('run-boot-action')));
      await tester.pumpAndSettle();

      expect(orchestrator.resetCalls, 1);
      expect(orchestrator.runCalls, 1);
      expect(orchestrator.lastState.status, AppLaunchStatus.running);
      expect(orchestrator.lastState.phase, AppLaunchPhase.preloadCompleteHome);
      expect(find.text('Catalog loading'), findsOneWidget);

      orchestrator.complete();
      await tester.pump();
    },
  );

  testWidgets('startup contract logs keep boot action reason codes', (
    tester,
  ) async {
    final orchestrator = _FakeLaunchOrchestrator();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _BootActionReasonCodePage(),
        ),
        GoRoute(
          path: AppRoutePaths.welcomeSourceLoading,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Catalog loading'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLaunchOrchestratorProvider.overrideWith(() => orchestrator),
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(
              enableTelemetry: true,
              enableEntryJourneyTelemetryV2: true,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byKey(const Key('run-source-connected')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('run-source-selected')));
    await tester.pumpAndSettle();

    final contractLogs = logger.events
        .where((event) => event.category == 'startup_contract')
        .map((event) => event.message)
        .join('\n');

    expect(contractLogs, contains('event=boot_action_triggered'));
    expect(contractLogs, contains('reason_code=source_connected'));
    expect(contractLogs, contains('reason_code=source_selected'));
    expect(contractLogs, contains('event=source_connected'));
    expect(contractLogs, contains('event=source_selected'));
    expect(contractLogs, contains('run_reason=boot_action_retry'));
  });
}

class _BootActionTestPage extends ConsumerWidget {
  const _BootActionTestPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('run-boot-action'),
          onPressed: () {
            unawaited(
              executeBootAction(
                context,
                ref,
                const BootActionRequest(
                  intent: BootActionIntent.retry,
                  reasonCode: 'source_connected',
                  destinationOverride: AppRoutePaths.welcomeSourceLoading,
                ),
              ),
            );
          },
          child: const Text('Run boot'),
        ),
      ),
    );
  }
}

class _BootActionReasonCodePage extends ConsumerWidget {
  const _BootActionReasonCodePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('run-source-connected'),
            onPressed: () {
              unawaited(
                executeBootAction(
                  context,
                  ref,
                  const BootActionRequest(
                    intent: BootActionIntent.retry,
                    reasonCode: 'source_connected',
                    destinationOverride: '/',
                  ),
                ),
              );
            },
            child: const Text('Source connected'),
          ),
          ElevatedButton(
            key: const Key('run-source-selected'),
            onPressed: () {
              unawaited(
                executeBootAction(
                  context,
                  ref,
                  const BootActionRequest(
                    intent: BootActionIntent.retry,
                    reasonCode: 'source_selected',
                    destinationOverride: '/',
                  ),
                ),
              );
            },
            child: const Text('Source selected'),
          ),
        ],
      ),
    );
  }
}

class _FakeLaunchOrchestrator extends AppLaunchOrchestrator {
  final Completer<AppLaunchResult> _runCompleter = Completer<AppLaunchResult>();

  int resetCalls = 0;
  int runCalls = 0;
  AppLaunchState lastState = const AppLaunchState(
    status: AppLaunchStatus.success,
    phase: AppLaunchPhase.done,
    destination: BootstrapDestination.welcomeSources,
  );

  @override
  AppLaunchState build() => lastState;

  @override
  void reset() {
    resetCalls += 1;
    lastState = const AppLaunchState();
    state = lastState;
  }

  @override
  Future<AppLaunchResult> run() {
    runCalls += 1;
    lastState = const AppLaunchState(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.preloadCompleteHome,
    );
    state = lastState;
    return _runCompleter.future;
  }

  void complete() {
    if (_runCompleter.isCompleted) return;
    _runCompleter.complete(
      const AppLaunchResult(
        destination: BootstrapDestination.home,
        meta: AppLaunchMeta(),
      ),
    );
  }
}

class _MemoryLogger extends AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
