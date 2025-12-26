import 'package:flutter/foundation.dart';

import 'package:movi/src/core/config/models/app_config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/adapters/console_logger.dart';
import 'package:movi/src/core/logging/adapters/file_logger.dart';
import 'package:movi/src/core/logging/level_filtering_logger.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/rate_limiting_logger.dart';
import 'package:movi/src/core/logging/sampling_logger.dart';

class LoggingModule {
  static void register() {
    if (sl.isRegistered<AppLogger>()) return;
    sl.registerLazySingleton<AppLogger>(() {
      final cfg = sl<AppConfig>().logging;
      AppLogger base;
      if (!kIsWeb && cfg.enableFile) {
        base = FileLogger(
          flushInterval: cfg.flushInterval,
          maxFileSizeBytes: cfg.maxFileSizeBytes,
          maxFiles: cfg.maxFiles,
          alsoConsole: cfg.enableConsole,
          rotateDaily: cfg.rotateDaily,
          maxDailyFiles: cfg.maxDailyFiles,
          compressOld: cfg.compressOld,
          bufferCapacity: cfg.bufferCapacity,
          dropOldest: cfg.dropOldest,
          extraSensitiveKeys: cfg.sensitiveKeys,
        );
      } else {
        final printer = cfg.enableConsole ? null : (_emptyPrint);
        base = ConsoleLogger(
          printer: printer,
          extraSensitiveKeys: cfg.sensitiveKeys,
        );
      }
      AppLogger logger = LevelFilteringLogger(
        base,
        cfg.minLevel,
        cfg.minLevelByCategory,
      );
      logger = SamplingLogger(
        logger,
        samplingByLevel: cfg.samplingByLevel,
        samplingByCategory: cfg.samplingByCategory,
      );
      logger = RateLimitingLogger(
        logger,
        defaultPerMinute: cfg.defaultRateLimitPerMinute,
        perCategory: cfg.rateLimitPerCategory,
        exposeMetrics: cfg.exposeMetrics,
        metricsInterval: cfg.metricsInterval,
      );
      return logger;
    });
  }

  static Future<void> dispose() async {
    if (!sl.isRegistered<AppLogger>()) return;
    final logger = sl<AppLogger>();
    if (logger is LoggerLifecycle) {
      await (logger as LoggerLifecycle).dispose();
    }
    sl.unregister<AppLogger>();
  }
}

void _emptyPrint(String _) {}
