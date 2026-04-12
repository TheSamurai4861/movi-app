import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:movi/src/core/diagnostics/domain/entities/diagnostic_bundle.dart';

final class DiagnosticExportResult {
  const DiagnosticExportResult({required this.path, required this.fileName});

  final String path;
  final String fileName;
}

final class DiagnosticExportRepository {
  const DiagnosticExportRepository();

  Future<DiagnosticExportResult> saveToDocuments({
    required DiagnosticBundle bundle,
  }) async {
    final Directory docs = await _resolveExportDirectory();
    final ts = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final fileName = 'movi_diagnostic_$ts.json';
    final path = p.join(docs.path, fileName);
    final file = File(path);
    await file.writeAsString(bundle.toPrettyJson(), flush: true);
    return DiagnosticExportResult(path: path, fileName: fileName);
  }

  Future<Directory> _resolveExportDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {
      // ignore
    }
    return getApplicationDocumentsDirectory();
  }
}
