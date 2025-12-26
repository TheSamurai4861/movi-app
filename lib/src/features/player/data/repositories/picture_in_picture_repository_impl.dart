import 'dart:async';

import 'package:movi/src/features/player/domain/repositories/picture_in_picture_repository.dart';
import 'package:movi/src/features/player/data/services/native_pip_service.dart';

/// Implémentation du PictureInPictureRepository pour Android/iOS
/// Utilise NativePipService pour communiquer avec le code natif
class PictureInPictureRepositoryImpl implements PictureInPictureRepository {
  PictureInPictureRepositoryImpl() {
    _nativePipService = NativePipService();
    _subscription = _nativePipService.isActiveStream.listen((isActive) {
      if (!_isActiveController.isClosed) {
        _isActiveController.add(isActive);
      }
    });
  }

  late final NativePipService _nativePipService;
  late final StreamSubscription<bool> _subscription;
  late final StreamController<bool> _isActiveController =
      StreamController<bool>.broadcast();
  bool _disposed = false;

  @override
  Future<bool> isSupported() async {
    if (_disposed) return false;
    return await _nativePipService.isSupported();
  }

  @override
  Future<void> enter() async {
    if (_disposed) return;
    if (!await isSupported()) return;
    await _nativePipService.enter();
  }

  @override
  Future<void> exit() async {
    if (_disposed) return;
    await _nativePipService.exit();
  }

  @override
  Stream<bool> get isActiveStream => _isActiveController.stream;

  @override
  dynamic get windowController => null; // Android/iOS n'utilise pas de WindowController

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription.cancel();
    _isActiveController.close();
    _nativePipService.dispose();
  }
}

