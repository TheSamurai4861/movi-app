import '../di/injector.dart';
import 'env/environment.dart';
import 'models/app_config.dart';
import 'models/app_metadata.dart';
import 'models/feature_flags.dart';
import 'services/secret_store.dart';

class AppConfigFactory {
  const AppConfigFactory(this._secretStore);

  final SecretStore _secretStore;

  Future<AppConfig> build({
    required EnvironmentFlavor flavor,
    FeatureFlags? featureOverrides,
    AppMetadata? metadataOverride,
  }) async {
    final tmdbKey = await _secretStore.read('TMDB_API_KEY');
    final network = flavor.network.copyWith(tmdbApiKey: tmdbKey);
    final flags = featureOverrides ?? flavor.defaultFlags;
    final metadata = metadataOverride ?? flavor.metadata;

    return AppConfig(
      environment: flavor,
      network: network,
      featureFlags: flags,
      metadata: metadata,
    );
  }
}

Future<AppConfig> registerConfig({
  required EnvironmentFlavor flavor,
  SecretStore? secretStore,
  FeatureFlags? featureOverrides,
  AppMetadata? metadataOverride,
}) async {
  final store = secretStore ?? SecretStore();
  _replace<SecretStore>(store);
  final factory = AppConfigFactory(store);
  final config = await factory.build(
    flavor: flavor,
    featureOverrides: featureOverrides,
    metadataOverride: metadataOverride,
  );
  _replace<EnvironmentFlavor>(flavor);
  _replace<AppConfig>(config);
  return config;
}

void _replace<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) {
    sl.unregister<T>();
  }
  sl.registerSingleton<T>(instance);
}
