import 'package:movi/src/core/config/services/platform_selector.dart';
import 'package:movi/src/core/config/env/dev_environment.dart';
import 'package:movi/src/core/config/env/environment.dart';

typedef EnvironmentFallbackResolver =
    AppEnvironment Function(PlatformInfo info);

class EnvironmentLoader {
  EnvironmentLoader({
    PlatformInfo? platformInfo,
    EnvironmentFallbackResolver? fallbackResolver,
    void Function(String message)? onInfo,
  }) : platformInfo = platformInfo ?? const PlatformSelector(),
       _fallbackResolver = fallbackResolver ?? _defaultFallback,
       _onInfo = onInfo;

  final PlatformInfo platformInfo;
  final EnvironmentFallbackResolver _fallbackResolver;
  final void Function(String message)? _onInfo;
  EnvironmentFlavor? _cached;

  // Précompute compile-time defines to avoid runtime fromEnvironment calls on web.
  static const String _defineAppEnv = String.fromEnvironment('APP_ENV');
  static const String _defineFlutterAppEnv = String.fromEnvironment(
    'FLUTTER_APP_ENV',
  );

  EnvironmentFlavor load({AppEnvironment? override}) {
    if (override == null && _cached != null) return _cached!;
    final resolved = override ?? _resolveFromBuild();
    final flavor = createEnvironmentFlavor(resolved);
    if (override == null) _cached = flavor;
    return flavor;
  }

  AppEnvironment _resolveFromBuild() {
    final envFromDefine =
        _readDefine('APP_ENV') ?? _readDefine('FLUTTER_APP_ENV');
    if (envFromDefine != null) {
      return envFromDefine;
    }
    _onInfo?.call(
      'EnvironmentLoader: no --dart-define provided, using fallback resolver.',
    );
    return _fallbackResolver(platformInfo);
  }

  AppEnvironment? _readDefine(String key) {
    final value = switch (key) {
      'APP_ENV' => _defineAppEnv,
      'FLUTTER_APP_ENV' => _defineFlutterAppEnv,
      _ => '',
    };
    if (value.isEmpty) return null;
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

AppEnvironment _defaultFallback(PlatformInfo info) {
  if (info.currentPlatform == AppPlatform.ios) {
    return AppEnvironment.dev;
  }
  return info.isReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
}

EnvironmentFlavor createEnvironmentFlavor(AppEnvironment environment) {
  switch (environment) {
    case AppEnvironment.dev:
      return createDevEnvironment();
    case AppEnvironment.staging:
      return createStagingEnvironment();
    case AppEnvironment.prod:
      return createProdEnvironment();
  }
}
