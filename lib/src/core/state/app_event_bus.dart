import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEventType { iptvSynced }

class AppEvent {
  final AppEventType type;
  const AppEvent(this.type);
}

class AppEventBus {
  AppEventBus();
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});