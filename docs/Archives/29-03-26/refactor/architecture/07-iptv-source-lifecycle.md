# Cycle de vie d’une source IPTV — Movi
## A4 — Cartographie de l’existant

### 1. Objet du document
Ce document cartographie le cycle de vie d’une source IPTV dans Movi, depuis son ajout par l’utilisateur jusqu’à son exploitation par le reste de l’application.  
Il s’appuie uniquement sur le snapshot disponible et distingue ce qui est certain, probable ou à vérifier.

### 2. Résumé exécutif
Le système IPTV de Movi repose sur un flux majoritairement local, avec persistance SQLite pour les comptes/catalogues et stockage sécurisé séparé pour les credentials. Le snapshot confirme deux types de source : Xtream et Stalker, avec des use cases d’ajout distincts, des services de refresh dédiés et un mécanisme de sélection de source active. :contentReference[oaicite:19]{index=19} :contentReference[oaicite:20]{index=20}

L’ajout peut se faire depuis les écrans `welcome` ou depuis `settings`, puis passe par un contrôleur de connexion qui crée/active la source localement, met à jour l’état applicatif, peut persister vers Supabase selon une policy, et lance ensuite une synchronisation en arrière-plan. :contentReference[oaicite:21]{index=21} :contentReference[oaicite:22]{index=22}

La consommation de la source par l’application est ensuite répartie entre plusieurs blocs :
- lecture du catalogue via `IptvCatalogReader` ;
- lookup IPTV via `XtreamLookupService` ;
- construction d’URL de stream via les builders dédiés ;
- exploitation par `home`, `movie/tv` et le player. :contentReference[oaicite:23]{index=23} :contentReference[oaicite:24]{index=24}

### 3. Fichiers centraux identifiés
- UI : `welcome_source_page.dart`, `welcome_source_select_page.dart`, `iptv_connect_page.dart`, `iptv_source_add_page.dart`, `iptv_source_select_page.dart`, `iptv_sources_page.dart` :contentReference[oaicite:25]{index=25}
- Use cases : `add_xtream_source.dart`, `add_stalker_source.dart`, `refresh_xtream_catalog.dart`, `refresh_stalker_catalog.dart` :contentReference[oaicite:26]{index=26}
- Persistance : `iptv_local_repository.dart`, `iptv_account_store.dart`, `iptv_playlist_store.dart`, `iptv_episode_store.dart`, `credentials_vault.dart` :contentReference[oaicite:27]{index=27}
- Sync / cloud : `supabase_iptv_sources_repository.dart`, `supabase_iptv_sources_repository_impl.dart`, `xtream_sync_service.dart`, `iptv_credentials_edge_service.dart` :contentReference[oaicite:28]{index=28} :contentReference[oaicite:29]{index=29}
- Consommation : `iptv_catalog_reader.dart`, `xtream_lookup_service.dart`, `build_movie_video_source.dart`, `xtream_stream_url_builder_impl.dart`, `stalker_stream_url_builder.dart` :contentReference[oaicite:30]{index=30} :contentReference[oaicite:31]{index=31}

### 4. Séquence complète du cycle de vie

#### Étape 1 — Ajout de source
La source peut être ajoutée :
- depuis le flow `welcome/*` ;
- ou depuis `settings/iptv/*`. :contentReference[oaicite:32]{index=32} :contentReference[oaicite:33]{index=33}

`IptvSourceAddPage` utilise `iptvConnectControllerProvider.notifier.connect(...)` avec :
- `sourceType`
- `serverUrl`
- `username`
- `password`
- `macAddress`
- `alias` :contentReference[oaicite:34]{index=34}

#### Étape 2 — Validation
**Xtream** : `AddXtreamSource` valide `XtreamEndpoint.tryParse(rawUrl)` et exige `username/password` non vides avant d’appeler le repository. :contentReference[oaicite:35]{index=35}  
**Stalker** : `AddStalkerSource` valide `StalkerEndpoint.tryParse(rawUrl)` et le format MAC `XX:XX:XX:XX:XX:XX` avant d’appeler le repository. :contentReference[oaicite:36]{index=36} :contentReference[oaicite:37]{index=37}

#### Étape 3 — Transformation
Ce qui est certain :
- il existe des DTOs Xtream/Stalker (`xtream_auth_dto`, `stalker_auth_dto`, `xtream_category_dto`, `stalker_category_dto`, etc.) ;
- il existe des mappers comme `PlaylistMapper` et `StalkerPlaylistMapper`. :contentReference[oaicite:38]{index=38}

Ce qui est probable :
- les réponses réseau sont transformées en entités métier (`XtreamAccount`, `StalkerAccount`, `XtreamPlaylist`, `XtreamPlaylistItem`, etc.). :contentReference[oaicite:39]{index=39}

Ce qui reste à vérifier :
- le détail précis de la normalisation champ par champ pour tous les types.

#### Étape 4 — Persistance
Le snapshot confirme :
- une persistance locale via `IptvLocalRepository` et plusieurs stores spécialisés ; :contentReference[oaicite:40]{index=40}
- une persistance sécurisée des credentials via `CredentialsVault` ; :contentReference[oaicite:41]{index=41}
- une persistance cloud possible via `SupabaseIptvSourcesRepository`, avec `local_id`, `name`, `is_active`, `last_sync_at`, `expires_at`, `encrypted_credentials`, et éventuellement `server_url` / `username` selon le mode de vérité distant. :contentReference[oaicite:42]{index=42}

Le snapshot confirme aussi une migration legacy des playlists vers des tables normalisées gérées par `IptvPlaylistStore` et `IptvStorageTables`. :contentReference[oaicite:43]{index=43}

#### Étape 5 — Sélection active
La sélection active repose au minimum sur :
- `SelectedIptvSourcePreferences.selectedSourceId` ; :contentReference[oaicite:44]{index=44}
- `AppStateController.setActiveIptvSources(...)` ; :contentReference[oaicite:45]{index=45} :contentReference[oaicite:46]{index=46}

Au bootstrap :
- si une seule source valide existe, elle est sélectionnée automatiquement ;
- si plusieurs sources existent sans sélection valide, la destination devient `chooseSource`. :contentReference[oaicite:47]{index=47}

Dans `IptvConnectController.connect()` :
- la source ajoutée est activée pour l’app ;
- la préférence de source sélectionnée est mise à jour si nécessaire. :contentReference[oaicite:48]{index=48}

#### Étape 6 — Refresh / sync
Le snapshot confirme plusieurs niveaux :
- `RefreshXtreamCatalog` et `RefreshStalkerCatalog` existent comme use cases ; :contentReference[oaicite:49]{index=49}
- `XtreamSyncService` existe et est utilisé au lancement ; :contentReference[oaicite:50]{index=50} :contentReference[oaicite:51]{index=51}
- `IptvConnectController` lance aussi un background sync best-effort après `connect()`. :contentReference[oaicite:52]{index=52}
- la sync manuelle globale utilisateur peut inclure les sources IPTV via `ComprehensiveCloudSyncService`. :contentReference[oaicite:53]{index=53}

Ce qui n’est pas entièrement démontré ici :
- le détail exhaustif de la politique de refresh pour tous les cas.

#### Étape 7 — Consommation par l’application
Le snapshot confirme :
- `IptvCatalogReader` lit le catalogue depuis `IptvLocalRepository` et expose recherche/liste/catégories/disponibilité TMDB ; :contentReference[oaicite:54]{index=54}
- `XtreamLookupService` existe et est injecté dans les blocs home/playback ; :contentReference[oaicite:55]{index=55}
- `BuildMovieVideoSource`, `XtreamStreamUrlBuilderImpl` et `StalkerStreamUrlBuilder` existent pour la construction de la source vidéo ; :contentReference[oaicite:56]{index=56}
- `HomeFeedRepositoryImpl` dépend de `IptvCatalogReader` ; :contentReference[oaicite:57]{index=57}

La formulation la plus rigoureuse est donc :
- `home`, les détails contenus et le player dépendent du sous-système IPTV ;
- le degré exact de filtrage et d’enrichissement doit être qualifié plus finement si nécessaire.

### 5. Flux secondaires / variantes
- **Xtream vs Stalker** : les use cases d’ajout et les repositories sont séparés. Stalker passe explicitement par un `handshake` puis un `getProfile`. :contentReference[oaicite:58]{index=58}
- **Settings vs Welcome** : le snapshot confirme deux points d’entrée UI distincts. :contentReference[oaicite:59]{index=59} :contentReference[oaicite:60]{index=60}
- **Hydratation depuis Supabase au bootstrap** : si les comptes locaux sont absents, le bootstrap peut tenter une hydratation locale à partir de Supabase, avec déchiffrement via `IptvCredentialsEdgeService`. :contentReference[oaicite:61]{index=61}
- **Performance profile** : des timings spécifiques existent (`iptvInitialSyncDelay`, `iptvConnectSyncDelay`), mais un mode “Stalker simplifié” n’est pas confirmé par les extraits vérifiés. :contentReference[oaicite:62]{index=62}

### 6. Dépendances transverses
- **startup** : le bootstrap IPTV et le démarrage de `XtreamSyncService` sont liés au lancement applicatif. :contentReference[oaicite:63]{index=63}
- **settings** : l’administration IPTV vit largement dans `features/settings`. :contentReference[oaicite:64]{index=64}
- **welcome/bootstrap** : les routes et pages `welcome/*` participent à l’ajout/sélection initiale. :contentReference[oaicite:65]{index=65}
- **profile** : la sélection de source et certaines préférences sont croisées avec le profil courant ; le détail exact du chiffrement par profil reste à vérifier. :contentReference[oaicite:66]{index=66} :contentReference[oaicite:67]{index=67}
- **security/credentials** : `CredentialsVault` et `IptvCredentialsEdgeService` sont centraux. :contentReference[oaicite:68]{index=68}
- **sync utilisateur globale** : la sync IPTV apparaît aussi dans la sync transverse utilisateur. :contentReference[oaicite:69]{index=69}

### 7. Problèmes structurels observés
- logique IPTV dispersée entre `features/iptv`, `features/settings`, `core/storage`, `core/preferences`, `core/state`, startup et sync globale ; :contentReference[oaicite:70]{index=70} :contentReference[oaicite:71]{index=71}
- sélection active partagée entre préférences et état applicatif ; :contentReference[oaicite:72]{index=72}
- consommation IPTV répartie entre home, détails et player ; :contentReference[oaicite:73]{index=73} :contentReference[oaicite:74]{index=74}
- frontières parfois floues entre administration UI, persistance locale, sync cloud et résolution de contenu. :contentReference[oaicite:75]{index=75}

### 8. Carte synthétique du flux
```text
UI d’ajout (welcome / settings)
  -> validation endpoint + credentials / MAC
  -> repository Xtream ou Stalker
  -> persistance locale (repository + stores + vault)
  -> sélection active (preferences + app state)
  -> refresh / background sync / bootstrap sync
  -> lecture du catalogue via IptvCatalogReader
  -> lookup / stream URL builders
  -> home / details / player
```

### 9. Conclusion

La structure générale du résultat initial était bonne, mais plusieurs détails étaient formulés comme certains alors qu’ils ne sont que probables.
La version corrigée montre que le snapshot prouve bien :

* deux types de source ;
* un ajout via `welcome` et `settings` ;
* une activation locale ;
* une sélection active ;
* une persistance locale + sécurisée ;
* une sync / hydratation partiellement cloud ;
* une consommation par home/détails/player.   

En revanche, les détails fins de chiffrement, certains noms de tables exacts, et quelques comportements précis de filtrage doivent rester marqués comme **à vérifier**.

