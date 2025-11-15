import 'package:flutter_riverpod/misc.dart';

import 'package:movi/src/core/config/env/environment.dart';
import 'package:movi/src/core/config/models/app_config.dart';
import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';

/// Crée l’ensemble des overrides de configuration à utiliser
/// dans un ProviderScope (tests, stories, flavors, etc.).
List<Override> createConfigOverrides(AppConfig config) {
  return [
    appConfigProvider.overrideWithValue(config),
    environmentProvider.overrideWithValue(config.environment),
    featureFlagsProvider.overrideWithValue(config.featureFlags),
    networkEndpointsProvider.overrideWithValue(config.network),
    appMetadataProvider.overrideWithValue(config.metadata),
  ];
}

/// Override ciblé des feature flags (utile pour les tests / stories).
Override overrideFeatureFlags(FeatureFlags flags) {
  return featureFlagsProvider.overrideWithValue(flags);
}

/// Override ciblé de l’environnement (dev, prod, etc.).
Override overrideEnvironment(EnvironmentFlavor flavor) {
  return environmentProvider.overrideWithValue(flavor);
}

/// Override ciblé des endpoints réseau.
Override overrideNetworkEndpoints(NetworkEndpoints endpoints) {
  return networkEndpointsProvider.overrideWithValue(endpoints);
}

/// Override ciblé des métadonnées d’app (nom, version, etc.).
Override overrideAppMetadata(AppMetadata metadata) {
  return appMetadataProvider.overrideWithValue(metadata);
}
