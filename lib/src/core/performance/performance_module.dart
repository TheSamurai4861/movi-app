import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/performance/data/procfs_device_capabilities_repository.dart';
import 'package:movi/src/core/performance/domain/device_capabilities_repository.dart';
import 'package:movi/src/core/performance/domain/performance_profile.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';
import 'package:movi/src/core/performance/domain/resolve_performance_profile.dart';

class PerformanceModule {
  static Future<void> register(GetIt sl) async {
    final sw = Stopwatch()..start();
    debugPrint('[DEBUG][Startup] PerformanceModule.register: START');
    
    try {
      if (!sl.isRegistered<DeviceCapabilitiesRepository>()) {
        sl.registerLazySingleton<DeviceCapabilitiesRepository>(
          () => const ProcfsDeviceCapabilitiesRepository(),
        );
        debugPrint('[DEBUG][Startup] PerformanceModule.register: DeviceCapabilitiesRepository registered (${sw.elapsedMilliseconds}ms)');
      }

      final capsRepo = sl<DeviceCapabilitiesRepository>();
      debugPrint('[DEBUG][Startup] PerformanceModule.register: reading capabilities');
      final caps = await capsRepo.readCapabilities().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[DEBUG][Startup] PerformanceModule.register: WARNING - readCapabilities timeout, using defaults');
          throw TimeoutException('readCapabilities timeout', const Duration(seconds: 5));
        },
      );
      debugPrint('[DEBUG][Startup] PerformanceModule.register: capabilities read DONE (${sw.elapsedMilliseconds}ms)');
      
      final profile = const ResolvePerformanceProfile()(caps);
      final tuning = PerformanceTuning.fromProfile(profile);
      debugPrint('[DEBUG][Startup] PerformanceModule.register: profile resolved (${sw.elapsedMilliseconds}ms)');

      if (sl.isRegistered<PerformanceTuning>()) {
        sl.unregister<PerformanceTuning>();
      }
      sl.registerSingleton<PerformanceTuning>(tuning);

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
      debugPrint('[DEBUG][Startup] PerformanceModule.register: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
    } catch (e, st) {
      sw.stop();
      debugPrint('[DEBUG][Startup] PerformanceModule.register: ERROR after ${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[DEBUG][Startup] PerformanceModule.register: Stack trace: $st');
      // Ne pas faire échouer le startup si PerformanceModule échoue
      // Utiliser des valeurs par défaut
      if (!sl.isRegistered<PerformanceTuning>()) {
        final defaultTuning = PerformanceTuning.fromProfile(PerformanceProfile.normal);
        sl.registerSingleton<PerformanceTuning>(defaultTuning);
        debugPrint('[DEBUG][Startup] PerformanceModule.register: Using default tuning as fallback');
        
        // Appliquer la configuration par défaut au NetworkExecutor
        _configureNetworkExecutor(sl, defaultTuning);
      }
    }
  }

  /// Configure le NetworkExecutor avec les paramètres de tuning
  static void _configureNetworkExecutor(GetIt sl, PerformanceTuning tuning) {
    if (!sl.isRegistered<NetworkExecutor>()) {
      debugPrint('[DEBUG][Startup] PerformanceModule: NetworkExecutor not registered, skipping configuration');
      return;
    }
    
    final executor = sl<NetworkExecutor>();
    executor.configureConcurrency('tmdb', tuning.tmdbMaxConcurrent);
    executor.configureLimiterAcquireTimeout(
      tuning.isLowResources ? const Duration(seconds: 30) : const Duration(seconds: 10),
    );
    executor.configureInflightJoinTimeout(
      tuning.isLowResources ? const Duration(seconds: 45) : const Duration(seconds: 15),
    );
    
    debugPrint('[DEBUG][Startup] PerformanceModule: NetworkExecutor configured (profile=${tuning.profile.name})');
  }
}
