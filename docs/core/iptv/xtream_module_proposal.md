# Core — Intégration de l’API Xtream (scope VOD/Séries uniquement)

## 1. Objectifs & périmètre
- **Alignement MOVI** : se concentrer sur la découverte de films/séries (cf. `docs/movi_overview.md`, roadmap data/domain) sans activer la diffusion Live TV pour l’instant.
- **Source utilisateur** : permettre à l’utilisateur d’ajouter une URL Xtream (`player_api.php`) + credentials, puis d’exposer le catalogue VOD/Séries dans les écrans Home/Bibliothèque comme une « playlist personnelle ».
- **Fiabilité** : gérer l’auth, la validation et la persistance locale des métadonnées pour éviter de re-télécharger des milliers d’items à chaque ouverture.

## 2. Architecture proposée (`lib/src/core/iptv/`)
```
core/iptv/
├── domain/
│   ├── entities/
│   │   ├── xtream_account.dart          # Credentials + serveur normalisés
│   │   ├── xtream_catalog_snapshot.dart # Données VOD/Séries agrégées
│   │   └── xtream_playlist_item.dart    # Elément de playlist (film/série)
│   ├── repositories/iptv_repository.dart # Contrat pour l’app (ajout/maj sources)
│   └── value_objects/xtream_endpoint.dart
├── data/
│   ├── datasources/
│   │   ├── xtream_remote_data_source.dart # Appelle player_api.php (action=…)
│   │   └── xtream_cache_data_source.dart  # Persistance locale (Isar/Hive)
│   ├── dtos/
│   │   ├── xtream_auth_dto.dart
│   │   ├── xtream_category_dto.dart
│   │   └── xtream_stream_dto.dart
│   └── repositories/iptv_repository_impl.dart
├── application/
│   ├── usecases/
│   │   ├── add_xtream_source.dart
│   │   ├── refresh_xtream_catalog.dart
│   │   └── list_xtream_playlists.dart
│   └── services/playlist_mapper.dart      # Convertit DTO → MovieSummary/TvShowSummary
└── presentation/ (plus tard)              # Widgets/Controllers spécifiques
```

## 3. Flux : ajout d’une nouvelle source IPTV
1. **UI Settings → “Ajouter source Xtream”**
   - Inputs : `serverUrl`, `username`, `password`, alias utilisateur.
   - Validation basique (HTTPS recommandé, pas de champ vide).
2. **Use case `AddXtreamSource`**
   - Normalise l’URL (`XtreamEndpoint` stocke host, port, scheme).
   - Appelle `XtreamRemoteDataSource.authenticate()` pour vérifier `user_info.auth == 1`.
   - Construit un `XtreamAccount` (ID hashé `sha256(server+user)`), stocke credentials chiffrés (SecureStorage).
   - Sauvegarde minimal `XtreamCatalogSnapshot` vide dans cache (statut `pending_fetch`).
3. **Job de synchronisation (immédiat)**
   - Enchaîne les endpoints nécessaires : `get_vod_categories`, `get_vod_streams`, `get_series_categories`, `get_series`.
   - Ignore `get_live_*` (hors scope).
   - Découpe par pages si besoin (certains serveurs limitent la taille).
4. **Mapping playlist**
   - `PlaylistMapper` convertit chaque VOD/Serie en `MovieSummary` / `TvShowSummary` avec un `ContentReference` `type=movie|series` + stockage du `stream_id`, `category_id`, `poster` (stream_icon) et `tmdbId` si fourni (certains serveurs fournissent `tmdb_id`).
   - Les contenus sont regroupés dans une `XtreamPlaylist` par catégorie (ex: « Films Action – Source X ») pour être exposés dans l’onglet Bibliothèque / Playlists.
5. **Persistance**
   - `XtreamCacheDataSource` stocke :
     - `xtream_accounts` (id, alias, endpoint, status, expiration).
     - `xtream_catalogs` (account_id, lastSync, counts, error).
     - `xtream_items` (account_id, stream_id, type, metadata minimal).
   - Les payloads bruts peuvent être compressés/JSON pour relecture rapide, mais seuls les champs utiles au domain sont matérialisés dans les entités MOVI.

## 4. Gestion des playlists et contenus
- **Playlist logique** : chaque catégorie VOD/Séries devient une playlist MOVI (`PlaylistSummary`) avec `contentReference` pointant vers les Movie/Tv summaries générés. Les playlists sont marquées `source=xtream` pour filtrer côté UI.
- **Rétention** :
  - On conserve les derniers `N` snapshots pour détecter les suppressions (ex: film retiré). Un diff léger (hash listes) permet d’archiver les contenus disparus.
  - Les assets (posters) se chargent via l’URL fournie par Xtream ; pas de téléchargement local à ce stade.
- **Actualisation** :
  - Cron app (Workmanager/TODO) toutes les 24h ou via action utilisateur “Rafraîchir”.
  - Stratégie de pagination : certains serveurs renvoient >10k entrées ; on peut découper par `category_id` pour limiter la mémoire.

## 5. Sécurité & stockage des identifiants
- Credentials stockés chiffrés via `SecretStore` (ou `flutter_secure_storage` côté mobile).
- En mémoire seules les sessions courtes sont gardées ; chaque requête reconstruit l’URL signée `player_api.php?username=…`.
- Les erreurs (ex: auth expirée, compte suspendu) sont propagées à l’utilisateur via un statut sur l’alias (`Active`, `Expired`, `Error`).

## 6. Traitement des métadonnées
- **Champs disponibles** :
  - `stream_id`, `name`, `description`, `rating`, `rating_5based`, `added`, `category_id`, `series_id` (pour séries), `container_extension`, `direct_source`, `tmdb`, `releasedate`.
  - `info` (pour séries) contient saisons/épisodes → peut alimenter `Season`/`Episode`.
- **Normalisation MOVI** :
  - `tmdb` (quand présent) devient `tmdbId` sur `MovieSummary`/`TvShowSummary`.
  - `releasedate` → `releaseYear`.
  - `info.genres` → tags.
  - `plot`/`description` → `Synopsis`.
- **Filtres** :
  - On ignore les flux Live (`stream_type == 'live'`).
  - On masque les contenus sans poster + synopsis si l’utilisateur le souhaite (préférence).

## 7. Roadmap d’implémentation
1. **Sprint 1**
   - Créer `core/iptv` structure + entités/domain contracts.
   - Implémenter `XtreamRemoteDataSource` (auth + fetch categories/streams).
   - Ajouter `xtream` module à GetIt (`core/di`).
2. **Sprint 2**
   - Persistance locale (Hive/Isar) pour accounts + catalog + items.
   - Mapping vers `MovieSummary`/`TvShowSummary` + exposer playlists dans Bibliothèque (lecture seule).
3. **Sprint 3**
   - Rafraîchissement automatique + UI Settings (“Sources IPTV”).
   - Tests end-to-end sur un compte Xtream dédié (mock server si besoin).

## 8. Extension future (conformité MOVI)
- Une fois la partie VOD/séries stable, on pourra ajouter les flux Live en suivant la même logique mais en les stockant séparément (TV guide, EPG) conformément à la vision MOVI (section 2.3 « Fonctionnalités futures »).
- Prévoir un `IptvSourceCapability` pour activer/désactiver des sections UI selon les ressources disponibles (VOD only vs VOD+Live).

Cette proposition garde l’intégration Xtream encapsulée dans `core/iptv`, valorise les playlists MOVI existantes et respecte la feuille de route actuelle (pas de live TV, focus data/domain).***
