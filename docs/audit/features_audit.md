On va transformer ton audit en **plan de refactor multi-étapes**, faisable **feature par feature** sans tout casser d’un coup.

Je garde tes constats, mais je les réorganise pour les faire passer en **petites tranches successives**.

---

## 0. Principe du refactor par étapes

Objectifs :

* Toujours garder `main` dans un état **buildable**.
* Ne **jamais** mélanger trop de chantiers dans la même PR.
* Chaque étape :

  * a un **scope précis**,
  * touche **peu de fichiers critiques**,
  * a une **Definition of Done** claire (tests, compilation, comportement identique).

Je te propose un plan en **6 étapes** :

1. ✅ DI & Riverpod (stabiliser la base technique)
2. ✅ Library domain (favoris / historique)
3. ✅ Service unique IPTV (`IptvCatalogReader`)
4. ✅ Home refactor (usecases & contrôleur)
5. ✅ Search refactor (instant + paginé)
6. ✅ Rafraîchissement Home via events, pas via accès direct

---

## Étape 1 – DI & Riverpod : nettoyer la fondation

### But

Mettre au propre **les providers et la DI** pour faciliter la suite (Home, Search, IPTV).

### Scope

* `lib/src/core/di/*`
* `lib/src/core/state/*`
* `lib/src/core/...` où `flutter_riverpod/legacy.dart` est importé
* Providers de features (Home, Search, Settings) mais **sans changer leur logique métier**.

### Actions détaillées

1. **Supprimer progressivement `flutter_riverpod/legacy.dart`**

   * Remplacer par :

     * `StateNotifier` via `package:state_notifier/state_notifier.dart`
       ou
     * `AsyncNotifier` / `Notifier` (Riverpod moderne).
   * Garder la même interface publique des providers.

2. **Éviter les side-effects dans les constructeurs**

   * Exemples :

     ```dart
     final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
       (ref) => HomeController(ref.read(homeFeedRepositoryProvider))..load(),
     );
     ```
   * Déplacer les `..load()` dans :

     * `build()` d’un `AsyncNotifier`, ou
     * une méthode `init()` appelée explicitement par la page (ex : `ref.read(homeControllerProvider.notifier).load()` dans `initState`).

3. **Encapsuler GetIt derrière des providers**

   * Créer un `slProvider` (si pas déjà fait) :

     ```dart
     final slProvider = Provider<GetIt>((_) => sl);
     ```
   * Pour chaque repository/service utilisé dans une feature :

     ```dart
     final homeFeedRepositoryProvider = Provider<HomeFeedRepository>(
       (ref) => ref.read(slProvider)<HomeFeedRepository>(),
     );
     ```
   * Ne plus appeler `sl.get<T>()` directement dans la présentation.

### Definition of Done (Étape 1)

* Plus aucune importation de `flutter_riverpod/legacy.dart`.
* Tous les contrôleurs ont des **constructeurs sans side-effects** (pas de `..load()`).
* Les tests widgets peuvent override un repository via `ProviderScope(overrides: [...])` sans se battre avec GetIt.

---

## Étape 2 – Library domain : découpler du `storage`

### But

Rendre le **domaine Library** indépendant des implémentations SQLite / storage.

### Scope

* `lib/src/features/library/domain/usecases/*`
* `lib/src/features/library/data/repositories/*`
* `lib/src/core/storage/*` utilisé par Library

### Actions

1. **Créer des interfaces domaine**

   * Exemples :

     * `FavoritesRepository`
     * `HistoryRepository`
   * Dans `lib/src/features/library/domain/repositories/`.

2. **Adapter les usecases**

   * `LikePerson`, `UnlikePerson`, etc. doivent dépendre d’**interfaces domaine**, pas de `WatchlistLocalRepository` directement.
   * Retirer les imports de `core/storage.dart` de la couche domain.

3. **Adapter les implémentations data**

   * Créer `FavoritesRepositoryImpl`, `HistoryRepositoryImpl` dans `data/repositories/`.
   * Ces impls utilisent `WatchlistLocalRepository`, `HistoryLocalRepository`, etc.

4. **Adapter la DI**

   * Dans la config/DI, binder :

     ```dart
     FavoritesRepository => FavoritesRepositoryImpl
     HistoryRepository   => HistoryRepositoryImpl
     ```

### Definition of Done (Étape 2)

* Aucun usecase Domain Library n’importe `core/storage`.
* Les tests unitaires des usecases peuvent utiliser des fake `FavoritesRepository` / `HistoryRepository` en mémoire.

---

## Étape 3 – Service unique IPTV : `IptvCatalogReader`

### But

**Supprimer la duplication** et les couplages transverses autour des playlists IPTV.

### Scope

* `HomeFeedRepositoryImpl` (ou équivalent)
* `CategoryLocalDataSource`
* `SearchRepositoryImpl` (partie IPTV)
* `lib/src/features/iptv/data/*`

### Actions

1. **Créer un module `iptv/application`**

   * Fichier-type :
     `lib/src/features/iptv/application/iptv_catalog_reader.dart`

2. **Définir un type pivot `ContentReference`**

   * Dans un endroit partagé propre, par ex. `shared/domain/value_objects` :

     ```dart
     class ContentReference {
       final String id;
       final MediaTitle title;
       final ContentType type; // movie / series
       final Uri? poster;
       final int? year;
       // ...
     }
     ```

3. **Implémenter `IptvCatalogReader`**

   * Il dépend seulement de `IptvLocalRepository`.
   * Il expose :

     * `Future<List<ContentReference>> listAccounts()`
     * `Future<List<ContentReference>> listCategory(CategoryKey key)`
     * `Future<List<ContentReference>> searchCatalog(String query)`

4. **Remplacer la logique dupliquée**

   * Dans Home, Category Browser, Search :

     * retirer tout accès direct à `IptvLocalRepository`,
     * utiliser les méthodes de `IptvCatalogReader`.

5. **Supprimer les imports transverses**

   * Ex. `CategoryLocalDataSource` qui importe `home_feed_repository_impl.dart : XtreamAccountLite` → plus jamais.

### Definition of Done (Étape 3)

* Home, Search, Category Browser **n’importent plus** de types IPTV internes d’autres features.
* Toute lecture IPTV passe par `IptvCatalogReader`.
* Les fonctions `_safeGetAccounts`, `_cleanCategoryTitle`, `_safePosterUri` n’existent qu’à **un seul endroit**.

---

## Étape 4 – Home : usecases & contrôleur allégés

### But

Sortir la logique métier du `HomeController` et la mettre dans des usecases testables.

### Scope

* `lib/src/features/home/presentation/providers/home_providers.dart`
* `lib/src/features/home/domain/usecases/*` (à créer/compléter)
* `HomeFeedRepository` & éventuellement sa signature

### Actions

1. **Définir des usecases pour Home**

   * `LoadHomeHero`
   * `LoadHomeContinueWatching`
   * `LoadHomeIptvSections`
   * `RefreshHomeFeed` (si nécessaire)
   * Ils consomment :

     * `HomeFeedRepository`
     * `IptvCatalogReader` (via repository ou directement)

2. **Alléger le contrôleur**

   * Transformer `HomeController` en :

     * soit `AsyncNotifier<HomeState>`,
     * soit `StateNotifier<HomeState>` + méthodes async claires.
   * Il ne fait plus que :

     * composer les résultats des usecases,
     * gérer `AsyncValue` / états de chargement / erreurs.

3. **Supprimer la logique réseau & CancelToken du contrôleur**

   * Ces détails vont :

     * soit dans les usecases,
     * soit dans les repositories.

4. **Refaire l’initialisation**

   * Plus de `..load()` implicite dans le provider.
   * Soit :

     * tu utilises `build()` d’un `AsyncNotifier`,
     * soit la page appelle une méthode `init()` une seule fois.

### Definition of Done (Étape 4)

* `HomeController` fait < 200 lignes (ordre d’idée).
* Aucun import de `dio`, `CancelToken`, `LoggingService` dans la présentation Home.
* Tests unitaires possibles sur chaque usecase (avec mocks).

---

## Étape 5 – Search : scinder instantané / paginé + clarifier la logique

### But

Rendre la feature Search plus lisible, testable, et moins monolithique.

### Scope

* `lib/src/features/search/presentation/pages/search_page.dart`
* `lib/src/features/search/presentation/pages/search_results_page.dart`
* `lib/src/features/search/presentation/providers/*`
* `lib/src/features/search/domain/usecases/*` (à créer/adapter)

### Actions

1. **Scinder la présentation**

   * Fichiers séparés :

     * `search_instant_controller.dart`
     * `search_paged_controller.dart`
     * `search_providers.dart` pour la DI.

2. **Créer deux usecases**

   * `SearchInstant` :

     * pour les suggestions rapides / résultats immédiats sur petite page.
   * `SearchPaginated` :

     * renvoie un `SearchPage` avec `page`, `totalPages`, etc.
     * encapsule toutes les règles de pagination.

3. **Encapsuler la logique de debounce dans un seul endroit**

   * Soit dans le contrôleur,
   * Soit dans un service à part utilisé par le contrôleur.

4. **Utiliser `IptvCatalogReader` si tu cherches dans les contenus IPTV**

   * Plus de relecture directe de `IptvLocalRepository` dans `SearchRepositoryImpl`.

### Definition of Done (Étape 5)

* Les fichiers Search ne sont plus des pavés de 350+ lignes.
* Les usecases Search peuvent être testés avec des faux repositories.
* La page Search se contente de lire des providers `AsyncValue` et d’afficher.

---

## Étape 6 – Rafraîchissement Home via events, pas via accès direct

### But

Supprimer les accès directs entre IPTV Connect et Home, et rendre les flux de rafraîchissement plus “app-layer”.

### Scope

* `lib/src/features/welcome/` / `settings` / `iptv_connect_providers.dart`
* `lib/src/core/state/app_state_controller.dart`
* éventuellement un petit `EventBus` maison

### Actions

1. **Créer un mécanisme d’événements simple**

   * Par ex. dans `core/state` :

     ```dart
     enum AppEventType { iptvSynced }

     class AppEvent {
       final AppEventType type;
       const AppEvent(this.type);
     }

     final appEventBusProvider = Provider<AppEventBus>(...);
     ```
   * `AppEventBus` peut être :

     * un `StreamController<AppEvent>`,
     * ou un `StateNotifier<List<AppEvent>>` avec “consommation” des events.

2. **Émettre un event depuis IPTV Connect**

   * Au lieu de :

     ```dart
     ref.read(homeControllerProvider.notifier).load();
     ```
   * Faire :

     ```dart
     ref.read(appEventBusProvider).emit(AppEvent(AppEventType.iptvSynced));
     ```

3. **Écouter l’événement côté Home**

   * Dans `HomePage` ou le `HomeController` :

     ```dart
     ref.listen<AppEventBus>(appEventBusProvider, (prev, next) {
       // si event type == iptvSynced → refresh()
     });
     ```

### Definition of Done (Étape 6)

* Aucun appel direct à `homeControllerProvider` depuis IPTV Connect ou d’autres features.
* Le rafraîchissement Home est centralisé via un mécanisme d’événements/app-layer.

---

## Résumé ultra-court

Tu peux lire ton refactor comme une **suite de mini-projets** :

1. **Étape 1 – DI & Riverpod clean**
   → enlever `legacy`, limiter les side-effects.

2. **Étape 2 – Library domain clean**
   → plus de dépendance directe au storage.

3. **Étape 3 – `IptvCatalogReader`**
   → un seul service pour lire les playlists.

4. **Étape 4 – Home refactor**
   → usecases + contrôleur léger.

5. **Étape 5 – Search refactor**
   → instant vs paginé, usecases, fichiers plus petits.

6. **Étape 6 – Event bus / AppState events**
   → plus de cross-access direct entre features.

Si tu veux, au prochain message je peux te faire une **checklist “V1.1, V1.2, …”** avec les noms de branches conseillés et ce que chaque branche doit contenir exactement.
