# Audit du module `lib/src/core`

_Date : 2025-11-15_

## Résumé exécutif
- La structure `core/` couvre bien toutes les couches transverses (config, stockage, réseau, thème, widgets partagés), mais on observe une forte dépendance au service locator global `sl` qui rend la lisibilité et les tests compliqués.
- Plusieurs implémentations se veulent "clean architecture", pourtant elles mélangent infrastructure et UI (ex. widgets qui manipulent directement `GoRouter`, routeur qui parle à la base locale via `sl`).
- Les aspects sensibles (sécurité des identifiants, logging, gestion de la config) manquent de séparation claire ou de garanties (chiffrement léger, absence de cycle de vie pour les loggers, etc.).
- En optimisation, la plupart des classes sont correctes mais pourraient gagner en immutabilité typée, meilleure gestion mémoire (cache réseau global statique), et instrumentation (tests unitaires manquants, pas de métriques sur la base SQLite, etc.).

## Recommandations transverses
1. **Injection / modularisation** : remonter un builder unique qui assemble AppConfig, NetworkExecutor, loggers et stockage via des interfaces et non via `sl` statique. Les composants UI devraient recevoir leurs dépendances via `ProviderScope` ou `GoRouter` state.
2. **Sécurité** : remplacer `CredentialsVaultImpl` par `SecureCredentialsVault` partout, supprimer l'algorithme XOR maison, traiter la suppression par clé et auditer les accès au cache SQLite.
3. **Observabilité** : unifier `AppLogger` et `LoggingService` (actuellement deux implémentations concurrentes) et prévoir une API de fermeture/dump pour éviter les fuites (timers, IO non flushés).
4. **Réseau** : séparer les clients TMDB/Backend (base URL + header) et supprimer l'utilisation du TMDB API key comme Bearer générique. Le `NetworkExecutor` doit accepter un `CancelToken` et fournir un reset complet par instance au lieu de statiques.
5. **Stockage** : centraliser l'accès au `Database` (repository abstrait + DAO) et ajouter des limites (LRU, purge) pour `content_cache`, `history`, `continue_watching`.
6. **Widgets** : découpler la navigation (`GoRouter`) et les assets statiques des composants afin de les tester, ajouter de l'accessibilité (Semantics) et injecter les actions via callbacks uniquement.

## Détails par dossier et par fichier
### `config/`
- `lib/src/core/config/config.dart` : simple barrel file, RAS mais ajouter un commentaire indiquant l'ordre d'export souhaité.
- `lib/src/core/config/config_module.dart` : `registerConfig` remplace les singletons sans cycle de vie ni isolation par scope. Prévoir une factory pure + un enregistrement paresseux par `Provider`. Penser à injecter `SecretStore`/`EnvironmentLoader` au lieu d'appeler `_replace` à la volée.
- `lib/src/core/config/env/environment.dart` : data class minimale ; ajouter `==/hashCode` pour faciliter les tests et la comparaison de flavors.
- `lib/src/core/config/env/environment_loader.dart` : bonnes optimisations compile-time, mais `_resolveFromBuild` force `dev` sur iOS (ligne ~36) sans possibilité de config utilisateur → exposer un override via `PlatformInfo`. Ajouter un log lorsque les `--dart-define` sont absents.
- `lib/src/core/config/env/dev_environment.dart` : les fonctions `create*Environment` dupliquent beaucoup d'options (timeouts, flags). Extraire un builder commun et surtout documenter l'absence de fallback TMDB (commentaire ligne ~28 non respecté).
- `lib/src/core/config/models/app_config.dart` : très complet, mais `==` compare map par valeur alors que `hashCode` (lignes ~94-133) hashe les références, ce qui casse `Set<AppConfig>`. Introduire `package:collection` (`DeepCollectionEquality`). Prévoir un mode `skipTmdbValidation` pour les environnements IPTV-only.
- `lib/src/core/config/models/app_metadata.dart` et `feature_flags.dart` : RAS fonctionnel. Pour aller vers la clean archi, déplacer les sous-flags (`HomeFlags`, `TelemetryFlags`…) dans la couche domain qui les consomme.
- `lib/src/core/config/models/logging_config.dart` : manque d'`==`/`hashCode`, on ne peut pas détecter un changement pour redémarrer les loggers. Ajouter la conversion `copyWith` pour les `Map` (copie défensive) et fournir un `validate()` garantissant que `sampling` ∈ [0,1].
- `lib/src/core/config/models/network_endpoints.dart` : getters utiles mais `joinRestPath`/`joinImagePath` concatènent des chaînes au lieu d'utiliser `Uri`. Renforcer avec `Uri.resolve` et valider que `restBaseUrl` est une URL absolue.
- `lib/src/core/config/providers/config_provider.dart` : chaque provider lit `sl` directement; préférez `ProviderScope` avec overrides issus de `registerConfig` pour dissocier infra/UI. Ajouter un `Provider<LoggingConfig>` pour éviter les `sl` directs côté features.
- `lib/src/core/config/providers/overrides.dart` : dépend de `package:flutter_riverpod/misc.dart` (API non supportée). Remplacer par `package:flutter_riverpod/flutter_riverpod.dart`. Ajouter des helpers pour override partiel (ex. `overrideNetworkTimeouts`).
- `lib/src/core/config/services/platform_selector.dart` : RAS, mais offrir une implémentation `TestPlatformInfo` pour les tests.
- `lib/src/core/config/services/secret_store.dart` : bon `conditional export`.
- `lib/src/core/config/services/secret_store_io.dart` : lecture `.env` utile mais aucune persistance sécurisée (tout est en clair) et `_envFileCache` n'est jamais rafraîchi ==> ajouter un TTL ou `invalidateCache()`. Prévoir une API `write` qui synchronise l'env file (actuellement no-op).
- `lib/src/core/config/services/secret_store_web.dart` : simple map, acceptable. Ajouter un commentaire expliquant comment injecter les secrets par `preload()`.

### `di/`
- `lib/src/core/di/di.dart` : barrel. Documenter qu'il expose `sl`.
- `lib/src/core/di/injector.dart` : `initDependencies` appelle `LoggingModule.register()` avant même d'avoir un `AppConfig` enregistré -> crash possible. Proposer un `BootstrapPipeline` (Config → Secrets → Storage → Network). `_registerTmdb` déclenche l'enregistrement de tous les modules features dans `core`, ce qui casse la séparation domain/data. Externaliser chaque module dans son dossier `features/*`.
- `lib/src/core/di/services/content_repository.dart` & `preferences_service.dart` : abstractions vides; déplacer dans `shared/domain` pour briser la dépendance vers `core/di`.
- `lib/src/core/di/test_injector.dart` : `GetIt.I.reset()` efface tous les singletons, mais `initDependencies` recrée des singletons globaux (DB, Dio) qui polluent les tests parallèles. Prévoir un `scope` GetIt (`pushNewScope`) ou un bootstrap minimal pour tests unitaires.

### `logging/`
- `lib/src/core/logging/logger.dart` : base OK.
- `lib/src/core/logging/logging_module.dart` : oublie de disposer les loggers (fils FileLogger/RateLimitingLogger ont des timers). Ajouter une API `LoggingModule.dispose()` appelée à l'arrêt/app switch profile.
- `lib/src/core/logging/logging_service.dart` : service optionnel mais complètement séparé de `AppLogger`. Décider d'une seule implémentation (idéalement `AppLogger`). En l'état, `LoggingService.log` flush sur disque à chaque appel (ligne ~31), ce qui est coûteux.
- `lib/src/core/logging/adapters/file_logger.dart` : gère rotation/compression mais dépend de `path_provider` (non dispo sur tests) et ne ferme jamais `_timer`/`_sink` sauf via `dispose()` non appelé. Ajouter `AppLifecycleObserver` + `Dispose`. Prévoir un fallback no-op sur web.
- `lib/src/core/logging/adapters/console_logger.dart` : OK, penser à injecter `debugPrintThrottled` pour tests.
- `lib/src/core/logging/category_logger.dart`, `level_filtering_logger.dart`, `sampling_logger.dart` : conceptuellement bons. Ajouter un `dispose()` dans `SamplingLogger`/`RateLimitingLogger` si des ressources apparaissent.
- `lib/src/core/logging/rate_limiting_logger.dart` : démarre un `Timer.periodic` (ligne ~22) jamais annulé → fuite. Utiliser `Timer? _timer` + `dispose`.
- `lib/src/core/logging/sanitizer/message_sanitizer.dart` : couverture large. Ajouter la possibilité de nourrir `_sensitiveKeys` depuis la config.
- `lib/src/core/logging/logging.dart` : barrel, RAS.

### `models/`
- `lib/src/core/models/models.dart` : barrel.
- `lib/src/core/models/movi_media.dart` : structure simpliste (`poster`, `rating`, `year` en `String`). Pour la clean archi, exposer un `Media` côté domaine (int year, double rating) et laisser l'infrastructure adapter.
- `lib/src/core/models/movi_person.dart` : idem, manque `Equatable`/`copyWith`.

### `network/`
- `lib/src/core/network/network.dart` : barrel.
- `lib/src/core/network/network_executor.dart` : très riche mais quelques points :
  - le champ `cancelToken` de `run` n'est jamais transmis à `request` → annulation impossible.
  - `_memoryCache`, `_limiters`, `_inflight` sont statiques (lignes ~48-65) => toutes les instances partagent l'état, même entre tests/environnements. Exposer `dispose()` ou les rendre membres d'instance.
  - Caching stocke un `Response` Dio complet dans `_memoryCache` (ligne ~126), qui contient parfois des `Stream`. Sauvegarder uniquement `response.data` + métadonnées.
  - `dedupKey` n'est jamais invalidé si `mapper` lance une exception (il reste absent du cache). Ajouter un `try/finally`.
- `lib/src/core/network/network_failures.dart` : OK, envisager d'étendre `Failure.code`.
- `lib/src/core/network/dio_failure_mapper.dart` : ne gère pas `badCertificate` (devrait être Failure dédié) et ne passe pas le `statusCode` dans `ServerFailure`.
- `lib/src/core/network/interceptors/auth_interceptor.dart` : très limité (Bearer statique). Prévoir un token provider capable de refresh + logguer l'échec.
- `lib/src/core/network/interceptors/locale_interceptor.dart` : simple, mais `LocaleCodeProvider` devrait permettre un `Stream`/`ValueNotifier` pour mise à jour dynamique.
- `lib/src/core/network/interceptors/retry_interceptor.dart` : ne respecte pas `CancelToken` (on relance des requêtes même si l'appel initial est annulé) et duplique le payload synchroniquement (risque `Stream` replays). Préférer un wrapper `NetworkExecutor`.
- `lib/src/core/network/interceptors/telemetry_interceptor.dart` : log en `debug` toutes les requêtes; prévoir un flag `TelemetryFlags.enableTelemetry` pour couper en prod.
- `lib/src/core/network/http_client_factory.dart` : mélange TMDB et backend interne : l'intercepteur Auth applique `tmdbApiKey` à toutes les routes (lignes ~29-34). Il faut au minimum injecter un `TokenResolver` spécifique à l'API ciblée et ne pas aller relire le secret store à chaque appel (mettre en cache en mémoire).
- `lib/src/core/network/config/network_module.dart` : enregistre `NetworkExecutor` une fois et n'offre pas de `dispose`. Lors d'un changement d'environnement (ex. `AppConfig` override), l'ancien `Dio` reste vivant. Prévoir `replaceSingleton` + `Dio.close()`.

### `preferences/`
- `lib/src/core/preferences/preferences.dart` : barrel.
- `lib/src/core/preferences/locale_preferences.dart` : implémentation mémorielle uniquement; la langue n'est pas persistée. Injecter `SharedPreferences`/`Hive` ou utiliser `FlutterSecureStorage`. Ajouter la notion de `Stream` pour écouter les changements.

### `router/`
- `lib/src/core/router/router.dart` : barrel.
- `lib/src/core/router/app_router.dart` : `GoRouter` global construit avec plein de dépendances directes (pages importées). Pour clean archi : exposer `AppRouteNames` + builder `createRouter(AppState appState, AppLogger logger)`. Dans `_LaunchGate`, l'accès direct à `sl<IptvLocalRepository>()` au démarrage déclenche un `await` sans gestion d'erreur ni cancellation; déplacer cette logique dans une `FutureProvider` + `GoRouter.redirect`. Éviter `LoggingService` ici -> utiliser `AppLogger`.

### `security/`
- `lib/src/core/security/credentials_vault.dart` : chiffrement XOR + clé stockée en clair dans `content_cache` => ne protège rien. Remplacer par `SecureCredentialsVault`. Bug : `removePassword` appelle `_cache.clearType('secret')` (ligne ~67) et efface toutes les entrées. Il faut cibler la clé `secret_pw_$accountId`.
- `lib/src/core/security/secure_credentials_vault.dart` : OK pour mobile, mais prévoir une implémentation desktop/web. Ajouter `IOSOptions/AndroidOptions` pour renforcer la sécurité.

### `shared/`
- `lib/src/core/shared/failure.dart` : base `Equatable`. Ajouter une factory `Failure.fromException` pour homogénéiser le mapping dans toutes les couches.

### `state/`
- `lib/src/core/state/state.dart` : barrel.
- `lib/src/core/state/app_state.dart` : modèle simple. Pour propre clean archi, séparer `AppState` (domain) de l'infrastructure Riverpod.
- `lib/src/core/state/app_state_controller.dart` : import `package:flutter_riverpod/legacy.dart`; migrer vers `hooks_riverpod` v2. Les méthodes `add/removeIptvSource` manipulent un `List<String>` ordinaire → utiliser des `Set` pour clarté. Penser à exposer un `Stream` pour l'état réseau.
- `lib/src/core/state/app_state_provider.dart` : pareil, migrer vers `flutter_riverpod/flutter_riverpod.dart` et fournir une surcouche `NotifierProvider`.

### `storage/`
- `lib/src/core/storage/storage.dart` : barrel.
- `lib/src/core/storage/storage_failures.dart` : définis mais jamais utilisés; décider si on mappe réellement les erreurs vers cette hiérarchie.
- `lib/src/core/storage/services/storage_module.dart` : n'enregistre ni `PlaylistLocalRepository`, ni `SecureStorageRepository`, ni `CredentialsVault`. Ajouter ces singletons et documenter la marche à suivre pour tests (ne pas ouvrir SQLite reel). Penser à fermer `Database` lors du shutdown.
- `lib/src/core/storage/services/cache_policy.dart` : dépend de `DateTime.now()`; injecter un `Clock` pour rendre testable.
- `lib/src/core/storage/database/sqlite_database.dart` : bonne config de migrations, mais `openDatabase` n'active pas `PRAGMA foreign_keys = ON` ni WAL. À ajouter dans `onConfigure`. Sur desktop, `getApplicationDocumentsDirectory` nécessite `WidgetsFlutterBinding.ensureInitialized`; garantir cet appel côté bootstrap.
- `lib/src/core/storage/repositories/content_cache_repository.dart` : `get` ne tient pas compte d'une politique TTL -> penser à supprimer les entrées expirées ou fournir un TTL par type. Ajouter un index sur `cache_type` pour `clearType`.
- `lib/src/core/storage/repositories/secure_storage_repository.dart` : stocke les payloads JSON en clair; préférer `SecureCredentialsVault`. Ajouter `listValues` pour introspection.
- `lib/src/core/storage/repositories/iptv_local_repository.dart` : `savePlaylists` ne supprime jamais les playlists obsolètes (dans la table). Prévoir une opération `DELETE` par `accountId` avant l'insertion. `getAvailableTmdbIds` charge toutes les playlists en mémoire -> faire une requête SQL qui extrait directement les IDs.
- `lib/src/core/storage/repositories/playlist_local_repository.dart` : `reorderItem` manipule toute la table en mémoire et applique un offset `+ 1000000` (ligne ~103) pouvant dépasser `INTEGER` si répété. Utiliser une transaction + positions `real` (0.0, 1.0, 1.5...).
- `lib/src/core/storage/repositories/watchlist_local_repository.dart` : interface orientée `ContentType`, pas de pagination. Ajouter une limite, un tri et un `Stream`.
- `lib/src/core/storage/repositories/continue_watching_local_repository.dart` : idem, aucune limite -> ajouter `LIMIT 100` et purger les entrées obsolètes.
- `lib/src/core/storage/repositories/history_local_repository.dart` : `play_count` augmente sans borne. Ajouter un `MAX 1000` + purge.

### `theme/`
- `lib/src/core/theme/theme.dart` : barrel.
- `lib/src/core/theme/app_colors.dart` : RAS.
- `lib/src/core/theme/app_theme.dart` : builder complet mais `GoogleFonts.montserrat()` est appelé dans un `try/catch` hors `WidgetsFlutterBinding.ensureInitialized`. Préparer les fonts dans `pubspec`. Beaucoup de duplication `AppColors` -> externaliser les styles communs (button/list) dans des fonctions dédiées.

### `utils/`
- `lib/src/core/utils/index.dart` & `utils.dart` : barrels.
- `lib/src/core/utils/app_assets.dart` : centralise les assets PNG. Réfléchir à migrer vers des `VectorGraphic` pour changer de couleur. Ajouter les assets manquants (settings nav). Attention aux doublons `iconSearch`/`navSearch`.
- `lib/src/core/utils/app_spacing.dart` : RAS.
- `lib/src/core/utils/context_extensions.dart` : expose `sl<AppLogger>()` via `context.logger`, ce qui couple l'UI au service locator. Retirer cette méthode pour garder les widgets testables.
- `lib/src/core/utils/logger_utils.dart` : idem, wrap direct de `sl`. Fournir plutôt une fonction prenant `AppLogger` en paramètre.
- `lib/src/core/utils/result.dart` : sealed class utile; ajouter helpers `map`, `mapError`, `flatMap` pour éviter les `fold` répétitifs.
- `lib/src/core/utils/validators.dart` : simple helper. Compléter avec la validation d'URL IPv6 + schéma.

### `widgets/`
- `lib/src/core/widgets/widgets.dart` : barrel.
- `lib/src/core/widgets/overlay_splash.dart` : widget simple; ajouter `Semantics` pour l'élément de chargement et injecter l'asset via `AppAssets`.
- `lib/src/core/widgets/movi_see_all_card.dart` : déclenche une navigation directe via `context.push`. Pour la clean archi, exposer un callback `onTap(CategoryPageArgs)` et laisser le parent décider. Ajouter `Semantics` + `Hero` optionnel.
- `lib/src/core/widgets/movi_primary_button.dart` : mélange callback et navigation; séparer les responsabilités (button pure + builder d'action). Prévoir un `ButtonStyle` paramétrable et supprimer la dépendance directe à `GoRouter`.
- `lib/src/core/widgets/movi_pill.dart` : OK, ajouter un paramètre `color`.
- `lib/src/core/widgets/movi_person_card.dart` : `onTap` mène toujours vers `AppRouteNames.person` sans passer l'ID de `person` → impossible d'ouvrir les bonnes fiches. Accepter un callback `onTap(MoviPerson)`.
- `lib/src/core/widgets/movi_media_card.dart` : idem, n'envoie pas l'identifiant ni les métadonnées. De plus, `_PosterWithOverlay` n'a aucun overlay (le nom est trompeur). Renommer et fournir un `Hero`.
- `lib/src/core/widgets/movi_marquee_text.dart` : `ShaderMask` utilise `Colors.white` fixe, ce qui casse les thèmes clairs. Passer par `widget.style.color` et ajouter `dispose` safe sur `_loop`.
- `lib/src/core/widgets/movi_items_list.dart` : API riche mais prend une `List<Widget>` déjà construite (pas de builder), rendant le lazy loading impossible. Remplacer par un `IndexedWidgetBuilder` + `itemCount`.
- `lib/src/core/widgets/movi_favorite_button.dart` : accessible, mais images PNG → préférer `IconButton` + `AnimatedSwitcher` pour la theming.
- `lib/src/core/widgets/movi_bottom_nav_bar.dart` : superbe UI mais purement visuelle. Ajouter un `BottomNavigationBarItem` compatible `NavigationBarDestination` ou au moins un paramètre `semanticLabel`.

