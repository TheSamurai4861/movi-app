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
  })  : _fileName = fileName,
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
    // IMPORTANT: init is async; we must not drop early logs.
    if (!kIsWeb) {
      // ignore: discarded_futures
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
  DateTime? _currentDay;

  final List<String> _buffer = <String>[];
  int _droppedEvents = 0;
  int get droppedEventsCount => _droppedEvents;

  bool _initializing = false;

  Future<void> _initFileSink() async {
    if (_sink != null) return;
    if (_initializing) return;
    _initializing = true;

    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      final String logPath = p.join(docs.path, _fileName);

      _file = File(logPath);
      await _file!.create(recursive: true);
      _sink = _file!.openWrite(mode: FileMode.append);

      _timer ??= Timer.periodic(_flushInterval, (_) {
        // ignore: discarded_futures
        _flush();
      });

      _currentDay ??= DateTime.now();

      // Flush any buffered lines captured before sink became ready.
      await _flush();
    } catch (_) {
      // Keep logger non-fatal: do not throw.
      // Worst case: file sink not available, console logging still works.
    } finally {
      _initializing = false;
    }
  }

  void _printConsole(String line) {
    if (!_alsoConsole) return;
    _printer(line);
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

  Future<void> _flush() async {
    final sink = _sink;
    if (sink == null) return;
    if (_buffer.isEmpty) return;

    try {
      for (final line in _buffer) {
        sink.writeln(line);
      }
      await sink.flush();
    } catch (_) {
      // Non-fatal; keep buffer? Risk of infinite growth.
      // Clear buffer to avoid memory leak if sink becomes invalid.
    } finally {
      _buffer.clear();
    }
  }

  void _rotate() {
    try {
      _sink?.flush();
      _sink?.close();
    } catch (_) {}
    _sink = null;

    final file = _file;
    if (file == null) {
      // If init was not done, try to init later.
      // ignore: discarded_futures
      _initFileSink();
      return;
    }

    final String dir = p.dirname(file.path);
    final String base = p.basenameWithoutExtension(file.path);
    final String ext = p.extension(file.path);
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String rotated = p.join(dir, '$base.$stamp$ext');

    try {
      file.renameSync(rotated);
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

    // Cleanup old files.
    final List<File> files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith(base))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

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
        byDay.putIfAbsent(key, () => <File>[]).add(f);
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

    _currentDay = DateTime.now();
    // ignore: discarded_futures
    _initFileSink();
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Daily rotation check (best-effort, non-async).
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

    // Buffer ALWAYS (even if sink isn't ready yet) to avoid dropping early logs.
    _addToBuffer(base);
    if (error != null) _addToBuffer(' -> ${_sanitizer.sanitize('$error')}');
    if (stackTrace != null) _addToBuffer(stackTrace.toString());

    // Best-effort init if not ready.
    if (_sink == null && !_initializing) {
      // ignore: discarded_futures
      _initFileSink();
    }

    // Size rotation (still sync; keep minimal change, avoid breaking behavior).
    if (_sink != null) {
      final size = (_file == null) ? 0 : (_file!.lengthSync());
      if (size > _maxFileSizeBytes) {
        _rotate();
      }
    }
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
}
