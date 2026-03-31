import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/diagnostics/domain/entities/diagnostic_bundle.dart';
import 'package:movi/src/core/diagnostics/infrastructure/identity/diagnostic_identity_hasher.dart';
import 'package:movi/src/core/diagnostics/infrastructure/logs/log_file_reader.dart';
import 'package:movi/src/core/diagnostics/infrastructure/sanitizer/diagnostic_sanitizer.dart';

final class BuildDiagnosticBundle {
  BuildDiagnosticBundle(
    this._metadata,
    this._logReader,
    this._sanitizer,
    this._hasher,
  );

  final AppMetadata _metadata;
  final LogFileReader _logReader;
  final DiagnosticSanitizer _sanitizer;
  final DiagnosticIdentityHasher _hasher;

  Future<DiagnosticBundle> call({
    required int maxLogLinesToScan,
    required bool includeHashedIdentity,
    String? accountId,
    String? profileId,
  }) async {
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final read = await _logReader.readLastLines(maxLines: maxLogLinesToScan);
    final filtered = _sanitizer.filterAndSanitizeErrorLogs(read.lines);

    final platform = Platform.operatingSystem;
    final buildMode = kReleaseMode ? 'release' : 'debug';

    String? accountHash;
    String? profileHash;
    if (includeHashedIdentity) {
      if (accountId != null && accountId.trim().isNotEmpty) {
        accountHash = await _hasher.hashId(accountId.trim());
      }
      if (profileId != null && profileId.trim().isNotEmpty) {
        profileHash = await _hasher.hashId(profileId.trim());
      }
    }

    final summary = _buildSummary(filtered);

    return DiagnosticBundle(
      createdAtUtcIso: createdAt,
      appVersion: _metadata.version,
      appBuildNumber: _metadata.buildNumber,
      platform: platform,
      buildMode: buildMode,
      accountIdHash: accountHash,
      profileIdHash: profileHash,
      scannedLogLineCount: read.lines.length,
      keptLogLineCount: filtered.length,
      logLines: filtered,
      droppedLogLineCount: read.droppedCount,
      summary: summary,
    );
  }

  DiagnosticSummary _buildSummary(List<String> lines) {
    var warn = 0;
    var error = 0;

    DateTime? first;
    DateTime? last;

    final categoryCounts = <String, int>{};

    final eventRe = RegExp(
      r'^\[(?<ts>[^]]+)\]\[(?<lvl>WARN|ERROR)\](?:\s+\[(?<cat>[^]]+)\])?',
    );

    for (final line in lines) {
      final m = eventRe.firstMatch(line);
      if (m == null) continue;

      final lvl = m.namedGroup('lvl') ?? '';
      if (lvl == 'WARN') warn++;
      if (lvl == 'ERROR') error++;

      final tsRaw = m.namedGroup('ts');
      final ts = tsRaw == null ? null : DateTime.tryParse(tsRaw);
      if (ts != null) {
        first = (first == null || ts.isBefore(first)) ? ts : first;
        last = (last == null || ts.isAfter(last)) ? ts : last;
      }

      final cat = m.namedGroup('cat');
      if (cat != null && cat.trim().isNotEmpty) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }
    }

    final topCats =
        categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return DiagnosticSummary(
      warnCount: warn,
      errorCount: error,
      topCategories:
          topCats.take(5).map((e) => e.key).toList(growable: false),
      firstSeenUtcIso: first?.toUtc().toIso8601String(),
      lastSeenUtcIso: last?.toUtc().toIso8601String(),
    );
  }
}

