import 'package:movi/src/core/logging/logger.dart';

class LoggingConfig {
  const LoggingConfig({
    this.minLevel = LogLevel.info,
    this.enableConsole = true,
    this.enableFile = true,
    this.flushInterval = const Duration(milliseconds: 500),
    this.maxFileSizeBytes = 5 * 1024 * 1024,
    this.maxFiles = 5,
    this.rotateDaily = false,
    this.maxDailyFiles = 5,
    this.compressOld = false,
    this.bufferCapacity = 2000,
    this.dropOldest = true,
    this.samplingByLevel = const {},
    this.samplingByCategory = const {},
    this.defaultRateLimitPerMinute = 0,
    this.rateLimitPerCategory = const {},
    this.exposeMetrics = false,
    this.metricsInterval = const Duration(minutes: 1),
    this.minLevelByCategory = const {},
  });

  final LogLevel minLevel;
  final bool enableConsole;
  final bool enableFile;
  final Duration flushInterval;
  final int maxFileSizeBytes;
  final int maxFiles;
  final bool rotateDaily;
  final int maxDailyFiles;
  final bool compressOld;
  final int bufferCapacity;
  final bool dropOldest;
  final Map<LogLevel, double> samplingByLevel;
  final Map<String, double> samplingByCategory;
  final int defaultRateLimitPerMinute;
  final Map<String, int> rateLimitPerCategory;
  final bool exposeMetrics;
  final Duration metricsInterval;
  final Map<String, LogLevel> minLevelByCategory;

  LoggingConfig copyWith({
    LogLevel? minLevel,
    bool? enableConsole,
    bool? enableFile,
    Duration? flushInterval,
    int? maxFileSizeBytes,
    int? maxFiles,
    bool? rotateDaily,
    int? maxDailyFiles,
    bool? compressOld,
    int? bufferCapacity,
    bool? dropOldest,
    Map<LogLevel, double>? samplingByLevel,
    Map<String, double>? samplingByCategory,
    int? defaultRateLimitPerMinute,
    Map<String, int>? rateLimitPerCategory,
    bool? exposeMetrics,
    Duration? metricsInterval,
    Map<String, LogLevel>? minLevelByCategory,
  }) {
    return LoggingConfig(
      minLevel: minLevel ?? this.minLevel,
      enableConsole: enableConsole ?? this.enableConsole,
      enableFile: enableFile ?? this.enableFile,
      flushInterval: flushInterval ?? this.flushInterval,
      maxFileSizeBytes: maxFileSizeBytes ?? this.maxFileSizeBytes,
      maxFiles: maxFiles ?? this.maxFiles,
      rotateDaily: rotateDaily ?? this.rotateDaily,
      maxDailyFiles: maxDailyFiles ?? this.maxDailyFiles,
      compressOld: compressOld ?? this.compressOld,
      bufferCapacity: bufferCapacity ?? this.bufferCapacity,
      dropOldest: dropOldest ?? this.dropOldest,
      samplingByLevel: samplingByLevel ?? this.samplingByLevel,
      samplingByCategory: samplingByCategory ?? this.samplingByCategory,
      defaultRateLimitPerMinute:
          defaultRateLimitPerMinute ?? this.defaultRateLimitPerMinute,
      rateLimitPerCategory: rateLimitPerCategory ?? this.rateLimitPerCategory,
      exposeMetrics: exposeMetrics ?? this.exposeMetrics,
      metricsInterval: metricsInterval ?? this.metricsInterval,
      minLevelByCategory: minLevelByCategory ?? this.minLevelByCategory,
    );
  }

  @override
  String toString() {
    return 'LoggingConfig(minLevel: ${minLevel.name}, console: $enableConsole, file: $enableFile, flush: ${flushInterval.inMilliseconds}ms, maxSize: $maxFileSizeBytes, maxFiles: $maxFiles, rotateDaily: $rotateDaily, maxDailyFiles: $maxDailyFiles, compressOld: $compressOld, bufferCapacity: $bufferCapacity, dropOldest: $dropOldest, samplingByLevel: $samplingByLevel, samplingByCategory: $samplingByCategory, defaultRate: $defaultRateLimitPerMinute, rateByCategory: $rateLimitPerCategory, metrics: $exposeMetrics, metricsInterval: ${metricsInterval.inMinutes}m, minLevelByCategory: $minLevelByCategory)';
  }
}