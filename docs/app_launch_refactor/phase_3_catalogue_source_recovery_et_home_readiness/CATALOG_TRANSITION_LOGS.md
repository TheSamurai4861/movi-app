# Phase 3 - Etape 9 - Logs de transition catalogue

## Objectif

Rendre le chemin catalogue lisible pendant un run sans exposer de secrets source
ni de contenu provider brut.

## Evenements normalises

```text
evenement | declencheur | champs | exemple log-safe | test
catalog_snapshot_checked | chaque lecture snapshot orchestrateur | runId, sourceKey, phase, reasonCode, catalogMode, reason, exists, hasPlaylists, hasItems | event=catalog_snapshot_checked result=success sourceKey=12abc reasonCode=catalog_snapshot_missing | opens home when blocking refresh creates the missing local snapshot
catalog_snapshot_cached | lecture d'un snapshot cached exploitable | runId, sourceKey, phase, reasonCode, catalogMode, destination | event=catalog_snapshot_cached result=success destination=home | opens home when blocking refresh creates the missing local snapshot
catalog_snapshot_missing | lecture d'un snapshot absent | runId, sourceKey, phase, reasonCode, catalogMode | event=catalog_snapshot_missing result=missing reasonCode=catalog_snapshot_missing | opens home when blocking refresh creates the missing local snapshot
catalog_preparation_started | debut du refresh bloquant borne | runId, sourceKey, phase, reasonCode, catalogMode | event=catalog_preparation_started result=start phase=preloadCompleteHome | exposes catalog preparing while first run waits for missing snapshot refresh
catalog_preparation_completed | refresh + relecture ouvrent un snapshot exploitable | runId, sourceKey, phase, reasonCode, catalogMode, durationMs, destination | event=catalog_preparation_completed result=success destination=home durationMs=42 | opens home when blocking refresh creates the missing local snapshot
catalog_preparation_failed | refresh + relecture finissent en source recovery | runId, sourceKey, phase, reasonCode, catalogMode, durationMs, destination | event=catalog_preparation_failed result=failure destination=welcomeSources reasonCode=catalog_sync_timeout | routes to source recovery when blocking refresh exceeds its timeout
```

## Champs exclus

Les nouveaux logs catalogue utilisent `sourceKey` au lieu du `sourceId` brut.
Ils n'incluent pas :

- url complete ;
- username ;
- password ;
- token ;
- contenu brut provider ;
- alias utilisateur de la source.

Les anciens logs de debug startup peuvent encore contenir des identifiants
techniques locaux. L'etape 9 ne les supprime pas pour eviter de changer le
comportement de diagnostic existant ; elle ajoute un chemin catalogue log-safe
dedie pour les transitions critiques.

## Lecture d'un run

Premier run sans snapshot puis refresh success :

```text
catalog_snapshot_checked -> catalog_snapshot_missing
catalog_preparation_started
catalog_snapshot_checked -> catalog_snapshot_cached
catalog_snapshot_cached
catalog_preparation_completed -> destination=home
```

Second run avec snapshot cached :

```text
catalog_snapshot_checked -> catalog_snapshot_cached
catalog_snapshot_cached -> destination=home
```

Refresh timeout :

```text
catalog_snapshot_checked -> catalog_snapshot_missing
catalog_preparation_started
catalog_snapshot_checked -> catalog_snapshot_missing
catalog_snapshot_missing
catalog_preparation_failed -> reasonCode=catalog_sync_timeout destination=welcomeSources
```

## Definition de fini de l'etape 9

- [x] Un run sans snapshot se lit dans les logs.
- [x] Un second run cached se distingue d'un refresh bloquant.
- [x] Les erreurs source ont un reason code stable.
- [x] Les logs catalogue ajoutes utilisent une cle source log-safe.
