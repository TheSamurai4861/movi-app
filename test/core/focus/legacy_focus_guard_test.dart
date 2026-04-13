import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('legacy focus guard', () {
    test('MoviRouteFocusBoundary is not reintroduced outside the legacy core file', () {
      final offenders = _findLegacySymbolUsages(
        symbol: 'MoviRouteFocusBoundary(',
        allowedFiles: const {
          'lib/src/core/focus/movi_route_focus_boundary.dart',
        },
      );

      expect(
        offenders,
        isEmpty,
        reason: _buildFailureReason(
          symbol: 'MoviRouteFocusBoundary(',
          offenders: offenders,
          remediation:
              'Migre l\'ecran vers FocusRegionScope + FocusRegionBinding + exitMap. '
              'Le wrapper legacy ne doit plus etre reutilise dans les pages metier.',
        ),
      );
    });

    test('legacy onUnhandled callbacks are not reintroduced outside the legacy core file', () {
      final backOffenders = _findLegacySymbolUsages(
        symbol: 'onUnhandledBack',
        allowedFiles: const {
          'lib/src/core/focus/movi_route_focus_boundary.dart',
        },
      );
      final leftOffenders = _findLegacySymbolUsages(
        symbol: 'onUnhandledLeft',
        allowedFiles: const {
          'lib/src/core/focus/movi_route_focus_boundary.dart',
        },
      );
      final offenders = <String>{...backOffenders, ...leftOffenders}.toList()..sort();

      expect(
        offenders,
        isEmpty,
        reason: _buildFailureReason(
          symbol: 'onUnhandledBack/onUnhandledLeft',
          offenders: offenders,
          remediation:
              'Utilise FocusRegionScope/FocusOverlayScope et des sorties structurelles via orchestrator, '
              'pas des callbacks route-level legacy.',
        ),
      );
    });
  });
}

List<String> _findLegacySymbolUsages({
  required String symbol,
  required Set<String> allowedFiles,
}) {
  final repoRoot = Directory.current;
  final srcDir = Directory(p.join(repoRoot.path, 'lib', 'src'));
  if (!srcDir.existsSync()) {
    fail('Impossible de trouver lib/src depuis ${repoRoot.path}.');
  }

  final offenders = <String>[];
  for (final entity in srcDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.posix.normalize(
      p.relative(entity.path, from: repoRoot.path).replaceAll('\\', '/'),
    );
    if (allowedFiles.contains(relativePath)) {
      continue;
    }
    final contents = entity.readAsStringSync();
    if (contents.contains(symbol)) {
      offenders.add(relativePath);
    }
  }

  offenders.sort();
  return offenders;
}

String _buildFailureReason({
  required String symbol,
  required List<String> offenders,
  required String remediation,
}) {
  if (offenders.isEmpty) {
    return '';
  }
  final buffer = StringBuffer()
    ..writeln('Usage legacy detecte pour "$symbol" hors whitelist:')
    ..writeln();
  for (final offender in offenders) {
    buffer.writeln('- $offender');
  }
  buffer
    ..writeln()
    ..writeln(remediation);
  return buffer.toString();
}
