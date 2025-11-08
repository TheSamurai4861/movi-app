# Implémentation complète de la couche Data (TMDB + stockage local + IPTV)

## 1. Objectif
Structurer la couche `data/` de toutes les features MOVI pour qu’elle couvre :
- TMDB (remote + cache local).
- IPTV Xtream (remote + cache SQLite).
- Données utilisateur (watchlist, préférences, continue watching).

## 2. Architecture cible

```
features/<feature>/data/
├── datasources/
│   ├── tmdb_<feature>_remote_data_source.dart
│   └── <feature>_local_data_source.dart   # wrappers SQLite/cache
├── dtos/
├── repositories/
│   └── <feature>_repository_impl.dart     # combine remote/local
└── data_module.dart                      # enregistrement DI
```

### 2.1 Flux générique
1. **Use case** appelle le repository.
2. **Repository** → `localDataSource.get(id)` pour vérifier le cache (TTL 24h par ex.).
3. Si cache invalide → `remoteDataSource.fetch(id)` via `TmdbClient`.
4. Mapping vers entités domain.
5. Sauvegarde locale (`localDataSource.save(...)`) et retour.

### 2.2 Stockage local
- **SQLite** (via `core/storage/database/sqlite_database.dart`) avec tables :
  - `watchlist`, `content_cache`, `iptv_accounts`, `iptv_playlists`.
- `WatchlistLocalRepository`, `ContentCacheRepository`, `IptvLocalRepository` déjà présents.
- Local data source par feature (ex. `MovieLocalDataSource`) qui lit/écrit dans `content_cache` et utilise des clés (`movie_detail_550`, `movie_reco_550`, etc.).
- Sérialisation JSON (via `dto.toJson()`).

### 2.3 Gestion langue/fallback
- `TmdbClient` utilise `LocalePreferences`.
- Pour les champs critiques (overview, logos), si vide après fetch principal, lancer un fetch fallback `language='en-US'` et fusionner.
- Stocker la langue utilisée dans le cache (clé inclut `locale`).

### 2.4 IPTV
- Déjà branché via `IptvLocalRepository` (SQLite). À compléter :
  - Ajouter TTL pour snapshots (`content_cache`).
  - Normaliser les playlists (type movie/series).

## 3. Étapes par feature
### Movie
1. Créer `MovieLocalDataSource` (méthodes `getMovie`, `saveMovie`, `getRecommendations`, `saveRecommendations`) s’appuyant sur `ContentCacheRepository`.
2. Injecter dans `MovieRepositoryImpl` et appliquer la stratégie remote+local.
3. Ajouter `ContinueWatchingLocalRepository` (table `continue_watching`) pour stocker la progression.

### TV
1. `TvLocalDataSource` (détails, saisons, épisodes, search).
2. Cache des saisons/épisodes pour éviter les multiples hits TMDB.
3. Watchlist déjà branchée (via SQLite).

### Person
1. `PersonLocalDataSource` (biodata + filmographie).
2. TTL plus long (les données changent peu).

### Saga
1. `SagaLocalDataSource` pour les collections TMDB.
2. Calculer et stocker `totalDuration` (somme des parties) dans `content_cache`.

### IPTV
1. Remplacer les structures `Map` par `IptvLocalRepository` (fait).
2. Ajouter `XtreamSyncService` (future tâche) pour planifier les rafraîchissements.

## 4. Tests
- **Unitaires** : mock remote + local data sources, vérifier que le cache est utilisé correctement.
- **Intégration** : garder `test/integration/tmdb_repositories_test.dart` (avec TMDB réel) et en ajouter pour l’IPTV (source mockable).

## 5. Roadmap
1. Compléter les data sources locales (movie/tv/person/saga) + injection DI.
2. Implémenter TTL/cache invalidation.
3. Ajouter `continue_watching` + `history` tables.
4. Brancher `LocalePreferences` dans les features UI (changement de langue → purge cache).
5. Écrire tests unitaires sur chaque repository.

Cette feuille de route finalise la couche data de MOVI en combinant TMDB, IPTV et stockage utilisateur sous un schéma propre et testable.***
