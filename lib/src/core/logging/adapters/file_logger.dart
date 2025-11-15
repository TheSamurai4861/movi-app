import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:movi/src/core/logging/adapters/console_logger.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/sanitizer/message_sanitizer.dart';

class FileLogger extends AppLogger implements LoggerLifecycle {
  FileLogger({
    String fileName = 'app.log',
    Duration flushInterval = const Duration(milliseconds: 500),
    int maxFileSizeBytes = 5 * 1024 * 1024,
    int maxFiles = 5,
    bool alsoConsole = true,
    bool rotateDaily = false,
    int maxDailyFiles = 5,
    bool compressOld = false,
    int bufferCapacity = 2000,
    bool dropOldest = true,
    Set<String>? extraSensitiveKeys,
    ConsolePrinter? consolePrinter,
  }) : _fileName = fileName,
       _flushInterval = flushInterval,
       _maxFileSizeBytes = maxFileSizeBytes,
       _maxFiles = maxFiles,
       _alsoConsole = alsoConsole,
       _rotateDaily = rotateDaily,
       _maxDailyFiles = maxDailyFiles,
       _compressOld = compressOld,
       _bufferCapacity = bufferCapacity,
       _dropOldest = dropOldest,
       _printer = consolePrinter ?? debugPrint,
       _sanitizer = MessageSanitizer(extraSensitiveKeys: extraSensitiveKeys) {
    if (!kIsWeb) {
      _initFileSink();
    }
  }

  final String _fileName;
  final Duration _flushInterval;
  final int _maxFileSizeBytes;
  final int _maxFiles;
  final bool _alsoConsole;
  final bool _rotateDaily;
  final int _maxDailyFiles;
  final bool _compressOld;
  final int _bufferCapacity;
  final bool _dropOldest;
  final ConsolePrinter _printer;
  final MessageSanitizer _sanitizer;

  IOSink? _sink;
  File? _file;
  Timer? _timer;
  final List<String> _buffer = <String>[];
  DateTime? _currentDay;
  int _droppedEvents = 0;
  int get droppedEventsCount => _droppedEvents;

  Future<void> _initFileSink() async {
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      final String logPath = p.join(docs.path, _fileName);
      _file = File(logPath);
      await _file!.create(recursive: true);
      _sink = _file!.openWrite(mode: FileMode.append);
      _timer = Timer.periodic(_flushInterval, (_) => _flush());
      _currentDay = DateTime.now();
    } catch (_) {}
  }

  void _printConsole(String line) {
    if (!_alsoConsole) return;
    _printer(line);
  }

  Future<void> _flush() async {
    if (_sink == null) return;
    if (_buffer.isEmpty) return;
    try {
      _sink!.writeln(_buffer.join('\n'));
      await _sink!.flush();
    } catch (_) {}
    _buffer.clear();
  }

  void _rotate() {
    try {
      _sink?.flush();
      _sink?.close();
    } catch (_) {}
    if (_file == null) return;
    final String dir = p.dirname(_file!.path);
    final String base = p.basenameWithoutExtension(_file!.path);
    final String ext = p.extension(_file!.path);
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String rotated = p.join(dir, '$base.$stamp$ext');
    try {
      _file!.renameSync(rotated);
    } catch (_) {}
    if (_compressOld) {
      try {
        final bytes = File(rotated).readAsBytesSync();
        final gz = gzip.encode(bytes);
        final gzPath = '$rotated.gz';
        File(gzPath).writeAsBytesSync(gz, flush: true);
        try {
          File(rotated).deleteSync();
        } catch (_) {}
      } catch (_) {}
    }
    final List<File> files =
        Directory(dir)
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith(base))
            .toList()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
    if (files.length > _maxFiles) {
      for (final f in files.skip(_maxFiles)) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    if (_rotateDaily && _maxDailyFiles > 0) {
      final Map<String, List<File>> byDay = <String, List<File>>{};
      for (final f in files) {
        final d = f.statSync().modified;
        final key = '${d.year}-${d.month}-${d.day}';
        final list = byDay.putIfAbsent(key, () => <File>[]);
        list.add(f);
      }
      for (final entry in byDay.entries) {
        final list = entry.value;
        if (list.length > _maxDailyFiles) {
          for (final f in list.skip(_maxDailyFiles)) {
            try {
              f.deleteSync();
            } catch (_) {}
          }
        }
      }
    }
    _initFileSink();
    _currentDay = DateTime.now();
  }

  void _addToBuffer(String line) {
    if (_buffer.length >= _bufferCapacity) {
      if (_dropOldest) {
        _buffer.removeAt(0);
      } else {
        _droppedEvents++;
        return;
      }
    }
    _buffer.add(line);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _flush();
    try {
      await _sink?.close();
    } catch (_) {}
    _sink = null;
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_rotateDaily && _currentDay != null) {
      final now = DateTime.now();
      if (now.year != _currentDay!.year ||
          now.month != _currentDay!.month ||
          now.day != _currentDay!.day) {
        _rotate();
      }
    }
    final ts = DateTime.now().toIso8601String();
    final tag = level.name.toUpperCase();
    final cat = (category == null || category.isEmpty)
        ? ''
        : '[${_sanitizer.sanitize(category)}] ';
    final base = '[$ts][$tag] $cat${_sanitizer.sanitize(message)}';
    _printConsole(base);
    if (error != null) _printConsole(' -> ${_sanitizer.sanitize('$error')}');
    if (stackTrace != null) _printConsole(stackTrace.toString());
    if (_sink != null) {
      _addToBuffer(base);
      if (error != null) _addToBuffer(' -> ${_sanitizer.sanitize('$error')}');
      if (stackTrace != null) _addToBuffer(stackTrace.toString());
      if ((_file?.lengthSync() ?? 0) > _maxFileSizeBytes) {
        _rotate();
      }
    }
  }
}
