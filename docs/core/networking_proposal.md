# Core — Proposition d’implémentation pour la couche requêtes internet

## 1. Objectifs et contraintes MOVI
- **Couverture multiplateforme** : un unique socle Flutter pour mobile, desktop et TV nécessite une couche réseau unique, testable et configurable par environnement (dev/staging/prod, IPTV plus tard).
- **Scalabilité des features** : Home, Recherche, Playlists, IPTV et recommandations partageront la même stack. Elle doit être modulaire (`core/` vs `features/`) et injectable via GetIt.
- **Robustesse** : gestion native des erreurs REST, tolérance réseau (retry/backoff), instrumentation (logs, métriques) et observation pour la roadmap analytics décrite dans `docs/movi_overview.md`.

## 2. Architecture proposée (`lib/src/core/network/`)

```
core/network/
├── config/
│   ├── network_environment.dart       # URLs, clés API, timeouts par environnement
│   └── network_config.dart            # DTO immuable exposé au reste de l'app
├── http_client_factory.dart           # Construit Dio à partir de NetworkConfig
├── interceptors/
│   ├── auth_interceptor.dart          # Injecte token/session IPTV (quand prêt)
│   ├── locale_interceptor.dart        # Ajoute Accept-Language
│   ├── telemetry_interceptor.dart     # Logs structurés + Hook vers analytics
│   └── retry_interceptor.dart         # Backoff exponentiel + circuit breaker léger
├── network_executor.dart              # Helper pour exécuter les requêtes en SafeCall
├── network_exceptions.dart            # Mapping DioError -> NetworkFailure
├── connectivity_service.dart          # Wrapper sur connectivity_plus + cache état
└── serializers/
    └── json_serializer.dart           # Centralise jsonDecode/jsonEncode + configs
```

### 2.1 HttpClientFactory (Dio)
```dart
class HttpClientFactory {
  HttpClientFactory(this._config, this._interceptors);

  final NetworkConfig _config;
  final List<Interceptor> _interceptors;

  Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: _config.timeouts.connect,
      receiveTimeout: _config.timeouts.receive,
      headers: {'User-Agent': _config.userAgent},
    ));
    dio.interceptors.addAll(_interceptors);
    return dio;
  }
}
```
_Pourquoi Dio ?_ : support solide pour interceptors/Retry, cancellation, multipart, et compatibilité avec `retrofit` ou `chopper` si besoin plus tard. L’objectif est d’exposer uniquement un `Dio` configuré depuis `core` et de conserver les repositories côté `features/*/data` fins et testables.

### 2.2 Interceptors clés
- **AuthInterceptor** : récupère le token auprès d’un `AuthTokenProvider` (GetIt) pour gérer TMDB + futur IPTV sans dupliquer la logique.
- **LocaleInterceptor** : lit `AppLocaleStore` (déjà prévu pour settings) pour enrichir `Accept-Language` et `Region`.
- **TelemetryInterceptor** : envoie les métriques (latence, code HTTP, endpoint) vers un `TelemetryService` (placeholder). Compatible avec les ambitions analytics (section 3.8 de `movi_overview`).
- **RetryInterceptor** : applique un backoff exponentiel sur les erreurs réseau (408/429/5xx) avec jitter + compteur max configurable dans `NetworkConfig`.

### 2.3 NetworkExecutor
Objectif : standardiser la gestion des erreurs, des cancellations et du parsing.
```dart
typedef NetworkCall<T> = Future<Response<T>> Function(Dio client);

class NetworkExecutor {
  NetworkExecutor(this._client);
  final Dio _client;

  Future<R> run<T, R>({
    required NetworkCall<T> call,
    required R Function(T data) mapper,
  }) async {
    try {
      final response = await call(_client);
      return mapper(response.data as T);
    } on DioException catch (error) {
      throw NetworkFailure.fromDio(error);
    }
  }
}
```
Chaque data source remote aura uniquement à fournir la requête et le mapper vers son DTO. `NetworkFailure` expose des sous-types (`unauthorized`, `notFound`, `rateLimited`, `timeout`, `unknown`) pour une remontée contrôlée jusqu’au domain.

### 2.4 ConnectivityService
- S’appuie sur `connectivity_plus` + ping léger vers l’API pour confirmer l’état réel.
- Expose un `Stream<ConnectivityStatus>` consommable par les controllers (ex. afficher un banner offline sur Home).
- Permet de cortiquer la future persistance offline (section 3.7 de l’overview).

## 3. Sécurité, performances et observabilité
- **Sécurité** : stockage chiffré des clés (Flutter secure storage). L’interceptor d’auth expire automatiquement les tokens TMDB/IPTV et redirige vers un `AuthRepository`.
- **Performances** : pooling Dio, compression gzip activée, support HTTP/2 par défaut. Possibilité d’activer un cache ETag/If-Modified-Since via un interceptor additionnel.
- **Observabilité** : logs structurés (JSON) uniquement en `dev`; en prod, on envoie des événements vers Sentry/DataDog. Chaque requête possède un `requestId` injecté dans les headers pour le tracing cross-service.

## 4. Intégration côté features
1. `core/network` expose un `NetworkModule` (GetIt) qui enregistre :
   - `NetworkConfig` (par env)
   - `Dio` configuré
   - `NetworkExecutor`
   - `ConnectivityService`
2. Chaque repository remote (ex. `MovieRemoteDataSource`) injecte `NetworkExecutor`.
3. Mapping DTO → domain reste dans la couche data existante ; aucune dépendance UI.

## 5. Roadmap d’implémentation
1. **Sprint 1** : créer le package `core/network`, tests unitaires sur `NetworkExecutor` + `NetworkFailure`.
2. **Sprint 2** : brancher MovieRepository (TMDB) en remote-only pour valider la stack (Home hero/reco).
3. **Sprint 3** : ajouter le monitoring (TelemetryInterceptor) + gestion offline basique via `ConnectivityService`.
4. **Sprint 4** : préparer l’extension IPTV (auth personnalisée + endpoints multiples) en enrichissant `NetworkEnvironment`.

Cette proposition répond aux exigences de modularité, fiabilité et observabilité listées dans `docs/movi_overview.md`, tout en restant compatible avec les futures évolutions (IPTV, analytics, offline). Elle fournit un socle « pro » que l’on pourra étendre avec du caching local (Hive/Isar) et des workers de synchronisation lorsque les besoins data/domain seront finalisés.
