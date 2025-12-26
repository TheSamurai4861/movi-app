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
    this.sensitiveKeys = const {},
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
  final Set<String> sensitiveKeys;

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
    Set<String>? sensitiveKeys,
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
      sensitiveKeys: sensitiveKeys ?? this.sensitiveKeys,
    );
  }

  /// Throws [ArgumentError] when a sampling/rate limit value is outside bounds.
  void validate() {
    bool isBetweenZeroAndOne(num value) => value >= 0 && value <= 1;
    for (final entry in samplingByLevel.entries) {
      if (!isBetweenZeroAndOne(entry.value)) {
        throw ArgumentError.value(
          entry.value,
          'samplingByLevel(${entry.key})',
          'Sampling probability must be between 0 and 1.',
        );
      }
    }
    for (final entry in samplingByCategory.entries) {
      if (!isBetweenZeroAndOne(entry.value)) {
        throw ArgumentError.value(
          entry.value,
          'samplingByCategory(${entry.key})',
          'Sampling probability must be between 0 and 1.',
        );
      }
    }
    if (defaultRateLimitPerMinute < 0) {
      throw ArgumentError.value(
        defaultRateLimitPerMinute,
        'defaultRateLimitPerMinute',
        'Rate limit cannot be negative.',
      );
    }
    for (final entry in rateLimitPerCategory.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          'rateLimitPerCategory(${entry.key})',
          'Rate limit cannot be negative.',
        );
      }
    }
    if (bufferCapacity <= 0) {
      throw ArgumentError.value(bufferCapacity, 'bufferCapacity');
    }
    if (maxFileSizeBytes <= 0) {
      throw ArgumentError.value(maxFileSizeBytes, 'maxFileSizeBytes');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoggingConfig) return false;
    return minLevel == other.minLevel &&
        enableConsole == other.enableConsole &&
        enableFile == other.enableFile &&
        flushInterval == other.flushInterval &&
        maxFileSizeBytes == other.maxFileSizeBytes &&
        maxFiles == other.maxFiles &&
        rotateDaily == other.rotateDaily &&
        maxDailyFiles == other.maxDailyFiles &&
        compressOld == other.compressOld &&
        bufferCapacity == other.bufferCapacity &&
        dropOldest == other.dropOldest &&
        _mapEquals(samplingByLevel, other.samplingByLevel) &&
        _mapEquals(samplingByCategory, other.samplingByCategory) &&
        defaultRateLimitPerMinute == other.defaultRateLimitPerMinute &&
        _mapEquals(rateLimitPerCategory, other.rateLimitPerCategory) &&
        exposeMetrics == other.exposeMetrics &&
        metricsInterval == other.metricsInterval &&
        _mapEquals(minLevelByCategory, other.minLevelByCategory) &&
        _setEquals(sensitiveKeys, other.sensitiveKeys);
  }

  @override
  int get hashCode => Object.hash(
    minLevel,
    enableConsole,
    enableFile,
    flushInterval,
    maxFileSizeBytes,
    maxFiles,
    rotateDaily,
    maxDailyFiles,
    compressOld,
    bufferCapacity,
    dropOldest,
    _mapHash(samplingByLevel),
    _mapHash(samplingByCategory),
    defaultRateLimitPerMinute,
    _mapHash(rateLimitPerCategory),
    exposeMetrics,
    metricsInterval,
    _mapHash(minLevelByCategory),
    Object.hashAllUnordered(sensitiveKeys),
  );

  @override
  String toString() {
    return 'LoggingConfig(minLevel: ${minLevel.name}, console: $enableConsole, file: $enableFile, flush: ${flushInterval.inMilliseconds}ms, maxSize: $maxFileSizeBytes, maxFiles: $maxFiles, rotateDaily: $rotateDaily, maxDailyFiles: $maxDailyFiles, compressOld: $compressOld, bufferCapacity: $bufferCapacity, dropOldest: $dropOldest, samplingByLevel: $samplingByLevel, samplingByCategory: $samplingByCategory, defaultRate: $defaultRateLimitPerMinute, rateByCategory: $rateLimitPerCategory, metrics: $exposeMetrics, metricsInterval: ${metricsInterval.inMinutes}m, minLevelByCategory: $minLevelByCategory, sensitiveKeys: $sensitiveKeys)';
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  int _mapHash<K, V>(Map<K, V> map) => Object.hashAll(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );

  bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a) {
      if (!b.contains(entry)) return false;
    }
    return true;
  }
}
