# Phase 3 - Etape 2 - Contrat de readiness catalogue

## Objectif

Figer les etats catalogue que l'orchestrateur peut consommer sans deviner.

Cette etape stabilise le vocabulaire domaine entre lecture snapshot, refresh
bloquant, recovery source et ouverture Home.

## Decision principale

Le contrat distingue maintenant trois familles de resultat :

- `HomeReady` / `HomePartial` : Home peut s'ouvrir car le snapshot est
  exploitable.
- `CatalogPreparationRequired` : Home ne peut pas s'ouvrir encore, mais la
  prochaine action technique est un refresh bloquant borne.
- `SourceRecoveryRequired` : Home ne doit pas s'ouvrir et l'utilisateur doit
  voir une recovery source.

Cette separation evite d'utiliser `SourceRecoveryRequired` comme signal interne
de refresh. Un snapshot absent n'est plus une recovery utilisateur avant que le
refresh ait ete tente.

## Sens des reason codes critiques

### `catalog_snapshot_cached`

```text
cache present | cache exploitable | Home autorisee | pas de refresh bloquant
```

Un snapshot cached contient des playlists et au moins un item jouable. Il peut
ouvrir Home rapidement. Une sync de fond peut etre proposee ou lancee, mais elle
ne bloque pas Home.

### `catalog_snapshot_missing`

```text
cache absent | Home non autorisee | preparation catalogue visible | refresh borne
```

Un snapshot missing signifie que la source selectionnee n'a pas de snapshot
local exploitable. L'etat utilisateur cible est `catalog_preparing`, pas une
recovery immediate. La recovery n'apparait qu'apres echec du refresh ou
catalogue toujours inexploitable.

## Table des etats

```text
etat catalogue | contrat existant | ajout requis | reason code | destination | test
snapshot exploitable fresh | CatalogMode.fresh + HomeReady | aucun | catalog_snapshot_fresh | home | catalog_snapshot_test.dart, resolve_catalog_readiness_test.dart
snapshot exploitable cached | CatalogMode.cached + HomePartial | clarification documentee : Home autorisee sans refresh bloquant | catalog_snapshot_cached | home | catalog_snapshot_test.dart, resolve_catalog_readiness_test.dart
snapshot exploitable stale | CatalogMode.stale + HomePartial | aucun contrat ; production reader a traiter plus tard si freshness disponible | catalog_snapshot_stale | home | catalog_snapshot_test.dart, resolve_catalog_readiness_test.dart
snapshot absent | CatalogMode.missing | ajout de CatalogPreparationRequired | catalog_snapshot_missing | catalog_preparing puis home ou source recovery | resolve_catalog_readiness_test.dart
snapshot vide avant refresh | CatalogMode.empty + SourceRecoveryRequired | aucun pour cette etape ; reste recovery catalogue vide | catalog_empty | welcomeSources/source recovery | resolve_catalog_readiness_test.dart
snapshot indisponible | CatalogMode.unavailable + SourceRecoveryRequired | aucun pour cette etape | catalog_snapshot_unavailable | welcomeSources/source recovery | resolve_catalog_readiness_test.dart
refresh requis | CatalogPreparationRequired | ajoute dans HomeReadiness | catalog_snapshot_missing | reste sur phase preloadCompleteHome/catalog_preparing pendant refresh | resolve_catalog_readiness_test.dart, app_launch_orchestrator_local_mode_test.dart
refresh success avec snapshot exploitable | CatalogRefreshOutcome.succeeded + snapshot relu openable | aucun | catalog_snapshot_cached ou catalog_snapshot_fresh/stale selon snapshot | home | app_launch_orchestrator_local_mode_test.dart
refresh success sans contenu utile | CatalogRefreshOutcome.succeeded ou empty + snapshot non openable | aucun | catalog_empty | welcomeSources/source recovery | resolve_catalog_readiness_test.dart, app_launch_orchestrator_local_mode_test.dart
refresh timeout | CatalogRefreshOutcome.timedOut + SourceRecoveryRequired | aucun contrat ; duree a traiter etape 5 | catalog_sync_timeout | welcomeSources/source recovery | resolve_catalog_readiness_test.dart, app_launch_orchestrator_local_mode_test.dart
provider error | CatalogRefreshOutcome.providerError + SourceRecoveryRequired | aucun contrat ; mapping Stalker a traiter etape 6 | catalog_provider_error | welcomeSources/source recovery | resolve_catalog_readiness_test.dart, app_launch_orchestrator_local_mode_test.dart
credentials invalides | CatalogRefreshOutcome.credentialsInvalid + SourceRecoveryRequired | aucun contrat ; emission orchestrateur/provider a traiter etape 6 | catalog_credentials_invalid | welcomeSources/source recovery reconnect | resolve_catalog_readiness_test.dart
catalogue vide | CatalogRefreshOutcome.empty ou succeeded sans snapshot utile | aucun | catalog_empty | welcomeSources/source recovery | resolve_catalog_readiness_test.dart, app_launch_orchestrator_local_mode_test.dart
```

## Changement de code effectue

### Contrat domaine

Ajout dans `lib/src/core/startup/domain/boot_contracts.dart` :

```text
CatalogPreparationRequired extends HomeReadiness
```

Ce contrat represente un catalogue non exploitable dont la suite normale est une
preparation technique bornee, pas une recovery utilisateur.

### Resolver

`ResolveCatalogReadiness` emet maintenant :

```text
CatalogMode.missing + CatalogRefreshOutcome.notRun
-> CatalogPreparationRequired(catalog_snapshot_missing)
```

Les erreurs apres refresh restent des `SourceRecoveryRequired`.

### Orchestrateur

`AppLaunchOrchestrator` lance le refresh bloquant sur
`CatalogPreparationRequired`, puis relit le snapshot et rappelle le resolver
avec le `CatalogRefreshOutcome`.

## Decisions explicites

- `cached`, `fresh` et `stale` sont openable et ne declenchent pas de refresh
  bloquant.
- `missing` avant refresh signifie preparation catalogue.
- `missing` apres refresh success sans contenu utile est converti en
  `catalog_empty` par le couple `refreshOutcome + snapshot relu`.
- `empty` avant refresh reste une recovery `catalog_empty` pour cette etape.
- `unavailable` reste une recovery de lecture locale/source, pas une
  preparation.
- `credentialsInvalid` est conserve dans le contrat, mais son emission runtime
  reste a traiter en etape 6.

## Risques restants

- Le timeout bloquant reste de 20 secondes par tentative avec 3 tentatives.
- Le mapping credentials invalides n'est pas encore relie aux failures provider.
- Le chemin Stalker error reste a corriger dans le mapping refresh.
- `CatalogSnapshotReader` ne produit toujours pas `CatalogMode.stale`.
- Les logs de preparation restent perfectibles et seront traites en etape 9.

## Definition de fini de l'etape 2

- [x] Les etats catalogue critiques sont representes par un contrat stable.
- [x] `cached` et `missing` ne peuvent plus etre confondus.
- [x] Les erreurs source ont des sorties dediees avant Home.
