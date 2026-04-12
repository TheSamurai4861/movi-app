import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class LogReadResult {
  const LogReadResult({required this.lines, required this.droppedCount});

  final List<String> lines;
  final int droppedCount;
}

final class LogFileReader {
  const LogFileReader({this.fileName = 'app.log'});

  final String fileName;

  Future<LogReadResult> readLastLines({required int maxLines}) async {
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      final String logPath = p.join(docs.path, fileName);
      final file = File(logPath);
      if (!await file.exists()) {
        return const LogReadResult(lines: <String>[], droppedCount: 0);
      }

      final all = await file.readAsLines();
      if (all.isEmpty) {
        return const LogReadResult(lines: <String>[], droppedCount: 0);
      }

      if (all.length <= maxLines) {
        return LogReadResult(lines: all, droppedCount: 0);
      }

      final start = all.length - maxLines;
      return LogReadResult(lines: all.sublist(start), droppedCount: start);
    } catch (_) {
      return const LogReadResult(lines: <String>[], droppedCount: 0);
    }
  }
}
