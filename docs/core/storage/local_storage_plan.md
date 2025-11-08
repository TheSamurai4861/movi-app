# Plan – Stockage local multi-plateforme

## 1. Objectifs
- Persister les données utilisateur (watchlist, préférences, sources IPTV, historique) localement sur iOS/Android.
- Périmètre initial : cache TMDB (détails film/série/personne), playlists Xtream, app-state (langue, thème), data utilisateur (watchlist, continue watching).
- Respect de l’architecture : `core/storage` fournit les abstractions, chaque feature utilise un repository combinant remote/local.

## 2. Choix technologiques
- **Base clé/valeur légère** pour préférences (langue, thème) : `LocalePreferences` (wrapper maison).
- **Base relationnelle** pour les données structurées (watchlist, cache, comptes IPTV) : **SQLite** via `sqflite`. Raisons : pas de génération de code, compatible iOS/Android, transactions, requêtes complexes.

## 3. Structure proposée (`lib/src/core/storage/`)
```
core/storage/
├── database/
│   └── sqlite_database.dart        # ouverture/migrations
├── repositories/
│   ├── watchlist_local_repository.dart
│   ├── content_cache_repository.dart
│   └── iptv_local_repository.dart
├── services/
│   ├── storage_module.dart        # Enregistrement dans GetIt
│   └── sync_service.dart          # Gère l’écriture/invalidations (à venir)
└── preferences/
    └── locale_preferences.dart    # déjà présent (à déplacer)
```

### 3.1 Tables SQLite
- `watchlist` : `content_id`, `content_type`, `title`, `poster`, `added_at`.
- `content_cache` : `cache_key`, `cache_type`, `payload`, `updated_at` (payload = JSON brut pour Movie/Tv/Person/Saga).
- `iptv_accounts` : infos connexion + statut.
- `iptv_playlists` : snapshots de playlists (payload JSON).

### 3.2 Repositories locaux
- `WatchlistLocalRepository` : `exists/save/remove/list` via `sqflite`.
- `ContentCacheRepository` : stocke n’importe quel payload JSON (Movie/Tv/Person/Saga) pour le caching offline.
- `IptvLocalRepository` : persiste comptes Xtream + playlists.

## 4. Intégration DI
- `StorageModule.register()` (dans `core/di/injector.dart`) :
  1. Ouvre Isar (ensure single instance via `await Isar.open([...])`).
  2. Enregistre les repositories locaux (`MovieLocalRepository`, etc.).
- Les repositories features (movie/tv/person/saga/IPTV) reçoivent en dépendance `localRepo` + `remoteRepo`.

## 5. Stratégies de synchronisation
- **Cache TTL** : stocker `updatedAt` dans chaque entity et définir une durée d’expiration (ex. 24h pour TMDB detail).
- **Watchlist / user data** : écritures locales immédiates (persistées dans Isar) + sync future lorsqu’une backend user sera dispo.
- **Sources IPTV** : déjà traitées via `XtreamCacheDataSource`; remplacer Map in-memory par entités Isar.

## 6. Testing
- Fournir un `IsarTestHelper` (in-memory instance) pour les tests unitaires.
- Tests d’intégration : vérifier round-trip `save/get` pour chaque entity + TTL logic.

## 7. Steps d’implémentation
1. Ajouter dépendances `sqflite`, `path`, `path_provider`.
2. Créer `core/storage/database/sqlite_database.dart` (création tables).
3. Implémenter `WatchlistLocalRepository`, `ContentCacheRepository`, `IptvLocalRepository`.
4. Intégrer via `StorageModule.register()` dans la DI.
5. Adapter `MovieRepositoryImpl` et `TvRepositoryImpl` pour utiliser `WatchlistLocalRepository`; migrer `XtreamCacheDataSource` vers `IptvLocalRepository`.

Ce plan assure un stockage local robuste, aligné sur clean architecture, et supporte à la fois les caches TMDB et les données utilisateur/iptv.***
