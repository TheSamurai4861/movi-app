import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movi/src/app.dart';
import 'package:movi/src/core/startup/app_startup_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser MediaKit pour le player vidéo
  MediaKit.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exception}');
  };
  WidgetsBinding.instance.platformDispatcher.onError =
      (Object error, StackTrace stack) {
        debugPrint('DispatcherError: $error');
        return true;
      };
  runApp(
    const ProviderScope(
      child: AppStartupGate(child: MyApp()),
    ),
  );
}
