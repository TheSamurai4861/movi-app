# Plan d’implémentation — `core/network`

## 1. Objectifs
- Fournir une stack HTTP commune (Dio) configurable par environnement.
- Centraliser la gestion des erreurs, des retries et de la télémétrie.
- Préparer l’intégration de modules consommateurs (movies, Xtream, etc.).

## 2. Étapes

### 2.1 Structure & Config
1. Créer `lib/src/core/network/` avec :
   - `config/network_module.dart` (registre GetIt).
   - `http_client_factory.dart`.
   - `network_executor.dart`.
   - `network_exceptions.dart`.
   - `interceptors/{auth,locale,telemetry,retry}_interceptor.dart`.
2. Ajouter `NetworkConfig` dans `core/config` (companion du `AppConfig.network` déjà défini).
3. Définir `NetworkEnvironmentMapper` qui traduit `AppConfig` → `BaseOptions` pour Dio.

### 2.2 HttpClientFactory
1. `HttpClientFactory` reçoit :
   - `AppConfig` (baseUrl, timeouts, UA).
   - `List<Interceptor>`.
2. Configure Dio :
   ```dart
   Dio(BaseOptions(
     baseUrl: config.network.restBaseUrl,
     connectTimeout: config.network.timeouts.connect,
     receiveTimeout: config.network.timeouts.receive,
     sendTimeout: config.network.timeouts.send,
     headers: {'User-Agent': config.metadata.versionTag},
   ));
   ```
3. Ajoute les interceptors dans l’ordre : `Auth` → `Locale` → `Retry` → `Telemetry`.

### 2.3 NetworkExecutor
1. Propose `Future<R> run<T, R>({required NetworkCall<T> call, required R Function(T data) mapper})`.
2. Intercepte `DioException` et mappe vers `NetworkFailure` (timeout, unauthorized, server, unknown).
3. Optionnel : support `ResponseType.bytes`/`stream` via paramètre.

### 2.4 Exceptions & Logs
1. `NetworkFailure` sous-types : `unauthorized`, `forbidden`, `notFound`, `rateLimited`, `timeout`, `unknown`.
2. Utiliser `TelemetryService` (stub) pour logguer latence + status.

### 2.5 Tests
1. Ajouter tests unitaires pour `NetworkExecutor` (mock `Dio`).
2. Tests d’intégration basiques sur `HttpClientFactory` (vérifier options).

## 3. Livrables
- Code complet sous `lib/src/core/network`.
- Module enregistré via `core/di`.
- Documentation courte (`README` ou `docs/core/networking_proposal.md` mise à jour) décrivant l’usage.
