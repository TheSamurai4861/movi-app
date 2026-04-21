import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/performance/data/procfs_device_capabilities_repository.dart';
import 'package:movi/src/core/performance/domain/device_capabilities_repository.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/performance/domain/performance_profile.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';
import 'package:movi/src/core/performance/domain/resolve_performance_profile.dart';

class PerformanceModule {
  static Future<void> register(GetIt sl) async {
    final sw = Stopwatch()..start();
    _logDebug('register start');

    try {
      if (!sl.isRegistered<DeviceCapabilitiesRepository>()) {
        sl.registerLazySingleton<DeviceCapabilitiesRepository>(
          () => const ProcfsDeviceCapabilitiesRepository(),
        );
        _logDebug(
          'register_repository success durationMs=${sw.elapsedMilliseconds}',
        );
      }

      final capsRepo = sl<DeviceCapabilitiesRepository>();
      _logDebug('read_capabilities start');
      final caps = await capsRepo.readCapabilities().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logWarn(
            action: 'read_capabilities',
            result: 'timeout',
            code: 'performance_capabilities_timeout',
            context: 'fallback=default_tuning',
          );
          throw TimeoutException(
            'readCapabilities timeout',
            const Duration(seconds: 5),
          );
        },
      );
      _logDebug(
        'read_capabilities success durationMs=${sw.elapsedMilliseconds}',
      );

      final profile = const ResolvePerformanceProfile()(caps);
      final tuning = PerformanceTuning.fromProfile(profile);
      _logDebug(
        'resolve_profile success profile=${tuning.profile.name} '
        'durationMs=${sw.elapsedMilliseconds}',
      );

      if (sl.isRegistered<PerformanceTuning>()) {
        sl.unregister<PerformanceTuning>();
      }
      sl.registerSingleton<PerformanceTuning>(tuning);
      if (!sl.isRegistered<PerformanceDiagnosticLogger>() &&
          sl.isRegistered<AppLogger>()) {
        sl.registerLazySingleton<PerformanceDiagnosticLogger>(
          () => PerformanceDiagnosticLogger(sl<AppLogger>()),
        );
      }

      // Appliquer la configuration au NetworkExecutor
      _configureNetworkExecutor(sl, tuning);

      if (kDebugMode && sl.isRegistered<AppLogger>()) {
        sl<AppLogger>().debug(
          '[Perf] profile=${tuning.profile.name} '
          'cpu=${caps.cpuCores} memBytes=${caps.totalMemoryBytes ?? "n/a"} '
          'tmdbMaxConcurrent=${tuning.tmdbMaxConcurrent}',
          category: 'performance',
        );
      }

      sw.stop();
      _logDebug('register complete durationMs=${sw.elapsedMilliseconds}');
    } catch (e, st) {
      sw.stop();
      _logError(
        action: 'bootstrap',
        code: 'performance_bootstrap_failed',
        context: 'type=${e.runtimeType}',
      );
      _logDebug('bootstrap error=$e');
      _logDebug('bootstrap stackTrace=$st');
      // Ne pas faire échouer le startup si PerformanceModule échoue
      // Utiliser des valeurs par défaut
      if (!sl.isRegistered<PerformanceTuning>()) {
        final defaultTuning = PerformanceTuning.fromProfile(
          PerformanceProfile.normal,
        );
        sl.registerSingleton<PerformanceTuning>(defaultTuning);
        _logWarn(
          action: 'bootstrap',
          result: 'degraded',
          code: 'performance_default_tuning_fallback',
          context: 'reason=bootstrap_failure',
        );
        if (!sl.isRegistered<PerformanceDiagnosticLogger>() &&
            sl.isRegistered<AppLogger>()) {
          sl.registerLazySingleton<PerformanceDiagnosticLogger>(
            () => PerformanceDiagnosticLogger(sl<AppLogger>()),
          );
        }

        // Appliquer la configuration par défaut au NetworkExecutor
        _configureNetworkExecutor(sl, defaultTuning);
      }
    }
  }

  /// Configure le NetworkExecutor avec les paramètres de tuning
  static void _configureNetworkExecutor(GetIt sl, PerformanceTuning tuning) {
    if (!sl.isRegistered<NetworkExecutor>()) {
      _logWarn(
        action: 'configure_network_executor',
        result: 'skipped',
        code: 'network_executor_missing',
        context: 'reason=not_registered',
      );
      return;
    }

    final executor = sl<NetworkExecutor>();
    executor.configureConcurrency('tmdb', tuning.tmdbMaxConcurrent);
    executor.configureLimiterAcquireTimeout(
      tuning.isLowResources
          ? const Duration(seconds: 30)
          : const Duration(seconds: 10),
    );
    executor.configureInflightJoinTimeout(
      tuning.isLowResources
          ? const Duration(seconds: 45)
          : const Duration(seconds: 30),
    );

    _logDebug(
      'configure_network_executor success profile=${tuning.profile.name}',
    );
  }

  static void reapplyNetworkExecutorTuning(GetIt sl) {
    if (!sl.isRegistered<PerformanceTuning>()) return;
    _configureNetworkExecutor(sl, sl<PerformanceTuning>());
  }

  static void _logDebug(String message) {
    if (!kDebugMode) return;
    debugPrint('[Performance][debug] $message');
  }

  static void _logWarn({
    required String action,
    required String result,
    String? code,
    String? context,
  }) {
    final codePart = (code == null || code.isEmpty) ? '' : ' code=$code';
    final contextPart = (context == null || context.isEmpty)
        ? ''
        : ' context=$context';
    debugPrint(
      '[Performance] action=$action result=$result$codePart$contextPart',
    );
  }

  static void _logError({
    required String action,
    required String code,
    String? context,
  }) {
    final contextPart = (context == null || context.isEmpty)
        ? ''
        : ' context=$context';
    debugPrint(
      '[Performance] action=$action result=failure code=$code$contextPart',
    );
  }
}
