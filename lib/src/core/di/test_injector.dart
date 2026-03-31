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
  bool allowAuthStubFallback = false,
  bool allowInMemoryStorageFallback = false,
}) async {
  GetIt.I.pushNewScope();

  final resolvedAppConfig = _resolveTestAppConfig(
    appConfig: appConfig,
    allowAuthStubFallback: allowAuthStubFallback,
    allowInMemoryStorageFallback: allowInMemoryStorageFallback,
  );

  if (resolvedAppConfig != null) {
    GetIt.I.registerSingleton<AppConfig>(resolvedAppConfig);
  }
  if (secretStore != null) {
    GetIt.I.registerSingleton<SecretStore>(secretStore);
  }

  await initDependencies(
    appConfig: resolvedAppConfig,
    secretStore: secretStore,
    localeProvider: localeProvider,
    registerFeatureModules: registerFeatureModules,
  );

  return TestInjectorScope._(() => GetIt.I.popScope());
}

AppConfig? _resolveTestAppConfig({
  required AppConfig? appConfig,
  required bool allowAuthStubFallback,
  required bool allowInMemoryStorageFallback,
}) {
  if (appConfig == null) {
    if (allowAuthStubFallback || allowInMemoryStorageFallback) {
      throw ArgumentError(
        'initTestDependencies requires an AppConfig when explicit fallback '
        'flags are enabled.',
      );
    }
    return null;
  }

  return appConfig.copyWith(
    featureFlags: appConfig.featureFlags.copyWith(
      allowAuthStubFallback: allowAuthStubFallback,
      allowInMemoryStorageFallback: allowInMemoryStorageFallback,
    ),
  );
}
