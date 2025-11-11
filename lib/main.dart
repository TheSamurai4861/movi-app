import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/core/config/config_module.dart';
import 'src/core/config/env/environment_loader.dart';
import 'src/core/di/injector.dart';
import 'src/core/logging/logging_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggingService.init(fileName: 'log.txt');

  // Capture les erreurs Flutter et asynchrones au niveau global
  FlutterError.onError = (FlutterErrorDetails details) async {
    // Logue l'exception et la stack (évite de re-jeter pour ne pas perdre le flush)
    await LoggingService.log('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      await LoggingService.log('Stack: ${details.stack}');
    }
  };

  // Capture des erreurs non gérées côté dispatcher (Flutter 3+)
  WidgetsBinding.instance.platformDispatcher.onError = (Object error, StackTrace stack) {
    // Retourne true pour indiquer que l'erreur a été gérée (évite crash immédiat)
    unawaited(LoggingService.log('DispatcherError: $error'));
    unawaited(LoggingService.log('Stack: $stack'));
    return true;
  };
  final loader = EnvironmentLoader();
  final flavor = loader.load();
  final config = await registerConfig(flavor: flavor);
  await initDependencies(appConfig: config);

  await LoggingService.log('App start: flavor=$flavor');

  // Zone de garde pour les exceptions Dart non interceptées
  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) async {
    await LoggingService.log('UncaughtError: $error');
    await LoggingService.log('Stack: $stack');
  });
}
