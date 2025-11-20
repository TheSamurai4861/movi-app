# Rapport d’analyse — `src/features/saga`

## 1. Résumé global (vue d’ensemble)

La feature `saga` est globalement **bien conçue** :

- Architecture **Domain / Data / Presentation** claire.
- Domaine **pur** : entités (`Saga`, `SagaEntry`, `SagaSummary`), repository abstrait et use cases sans dépendance à Flutter. :contentReference[oaicite:0]{index=0}
- Couche Data correcte : remote + cache local, mapping DTO → Domain bien encapsulé dans `SagaRepositoryImpl`. :contentReference[oaicite:1]{index=1}
- UI : `SagaDetailPage` propre, avec favorite, disponibilité IPTV, “reprendre / commencer”, etc. :contentReference[oaicite:2]{index=2}  

Mais plusieurs points empêchent d’atteindre un niveau **“pro parfait”** :

- **Double source de vérité** pour les détails de saga : une fois via `SagaRepositoryImpl`, une fois via `sagaDetailProvider` qui reconstruit tout à la main, en doublant les appels réseau TMDB. :contentReference[oaicite:3]{index=3}  
- **Incohérences de responsabilités** entre Domain/Data et Presentation (remote dans les providers, cache ignoré).
- Quelques règles métier **ambiguës ou placeholders** (`getUserSagas` ignore `userId`, usage du watchlist générique).
- Quelques détails d’i18n / UX (`Erreur: $error` en dur) et de perf (boucles séquentielles pour les runtimes).

Globalement : base saine, mais il faut **resserrer la cohérence Domain/Data/Presentation** et clarifier certains choix métier.

---

## 2. Architecture & organisation

### 2.1 Rôle du dossier

La feature `saga` gère :

- La **représentation métier** d’une saga (collection TMDB) : films, timeline, tags, cover.
- La **récupération depuis TMDB** (remote) + **cache local**.
- La **projection en UI** : page de détail, films de la saga, disponibilité IPTV, favoris, progression utilisateur.

### 2.2 Structure et responsabilités

- `saga.dart`  
  → Barrel file qui exporte entités, repository, use cases et DTO principal. :contentReference[oaicite:4]{index=4}  

- `data/`
  - `datasources/saga_local_data_source.dart`  
    → Accès au cache `ContentCacheRepository` + `LocalePreferences`, avec TTL 1 jour, clé `saga_detail_<locale>_<id>`. :contentReference[oaicite:5]{index=5}  
  - `datasources/tmdb_saga_remote_data_source.dart`  
    → Appels TMDB : `collection/$id`, `movie/$id` (runtime), et recherche `search/collection`. :contentReference[oaicite:6]{index=6}  
  - `dtos/tmdb_saga_detail_dto.dart`  
    → DTO de détail + DTO pour chaque “part” avec mapping JSON↔cache, runtime optionnel. :contentReference[oaicite:7]{index=7}  
  - `repositories/saga_repository_impl.dart`  
    → Implémentation Domain :
    - tente d’abord le cache,
    - si besoin : fetch remote + save,
    - enrichit chaque part avec `runtime` (appel TMDB movie au besoin),
    - construit `Saga` + `SagaEntry` (ContentReference, poster, timelineYear),
    - expose aussi `getUserSagas` (via `WatchlistLocalRepository`) et `searchSagas`. :contentReference[oaicite:8]{index=8}  
  - `saga_data_module.dart`  
    → Enregistre remote/local/repo dans le service locator `sl`. :contentReference[oaicite:9]{index=9}  

- `domain/`
  - `entities/saga.dart`  
    → `Saga`, `SagaEntry`, `SagaSummary`, tous `Equatable`, basés sur des value objects (`SagaId`, `MediaTitle`, `Synopsis`, `ContentReference`). :contentReference[oaicite:10]{index=10}  
  - `repositories/saga_repository.dart`  
    → Contrat Domain : `getSaga`, `getUserSagas`, `searchSagas`. :contentReference[oaicite:11]{index=11}  
  - `usecases/get_saga_detail.dart`, `get_user_sagas.dart`, `search_sagas.dart`  
    → Petits wrappers autour du repo, 1 méthode chacun. :contentReference[oaicite:12]{index=12}  

- `presentation/`
  - `pages/saga_detail_page.dart`  
    → Page UI : hero, titre, stats, bouton start/continue, favoris, liste des films, dispo IPTV, navigation vers `movie`. :contentReference[oaicite:13]{index=13}  
  - `providers/saga_detail_providers.dart`  
    → `sagaDetailProvider` (construction d’un `SagaDetailViewModel` depuis `TmdbSagaRemoteDataSource`),  
      `sagaMoviesAvailabilityProvider` (cross-feature saga+iptv),  
      `sagaInProgressMovieProvider` (cross-feature saga+history),  
      et le ViewModel `SagaDetailViewModel`. :contentReference[oaicite:14]{index=14}  

### 2.3 Points forts

- **Domain pur** et expressif (bons value objects, `Equatable`).
- **Data layer** qui respecte bien la responsabilité (remote + cache local + mapping).
- **Use cases** minimalistes, faciles à tester et à utiliser dans d’autres features.
- Page de détail bien structurée visuellement (hero, CTA, liste de films, états IPTV).

### 2.4 Points à corriger

- `sagaDetailProvider` contourne complètement `SagaRepository`, duplique la logique de mapping & de runtime, et ignore le cache. :contentReference[oaicite:15]{index=15}  
- `getUserSagas` ignore l’argument `userId` et se base uniquement sur `WatchlistLocalRepository`. :contentReference[oaicite:16]{index=16}  
- Mélange de DI : service locator (`sl` et `slProvider`) + Riverpod dans les providers.
- Quelques strings non localisées, et une gestion d’erreur brute dans l’UI.

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Critique

#### 3.1.1 Double source de vérité & double appels TMDB pour le détail de saga

- **Fichiers / éléments**  
  - `SagaRepositoryImpl.getSaga` (Data/Domain). :contentReference[oaicite:17]{index=17}  
  - `saga_detail_providers.dart` → `sagaDetailProvider`. :contentReference[oaicite:18]{index=18}  

- **Problème**

  1. **Repository**  
     `SagaRepositoryImpl.getSaga` :
     - tente le cache (`SagaLocalDataSource.getSagaDetail`),  
     - sinon : `TmdbSagaRemoteDataSource.fetchSaga(sagaId)` puis `saveSagaDetail`,  
     - pour chaque `part` :
       ```dart
       final runtime = part.runtime ?? await _remote.fetchMovieRuntime(part.id);
       ```
       → enrichit avec `runtime`.  
     - construit un `Saga` complet (id, title, synopsis, cover, timeline, etc.). :contentReference[oaicite:19]{index=19}  

  2. **Provider**  
     `sagaDetailProvider` ne passe **pas** par le repo :
     - utilise `slProvider<TmdbSagaRemoteDataSource>()` directement,
     - refait un `fetchSaga(sagaIdInt, language: lang)` pour la langue UI,  
     - reconstruit un `Saga` localement (mapping manuel du DTO → `Saga`),  
     - **reboucle sur tous les films** pour récupérer les durées :
       ```dart
       for (final entry in movies) {
         final runtimeMinutes =
             await remoteDataSource.fetchMovieRuntime(movieId);
         ...
       }
       ```  
     - ignore totalement `SagaLocalDataSource` (cache) et `SagaRepositoryImpl`.

  Résultat :
  - **Deux chemins différents** pour obtenir les détails d’une saga.
  - En pratique, sur `SagaDetailPage`, tu combines :
    - `sagaDetailProvider` (pour le ViewModel),
    - `sagaMoviesAvailabilityProvider` et `sagaInProgressMovieProvider` qui, eux, passent par `SagaRepository`. :contentReference[oaicite:20]{index=20}  

  → Donc potentiellement **deux appels `collection/$id`** et **deux séries d’appels `movie/$id`** pour les runtimes pour la même saga, sans jamais partager ni cache, ni logique.

- **Pourquoi c’est un problème**

  - **Architecture** : la logique métier & de mapping (DTO → Domain) est dupliquée entre Data et Presentation.
  - **Performance** : appels réseau TMDB doublés (voire plus), pour des données identiques.
  - **Maintenance** : toute évolution du modèle saga doit être faite à 2 endroits (repo + provider).
  - **Cohérence** : potentiel décalage entre la saga vue par le domaine et celle vue par l’UI (langue, champs, etc.).

- **Suggestion de correction**

  - Faire de `SagaRepository` (et/ou du use case `GetSagaDetail`) **la seule source de vérité** :
    - `sagaDetailProvider` devrait consommer `GetSagaDetail` plutôt que `TmdbSagaRemoteDataSource` directement.
  - Si tu veux des métadonnées localisées (langue UI) **en plus** :
    - soit ajouter un paramètre `language` à `getSaga` et faire porter cette logique au repo + cache (`SagaLocalDataSource` a déjà `LocalePreferences`),  
    - soit faire un provider séparé pour “UI-only extra info” (ex. images null-language) mais en partant du `Saga` domaine existant.
  - Mutualiser la récupération des `runtime` (soit dans le repo, soit dans un service dédié), et éviter de refaire la même boucle ailleurs.

---

### 3.2 Important

#### 3.2.1 `GetUserSagas` / `SagaRepositoryImpl.getUserSagas` ignore `userId`

- **Fichier / élément**  
  `SagaRepositoryImpl.getUserSagas(String userId)`. :contentReference[oaicite:21]{index=21}  

- **Problème**

  ```dart
  @override
  Future<List<SagaSummary>> getUserSagas(String userId) async {
    // User-specific storage not implemented; reuse generic watchlist with type 'saga'.
    final entries = await _watchlist.readAll(ContentType.saga);
    ...
  }
