import 'dart:convert';

final class DiagnosticBundle {
  const DiagnosticBundle({
    required this.createdAtUtcIso,
    required this.appVersion,
    required this.appBuildNumber,
    required this.platform,
    required this.buildMode,
    required this.accountIdHash,
    required this.profileIdHash,
    required this.scannedLogLineCount,
    required this.keptLogLineCount,
    required this.logLines,
    required this.droppedLogLineCount,
    required this.summary,
  });

  final String createdAtUtcIso;
  final String appVersion;
  final String appBuildNumber;
  final String platform;
  final String buildMode;
  final String? accountIdHash;
  final String? profileIdHash;
  final int scannedLogLineCount;
  final int keptLogLineCount;
  final List<String> logLines;
  final int droppedLogLineCount;
  final DiagnosticSummary summary;

  Map<String, Object?> toJson() => <String, Object?>{
    'createdAtUtc': createdAtUtcIso,
    'app': <String, Object?>{
      'version': appVersion,
      'buildNumber': appBuildNumber,
      'platform': platform,
      'buildMode': buildMode,
    },
    'identity': <String, Object?>{
      'accountIdHash': accountIdHash,
      'profileIdHash': profileIdHash,
    },
    'logs': <String, Object?>{
      'scannedLines': scannedLogLineCount,
      'keptLines': keptLogLineCount,
      'lines': logLines,
      'dropped': droppedLogLineCount,
    },
    'summary': summary.toJson(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

final class DiagnosticSummary {
  const DiagnosticSummary({
    required this.warnCount,
    required this.errorCount,
    required this.topCategories,
    required this.firstSeenUtcIso,
    required this.lastSeenUtcIso,
  });

  final int warnCount;
  final int errorCount;
  final List<String> topCategories;
  final String? firstSeenUtcIso;
  final String? lastSeenUtcIso;

  Map<String, Object?> toJson() => <String, Object?>{
    'warn': warnCount,
    'error': errorCount,
    'topCategories': topCategories,
    'firstSeenUtc': firstSeenUtcIso,
    'lastSeenUtc': lastSeenUtcIso,
  };
}
