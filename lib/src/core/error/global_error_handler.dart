import 'dart:isolate';

import 'package:flutter/foundation.dart';

bool _initialized = false;
RawReceivePort? _isolateErrorPort;

/// Configure global error handling for the app.
///
/// This sets up:
/// - FlutterError.onError for framework-level errors.
/// - PlatformDispatcher.onError for engine/platform-level errors.
/// - Isolate-level error listener for uncaught errors in the current isolate.
///
/// IMPORTANT:
/// - This should be called once, early (before runApp).
void setupGlobalErrorHandling() {
  if (_initialized) return;
  _initialized = true;

  // 1) Framework-level errors (widgets, rendering, async in Flutter zone).
  FlutterError.onError = (FlutterErrorDetails details) {
    // Keep Flutter's default behavior in debug (prints nice error formatting).
    FlutterError.dumpErrorToConsole(details);

    // Still print a compact line for log grep.
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    final stack = details.stack;
    if (stack != null) {
      debugPrint('Stack trace:\n$stack');
    }
  };

  // 2) Engine / platform-level errors (plugins, platform channels, native code).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcherError: $error');
    debugPrint('Stack trace:\n$stack');

    // Returning true indicates we handled the error (prevents default propagation when possible).
    // If you want the app to crash in debug to catch issues, you can conditionally return false.
    return true;
  };

  // 3) Isolate-level errors (current isolate only).
  // Keep the port alive; otherwise it may be GC'ed and the listener stops working.
  _isolateErrorPort ??= RawReceivePort((dynamic pair) {
    try {
      final list = pair as List<dynamic>;
      final Object error = list.isNotEmpty ? list[0] as Object : 'Unknown isolate error';
      final StackTrace stack = (list.length > 1 && list[1] is StackTrace)
          ? list[1] as StackTrace
          : StackTrace.current;

      debugPrint('IsolateError: $error');
      debugPrint('Stack trace:\n$stack');
    } catch (e, s) {
      debugPrint('IsolateErrorListener parsing failed: $e');
      debugPrint('Stack trace:\n$s');
    }
  });

  Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);
}
