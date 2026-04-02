import 'dart:io';

/// Architecture import linter (Phase 2 / Jalon M2).
///
/// Usage:
///   dart run tool/arch_lint.dart
///   dart run tool/arch_lint.dart --out docs/architecture/reports/arch_violations_YYYY-MM-DD.md
///   dart run tool/arch_lint.dart --canary
///
/// Scope: scans `lib/` by default.
void main(List<String> args) {
  final parsed = _Args.parse(args);
  final root = Directory.current.path;

  if (parsed.canary) {
    stdout.writeln(_renderSelfCheck());
    exitCode = 0;
    return;
  }

  final violations = <Violation>[];
  final files = _listDartFiles(
    Directory(_join(root, parsed.scopeDir)),
  );

  for (final file in files) {
    final rel = _relPath(root, file.path);
    final imports = _extractImports(file);
    violations.addAll(_applyRules(
      sourceRelPath: rel,
      importLines: imports,
    ));
  }

  final report = _renderReport(
    scopeDir: parsed.scopeDir,
    generatedAt: DateTime.now().toUtc(),
    violations: violations,
    canaryOnly: false,
  );

  final outPath = parsed.outPath ??
      _join(
        root,
        'docs',
        'architecture',
        'reports',
        'arch_violations_${_dateStampUtc()}.md',
      );

  _ensureParentDir(outPath);
  File(outPath).writeAsStringSync(report, flush: true);
  stdout.writeln('arch_lint: wrote report to ${_relPath(root, outPath)}');

  if (parsed.expectAllRules) {
    final missing = _missingRuleIds(violations, _allRuleIds);
    if (missing.isNotEmpty) {
      stderr.writeln(
        'arch_lint: FAIL (expected all rule IDs). Missing: ${missing.join(", ")}',
      );
      exitCode = 2;
      return;
    }
  }

  if (parsed.baselinePath != null) {
    final baselineFile = File(_join(root, parsed.baselinePath!));
    if (!baselineFile.existsSync()) {
      stderr.writeln(
        'arch_lint: baseline not found: ${_relPath(root, baselineFile.path)}',
      );
      exitCode = 2;
      return;
    }

    final baseline = _loadBaselineFingerprints(baselineFile);
    final current = violations.map(_fingerprint).toSet();
    final added = current.difference(baseline).toList()..sort();

    if (added.isNotEmpty) {
      stderr.writeln(
        'arch_lint: FAIL (${added.length} new violation(s) vs baseline). See report: ${_relPath(root, outPath)}',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('arch_lint: OK (no new violations vs baseline).');
    exitCode = 0;
    return;
  }

  if (parsed.canaryFixtures) {
    // Canary fixtures are expected to violate rules.
    // Success criteria: required rule IDs are present (handled above).
    stdout.writeln('arch_lint: OK (canary fixtures).');
    exitCode = 0;
    return;
  }

  final blockingCount = violations.where((v) => v.severity == Severity.blocking)
      .length;
  if (blockingCount > 0) {
    stderr.writeln(
      'arch_lint: FAIL ($blockingCount blocking violation(s)). See report: ${_relPath(root, outPath)}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('arch_lint: OK (no blocking violations).');
  exitCode = 0;
}

enum Severity { blocking }

class Violation {
  Violation({
    required this.ruleId,
    required this.severity,
    required this.sourceFile,
    required this.importLine,
    required this.lineNumber,
    required this.message,
    required this.suggestion,
  });

  final String ruleId; // ARCH-R1..R5
  final Severity severity;
  final String sourceFile; // relative path
  final String importLine; // raw import line
  final int lineNumber; // 1-based
  final String message;
  final String suggestion;
}

class _Args {
  _Args({
    required this.scopeDir,
    required this.outPath,
    required this.canary,
    required this.baselinePath,
    required this.expectAllRules,
    required this.canaryFixtures,
  });

  final String scopeDir;
  final String? outPath;
  final bool canary;
  final String? baselinePath;
  final bool expectAllRules;
  final bool canaryFixtures;

  static _Args parse(List<String> args) {
    String scopeDir = 'lib';
    String? out;
    bool canary = false;
    String? baselinePath;
    bool expectAllRules = false;
    bool canaryFixtures = false;

    for (var i = 0; i < args.length; i++) {
      final a = args[i].trim();
      if (a == '--scope' && i + 1 < args.length) {
        scopeDir = args[++i].trim();
        continue;
      }
      if (a == '--out' && i + 1 < args.length) {
        out = args[++i].trim();
        continue;
      }
      if (a == '--baseline' && i + 1 < args.length) {
        baselinePath = args[++i].trim();
        continue;
      }
      if (a == '--expect-all-rules') {
        expectAllRules = true;
        continue;
      }
      if (a == '--canary-fixtures') {
        canaryFixtures = true;
        continue;
      }
      if (a == '--canary') {
        canary = true;
        continue;
      }
    }
    return _Args(
      scopeDir: scopeDir,
      outPath: out,
      canary: canary,
      baselinePath: baselinePath,
      expectAllRules: expectAllRules,
      canaryFixtures: canaryFixtures,
    );
  }
}

List<File> _listDartFiles(Directory root) {
  if (!root.existsSync()) return const [];
  final out = <File>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    out.add(entity);
  }
  return out;
}

List<_ImportLine> _extractImports(File file) {
  final lines = file.readAsLinesSync();
  final out = <_ImportLine>[];

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final trimmed = raw.trimLeft();
    if (!trimmed.startsWith('import ')) continue;

    final uri = _parseImportUri(trimmed);
    if (uri == null) continue;

    out.add(_ImportLine(
      lineNumber: i + 1,
      rawLine: raw,
      uri: uri,
    ));
  }

  return out;
}

String? _parseImportUri(String trimmedImportLine) {
  final firstQuote = trimmedImportLine.indexOf("'");
  final quoteChar = firstQuote >= 0 ? "'" : '"';
  final start = trimmedImportLine.indexOf(quoteChar);
  if (start < 0) return null;
  final end = trimmedImportLine.indexOf(quoteChar, start + 1);
  if (end < 0) return null;
  return trimmedImportLine.substring(start + 1, end).trim();
}

class _ImportLine {
  _ImportLine({
    required this.lineNumber,
    required this.rawLine,
    required this.uri,
  });

  final int lineNumber;
  final String rawLine;
  final String uri;
}

const List<String> _allRuleIds = ['ARCH-R1', 'ARCH-R2', 'ARCH-R3', 'ARCH-R4', 'ARCH-R5'];

List<Violation> _applyRules({
  required String sourceRelPath,
  required List<_ImportLine> importLines,
}) {
  final out = <Violation>[];

  final sourceIsPresentation = sourceRelPath.contains('/presentation/');
  final sourceIsDomain = sourceRelPath.contains('/domain/');

  final sourceIsFeature = sourceRelPath.contains('/features/');
  final featureName = sourceIsFeature ? _featureNameFromPath(sourceRelPath) : null;

  final sourceIsUiFile = _isUiPresentationFile(sourceRelPath);

  for (final imp in importLines) {
    final uri = imp.uri;

    // Ignore Dart and Flutter SDK imports for our rules.
    if (uri.startsWith('dart:')) continue;
    if (uri.startsWith('package:flutter/')) continue;
    if (uri.startsWith('package:flutter_')) continue;

    final isMoviPackage = uri.startsWith('package:movi/');
    final targetRelPath = isMoviPackage ? uri.replaceFirst('package:movi/', '')
        : null;

    // ARCH-R1: presentation -> data
    if (sourceIsPresentation && targetRelPath != null &&
        targetRelPath.contains('/data/')) {
      out.add(_v(
        ruleId: 'ARCH-R1',
        sourceRelPath: sourceRelPath,
        imp: imp,
        message: 'Interdit: presentation -> data',
        suggestion: 'Dépendre de domain/application et exposer une abstraction.',
      ));
      continue;
    }

    // ARCH-R2: domain -> data
    if (sourceIsDomain && targetRelPath != null &&
        targetRelPath.contains('/data/')) {
      out.add(_v(
        ruleId: 'ARCH-R2',
        sourceRelPath: sourceRelPath,
        imp: imp,
        message: 'Interdit: domain -> data',
        suggestion: 'Extraire une interface (repository) côté domain, impl côté data.',
      ));
      continue;
    }

    // ARCH-R3: presentation -> external SDK (denylist)
    if (sourceIsPresentation && !isMoviPackage && uri.startsWith('package:')) {
      final pkg = _packageName(uri);
      if (_externalSdkDenylist.contains(pkg)) {
        out.add(_v(
          ruleId: 'ARCH-R3',
          sourceRelPath: sourceRelPath,
          imp: imp,
          message: 'Interdit: presentation -> SDK externe ($pkg)',
          suggestion: 'Isoler le SDK dans core/data (adapter) et exposer une abstraction.',
        ));
        continue;
      }
    }

    // ARCH-R4: feature -> feature
    if (featureName != null && targetRelPath != null &&
        targetRelPath.startsWith('src/features/')) {
      final targetFeature = _featureNameFromPath('lib/$targetRelPath');
      if (targetFeature != null && targetFeature != featureName) {
        out.add(_v(
          ruleId: 'ARCH-R4',
          sourceRelPath: sourceRelPath,
          imp: imp,
          message: 'Interdit: feature "$featureName" -> feature "$targetFeature"',
          suggestion: 'Passer par shared/core ou définir un contrat approuvé explicite.',
        ));
        continue;
      }
    }

    // ARCH-R5: UI locator usage
    if (sourceIsUiFile) {
      if (uri == 'package:get_it/get_it.dart' ||
          uri == 'package:movi/src/core/di/di.dart') {
        out.add(_v(
          ruleId: 'ARCH-R5',
          sourceRelPath: sourceRelPath,
          imp: imp,
          message: 'Interdit: accès direct au locator en UI',
          suggestion: 'Passer par providers Riverpod / injection testable.',
        ));
        continue;
      }
    }
  }

  // ARCH-R5 (usage patterns) — lightweight heuristic:
  // if it is a UI file and it imports di.dart or get_it, we already flagged above.
  // (Deeper token scanning can be added later if needed.)

  return out;
}

Violation _v({
  required String ruleId,
  required String sourceRelPath,
  required _ImportLine imp,
  required String message,
  required String suggestion,
}) {
  return Violation(
    ruleId: ruleId,
    severity: Severity.blocking,
    sourceFile: sourceRelPath,
    importLine: imp.rawLine,
    lineNumber: imp.lineNumber,
    message: message,
    suggestion: suggestion,
  );
}

String _fingerprint(Violation v) {
  final importUri = _parseImportUri(v.importLine.trimLeft()) ?? '<unknown>';
  return '${v.ruleId}|${v.sourceFile}|$importUri';
}

Set<String> _loadBaselineFingerprints(File baselineMarkdown) {
  final lines = baselineMarkdown.readAsLinesSync();
  final out = <String>{};

  String? currentRuleId;
  String? currentSourceFile;
  String? currentImportUri;

  bool inImportBlock = false;
  for (final line in lines) {
    final trimmed = line.trimRight();

    if (trimmed.startsWith('### ')) {
      // Example: "### ARCH-R5 — lib/foo.dart:8"
      final after = trimmed.substring(4);
      final parts = after.split(' — ');
      if (parts.length >= 2) {
        currentRuleId = parts.first.trim();
        final fileAndLine = parts[1].trim();
        final colon = fileAndLine.lastIndexOf(':');
        currentSourceFile = colon >= 0
            ? fileAndLine.substring(0, colon).trim()
            : fileAndLine.trim();
      } else {
        currentRuleId = null;
        currentSourceFile = null;
      }
      currentImportUri = null;
      inImportBlock = false;
      continue;
    }

    if (trimmed == '```') {
      inImportBlock = !inImportBlock;
      continue;
    }

    if (inImportBlock && trimmed.trimLeft().startsWith('import ')) {
      currentImportUri = _parseImportUri(trimmed.trimLeft());
      if (currentRuleId != null &&
          currentSourceFile != null &&
          currentImportUri != null) {
        out.add('$currentRuleId|$currentSourceFile|$currentImportUri');
      }
      continue;
    }
  }

  return out;
}

List<String> _missingRuleIds(List<Violation> violations, List<String> expected) {
  final present = violations.map((v) => v.ruleId).toSet();
  return expected.where((id) => !present.contains(id)).toList();
}

String _packageName(String uri) {
  // uri like package:foo/bar.dart -> foo
  final withoutPrefix = uri.replaceFirst('package:', '');
  final idx = withoutPrefix.indexOf('/');
  return idx < 0 ? withoutPrefix : withoutPrefix.substring(0, idx);
}

String? _featureNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final marker = '/features/';
  final idx = normalized.indexOf(marker);
  if (idx < 0) return null;
  final rest = normalized.substring(idx + marker.length);
  final slash = rest.indexOf('/');
  if (slash < 0) return null;
  final name = rest.substring(0, slash).trim();
  return name.isEmpty ? null : name;
}

bool _isUiPresentationFile(String sourceRelPath) {
  final p = sourceRelPath.replaceAll('\\', '/');
  if (!p.contains('/presentation/')) return false;
  return p.contains('/presentation/pages/') ||
      p.contains('/presentation/widgets/') ||
      p.contains('/presentation/providers/') ||
      p.contains('/presentation/controllers/');
}

const Set<String> _externalSdkDenylist = {
  'get_it',
  'supabase_flutter',
  'dio',
  'sqflite',
};

String _renderReport({
  required String scopeDir,
  required DateTime generatedAt,
  required List<Violation> violations,
  required bool canaryOnly,
}) {
  final b = StringBuffer();
  b.writeln('# Architecture violations report');
  b.writeln();
  b.writeln('- Scope: `$scopeDir/`');
  b.writeln('- Generated (UTC): `${generatedAt.toIso8601String()}`');
  b.writeln('- Mode: `${canaryOnly ? "canary" : "enforce"}`');
  b.writeln('- Violations: **${violations.length}**');
  b.writeln();
  b.writeln('## Summary by rule');
  b.writeln();

  final byRule = <String, int>{};
  for (final v in violations) {
    byRule[v.ruleId] = (byRule[v.ruleId] ?? 0) + 1;
  }

  if (byRule.isEmpty) {
    b.writeln('- (none)');
  } else {
    for (final e in byRule.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      b.writeln('- **${e.key}**: ${e.value}');
    }
  }

  b.writeln();
  b.writeln('## Details');
  b.writeln();

  if (violations.isEmpty) {
    b.writeln('No blocking violations detected.');
    b.writeln();
    return b.toString();
  }

  for (final v in violations) {
    b.writeln('### ${v.ruleId} — ${v.sourceFile}:${v.lineNumber}');
    b.writeln();
    b.writeln('- **Message**: ${v.message}');
    b.writeln('- **Suggestion**: ${v.suggestion}');
    b.writeln('- **Import**:');
    b.writeln();
    b.writeln('```');
    b.writeln(v.importLine.trimRight());
    b.writeln('```');
    b.writeln();
  }

  return b.toString();
}

String _renderSelfCheck() {
  return [
    'arch_lint: self-check (canary)',
    '',
    'Rules:',
    '- ARCH-R1: presentation -> data (source contains /presentation/, target contains /data/)',
    '- ARCH-R2: domain -> data (source contains /domain/, target contains /data/)',
    '- ARCH-R3: presentation -> external SDK denylist (${_externalSdkDenylist.join(", ")})',
    '- ARCH-R4: feature(A) -> feature(B) when A != B (package:movi/src/features/...)',
    '- ARCH-R5: UI files (presentation/pages|widgets|providers|controllers) must not import get_it or core/di/di.dart',
    '',
    'Usage:',
    '- dart run tool/arch_lint.dart',
    '- dart run tool/arch_lint.dart --out docs/architecture/reports/arch_violations_YYYY-MM-DD.md',
    '- dart run tool/arch_lint.dart --scope tool/arch_lint_canary --canary-fixtures --expect-all-rules --out docs/architecture/reports/arch_canary_report.md',
    '- dart run tool/arch_lint.dart --baseline docs/architecture/reports/arch_violations_baseline.md --out docs/architecture/reports/arch_delta_report.md',
  ].join('\n');
}

String _dateStampUtc() {
  final now = DateTime.now().toUtc();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

void _ensureParentDir(String path) {
  final f = File(path);
  f.parent.createSync(recursive: true);
}

String _join(String a, [String? b, String? c, String? d, String? e, String? f]) {
  final parts = <String>[a];
  for (final p in [b, c, d, e, f]) {
    if (p == null || p.isEmpty) continue;
    parts.add(p);
  }
  return parts.join(Platform.pathSeparator);
}

String _relPath(String root, String fullPath) {
  final r = root.replaceAll('\\', '/');
  final p = fullPath.replaceAll('\\', '/');
  if (p.startsWith(r)) {
    final rel = p.substring(r.length);
    return rel.startsWith('/') ? rel.substring(1) : rel;
  }
  return fullPath;
}

