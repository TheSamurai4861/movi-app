import '../services/platform_selector.dart';
import 'dev_environment.dart';
import 'environment.dart';

class EnvironmentLoader {
  const EnvironmentLoader({PlatformSelector? platformSelector})
      : platformSelector = platformSelector ?? const PlatformSelector();

  final PlatformSelector platformSelector;

  EnvironmentFlavor load({AppEnvironment? override}) {
    final resolved = override ?? _resolveFromBuild();
    return createEnvironmentFlavor(resolved);
  }

  AppEnvironment _resolveFromBuild() {
    final envFromDefine = _readDefine('APP_ENV') ?? _readDefine('FLUTTER_APP_ENV');
    if (envFromDefine != null) {
      return envFromDefine;
    }
    return platformSelector.isReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
  }

  AppEnvironment? _readDefine(String key) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) {
      return null;
    }
    return _parse(value);
  }

  AppEnvironment _parse(String raw) {
    switch (raw.toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }
}

EnvironmentFlavor createEnvironmentFlavor(AppEnvironment environment) {
  switch (environment) {
    case AppEnvironment.dev:
      return DevEnvironment();
    case AppEnvironment.staging:
      return StagingEnvironment();
    case AppEnvironment.prod:
      return ProdEnvironment();
  }
}
