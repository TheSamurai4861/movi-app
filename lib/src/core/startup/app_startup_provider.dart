import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logging_module.dart';
import 'package:movi/src/core/preferences/preferences.dart';

final appStartupProvider = FutureProvider<void>((ref) async {
  WidgetsFlutterBinding.ensureInitialized();
  final loader = EnvironmentLoader();
  registerEnvironmentLoader(loader);
  final flavor = loader.load();
  debugPrint('avant registerConfig');
  final config = await registerConfig(
    flavor: flavor,
    requireTmdbKey: kReleaseMode,
  );
  debugPrint('après registerConfig OK');
  debugPrint('avant initDependencies');
  await initDependencies(
    appConfig: config,
    localeProvider: () => sl<LocalePreferences>().languageCode,
  );
  debugPrint('après initDependencies OK');
  debugPrint('avant LoggingModule.register');
  LoggingModule.register();
  debugPrint('après LoggingModule.register OK');
});