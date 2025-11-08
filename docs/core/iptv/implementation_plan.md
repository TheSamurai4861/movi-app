# Plan d’implémentation — `core/iptv` (Xtream)

## 1. Pré-requis
- `core/network` opérationnel (Dio + NetworkExecutor).
- `core/config` exposé via GetIt/Riverpod (`AppConfig` pour URLs/timeouts).
- Module DI capable d’injecter `NetworkExecutor`, `SecretStore`, `PreferencesService`.

## 2. Étapes

### 2.1 Domain
1. Créer `lib/src/core/iptv/domain/entities/` :
   - `XtreamAccount` (endpoint, alias, status, expiry).
   - `XtreamPlaylistItem` (movie/series metadata).
   - `XtreamCatalogSnapshot`.
2. Interfaces :
   - `IptvRepository` (add source, refresh catalog, list playlists, remove source).
   - `XtreamCredentials` value-object (username/password chiffré).

### 2.2 Data layer
1. Datasources :
   - `XtreamRemoteDataSource` (utilise `NetworkExecutor` pour `player_api.php`).
   - `XtreamCacheDataSource` (Hive/Isar pour comptes + items).
2. DTOs :
   - `XtreamAuthDto`, `XtreamCategoryDto`, `XtreamStreamDto`, `XtreamSeriesInfoDto`.
   - Mappers vers domain.
3. Repository impl :
   ```dart
   class IptvRepositoryImpl implements IptvRepository {
     final XtreamRemoteDataSource remote;
     final XtreamCacheDataSource cache;
     final PlaylistMapper mapper;
   }
   ```

### 2.3 Application layer
1. Use cases :
   - `AddXtreamSource` (valide credentials + crée compte).
   - `RefreshXtreamCatalog` (récupère VOD/Séries, stocke snapshot).
   - `ListXtreamPlaylists` (retourne playlists MOVI).
2. Services :
   - `PlaylistMapper` → `MovieSummary` / `TvShowSummary`.
   - `XtreamScheduler` (rafraîchissement périodique via Workmanager ultérieurement).

### 2.4 Intégration DI
1. Nouveau module `XtreamModule.register(sl)` :
   - Requiert `NetworkExecutor`, `SecretStore`, `PreferencesService`.
   - Enregistre `XtreamRemoteDataSource`, `XtreamCacheDataSource`, `IptvRepository`.
2. Ajouter hooks test : `FakeXtreamRemoteDataSource`, `InMemoryXtreamCache`.

### 2.5 Flux utilisateur
1. Settings → “Sources IPTV”.
2. Formulaire → `AddXtreamSource`.
3. Après succès, lancer `RefreshXtreamCatalog`.
4. Les playlists générées alimentent Bibliothèque via `ListXtreamPlaylists`.

### 2.6 Documentation & QA
1. Mettre à jour `docs/core/iptv/xtream_module_proposal.md` avec les pointeurs code une fois implémenté.
2. Tests :
   - Unitaires sur mappers + usecases.
   - Intégration network (mock server) pour `XtreamRemoteDataSource`.

## 3. Livrable final
- Module `core/iptv` auto-contenu, branché sur `core/network` et `core/config`.
- Ready pour exposer playlists Xtream dans les features MOVI quand la UI sera prête.
