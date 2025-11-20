# Plan d’implémentation — Feature `search`

## Vue d’ensemble
- Objectif: refactorer la recherche pour respecter Clean Architecture, améliorer i18n/UX, performance (debounce, pagination, cache), et fiabilité (tests Domain/Data/Presentation).
- Portée: Domain/Data/Presentation + DI et tests. Pas de refonte UI complète; focus sur architecture et robustesse.

## Architecture cible
- Domain: entités (`MovieSummary`, `TvSummary`, `PersonSummary`, `SagaSummary`), contrats (`SearchRepository`, `SearchHistoryRepository`), use cases (`SearchInstant`, `SearchPaginatedMovies`, `SearchPaginatedShows`, `LoadWatchProviders`, `SaveSearchQuery`, `GetSearchHistory`).
- Data: `TmdbSearchRemoteDataSource`, `SearchLocalDataSource` (history + watch providers cache), mappers DTO→entities.
- Presentation: controllers Riverpod (`search_instant_controller`, `search_paged_controller`) consommant uniquement les use cases; pages utilisent des ViewModels.

## Étapes

### Étape 1 — Domain (contrats & use cases)
- Actions:
  - Introduire `SearchRepository` avec méthodes: `instant(query)`, `movies(query, page)`, `shows(query, page)`, `people(query)`, `sagas(query)`, `watchProviders(region)`.
  - `SearchHistoryRepository`: `save(query)`, `remove(query)`, `list()`, `clear()`.
  - Use cases:
    - `SearchInstant` (renvoie agrégat movies/shows/people/sagas).
    - `SearchPaginatedMovies`, `SearchPaginatedShows`.
    - `LoadWatchProviders` (par région; FR par défaut, configurable).
    - `SaveSearchQuery`, `GetSearchHistory`.

### Étape 2 — Data (remote/local, mappers)
- Actions:
  - Créer `TmdbSearchRemoteDataSource` (routes `search/movie`, `search/tv`, `search/person`, `search/collection`, `watch/providers`) avec `language` via `LocalePreferences`.
  - Créer `SearchLocalDataSource` pour l’historique (clé `search_history_<query>`) et cache providers (clé `watch_providers_<region>` avec TTL 1 jour).
  - Mappers: `TmdbMovieSummaryDto`, `TmdbTvSummaryDto`, `TmdbPersonSummaryDto`, `TmdbWatchProviderDto` → entités Domain.
  - Repository `SearchRepositoryImpl` orchestrant remote/local et conversions.

### Étape 3 — Presentation (controllers & pages)
- Actions:
  - Refactorer `search_instant_controller` pour consommer `SearchInstant` (supprimer appels directs et maintenir debounce 1s, min 3 chars).
  - Refactorer `search_paged_controller` pour consommer `SearchPaginatedMovies/Shows` (pages incrémentales, `hasMore`, `error`).
  - `provider_all_results_page` et `provider_results_page`: déplacer le code d’accès direct à `TmdbClient` vers use case `LoadWatchProviders` + repository paginé; injecter via `sl`.
  - `watch_providers_grid`: charger via use case, afficher `loading/error` localisés.

### Étape 4 — DI
- Actions:
  - Étendre `SearchDataModule.register()` pour enregistrer: `TmdbSearchRemoteDataSource`, `SearchLocalDataSource`, `SearchRepositoryImpl` + tous les use cases.
  - S’assurer que `injector.initDependencies()` appelle `SearchDataModule.register()` (déjà présent).

### Étape 5 — i18n & UX
- Actions:
  - Remplacer les messages en dur dans `search_page`, `search_results_page`, `provider_*_page` par `AppLocalizations` (erreurs, “Aucun résultat”, “Réessayer”).
  - Uniformiser les libellés et placeholders (recherche, filtre provider).
  - Afficher `Retry` sur échec réseau (ré-invocation provider ou use case concerné).

### Étape 6 — Performance & robustesse
- Actions:
  - Debounce côté controller (déjà présent), centraliser au même endroit; ignorer requêtes < 3 caractères.
  - Utiliser `cacheTtl` du `TmdbClient` pour les recherches “chaudes” (ex. 30–60s) afin d’éviter les doublons.
  - Paginer efficacement (`page`, `total_pages`), éviter duplication d’appels au scroll.
  - Gestion des erreurs contrôlée: surfacer des messages propres, logs via logger, pas de `print`.

### Étape 7 — Tests
- Domain:
  - `test/features/search/domain/search_instant_usecase_test.dart` (success/empty/error).
  - `test/features/search/domain/search_paginated_movies_usecase_test.dart` (pagination, hasMore).
  - `test/features/search/domain/search_paginated_shows_usecase_test.dart`.
- Data:
  - `test/features/search/data/search_repository_impl_test.dart` (mapping, cache providers, language propagation).
  - `test/features/search/data/search_history_local_data_source_test.dart` (save/remove/list).
- Presentation:
  - `test/features/search/presentation/search_instant_controller_test.dart` (debounce, min length, error state).
  - `test/features/search/presentation/search_paged_controller_test.dart` (fetchNextPage, error state).
  - `test/features/search/presentation/provider_pages_test.dart` (use cases appelés, i18n erreurs).

### Étape 8 — Metrics & qualité
- Actions:
  - Couverture >80% sur use cases, mappers, controllers.
  - Lint & type-check: `flutter analyze`, `dart test` vert sur modules modifiés.
  - Temps de réponse < 2s pour recherches instantanées (avec cache chaud).

## Références code existant
- Controllers: `lib/src/features/search/presentation/controllers/search_instant_controller.dart`, `search_paged_controller.dart`.
- Pages: `lib/src/features/search/presentation/pages/search_page.dart`, `search_results_page.dart`, `provider_all_results_page.dart`, `provider_results_page.dart`.
- DTOs: `lib/src/features/search/data/dtos/tmdb_watch_provider_dto.dart`.
- DI: `lib/src/features/search/data/search_data_module.dart`, `lib/src/core/di/injector.dart` (module déjà enregistré).

## Checklist de livraison
- Domain: contrats et use cases en place.
- Data: remote/local + repository impl avec i18n/cache.
- Presentation: controllers/pages sans appel direct au remote.
- DI: module `SearchDataModule` étendu et initialisé.
- i18n: messages localisés homogènes.
- Tests: Domain/Data/Presentation ajoutés et passants.
