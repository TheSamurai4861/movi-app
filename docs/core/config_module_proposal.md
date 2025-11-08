# Core — Proposition pour le module configuration / environnements

## 1. Objectifs MOVI
- **Unifier les paramètres** (base URLs, clés, feature flags) pour toutes les plateformes supportées par MOVI sans multiplier les fichiers `main_<env>.dart`.
- **Rester « clean architecture »** : la configuration vit dans `core/`, est injectée via GetIt et reste agnostique des features.
- **Limiter la complexité** : mobile-first (cf. `docs/questions/architecture_decisions.md`), pas de multi-app, mais préparer l’ouverture future (desktop/TV, IPTV).

## 2. Structure proposée (`lib/src/core/config/`)
```
core/config/
├── config_module.dart          # Méthode registerConfig() appelée au bootstrap
├── env/
│   ├── environment.dart        # Enum + interface EnvironmentFlavor
│   ├── dev_environment.dart    # Implémentations concrètes (dev, staging, prod)
│   └── environment_loader.dart # Sélectionne l'env (paramètre CLI, file, var)
├── models/
│   ├── network_endpoints.dart  # URLs TMDB/IPTV, timeouts
│   ├── feature_flags.dart      # Toggles (ex: homeFeedRemote, newSearch)
│   ├── app_metadata.dart       # Version, build, support contact
│   └── app_config.dart         # Objet racine immuable agrégant le tout
├── providers/
│   ├── config_provider.dart    # Riverpod + GetIt hook pour AppConfig
│   └── overrides.dart          # Helpers pour tests (override flags, URLs)
└── services/
    ├── secret_store.dart       # Accès aux secrets (API key TMDB) + fallback
    └── platform_selector.dart  # Source unique de la plateforme courante
```

### Points clés
- `AppConfig` est **immutabilité + Equatable** pour simplifier les tests et diff.
- `EnvironmentLoader` effectue la résolution dans l’ordre : argument Flutter (`--dart-define=APP_ENV=staging`), variable d’environnement (utile Codemagic), fallback dev.
- `config_module.dart` enregistre `AppConfig`, `SecretStore`, `EnvironmentFlavor` dans GetIt + expose un provider Riverpod si nécessaire.

## 3. Modèle de données
```dart
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.network,
    required this.featureFlags,
    required this.metadata,
  });

  final EnvironmentFlavor environment;
  final NetworkEndpoints network;
  final FeatureFlags featureFlags;
  final AppMetadata metadata;
}

class FeatureFlags {
  const FeatureFlags({
    this.useRemoteHome = false,
    this.enableTelemetry = false,
    this.enableDownloads = false,
  });

  final bool useRemoteHome;
  final bool enableTelemetry;
  final bool enableDownloads;
}
```
Ces modèles restent volontairement simples (prêts pour l’extension IPTV ou offline) et alignés sur les besoins listés dans `docs/movi_overview.md`.

## 4. Flux d’utilisation
1. **Bootstrap** (`main.dart`) :
   ```dart
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final loader = EnvironmentLoader();
     final flavor = loader.load();
     final config = await registerConfig(flavor: flavor);
     await initDependencies(appConfig: config);
     runApp(const ProviderScope(child: MoviApp()));
   }
   ```
2. **Injection** : les data sources, services réseau ou UI consomment `AppConfig` via GetIt ou Riverpod (`ref.watch(appConfigProvider)`).
3. **Override Tests** :
   - `config/providers/overrides.dart` fournit `createConfigOverrides` pour `ProviderScope`.
   - `core/di/test_injector.dart` remet GetIt à zéro et réinjecte un `AppConfig` fake pour les tests unitaires.

## 5. Gestion des secrets et limites projet
- Les clés TMDB/IPTV sont chargées par `SecretStore` (fichier `.env`, secure storage, ou variables Codemagic). Aucun `const String apiKey = ...` dans le repo.
- Pas de génération d’app flavors multiples : une seule app, mais l’env choisi pilote les endpoints et flags.
- Pour rester léger, pas d’outil tiers (Flutter flavors, Firebase Remote Config) tant que ce n’est pas requis.

## 6. Roadmap d’implémentation
1. **Sprint actuel**
   - Créer `lib/src/core/config/` avec `AppConfig`, `EnvironmentFlavor`, `registerConfig`.
   - Support des env `dev` (localhost/mock), `staging`, `prod`.
   - Intégrer au bootstrap + exposer `AppConfig` dans GetIt.
2. **Sprint +1**
   - Ajouter `FeatureFlags` réels pour Home remote / expérimentation recherche.
   - Connecter `NetworkModule` pour lire `config.network`.
3. **Sprint +2**
   - Introduire `SecretStore` sécurisé + gestion dynamique via Codemagic (`--dart-define`).
   - Préparer les hooks pour `TelemetryService` (en fonction de `featureFlags.enableTelemetry`).

Ce module garde `core/` simple, extensible et respecte les limites actuelles (app mobile unique, standard naming, pas de bundles tests imposés) tout en préparant les besoins listés dans `docs/movi_overview.md` et `docs/questions/architecture_decisions.md`.
