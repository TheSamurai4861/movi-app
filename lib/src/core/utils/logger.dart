/// Simple logger wrapper to centralise logging logic across the app.
class AppLogger {
  void debug(String message) {
    // ignore: avoid_print
    print('[DEBUG] $message');
  }

  void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  void warn(String message) {
    // ignore: avoid_print
    print('[WARN] $message');
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print(' -> $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}
