class FocusDebugLogger {
  const FocusDebugLogger({this.enabled = false, this.sink});

  final bool enabled;
  final void Function(String message)? sink;

  void log(String message) {
    if (!enabled) return;
    sink?.call(message);
  }
}
