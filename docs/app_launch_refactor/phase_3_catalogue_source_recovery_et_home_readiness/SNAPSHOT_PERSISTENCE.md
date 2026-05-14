# Phase 3 - Etape 4 - Persistance du snapshot apres refresh

## Objectif

Garantir qu'un refresh reussi produit un snapshot exploitable pour le run
suivant.

Dans le code actuel, le critere utilise par `CatalogSnapshotReader` n'est pas le
snapshot metadata `XtreamCatalogSnapshot` ou `StalkerCatalogSnapshot`. Le reader
ouvre Home uniquement si les playlists existent et si au moins un item jouable
est present dans `playlistItems`.

## Lecture cible

`CatalogSnapshotReader.readForSource` lit :

```text
getPlaylists(sourceId, itemLimit: 0)
hasAnyPlaylistItems(accountIds: {sourceId})
```

Donc un refresh persiste un snapshot exploitable seulement si :

- au moins une playlist est sauvegardee pour la source ;
- au moins un item est sauvegarde dans les playlists de cette source ;
- la sauvegarde est terminee avant le retour success du refresh ;
- la relecture locale voit les memes `accountId`.

Le cache metadata `XtreamCacheDataSource.saveSnapshot` ou
`StalkerCacheDataSource.saveSnapshot` est utile pour l'historique de sync, mais
ne suffit pas a ouvrir Home.

## Table de verification

```text
refresh | ecriture snapshot | lecture second run | failure possible | test
Xtream normal | _buildAndSavePlaylists -> _local.savePlaylists, puis _createAndStoreSnapshot -> _cache.saveSnapshot | CatalogSnapshotReader relit playlists + playlistItems via IptvLocalRepository | saveSnapshot metadata peut reussir alors que playlists/items seraient vides ; Home depend des items, pas du metadata | app_launch_orchestrator_local_mode_test.dart
Xtream low resources | _savePlaylistsChunked movies/series, _syncPlaylistSettings, puis _createAndStoreSnapshotFromCounts | CatalogSnapshotReader relit les chunks sauvegardes | si les streams sont vides mais les counts viennent des categories/metadata, le reader restera empty car aucun item | non couvert directement par Phase 3
Stalker normal | _createAndStoreSnapshot appelle _buildAndSavePlaylists, _syncPlaylistSettings, puis _createAndStoreSnapshotFromCounts | CatalogSnapshotReader relit les playlists Stalker stockees comme XtreamPlaylist | le chemin actuel double potentiellement la sauvegarde car refreshCatalog appelle deja _buildAndSavePlaylists avant _createAndStoreSnapshot | non couvert directement par Phase 3
Stalker low resources | _savePlaylistsChunked movies/series, _syncPlaylistSettings, puis _createAndStoreSnapshotFromCounts | CatalogSnapshotReader relit les chunks sauvegardes | si token absent ou streams vides, pas de snapshot exploitable pour Home | non couvert directement par Phase 3
Fake orchestrateur Phase 3 | beforeResult sauvegarde une playlist avec item avant Ok refresh | premier run ouvre Home ; second run relit catalog_snapshot_cached sans rappeler refresh | le fake ne valide pas les repositories distants reels, seulement le contrat orchestrateur-reader | test `opens home when blocking refresh creates the missing local snapshot`
```

## Test second run ajoute

Le test `opens home when blocking refresh creates the missing local snapshot`
verifie maintenant :

1. premier run sans snapshot local ;
2. refresh bloquant appele une fois ;
3. le fake refresh sauvegarde une playlist avec item ;
4. Home s'ouvre ;
5. le fake refresh est ensuite configure en erreur ;
6. second run ;
7. Home s'ouvre quand meme ;
8. `RefreshXtreamCatalog` n'est pas rappele ;
9. les logs contiennent `catalog_snapshot_cached`.

Ce test encode l'invariant Phase 3 : un refresh success doit laisser un cache
local que le run suivant peut exploiter sans nouveau blocage long.

## Points verifies dans le code

- `IptvRepositoryImpl.refreshCatalog` sauvegarde les playlists avant de
  retourner le snapshot metadata.
- `IptvRepositoryImpl._refreshCatalogLowResources` sauvegarde les playlists par
  chunks avant de creer le snapshot metadata.
- `StalkerRepositoryImpl._createAndStoreSnapshot` sauvegarde les playlists et
  settings avant le snapshot metadata.
- `IptvPlaylistStore.savePlaylists` remplace la playlist et ses items dans la
  meme transaction par playlist.
- `IptvPlaylistQueryStore.hasAnyPlaylistItems` teste directement la table des
  items pour la source.

## Risques restants

- La validation repository reelle n'est pas exhaustive dans cette etape :
  aucun test d'integration remote Xtream/Stalker n'a ete ajoute.
- Le chemin Stalker conserve un risque deja identifie en etape 1 : dans
  l'orchestrateur, un `Err` de `RefreshStalkerCatalog` semble logge sans throw.
- Les modes low resources peuvent produire un snapshot metadata avec counts non
  nuls mais aucune item sauvegarde si les streams reels sont vides ; le reader
  classera alors correctement le catalogue en non exploitable.
- `CatalogSnapshotReader` ne lit pas `lastSyncAt`, donc il ne peut pas encore
  produire `CatalogMode.stale`.

## Definition de fini de l'etape 4

- [x] Un refresh success ne se termine pas tant que le snapshot exploitable n'est
  pas persiste ou que l'echec n'est pas explicite.
- [x] Le second run peut prouver que le cache est reutilise.
- [x] Le chemin success ne depend pas seulement de donnees en memoire.
