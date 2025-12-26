import 'package:get_it/get_it.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/network/network.dart';

/// Disposable scope returned when initializing dependencies for tests.
class TestInjectorScope {
  TestInjectorScope._(this._popScope);

  final void Function() _popScope;

  void dispose() {
    _popScope();
  }
}

/// Helper used in tests to create an isolated GetIt scope with fake config.
Future<TestInjectorScope> initTestDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
  bool registerFeatureModules = false,
}) async {
  GetIt.I.pushNewScope();

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
    registerFeatureModules: registerFeatureModules,
  );

  return TestInjectorScope._(() => GetIt.I.popScope());
}
