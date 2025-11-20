# Rapport d’analyse — Feature `search`

Dossier : `lib/src/features/search`

---

## 1. Résumé global (vue d’ensemble)

La feature `search` est globalement **bien structurée** : on retrouve une séparation claire Domain / Data / Presentation, des use cases simples, des value objects, et une intégration correcte avec Riverpod. La logique de recherche instantanée (films / séries / personnes / sagas), l’historique et la recherche par providers sont déjà à un niveau **propre et cohérent**.  

Les principaux points faibles sont :  
- un **mélange de patterns de DI** (service locator `sl` + providers Riverpod) qui complique la lisibilité et la testabilité,  
- du **code Data/HTTP directement dans les widgets de présentation** (Provider pages + providerPopularMediaProvider), en rupture avec la Clean Architecture,  
- quelques **fichiers très longs** (pages de recherche/provider) où la logique UI et la logique de chargement/pagination sont imbriquées,  
- quelques soucis potentiels de **performance** (multiplication d’appels TMDB côté UI, boucles séquentielles dans les providers).  

Le niveau global est **entre “correct” et “pro”** : l’architecture est solide, mais tu peux encore gagner en **clarté, testabilité et cohérence de patterns**.

---

## 2. Architecture & organisation

### 2.1 Rôle du dossier

La feature `search` couvre :

- La **recherche de contenus** : films, séries, personnes, sagas, et contenus IPTV (via `IptvCatalogReader`).
- La **gestion de l’historique de recherche** (stockage local par utilisateur).
- La **recherche par providers de streaming** (Netflix, Disney+, etc.) et l’affichage de résultats liés à un provider.
- L’**orchestration UI** : page principale de recherche, résultats paginés, grille de providers, pages par provider.

Responsabilité principale : **feature de recherche transverse**, qui agrège plusieurs sources (IPTV, TMDB) et expose une UI riche.

### 2.2 Séparation Domain / Data / Presentation

- **Domain**
  - Entités simples : `SearchHistoryItem`, `SearchPage<T>`.
  - Repositories abstraits : `SearchRepository`, `SearchHistoryRepository`.
  - Use cases : ajout/list/clear d’historique, recherche instantanée, recherche paginée, recherche par type (movies/shows/people).
  - Value object : `SearchQuery`.

  👉 **Points positifs**
  - Domain **indépendant de Flutter**.
  - Use cases très simples, mono-responsabilité.
  - `SearchPage<T>` est un bon wrapper de pagination.

- **Data**
  - Datasources :  
    - `SearchHistoryLocalDataSource` (cache local, scoped par user),  
    - `TmdbSearchRemoteDataSource`,  
    - `TmdbWatchProvidersRemoteDataSource`.
  - DTO : `TmdbWatchProviderDto`.
  - Impl répos : `SearchHistoryRepositoryImpl`, `SearchRepositoryImpl`.
  - Module DI : `SearchDataModule`.

  👉 **Points positifs**
  - Bonne séparation datasource / repository.
  - `SearchHistoryLocalDataSource` est résilient (logs + fallback silencieux).
  - `SearchRepositoryImpl` encapsule bien la logique de recherche IPTV + TMDB (surtout pour people).

- **Presentation**
  - Controllers Riverpod : `SearchInstantController`, `SearchPagedController`.
  - Providers Riverpod : repository/usecases/history/watch providers/etc.
  - Pages : `SearchPage`, `SearchResultsPage`, `ProviderResultsPage`, `ProviderAllResultsPage`.
  - Widgets : `WatchProvidersGrid`, cartes animées, etc.

  👉 **Points positifs**
  - Usage cohérent de Riverpod (`Notifier`, `AsyncNotifier`, `FutureProvider`, `Provider.family`).
  - UI claire : historique si pas de query, providers sinon, résultats quand query suffisante.
  - Composants réutilisables (grille de providers, cartes animées).

### 2.3 Rôle rapide de chaque fichier

**Data / datasources**
- `search_history_local_data_source.dart` : gestion de l’historique de recherche en cache local, scoped par utilisateur.
- `tmdb_search_remote_data_source.dart` : appels TMDB pour `search/movie`, `search/tv`, `search/person`.
- `tmdb_watch_providers_remote_data_source.dart` : récupération des watch providers TMDB (regions + providers films).

**Data / dtos**
- `tmdb_watch_provider_dto.dart` : DTO pour un watch provider TMDB (id, name, logo, displayPriority).

**Data / repositories**
- `search_history_repository_impl.dart` : impl de `SearchHistoryRepository` via `SearchHistoryLocalDataSource`.
- `search_repository_impl.dart` : impl de `SearchRepository` basée sur `IptvCatalogReader` (movies/shows) + TMDB (people) + SimilarityService.
- `search_data_module.dart` : enregistrement des services/data sources/repositories dans le service locator `sl`.

**Domain / entities**
- `search_history_item.dart` : value object pour une entrée d’historique (query + date).
- `search_page.dart` : page de résultats générique (items, page, totalPages).

**Domain / repositories**
- `search_history_repository.dart` : contrat pour l’historique de recherche.
- `search_repository.dart` : contrat pour la recherche movies/shows/people.

**Domain / usecases**
- `add_search_query_to_history.dart` : ajoute une query à l’historique.
- `list_search_history.dart` : liste l’historique.
- `remove_search_history_item.dart` : supprime une query.
- `search_instant.dart` : recherche instantanée (page 1) pour movies/shows/people.
- `search_movies.dart` / `search_shows.dart` / `search_people.dart` : use cases dédiés.
- `search_paginated.dart` : recherche paginée movies/shows.

**Domain / value_objects**
- `search_query.dart` : encapsule une query, avec parse d’un TMDB ID avec pattern spécifique.

**Presentation / controllers**
- `search_instant_controller.dart` : Notifier qui gère la recherche instantanée (query + debounce + appels aux usecases + sagas + historique).
- `search_paged_controller.dart` : Notifier de résultats paginés (état page, totalPages, items, load more).

**Presentation / models**
- `provider_all_results_args.dart` : args pour page qui affiche tous les résultats d’un provider (films/séries).
- `provider_results_args.dart` : args pour page provider “compacte”.
- `search_results_args.dart` : args pour la page de résultats paginés (query + type).

**Presentation / pages**
- `provider_all_results_page.dart` : page scrollable avec grille paginée de contenus d’un provider (calls direct TMDB).
- `provider_results_page.dart` : page qui affiche un aperçu films/séries d’un provider + recherche locale + navigation “voir tout”.
- `search_page.dart` : page principale de recherche (input, historique, providers grid, résultats instantanés).
- `search_results_page.dart` : page de résultats paginés pour une query, basée sur `SearchPagedController`.

**Presentation / providers**
- `search_history_providers.dart` : `SearchHistoryController` (AsyncNotifier) + provider pour repo.
- `search_providers.dart` : providers pour search repo/usecases, filtres sagas, watch providers, popular media, etc.

**Presentation / widgets**
- `watch_providers_grid.dart` : grille de providers, cartes colorées avec gradient + backdrop + navigation vers ProviderResultsPage.

**Barrel**
- `search.dart` : export des éléments Domain utiles à l’extérieur de la feature.

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Critique

#### 3.1.1 Logique HTTP/Data directement dans les pages UI

- **Fichiers concernés**
  - `provider_all_results_page.dart`
  - `provider_results_page.dart`
  - `search_providers.dart` (`providerPopularMediaProvider`, partiellement)
- **Problème**
  - Les widgets font eux-mêmes des appels à `TmdbClient.getJson` (endpoints `discover/movie` / `discover/tv`), gèrent la pagination (_currentPage, _hasMore, etc.), transforment les DTO en modèles UI.
- **Pourquoi c’est un problème**
  - Violation de la Clean Architecture : la présentation dépend directement d’un service Data (HTTP).
  - Testabilité réduite : difficile de mocker proprement les comportements sans toucher à la UI.
  - Duplication potentielle de logique (pagination, mapping TMDB -> MoviMedia).
- **Suggestion de correction**
  - Introduire un **repository spécialisé “watch providers content”** (ex. `ProviderContentRepository`) + data sources associés.
  - Créer des **use cases** :
    - `GetProviderMoviesPage`, `GetProviderShowsPage`,
    - `GetProviderPopularMedia`.
  - Adapter les pages pour consommer uniquement des **providers Riverpod** qui wrap ces use cases (ex. `providerResultsControllerProvider`).
  - Laisser la UI uniquement gérer l’état visuel (spinner / erreurs / affichage), pas la logique d’accès réseau.

#### 3.1.2 DI mixte et incohérente (service locator + Riverpod)

- **Fichiers concernés**
  - `search_data_module.dart`
  - `search_instant_controller.dart`
  - `search_paged_controller.dart`
  - `search_providers.dart`
- **Problème**
  - Certains éléments sont résolus via `slProvider` (`locator<SearchRepository>()`, `locator<TmdbWatchProvidersRemoteDataSource>()`, etc.), d’autres via des `Provider` Riverpod (ex. `searchRepositoryProvider`).
- **Pourquoi c’est un problème**
  - Double système de DI → complexité mentale accrue.
  - Plus difficile à tester : tu dois parfois override `sl` et parfois des providers.
  - Difficile de raisonner sur le cycle de vie des instances (qui gère quoi ?).
- **Suggestion de correction**
  - Choisir une approche dominante :
    - **Option A** : tout basculer sur **Riverpod** (DI par providers, `ref.read(...)`, modules DI remplacés par des providers “dataModule”).
    - **Option B** : garder `sl` principalement dans la couche Data/Core et exposer au Presentation uniquement des **abstractions** via providers Riverpod.
  - Dans les controllers :
    - remplacer les accès direct à `sl` par des injections via providers (`ref.read(searchRepositoryProvider)`).

#### 3.1.3 Logique Data “non encapsulée” dans les providers de présentation

- **Fichier concerné**
  - `search_providers.dart` (en particulier `providerPopularMediaProvider` et `watchProvidersProvider`)
- **Problème**
  - Ces providers mélangent :
    - accès `TmdbWatchProvidersRemoteDataSource` / `TmdbClient`,
    - règles métier (filtrage des providers connus / exclus / par nom),
    - mapping vers `PopularMediaPoster`.
- **Pourquoi c’est un problème**
  - Les règles métier (ordre des providers, liste `_knownProviderIds`, `_excludedProviderIds`) sont **enterrées dans la Presentation**.
  - Si tu veux réutiliser ce comportement ailleurs (autre écran, API, tests), tu dois le dupliquer.
- **Suggestion de correction**
  - Introduire un **service / domaine “WatchProvidersService”** dans la couche Domain/Data qui encapsule :
    - la logique de filtrage/tri,
    - le choix des providers connus / exclus.
  - Laisser les providers Riverpod uniquement orchestrer les appels à ce service, en gardant la logique métier hors de la présentation.

---

### 3.2 Important

#### 3.2.1 Redondance / incohérence autour de `SearchInstant` et `SearchRepository`

- **Fichiers concernés**
  - `search_instant_controller.dart`
  - `search_providers.dart` (provider `searchInstantUseCaseProvider`)
- **Problème**
  - `SearchInstantController` reconstruit lui-même ses usecases (`SearchInstant`, `SearchSagas`) à partir de `slProvider`, alors que des providers pour ces usecases existent déjà (`searchInstantUseCaseProvider`, `searchPaginatedUseCaseProvider`).
- **Pourquoi c’est un problème**
  - Incohérence : même usecase accessible par deux chemins différents.
  - Testabilité plus complexe : tu dois override à deux endroits.
- **Suggestion de correction**
  - Dans `SearchInstantController.build()`, utiliser les usecases exposés par les providers :
    - `final instant = ref.read(searchInstantUseCaseProvider);`
    - `final searchSagas = ref.read(searchSagasUseCaseProvider)` (à créer si besoin).
  - Laisser `SearchDataModule` se charger uniquement d’enregistrer les repositories.

#### 3.2.2 Fichiers de pages très longs (complexité UI)

- **Fichiers concernés**
  - `search_page.dart`
  - `provider_results_page.dart`
  - `provider_all_results_page.dart`
- **Problème**
  - Les pages contiennent :
    - toute la structure UI,
    - la gestion de la navigation,
    - parfois de la logique d’état (champs de texte, contrôleurs, filtrage local, affichage conditionnel).
- **Pourquoi c’est un problème**
  - Complexité cognitive élevée : difficile de scanner la page pour comprendre la structure.
  - Difficile de réutiliser certains blocs (header avec back + titre, sections de listes, animations).
- **Suggestion de correction**
  - Extraire des **widgets privés ou publics** :
    - `SearchHeader`, `SearchTextField`, `SearchResultsSection`, etc.
    - Pour les providers : `ProviderMoviesSection`, `ProviderShowsSection`.
  - Règle simple : une page ne devrait pas dépasser quelques centaines de lignes, et pas plus de 2–3 niveaux d’imbrication visuelle.

#### 3.2.3 Performance potentielle des providers asynchrones

- **Fichiers concernés**
  - `search_providers.dart` (`filteredSagasProvider`, `providerPopularMediaProvider`)
- **Problème**
  - `filteredSagasProvider` boucle sur chaque `SagaSummary` et fait un `await ref.watch(sagaAvailabilityProvider(saga).future)` séquentiel.
  - `providerPopularMediaProvider` fait potentiellement **2 appels TMDB par provider** (discover movie + discover tv).
- **Pourquoi c’est un problème**
  - Si la liste de sagas ou de providers grandit, la **latence peut grimper**.
  - Risque de déclenchement simultané de nombreux appels HTTP en parallèle depuis la Presentation (effet “thundering herd” si l’écran affiche beaucoup de providers).
- **Suggestion de correction**
  - Utiliser `Future.wait` pour paralléliser les appels :
    - transformer la boucle de `filteredSagasProvider` en une map de futures.
  - Mettre en place un **caching simple** (en mémoire ou stockage local) pour :
    - les résultats “popular media par provider”,
    - les sagas filtrées pour une requête donnée.
  - Éventuellement, limiter le nombre de providers affichés si la liste est très longue.

#### 3.2.4 SearchRepositoryImpl ne tire pas parti de `TmdbSearchRemoteDataSource` pour movies/shows

- **Fichier concerné**
  - `search_repository_impl.dart`
- **Problème**
  - Pour `searchMovies` / `searchShows`, le repo utilise uniquement `IptvCatalogReader.searchCatalog`, **sans fallback** ou combinaison avec `TmdbSearchRemoteDataSource`.
- **Pourquoi c’est un problème**
  - Le nom `SearchRepository` donne l’impression de couvrir “la recherche globale” (notamment TMDB).
  - Si l’IPTV ne contient pas un film connu, tu ne le trouveras pas, même s’il existe sur TMDB.
- **Suggestion de correction (si intention différente)**
  - Soit **renommer** le repository / les méthodes pour clarifier qu’il s’agit de “Recherche IPTV”.
  - Soit étendre le comportement pour :
    - fusionner les résultats IPTV + TMDB (avec déduplication),
    - ou faire un fallback TMDB si IPTV ne renvoie rien.

---

### 3.3 Nice to have

#### 3.3.1 Messages d’erreur trop verbeux côté UI

- **Fichiers concernés**
  - `search_instant_controller.dart`
  - `search_paged_controller.dart`
  - pages provider (SnackBars avec `$e`)
- **Problème**
  - Les messages d’erreur exposent directement `Exception.toString()` à l’utilisateur.
- **Pourquoi c’est un problème**
  - UX : messages peu lisibles, parfois techniques.
  - Peut exposer des informations internes (format d’exception, stack, etc.).
- **Suggestion de correction**
  - Logguer l’erreur complète dans les logs (`dev.log`, service de logging).
  - En UI, afficher un message **user-friendly**, par ex. “La recherche a échoué. Vérifie ta connexion et réessaie.”

#### 3.3.2 Définition des couleurs providers codée en dur dans `_WatchProviderCard`

- **Fichier concerné**
  - `watch_providers_grid.dart`
- **Problème**
  - La palette de couleurs par provider est définie dans un `Map<int, Color>` local.
- **Pourquoi c’est un problème**
  - Difficilement réutilisable ailleurs.
  - Si tu changes l’identité visuelle, tu dois modifier plusieurs endroits.
- **Suggestion de correction**
  - Déplacer cette logique dans un **theme / config centralisée** (ex. `ProviderBrandingConfig` dans `core` ou `shared`).
  - Réutiliser ces couleurs dans d’autres écrans liés aux providers.

#### 3.3.3 Légère duplication de logique d’historique

- **Fichier concerné**
  - `search_page.dart`
- **Problème**
  - La page gère à la fois :
    - la condition “query < 3” qui déclenche `searchHistoryControllerProvider.notifier.refresh()`,
    - l’appel à `searchControllerProvider.notifier.setQuery('')`.
- **Pourquoi c’est un problème**
  - La logique “quel état montrer (historique / providers / résultats)” pourrait être davantage centralisée dans le controller ou un petit service.
- **Suggestion de correction**
  - Encapsuler cette logique dans un petit **viewmodel / helper** ou dans le Notifier de recherche.

---

## 4. Plan de refactorisation par étapes

### Étape 1 — Unifier la DI pour la feature `search` (structurant)

1. Introduire systématiquement des **providers Riverpod** pour :
   - `SearchRepository`,
   - `SearchHistoryRepository`,
   - `TmdbWatchProvidersRemoteDataSource`,
   - `TmdbSearchRemoteDataSource`.
2. Adapter `SearchDataModule` pour qu’il ne fasse plus de DI côté Presentation, ou limiter son usage à la couche Data/Core.
3. Dans :
   - `SearchInstantController.build()`,
   - `SearchPagedController.build()`,
   - `search_history_providers.dart`,
   remplacer les usages de `slProvider().call()` par des `ref.read(...)` sur les providers dédiés.

### Étape 2 — Extraire la logique TMDB des pages providers vers Domain/Data

1. Créer :
   - un `ProviderContentRepository` avec :
     - `Future<SearchPage<MovieSummary>> getMoviesByProvider(...)`,
     - `Future<SearchPage<TvShowSummary>> getShowsByProvider(...)`,
     - `Future<PopularMediaPoster?> getPopularMediaForProvider(...)`.
2. Ajouter un datasource `TmdbProviderContentRemoteDataSource` qui encapsule les appels `discover/movie` / `discover/tv`.
3. Implémenter les **usecases** :
   - `GetProviderMoviesPage`,
   - `GetProviderShowsPage`,
   - `GetProviderPopularMedia`.
4. Adapter :
   - `ProviderAllResultsPage`,
   - `ProviderResultsPage`,
   - `providerPopularMediaProvider`,
   pour qu’ils consomment uniquement ces usecases via des Notifiers / FutureProviders.

### Étape 3 — Réduire la complexité des pages de recherche

1. Dans `search_page.dart` :
   - Extraire les widgets :
     - `SearchHeader`,
     - `SearchTextField`,
     - `SearchResultsSection`,
     - `SearchHistorySection` (remplace `_SearchHistoryList`),
     - `SearchSagasSection`.
2. Dans `provider_results_page.dart` :
   - Extraire :
     - `ProviderMoviesSection`,
     - `ProviderShowsSection`,
     - `ProviderSearchField`.
3. Garder les pages comme des **compositeurs de sections**, pas comme des “pages avec toute la logique inline”.

### Étape 4 — Améliorer les providers asynchrones (perf + lisibilité)

1. Dans `filteredSagasProvider` :
   - Refactoriser pour paralléliser les appels à `sagaAvailabilityProvider` via `Future.wait`.
   - Option : ajouter un simple cache en mémoire (Map<SagaId,List<int>>).
2. Dans `providerPopularMediaProvider` :
   - Ajouter un petit cache en mémoire par `(providerId, language)`.
   - Tu peux utiliser un `StateProvider<Map<...>>` ou une simple variable statique si tu veux rester simple.

### Étape 5 — Clarifier et documenter le rôle de `SearchRepositoryImpl`

1. Ajouter une **documentation claire** en haut de `SearchRepositoryImpl` :
   - “Ce repository fait des recherches dans l’IPTV catalog + TMDB pour les personnes.”
2. Si nécessaire :
   - introduire un second repository (ex. `TmdbSearchRepository`) si tu veux aussi une recherche pure TMDB.
3. Mettre à jour les usecases / naming si le comportement évolue (ex. `SearchIptvMovies` vs `SearchMovies`).

### Étape 6 — Polishing UI + erreurs

1. Normaliser les messages d’erreur dans les controllers :
   - message user-friendly + log détaillé.
2. Extraire la palette de couleurs providers dans une config centralisée.
3. Ajouter quelques tests unitaires/Widget tests :
   - `SearchInstantController` (query < 3, query valide, erreurs),
   - `SearchHistoryController` (ajout, suppression, clearAll),
   - `watchProvidersProvider` (filtrage et tri).

---

## 5. Bonnes pratiques à adopter pour la suite

1. **UI ⟶ Domain uniquement via usecases** : aucun appel HTTP direct dans les widgets ou controllers Riverpod ; toujours passer par un repository + usecase.
2. **Un seul système de DI côté Presentation** : idéalement, tout injecter via Riverpod (`Provider`, `NotifierProvider`, `FutureProvider`), en évitant d’appeler `sl` directement.
3. **Une classe / fichier = une responsabilité claire** : dès qu’une page dépasse ~300–400 lignes ou mélange plusieurs logiques, extraire des widgets ou controllers dédiés.
4. **Providers asynchrones = minimalisme + cache** : éviter de multiplier les appels réseau dans des boucles ; mutualiser avec `Future.wait`, et mettre du cache dès que c’est potentiellement coûteux.
5. **Domain pur et stable** : garder les entités, value objects et usecases sans dépendance Flutter/HTTP ; c’est déjà bien, continuer dans ce sens.
6. **Gestion d’erreurs user-friendly** : toujours séparer le message loggé du message affiché à l’utilisateur.
7. **Noms explicites et alignés avec le comportement** : si un repository ne cherche que dans l’IPTV catalog, le nom ou la doc doit le refléter.
8. **Tests unitaires sur les controllers Riverpod** : particulièrement pour la recherche et l’historique (c’est le cœur UX de la feature).
9. **Const et recompositions** : continuer à marquer les widgets stateless / invariables avec `const` pour limiter les rebuilds (globalement déjà bien géré).

---

Tu peux enregistrer ce rapport dans :

`docs/rapports/search_feature_analysis.md`

Ça te donnera une base claire pour planifier les prochains “Fix” / “V1.x” autour de la recherche.
