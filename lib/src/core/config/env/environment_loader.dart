// ignore_for_file: public_member_api_docs

import 'package:movi/src/core/config/services/platform_selector.dart';
import 'package:movi/src/core/config/env/dev_environment.dart';
import 'package:movi/src/core/config/env/environment.dart';

/// Function signature used to resolve a fallback [AppEnvironment]
/// when no `--dart-define` is provided.
typedef EnvironmentFallbackResolver = AppEnvironment Function(PlatformInfo info);

/// Central loader responsible for selecting the active [EnvironmentFlavor].
///
/// Priority:
/// 1. `override` parameter passed to [load]
/// 2. `--dart-define` values: APP_ENV / FLUTTER_APP_ENV
/// 3. Fallback resolver based on [PlatformInfo] (platform + release mode)
class EnvironmentLoader {
  EnvironmentLoader({
    PlatformInfo? platformInfo,
    EnvironmentFallbackResolver? fallbackResolver,
    void Function(String message)? onInfo,
  })  : platformInfo = platformInfo ?? const PlatformSelector(),
        _fallbackResolver = fallbackResolver ?? _defaultFallback,
        _onInfo = onInfo;

  /// Abstraction over the current platform (web, iOS, Android, desktop…).
  final PlatformInfo platformInfo;

  final EnvironmentFallbackResolver _fallbackResolver;
  final void Function(String message)? _onInfo;

  /// Cached flavor when [load] is called without an override.
  EnvironmentFlavor? _cached;

  // Precompute compile-time defines to avoid repeated `fromEnvironment` calls
  // at runtime (especially important on Web).
  static const String _defineAppEnv = String.fromEnvironment('APP_ENV');
  static const String _defineFlutterAppEnv = String.fromEnvironment(
    'FLUTTER_APP_ENV',
  );

  /// Resolve and return the active [EnvironmentFlavor].
  ///
  /// If [override] is provided, the cache is bypassed and a fresh flavor
  /// is created for that environment.
  EnvironmentFlavor load({AppEnvironment? override}) {
    if (override == null && _cached != null) {
      return _cached!;
    }

    final resolved = override ?? _resolveFromBuild();
    final flavor = createEnvironmentFlavor(resolved);

    if (override == null) {
      _cached = flavor;
    }

    return flavor;
  }

  /// Determines the [AppEnvironment] from compile-time defines,
  /// or falls back to [_fallbackResolver] when none are provided.
  AppEnvironment _resolveFromBuild() {
    final envFromDefine =
        _readDefine('APP_ENV') ?? _readDefine('FLUTTER_APP_ENV');

    if (envFromDefine != null) {
      return envFromDefine;
    }

    _onInfo?.call(
      'EnvironmentLoader: no --dart-define provided '
      '(platform=${platformInfo.currentPlatform}, '
      'release=${platformInfo.isReleaseMode}). Using fallback resolver.',
    );

    return _fallbackResolver(platformInfo);
  }

  /// Reads a compile-time env define and returns a parsed [AppEnvironment],
  /// or null if the value is absent or empty.
  AppEnvironment? _readDefine(String key) {
    final value = switch (key) {
      'APP_ENV' => _defineAppEnv,
      'FLUTTER_APP_ENV' => _defineFlutterAppEnv,
      _ => '',
    };

    if (value.isEmpty) return null;
    return _parse(value);
  }

  /// Parses a raw string (from defines) into an [AppEnvironment].
  ///
  /// Accepts several aliases:
  /// - dev, development
  /// - staging, stage
  /// - prod, production
  /// Unknown values fallback to [AppEnvironment.dev].
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

/// Default fallback resolver used by [EnvironmentLoader] when no
/// `--dart-define` is provided.
///
/// - iOS: always Dev
/// - Other platforms:
///   - Release mode → Prod
///   - Non-release → Dev
AppEnvironment _defaultFallback(PlatformInfo info) {
  if (info.currentPlatform == AppPlatform.ios) {
    return AppEnvironment.dev;
  }
  return info.isReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
}

/// Factory to create an [EnvironmentFlavor] from an [AppEnvironment].
///
/// Internally delegates to the flavor builders declared in `dev_environment.dart`.
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
