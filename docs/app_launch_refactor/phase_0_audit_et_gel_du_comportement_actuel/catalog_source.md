# Cartographie catalogue et source

## Synthese

Le chemin catalogue du lancement est pilote par `AppLaunchOrchestrator` pendant
la phase `preloadCompleteHome`.

La readiness catalogue utilise deux niveaux :

- `CatalogSnapshotReader`, qui lit uniquement le stockage local normalise
  `IptvLocalRepository` ;
- `ResolveCatalogReadiness`, qui transforme le snapshot local et le resultat
  eventuel d'un refresh bloquant en `HomeReady`, `HomePartial` ou
  `SourceRecoveryRequired`.

Point important : le `CatalogSnapshotReader` ne lit pas les caches
`XtreamCacheDataSource` / `StalkerCacheDataSource`. Pour le boot, le snapshot
utile est donc la presence de playlists et d'items locaux. Les snapshots caches
persistes par les repositories servent de metadata provider, mais la decision
Home depend de `getPlaylists()` et `hasAnyPlaylistItems()`.

## Chemin critique observe

```text
preloadCompleteHome
  -> selectedSourceId obligatoire
  -> CatalogSnapshotReader.readForSource(reason=launch_initial)
  -> ResolveCatalogReadiness(snapshot, refreshOutcome=notRun)
  -> SourceRecoveryRequired(catalogSnapshotMissing ou catalogEmpty)
  -> _ensureIptvCatalogReadyForLaunch()
  -> _ensureIptvCatalogReady(reason=launch_attempt_n)
  -> RefreshXtreamCatalog / RefreshStalkerCatalog
  -> repository.refreshCatalog()
  -> IptvLocalRepository.savePlaylists()
  -> IptvLocalRepository.upsertPlaylistSettingsBatch()
  -> cache.saveSnapshot()
  -> CatalogSnapshotReader.readForSource(reason=launch_after_blocking_refresh)
  -> ResolveCatalogReadiness(snapshot, refreshOutcome=succeeded)
  -> HomePartial(catalogSnapshotCached) ou SourceRecoveryRequired
  -> preload Home
  -> preload library
  -> home
```

Le chemin `catalog_snapshot_missing -> refresh -> cached -> home` est donc
documente : apres un refresh reussi, le reader relit les playlists/items locaux
et retourne actuellement `CatalogMode.cached`, pas `fresh`.

## Table des conditions catalogue

| condition catalogue | detection actuelle | action actuelle | log actuel | etat cible probable | risque |
| --- | --- | --- | --- | --- | --- |
| Aucune source active | `_appStateController.activeIptvSourceIds` vide dans `_ensureIptvCatalogReady`. | Skip refresh, retourne `catalogReady=false`. Le caller convertit en `iptvEmptyData`, puis `catalogEmpty`. | `iptv_context detail=no_active_sources`, `iptv_sync_decision action=skip detail=no_active_sources`. | Ecran selection/ajout source. | La cause "aucune source active" est perdue derriere `catalogEmpty`. |
| Source active absente du stockage local | `missingActiveIds = activeIds.difference(knownSourceIds)` apres lecture Xtream/Stalker locaux. | Continue quand meme les controles sur `activeIds`. | `active_sources_missing=... knownSourceIds=...`. | Ecran selection source avec message source indisponible localement. | Peut finir en catalogue vide au lieu d'un etat source introuvable. |
| Snapshot local present avec playlists et items | `CatalogSnapshotReader.getPlaylists(itemLimit: 0)` non vide + `hasAnyPlaylistItems(accountIds: {sourceId})` vrai. | Retourne `CatalogMode.cached`; `ResolveCatalogReadiness` produit `HomePartial(openHomeCached,resyncSource)`. | `catalog_snapshot code=catalog_snapshot_cached mode=cached exists=true hasPlaylists=true hasItems=true`. | Home possible avec indicateur "catalogue local". | `fresh` et `stale` existent dans les contrats mais ne sont pas produits par ce reader. |
| Playlists absentes pour la source selectionnee | `CatalogSnapshotReader` voit `playlists.isEmpty`. | Retourne `CatalogMode.missing`; l'orchestrateur lance un refresh bloquant. | `catalog_snapshot code=catalog_snapshot_missing mode=missing exists=false hasPlaylists=false hasItems=false`. | Ecran chargement catalogue source. | L'UI reste sur le splash/preload generique pendant l'operation. |
| Playlists presentes sans items | `CatalogSnapshotReader` voit `hasItems=false`. `_ensureIptvCatalogReady` logge aussi `missing_playlist_items`. | Retourne `CatalogMode.empty`; l'orchestrateur lance un refresh bloquant. | `catalog_snapshot code=catalog_empty mode=empty`, puis `iptv_context detail=missing_playlist_items`. | Ecran chargement catalogue avec etat "contenu local incomplet". | Le cas est distinguable dans les logs, mais pas dans une phase UI dediee. |
| Refresh necessaire | Dans `_ensureIptvCatalogReady`, playlists absentes ou aucun item local. | Log decision `refresh_needed`, puis refresh toutes les sources actives connues. | `iptv_sync_decision action=run detail=refresh_needed`. | Ecran chargement source/catalogue avec progression simple. | Le refresh porte sur `activeIds`, pas seulement `selectedSourceId`; le libelle UI devra rester general. |
| Refresh Xtream reussi | `RefreshXtreamCatalog(id)` retourne `Ok(XtreamCatalogSnapshot)`. | `refreshed=true`; apres boucle, verification `hasAnyPlaylistItems`. | `refresh_xtream result=success source=... movies=... series=...`. | Passage vers Home si des items existent. | Le succes provider seul ne suffit pas; si les items locaux restent absents, le boot bascule en catalogue vide. |
| Refresh Stalker reussi | `RefreshStalkerCatalog(id)` retourne `Ok(StalkerCatalogSnapshot)`. | `refreshed=true`; apres boucle, verification `hasAnyPlaylistItems`. | Seulement `debugPrint` en debug: `refresh_stalker success` et counts. | Passage vers Home si des items existent. | Pas de log startup structure comme Xtream; diagnostic moins exploitable. |
| Refresh timeout / reseau Xtream | `_mapIptvFailureToLaunchStep` mappe `TimeoutFailure`, `ConnectionFailure`, `BadCertificateFailure` et certains `SourceProbeErrorKind` vers `iptvNetworkTimeout`. Timeout global de 20s dans `_ensureIptvCatalogReadyForLaunch`. | Converti en `CatalogRefreshOutcome.timedOut`, puis `SourceRecoveryRequired(catalogSyncTimeout, retry, chooseSource)`. | `refresh_xtream result=failure ...`, puis `catalog_readiness result=recovery_required code=catalog_sync_timeout`. | Ecran recovery timeout avec retry / choisir source. | Le timeout global n'indique pas quelle requete provider a bloque. |
| Provider error Xtream | `_mapIptvFailureToLaunchStep` mappe les autres failures vers `iptvProviderError`. | Converti en `CatalogRefreshOutcome.providerError`, puis `SourceRecoveryRequired(catalogProviderError, retry, chooseSource)`. | `refresh_xtream result=failure ...`, puis `catalog_readiness ... code=catalog_provider_error`. | Ecran recovery provider. | Les erreurs auth invalides Xtream sont actuellement groupees providerError si elles arrivent sous `XtreamRouteExecutionFailure`. |
| Credentials invalid | `CatalogRefreshOutcome.credentialsInvalid` existe dans `ResolveCatalogReadiness`. | Aucun mapping direct observe depuis `_catalogRefreshOutcomeForLaunchError`. | Aucun log startup specifique observe pour `catalog_credentials_invalid` dans ce chemin. | Ecran reconnexion source. | Contrat pret mais emission effective non confirmee dans le boot actuel. |
| Refresh reussi mais catalogue vide | `_ensureIptvCatalogReadyForLaunch` jette `iptvEmptyData` si `catalogReady=false`; `ResolveCatalogReadiness` mappe `succeeded` ou `empty` vers `catalogEmpty` quand le snapshot reste non ouvrable. | Destination `welcomeSources` avec actions `resyncSource, chooseSource`. | `iptv_sync_decision detail=refresh_failed`, puis `catalog_readiness ... code=catalog_empty`. | Ecran catalogue vide avec resync / choisir source. | Peut masquer des erreurs Stalker avalees ou une source active manquante. |
| Snapshot local indisponible | `CatalogSnapshotReader` catch toute exception et retourne `CatalogMode.unavailable`. | Sans refresh outcome, `SourceRecoveryRequired(catalogSnapshotUnavailable, retry, exportLogs)`. | `catalog_snapshot code=catalog_snapshot_unavailable mode=unavailable`. | Ecran erreur stockage local avec retry / export logs. | Le catch masque l'exception source; il faudra conserver le log technique ailleurs. |
| Home partiel catalogue local | Snapshot ouvrable en `cached` ou `stale`. | Home reste atteignable avec degradation notice via `HomePartial`. | Telemetrie `catalog_minimal_ready result=success catalogMode=cached/stale`. | Home avec etat non bloquant. | L'utilisateur ne voit pas forcement que Home vient d'un catalogue local/cache. |

## Persistance apres refresh

### Xtream

`RefreshXtreamCatalog` appelle `IptvRepository.refreshCatalog(accountId)`.
Dans `IptvRepositoryImpl.refreshCatalog` :

- `_refreshAccountAuthInfo()` met a jour le compte local via
  `IptvLocalRepository.saveAccount()` ;
- `_fetchRemoteData()` charge categories, films et series ;
- `_buildAndSavePlaylists()` construit les playlists et appelle
  `IptvLocalRepository.savePlaylists()` ;
- `_syncPlaylistSettings()` appelle `upsertPlaylistSettingsBatch()` puis
  `deletePlaylistSettingsNotIn()` ;
- `_createAndStoreSnapshot()` persiste `XtreamCatalogSnapshot` via
  `XtreamCacheDataSource.saveSnapshot()`.

En mode low resources, les playlists sont sauvees par chunks via
`_savePlaylistsChunked()`, puis le snapshot metadata est persiste par
`_createAndStoreSnapshotFromCounts()`.

### Stalker

`RefreshStalkerCatalog` appelle `StalkerRepository.refreshCatalog(accountId)`.
Dans `StalkerRepositoryImpl.refreshCatalog` :

- `_refreshAccountAuthInfo()` tente de rafraichir le token et sauvegarde le
  compte local si le profil est autorise ;
- `_fetchRemoteData()` charge categories et streams ;
- `_buildAndSavePlaylists()` construit les playlists et appelle
  `_savePlaylistsChunked()`, qui appelle `IptvLocalRepository.savePlaylists()` ;
- `_syncPlaylistSettings()` persiste les settings ;
- `_createAndStoreSnapshot()` / `_createAndStoreSnapshotFromCounts()` persiste
  `StalkerCatalogSnapshot` via `StalkerCacheDataSource.saveSnapshot()`.

Observation : dans le chemin normal Stalker, `refreshCatalog()` appelle deja
`_buildAndSavePlaylists()` puis `_createAndStoreSnapshot()`, qui reconstruit et
resauvegarde aussi les playlists. Ce doublon est a verifier avant refactor.

## Erreurs source distinguables

| erreur source | signal actuel | mapping actuel |
| --- | --- | --- |
| Aucune source active | `activeIds.isEmpty`, log `no_active_sources`. | Devient indirectement `catalogEmpty` dans le chemin catalogue. |
| Source active inconnue localement | `missingActiveIds` non vide. | Log seulement, puis le refresh continue sur les sources connues. |
| Snapshot absent | `CatalogMode.missing`. | Refresh bloquant, puis recovery `catalogSnapshotMissing` si non resolu. |
| Snapshot sans items | `CatalogMode.empty` ou `missing_playlist_items`. | Refresh bloquant, puis `catalogEmpty` si non resolu. |
| Timeout reseau | `AppLaunchErrorCode.iptvNetworkTimeout`. | `catalogSyncTimeout`. |
| Provider error | `AppLaunchErrorCode.iptvProviderError`. | `catalogProviderError`. |
| Credentials invalid | `CatalogRefreshOutcome.credentialsInvalid` existe. | Pas de chemin d'emission direct observe dans `_catalogRefreshOutcomeForLaunchError`. |
| Stockage local indisponible | `CatalogMode.unavailable`. | `catalogSnapshotUnavailable`. |

## Points ou l'UI reste opaque

- Le refresh catalogue bloquant se passe dans la phase
  `preloadCompleteHome`. Aucun etat de phase dedie ne distingue "lecture
  snapshot", "refresh source", "verification apres refresh" et "preload Home".
- Les retry `_runWithRetry(actionName: iptv_preload)` exposent des messages
  techniques potentiels plutot qu'une progression UX catalogue.
- Les erreurs `no_active_sources` et `active_sources_missing` sont visibles dans
  les logs, mais peuvent etre aplaties en `catalogEmpty` cote decision UI.
- Stalker ne produit pas de log startup structure pour success/failure comme
  Xtream dans `_ensureIptvCatalogReady`.
- Les erreurs Stalker dans le `fold(err:)` sont seulement affichees en debug et
  ne jettent pas de `_LaunchStepException`. Si aucun item n'est disponible
  ensuite, le boot conclut plutot a un catalogue vide.
- Le reader catalogue retourne `cached` pour tout snapshot local ouvrable. Les
  modes `fresh` et `stale` ne sont pas derives de l'age du snapshot dans ce
  chemin.

## Implications pour les phases suivantes

- Conserver `CatalogSnapshotReader` comme lecture locale pure.
- Conserver `ResolveCatalogReadiness` comme decision pure.
- Ajouter un mapping UI explicite entre `CatalogMode` /
  `CatalogRefreshOutcome` / `SourceRecoveryRequired` et les ecrans Figma.
- Introduire des etats UI dedies pour le refresh catalogue bloquant sans
  dupliquer les reason codes.
- Clarifier le mapping credentials invalid et les erreurs Stalker avant de
  construire les ecrans recovery.
