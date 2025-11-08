Étapes proposées

Prérequis stockage

Finaliser le module SQLite (chemins, migrations).
Ajouter un helper de TTL générique (CachePolicy + utilitaires DateTime).
Movies – POC cache local

Créer MovieLocalDataSource (content_cache).
Adapter MovieRepositoryImpl pour lire/écrire le cache (détail & recommandations).
Tests unitaires (mock remote/local) + intégration.


TV – cache + saisons/épisodes

Data source locale pour show + saisons/épisodes (clé tv_detail_<locale>).
Repositories TV mis à jour (remote + local).
Tests similaires.

Statut : ✅ Implémenté (TvLocalDataSource avec clé dépendante de la locale, TvRepositoryImpl et tests `test/features/tv/data/tv_repository_impl_test.dart`).


Persons & Sagas

Local data sources pour bio/filmographie et collections.
Repositories mis à jour, tests.
Continue Watching / History

Nouvelle table SQLite (continue_watching).
Repos locaux + adaptation future côté UI.

Implémentations réalisées (Persons, Sagas, Continue Watching, History)

- DB / SQLite:
  - Table continue_watching + migration: `lib/src/core/storage/database/sqlite_database.dart`
  - Table history + migration: `lib/src/core/storage/database/sqlite_database.dart`
- Dépôts locaux:
  - Continue Watching: `lib/src/core/storage/repositories/continue_watching_local_repository.dart`
  - History: `lib/src/core/storage/repositories/history_local_repository.dart`
- DI Storage:
  - Enregistrement des dépôts: `lib/src/core/storage/services/storage_module.dart`
- Sagas:
  - Local DS: `lib/src/features/saga/data/datasources/saga_local_data_source.dart`
  - Repo offline-first (cache → remote): `lib/src/features/saga/data/repositories/saga_repository_impl.dart`
  - Module DI: `lib/src/features/saga/data/saga_data_module.dart`
- Persons:
  - Local DS: `lib/src/features/person/data/datasources/person_local_data_source.dart`
  - Repo offline-first: `lib/src/features/person/data/repositories/person_repository_impl.dart`
- Movies/TV (Continue Watching):
  - Movie repo `getContinueWatching()`: `lib/src/features/movie/data/repositories/movie_repository_impl.dart`
  - TV repo `getContinueWatching()`: `lib/src/features/tv/data/repositories/tv_repository_impl.dart`

À faire (tests/UI):
- Tests unitaires repo Person/Saga (succès/fallback/erreur), déjà amorcés pour DS Saga.
- UI: carrousel Continue Watching + vue History (tri par date, % via `position/duration`, film/épisode via `content_type` + `season/episode`).


IPTV sync

Ajout TTL snapshots dans content_cache.
Préparer XtreamSyncService (tâche planifiée).

Statut: ✅ Implémenté
- TTL snapshots (6h par défaut):
  - `lib/src/core/iptv/data/datasources/xtream_cache_data_source.dart` → `getSnapshot(..., policy)` et `snapshotPolicy`.
- Service de sync planifiée:
  - `lib/src/core/iptv/application/services/xtream_sync_service.dart`
  - Démarrage/arrêt via `start()/stop()`, intervalle par défaut 2h (configurable).
  - Logique: pour chaque source active (`AppStateController`), si snapshot expiré/absent → `RefreshXtreamCatalog`.
- DI module IPTV: service enregistré (non auto‑démarré)
  - `lib/src/core/iptv/config/iptv_module.dart`


On peut attaquer étape 1 dès que validé, puis enchaîner séquentiellement.


