import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/app.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/logging_module.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      LoggingModule.register();

      FlutterError.onError = (FlutterErrorDetails details) {
        sl<AppLogger>().error('FlutterError', details.exception, details.stack);
      };

      WidgetsBinding.instance.platformDispatcher.onError =
          (Object error, StackTrace stack) {
            sl<AppLogger>().error('DispatcherError', error, stack);
            return true;
          };

      final loader = EnvironmentLoader();
      registerEnvironmentLoader(loader);
      final flavor = loader.load();
      final config = await registerConfig(flavor: flavor);
      await initDependencies(appConfig: config);

      sl<AppLogger>().info('App start: flavor=$flavor');
      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      sl<AppLogger>().error('UncaughtError', error, stack);
    },
  );
}
