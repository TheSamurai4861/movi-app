import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Service pour la communication avec le code natif Android/iOS pour le PiP.
/// 
/// Utilise un MethodChannel pour communiquer avec les implémentations natives.
class NativePipService {
  NativePipService() {
    _channel.setMethodCallHandler(_handleMethodCall);
    _isActiveController = StreamController<bool>.broadcast();
  }

  static const MethodChannel _channel = MethodChannel('movi/native_pip');
  late final StreamController<bool> _isActiveController;
  bool _disposed = false;

  /// Stream des changements d'état du PiP (true = actif, false = inactif)
  Stream<bool> get isActiveStream => _isActiveController.stream;

  /// Vérifie si le PiP est supporté sur la plateforme actuelle
  Future<bool> isSupported() async {
    if (_disposed) return false;
    // PiP système uniquement sur Android/iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Entre en mode PiP
  Future<void> enter() async {
    if (_disposed) return;
    if (!await isSupported()) return;

    try {
      await _channel.invokeMethod('enter');
      _isActiveController.add(true);
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }
  }

  /// Sort du mode PiP
  Future<void> exit() async {
    if (_disposed) return;

    try {
      await _channel.invokeMethod('exit');
      _isActiveController.add(false);
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }
  }

  /// Gère les appels depuis le code natif
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipStateChanged':
        final isActive = call.arguments as bool? ?? false;
        if (!_isActiveController.isClosed) {
          _isActiveController.add(isActive);
        }
        break;
      case 'onUserLeaveHint':
        // Android notifie que l'utilisateur quitte l'app
        // On ne fait rien ici, c'est à VideoPlayerPage de décider
        // via didChangeAppLifecycleState ou un autre mécanisme
        break;
      default:
        throw MissingPluginException(
          'No implementation found for method ${call.method}',
        );
    }
  }

  /// Libère les ressources
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _isActiveController.close();
  }
}

