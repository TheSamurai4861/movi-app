// lib/src/core/logging/logging_service.dart
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Simple file logging service writing to user's Documents directory.
class LoggingService {
  static IOSink? _sink;
  static bool _initialized = false;

  /// Initialize the log file in the platform's Documents folder.
  static Future<void> init({String fileName = 'log.txt'}) async {
    if (_initialized) return;

    final Directory docs = await getApplicationDocumentsDirectory();
    final String logPath = p.join(docs.path, fileName);
    final file = File(logPath);
    await file.create(recursive: true);

    _sink = file.openWrite(mode: FileMode.append);
    _initialized = true;

    await log('Logging initialized at ${file.path}');
  }

  /// Append a line with timestamp and platform info.
  static Future<void> log(String message) async {
    try {
      final String ts = DateTime.now().toIso8601String();
      final String platform = _platformLabel();
      _sink?.writeln('[$ts][$platform] $message');
      await _sink?.flush();
    } catch (_) {
      // Avoid throwing in production logging
    }
  }

  static Future<void> dispose() async {
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
    _sink = null;
    _initialized = false;
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
