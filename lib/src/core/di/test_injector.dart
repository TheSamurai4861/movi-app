import 'package:get_it/get_it.dart';

import '../config/models/app_config.dart';
import '../config/services/secret_store.dart';
import '../network/interceptors/locale_interceptor.dart';
import 'injector.dart';

/// Helper used in tests to reset the service locator and register fake config.
Future<void> initTestDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
}) async {
  await GetIt.I.reset();

  if (appConfig != null) {
    GetIt.I.registerSingleton<AppConfig>(appConfig);
  }
  if (secretStore != null) {
    GetIt.I.registerSingleton<SecretStore>(secretStore);
  }

  await initDependencies(
    appConfig: appConfig,
    secretStore: secretStore,
    localeProvider: localeProvider,
  );
}
