# Plan de complétion — Feature `search`

Ce plan vise à combler les écarts identifiés entre le rapport initial et l'implémentation actuelle, en incluant l'historique de recherche et l'injection de dépendances.

## Étape 1 : Domain Layer (Watch Providers & History)
- [x] **Vérifier le Use Case** `LoadWatchProviders`
  - Fichier : `lib/src/features/search/domain/usecases/load_watch_providers.dart`
  - Statut : Existe déjà. Vérifier qu'il est utilisé correctement.
- [x] **Mettre à jour** `SearchRepository`
  - S'assurer que la méthode `Future<List<WatchProvider>> getWatchProviders(String region);` est bien définie (C'est le cas).
- [x] **Vérifier** `SearchHistoryRepository`
  - Fichier : `lib/src/features/search/domain/repositories/search_history_repository.dart`
  - S'assurer que les méthodes (save, list, remove, clear) sont présentes.

## Étape 2 : Data Layer (Implémentation & Cache)
- [x] **Mettre à jour** `SearchRepositoryImpl`
  - Implémenter la méthode manquante `getWatchProviders` en utilisant `TmdbWatchProvidersRemoteDataSource` (ou le remote approprié).
  - Gérer les erreurs : mapper `ServerException`/`CacheException` vers des `Failure` du domaine.
  - Ajouter la logique de cache pour les providers (TTL 1 jour) via `SearchLocalDataSource` (à vérifier/créer si absent pour cette partie).
- [x] **Vérifier/Finaliser** `SearchHistoryRepositoryImpl`
  - S'assurer qu'il utilise `SearchLocalDataSource` pour persister l'historique.

## Étape 3 : Injection de Dépendances (DI)
- [x] **Mettre à jour** `SearchDataModule`
  - Fichier : `lib/src/features/search/data/search_data_module.dart`
  - Enregistrer `TmdbWatchProvidersRemoteDataSource`.
  - Enregistrer `SearchLocalDataSource` (si ce n'est pas fait).
  - Enregistrer `SearchRepositoryImpl` (ou vérifier son enregistrement).
  - Enregistrer les Use Cases :
    - `LoadWatchProviders`
    - `SearchInstant`
    - `SearchPaginatedMovies` / `SearchPaginatedShows`
    - `GetSearchHistory` / `SaveSearchQuery` / `RemoveSearchHistoryItem` / `ClearSearchHistory`

## Étape 4 : Tests (Priorité Critique)
Le dossier `test/features/search` doit être complété.

### Domain Tests
- [x] `test/features/search/domain/load_watch_providers_usecase_test.dart`
- [ ] `test/features/search/domain/search_history_usecase_test.dart` (couvrir list/save/remove)

### Data Tests
- [ ] `test/features/search/data/search_repository_impl_test.dart`
  - Tester `getWatchProviders` (appel remote + mapping).
  - Tester la gestion des erreurs.
- [ ] `test/features/search/data/search_history_repository_impl_test.dart`

### Presentation Tests
- [ ] `test/features/search/presentation/search_instant_controller_test.dart`
- [ ] `test/features/search/presentation/search_history_controller_test.dart` (si applicable)

## Étape 5 : Presentation (Intégration)
- [x] **Mettre à jour** les pages de providers
  - `watch_providers_grid.dart` : OK (utilise le use case via provider).
  - `provider_all_results_page.dart` : OK (refactoré pour utiliser `LoadWatchProviders` et les nouvelles méthodes du repo).
  - Afficher les états de chargement et d'erreur localisés.
- [ ] **Intégrer** l'historique de recherche
  - S'assurer que l'historique s'affiche quand la recherche est vide (si c'est l'UX désirée).
  - Sauvegarder la requête lors d'une recherche validée.
