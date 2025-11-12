import '../services/platform_selector.dart';
import 'dev_environment.dart';
import 'environment.dart';

class EnvironmentLoader {
  const EnvironmentLoader({PlatformSelector? platformSelector})
    : platformSelector = platformSelector ?? const PlatformSelector();

  final PlatformSelector platformSelector;

  // Précompute compile-time defines to avoid runtime fromEnvironment calls on web.
  static const String _defineAppEnv = String.fromEnvironment('APP_ENV');
  static const String _defineFlutterAppEnv = String.fromEnvironment(
    'FLUTTER_APP_ENV',
  );

  EnvironmentFlavor load({AppEnvironment? override}) {
    final resolved = override ?? _resolveFromBuild();
    return createEnvironmentFlavor(resolved);
  }

  AppEnvironment _resolveFromBuild() {
    final envFromDefine =
        _readDefine('APP_ENV') ?? _readDefine('FLUTTER_APP_ENV');
    if (envFromDefine != null) {
      return envFromDefine;
    }
    // iOS: par défaut, utiliser l'environnement Dev si aucune variable compile-time n'est fournie.
    // Cela garantit qu'une clé TMDB valable (fallback Dev) est disponible sans --dart-define,
    // ce qui évite le basculement vers le fallback IPTV pour le Hero.
    if (platformSelector.currentPlatform == AppPlatform.ios) {
      return AppEnvironment.dev;
    }

    // Autres plateformes : prod en release, sinon dev.
    return platformSelector.isReleaseMode
        ? AppEnvironment.prod
        : AppEnvironment.dev;
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
