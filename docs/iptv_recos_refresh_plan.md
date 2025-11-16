Parfait, on fusionne les deux approches en gardant ce qui colle le mieux **à ton code actuel** + une archi propre.

---

## 1. Décisions de design (synthèse des deux plans)

1. **Filtrage des recommandations**

   * ✅ Garder la logique métier “les recos doivent exister dans les playlists IPTV” **au plus proche du domaine** : via un use case dédié, pas dans la VM.
   * ✅ Réutiliser ce que tu as déjà :

     * `IptvLocalRepository.getAvailableTmdbIds(...)` (plus direct et moins cher que `searchCatalog('')`).
   * ✅ Point d’intégration concret : `movieDetailControllerProvider`, juste après l’appel à `getRecommendations`.

2. **Rafraîchissement des playlists ≤ 5h**

   * ✅ Implémenter vraiment `XtreamCacheDataSource` avec un **TTL de 5h** via `CachePolicy`.
   * ✅ Sauvegarder un `XtreamCatalogSnapshot` après chaque `refreshCatalog`.
   * ✅ S’appuyer sur **`XtreamSyncService` déjà en place** comme orchestrateur :

     * il fait déjà un `_tick()` initial (parfait pour le “au lancement”).
   * ✅ Hook de démarrage simple : **appeler `XtreamSyncService.start()` dans `appStartupProvider`**.
   * ❌ Pas nécessaire de faire un gros nouveau use case `RefreshIptvPlaylistsIfStale` vu qu’on a déjà `XtreamSyncService` + cache TTL.

Résultat :

* Tu respectes Clean Architecture (use case dédié pour le filtrage).
* Tu touches très peu à la surface publique.
* Tu utilises au maximum les briques déjà en place.

---

## 2. Partie A — Recommandations uniquement disponibles dans les playlists IPTV

### 2.1. Nouveau Use Case domaine

**But :** encapsuler la logique “garder seulement les recos dont le `tmdbId` est dispo dans les playlists IPTV locales”.

* Fichier (suggestion) :
  `lib/src/features/movie/domain/usecases/filter_recommendations_by_iptv.dart`

* Use case : `FilterRecommendationsByIptvAvailability`

  * Entrée :

    * `List<MovieSummary> recommendations`
  * Dépendances :

    * `IptvLocalRepository` (pour appeler `getAvailableTmdbIds(type: XtreamPlaylistItemType.movie)`).
  * Sortie :

    * `List<MovieSummary>` filtrée.

* Logique interne :

  1. Appeler `getAvailableTmdbIds(XtreamPlaylistItemType.movie)` → `Set<int> available`.
  2. Si `available` est vide → renvoyer une liste vide (aucune playlist IPTV → pas de recos).
  3. Filtrer `recommendations` :

     * On garde uniquement les `MovieSummary` avec `tmdbId != null` et `available.contains(tmdbId)`.

Ainsi, **tout le code “IPTV aware” reste côté domaine**, et la présentation ne fait que consommer le résultat.

### 2.2. DI / Wiring du Use Case

* Module concerné : soit un module movie, soit `IptvDataModule` (au choix, mais idéalement un module “movie_domain”).
* Enregistrer :

  * `FilterRecommendationsByIptvAvailability` avec ses dépendances (`IptvLocalRepository`).

### 2.3. Intégration dans `movieDetailControllerProvider`

Fichier :
`lib/src/features/movie/presentation/providers/movie_detail_providers.dart`

Actuellement :

* Tu fais :

  * `detail = repo.getMovie(...)`
  * `people = repo.getCredits(...)`
  * `reco = repo.getRecommendations(...)`
  * Puis tu passes `reco` au `MovieDetailViewModel`.

Plan :

1. Importer le use case :

   * `import 'package:movi/src/features/movie/domain/usecases/filter_recommendations_by_iptv.dart';`
   * Récupérer le use case via `locator` :

     * `final filterReco = locator<FilterRecommendationsByIptvAvailability>();`

2. Après `final reco = await repo.getRecommendations(id);` :

   * Appeler `final filtered = await filterReco(reco);`

3. Passer `filtered` au lieu de `reco` quand tu construis la VM :

   * `recommendations: filtered`.

### 2.4. Comportement UI

* Si `filtered` est vide :

  * La VM contient une liste vide (`MovieDetailViewModel.recommendations`).
  * Les widgets qui affichent la section “Recommandations” doivent :

    * soit **ne pas rendre** la section si la liste est vide,
    * soit afficher un texte neutre du style “Aucune recommandation disponible via votre playlist IPTV”.

---

## 3. Partie B — Rafraîchir les playlists IPTV si > 5h

### 3.1. Implémenter réellement `XtreamCacheDataSource` (TTL 5h)

Fichier :
`lib/src/features/iptv/data/datasources/xtream_cache_data_source.dart`

Objectif : utiliser `ContentCacheRepository` + `CachePolicy` pour stocker un `XtreamCatalogSnapshot` par compte avec TTL = 5h.

1. **Champs à ajouter**

   * `final IptvLocalRepository _local;` *(optionnel selon ton usage)*
   * `final ContentCacheRepository _cache;`
   * Constructeur qui assigne ces deux champs (ils sont déjà fournis par DI dans `IptvDataModule`).

2. **Politique par défaut**

   * `static final CachePolicy snapshotPolicy = CachePolicy(ttl: Duration(hours: 5));`

3. **Formatage du cache**

   * Type de cache : ex. `const _cacheType = 'iptv_snapshot';`
   * Clé :

     * `String _keyFor(String accountId) => 'iptv_snapshot_$accountId';`

4. **Méthode `saveSnapshot(XtreamCatalogSnapshot snapshot)`**

   * Construire un `Map<String, dynamic>` :

     * `accountId`
     * `lastSyncAt` (ex. `toIso8601String()` ou timestamp ms).
     * `movieCount`
     * `seriesCount`
     * `lastError`.
   * Appeler `_cache.put(key: _keyFor(snapshot.accountId), type: _cacheType, payload: map)`.

5. **Méthode `getSnapshot(String accountId, {CachePolicy? policy})`**

   * Choisir la policy : `policy ?? snapshotPolicy`.
   * Appeler `_cache.get(_keyFor(accountId), policy: policy);`
   * Si `null` → retourner `null`.
   * Sinon → reconstruire un `XtreamCatalogSnapshot` à partir du `Map` :

     * Parser `lastSyncAt` en `DateTime`.
   * Si le TTL est dépassé, `ContentCacheRepository` supprimera l’entrée et renverra `null` → ce qui déclenchera un refresh via `XtreamSyncService`.

> Pas besoin d’étendre `IptvLocalRepository` pour stocker le snapshot : **tout tient dans `ContentCacheRepository`**, plus simple et déjà pensé pour ça.

---

### 3.2. Persister le snapshot dans `IptvRepositoryImpl.refreshCatalog`

Fichier :
`lib/src/features/iptv/data/repositories/iptv_repository_impl.dart`

1. **Dépendance supplémentaire**

   * Ajouter un champ `_cache` de type `XtreamCacheDataSource`.
   * Mettre à jour le constructeur pour inclure ce paramètre.
   * Mettre à jour `IptvDataModule.register()` pour passer `sl<XtreamCacheDataSource>()` lors de l’instanciation du repo.

2. **Après `savePlaylists`**

   * Tu construis déjà un `XtreamCatalogSnapshot` (avec `lastSyncAt: DateTime.now()`).
   * Ajouter l’appel :

     * `_cache.saveSnapshot(snapshot);`
   * Renvoyer `snapshot` comme avant.

> À partir de là, tu as un snapshot daté pour chaque `refreshCatalog`.

---

### 3.3. Utiliser le TTL dans `XtreamSyncService`

Fichier :
`lib/src/features/iptv/application/services/xtream_sync_service.dart`

Le code fait déjà :

* Pour chaque `accountId` actif :

  * `final snapshot = await _cache.getSnapshot(accountId, policy: XtreamCacheDataSource.snapshotPolicy);`
  * Si `snapshot == null` → `await _refresh(accountId);`

Donc, dès que `XtreamCacheDataSource` est correctement branché :

* Si le dernier `lastSyncAt` a plus de **5h** (TTL), `ContentCacheRepository` considère que l’entrée est expirée → supprimée → `getSnapshot` retourne `null` → `XtreamSyncService` déclenche un `refresh`.

Tu obtiens donc **exactement la logique “> 5h → refresh”** sans rajouter un nouveau use case.

---

### 3.4. Hook au lancement de l’app

Fichier :
`lib/src/core/startup/app_startup_provider.dart`

1. Après `await initDependencies(...)` et `LoggingModule.register()` :

   * Résoudre le service :

     * `final syncService = sl<XtreamSyncService>();`
   * Appeler :

     * `syncService.start();`

2. Effet :

   * `start()` pose un `Timer.periodic(...)` et lance **un `_tick()` initial** (grâce au `unawaited(_tick());` dans `start()`).
   * Lors de ce `_tick()` initial :

     * Pour chaque `accountId` dans `AppStateController.activeIptvSourceIds` :

       * `getSnapshot` avec TTL 5h :

         * **Pas de snapshot ou expiré** → `refreshCatalog(accountId)` → playlists fraîchement chargées.
         * **Snapshot récent (< 5h)** → rien ne se passe.

> Ça remplit le cahier des charges :
> “Au lancement, si la playlist n’a pas été rafraîchie depuis > 5h, on la rafraîchit automatiquement.”

---

### 3.5. TTL configurable

Si tu veux suivre ton plan initial “TTL configurable” :

* Définir la `Duration` dans un seul endroit :

  * Soit une constante `const Duration kIptvPlaylistTtl = Duration(hours: 5);`
  * Soit tirer cette durée d’une config (`AppConfig` / `.env`) et construire `CachePolicy` à partir de là.
* `XtreamCacheDataSource.snapshotPolicy` devient alors soit :

  * un `final` construit via DI,
  * soit une `CachePolicy` construite avec une valeur lue côté config.

---

## 4. DI / Intégration globale

À ajuster dans les modules existants :

1. **IptvDataModule**

   * `XtreamCacheDataSource` : reste enregistré, mais on lui passe vraiment `IptvLocalRepository` + `ContentCacheRepository`.
   * `IptvRepositoryImpl` : constructeur enrichi avec `_cache`.
   * `XtreamSyncService` : inchangé (il utilise déjà `_cache` + `_refresh` + `_state`).

2. **Module Movie / global DI**

   * Enregistrer `FilterRecommendationsByIptvAvailability` avec :

     * `IptvLocalRepository`.
   * Dans `movieDetailControllerProvider`, récupérer le use case via `slProvider`.

---

## 5. Validation & scénarios à tester

1. **Recommandations**

   * Film avec recos TMDB dont certains `tmdbId` sont dans les playlists IPTV → seuls ces films sont affichés.
   * Aucun `tmdbId` commun → section “Recommandations” vide/masquée.

2. **Rafraîchissement playlists**

   * Snapshot inexistant (premier lancement / premier account) :

     * `_tick()` initial → `getSnapshot` → `null` → `refreshCatalog`.
   * Snapshot récent (moins de 5h) :

     * `_tick()` → `getSnapshot` OK → pas de network call.
   * Snapshot ancien (plus de 5h) :

     * `_tick()` → TTL expiré → `getSnapshot` renvoie `null` → `refreshCatalog`.

3. **Perf / UX**

   * Le filtrage des recos est en mémoire : `O(n)` sur une petite liste → négligeable.
   * Le refresh au lancement ne se lance que si besoin (TTL > 5h) → pas de spam réseau.

---

Si tu veux, au prochain message je peux te lister **fichier par fichier** les modifications à faire sous forme de checklist (toujours sans coller de code), genre “dans `XtreamCacheDataSource` : ajouter champ X, méthode Y, etc.” pour que tu puisses implémenter tranquillement.
