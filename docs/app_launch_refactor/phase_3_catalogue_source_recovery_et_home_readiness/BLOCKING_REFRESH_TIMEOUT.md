# Phase 3 - Etape 5 - Timeout du refresh bloquant

## Objectif

Remplacer l'attente opaque par une attente bornee et diagnosable.

Le refresh catalogue bloquant est execute uniquement quand le snapshot local
n'est pas exploitable et que le resolver retourne `CatalogPreparationRequired`.
Un snapshot exploitable reste autoritaire et evite ce chemin.

## Decision

Le timeout de refresh bloquant est maintenant un contrat nomme dans
`AppLaunchOrchestrator` :

```text
catalogBlockingRefreshTimeout = 20 seconds
catalogBlockingRefreshRetryInitialDelay = 300 milliseconds
```

Ces valeurs remplacent la duree inline dans `_ensureIptvCatalogReadyForLaunch`.
Elles sont `@visibleForTesting` pour permettre un test rapide avec un fake qui
ne repond jamais.

## Table de mapping

```text
operation bloquante | timeout | reason code | recovery | action | test
_ensureIptvCatalogReady(reason: launch_attempt_N) | AppLaunchOrchestrator.catalogBlockingRefreshTimeout, 20s par tentative en production | catalog_sync_timeout | La source ne repond pas | retry + chooseSource | routes to source recovery when blocking refresh exceeds its timeout
retry du refresh bloquant | AppLaunchOrchestrator.catalogBlockingRefreshRetryInitialDelay, 300ms puis backoff quadratique | retry_scheduled en telemetry, puis catalog_sync_timeout si toutes les tentatives echouent | reste en preparation pendant les retries, puis source recovery | retry + chooseSource | routes to source recovery when blocking refresh exceeds its timeout
snapshot cached/stale/fresh | aucun refresh bloquant | catalog_snapshot_cached/stale/fresh | Home rapide | openHomeCached/resyncSource pour cached/stale | tests resolver + orchestrateur snapshot-first
```

## Changement de code

Dans `lib/src/core/startup/app_launch_orchestrator.dart` :

- ajout de `catalogBlockingRefreshTimeout` ;
- ajout de `catalogBlockingRefreshRetryInitialDelay` ;
- `_ensureIptvCatalogReadyForLaunch` utilise ces valeurs nommees.

Le timeout continue a mapper vers :

```text
AppLaunchErrorCode.iptvNetworkTimeout
-> CatalogRefreshOutcome.timedOut
-> StartupRecoveryReasonCodes.catalogSyncTimeout
-> SourceRecoveryRequired(retry, chooseSource)
```

## Test ajoute

Le test `routes to source recovery when blocking refresh exceeds its timeout`
configure :

- `catalogBlockingRefreshTimeout = 10 ms` ;
- `catalogBlockingRefreshRetryInitialDelay = 0 ms` ;
- `RefreshXtreamCatalog.beforeResult` avec un `Completer` jamais complete.

Le test verifie :

- destination `BootstrapDestination.welcomeSources` ;
- `RefreshXtreamCatalog` appele 3 fois ;
- Home non prechargee ;
- execution inferieure a 1 seconde ;
- logs contenant `catalog_sync_timeout` ;
- aucune degradation Home partielle.

## Risques restants

- La duree production reste 20 secondes par tentative avec 3 tentatives. Elle
  est explicite et testable, mais la reduction produit du delai total sera une
  decision de l'etape 10 ou d'une decision produit separee.
- Les futures sous-jacentes timeout ne sont pas annulees par `Future.timeout`.
  Le test couvre la sortie utilisateur, pas l'annulation bas niveau des appels
  provider.
- Le mapping credentials invalides et Stalker error reste hors perimetre de
  cette etape et sera traite en etape 6.

## Definition de fini de l'etape 5

- [x] Le refresh bloquant ne peut plus attendre indefiniment ou de facon opaque.
- [x] Le timeout produit une recovery source, pas Home partiel.
- [x] Le test ne ralentit pas la suite automatisee.
