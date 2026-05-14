# Phase 3 - Decisions finales

## Objectif stabilise

Un snapshot absent ne produit plus une attente opaque. Le chemin catalogue est
maintenant explicite :

- snapshot exploitable : Home s'ouvre sans refresh bloquant ;
- snapshot absent : `catalog_preparing` est expose pendant une preparation
  bornee ;
- refresh echoue : source recovery typee ;
- refresh reussi mais catalogue vide : source recovery `catalog_empty` ;
- second run apres refresh success : le snapshot persiste evite un nouveau
  blocage long.

## Decisions catalogue

```text
decision | contrat | effet runtime | preuve
snapshot fresh/cached/stale | HomeReady ou HomePartial openable | Home rapide, sync de fond possible | ResolveCatalogReadiness + orchestrateur cached
snapshot missing avant refresh | CatalogPreparationRequired | ecran catalog_preparing puis refresh bloquant borne | test catalog_preparing
refresh success + snapshot exploitable | HomeReady/HomePartial apres relecture | Home ouverte, snapshot persiste | test refresh creates snapshot + second run
refresh timeout | SourceRecoveryRequired catalog_sync_timeout | welcomeSources, pas Home partiel | tests TimeoutFailure et Future.timeout
provider error | SourceRecoveryRequired catalog_provider_error | welcomeSources, pas Home partiel | tests Xtream et Stalker
credentials invalides | SourceRecoveryRequired catalog_credentials_invalid | reconnecter source, changer de source si alternative locale | tests credentials recovery/actions
catalogue vide | SourceRecoveryRequired catalog_empty | resynchroniser ou changer de source | test refresh leaves catalog empty
```

## Contrats modifies

- `CatalogPreparationRequired` a ete ajoute a `HomeReadiness` pour separer une
  preparation technique normale d'une recovery utilisateur.
- `CatalogMode.missing` avec refresh non lance produit maintenant
  `CatalogPreparationRequired(catalog_snapshot_missing)`.
- `AppLaunchErrorCode.iptvCredentialsInvalid` mappe les erreurs credentials
  vers `CatalogRefreshOutcome.credentialsInvalid`.
- `AppLaunchState.recoveryPlan` transporte les actions recovery catalogue vers
  `BootScreenMapper`.
- `StartupRecoveryMapper` connait `iptvCredentialsInvalid`.

## Refresh bloquant

Le refresh bloquant est borne par des durees nommees et testables :

```text
contrat | valeur production | test
catalogBlockingRefreshTimeout | 20s par tentative | timeout reduit a 10ms
catalogBlockingRefreshRetryInitialDelay | 300ms avant backoff | reduit a Duration.zero
```

Le timeout aboutit a `catalog_sync_timeout`, destination `welcomeSources`, et
ne charge pas Home.

## Actions recovery

```text
reason code | action principale | action secondaire
catalog_sync_timeout | Reessayer | Changer de source
catalog_provider_error | Reessayer | Changer de source
catalog_credentials_invalid | Reconnecter la source | Changer de source seulement si plusieurs sources locales
catalog_empty | Resynchroniser | Changer de source
catalog_preparing | aucune | aucune
```

Le handler cible reste testable via `BootActionPlanner`.

## Logs

Les transitions catalogue disposent maintenant de logs dedies et log-safe :

- `catalog_snapshot_checked` ;
- `catalog_snapshot_cached` ;
- `catalog_snapshot_missing` ;
- `catalog_preparation_started` ;
- `catalog_preparation_completed` ;
- `catalog_preparation_failed`.

Les nouveaux logs utilisent `sourceKey` au lieu du `sourceId` brut. Les anciens
logs debug startup ne sont pas supprimes dans cette phase pour eviter de
modifier les diagnostics existants.

## Tests ajoutes ou mis a jour

Couverture ciblee :

- `resolve_catalog_readiness_test.dart` : decisions catalogue pures ;
- `startup_recovery_mapper_test.dart` : reason codes et actions recovery ;
- `boot_screen_mapper_test.dart` : modele boot et actions visibles ;
- `boot_action_handler_test.dart` : destinations/actions boot ;
- `app_launch_orchestrator_local_mode_test.dart` : refresh success, timeout,
  provider, credentials, empty, cached, second run, Home partial.

Derniere verification executee pour l'etape 10 :

```text
flutter test test/core/startup/resolve_catalog_readiness_test.dart test/core/startup/startup_recovery_mapper_test.dart test/core/startup/boot_screen_mapper_test.dart test/core/startup/boot_action_handler_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart
Resultat : 87 tests OK

flutter analyze lib/src/core/startup/app_launch_orchestrator.dart lib/src/core/startup/domain/resolve_catalog_readiness.dart lib/src/core/startup/domain/startup_recovery_mapper.dart lib/src/core/startup/presentation/boot_screen_mapper.dart test/core/startup/resolve_catalog_readiness_test.dart test/core/startup/startup_recovery_mapper_test.dart test/core/startup/boot_screen_mapper_test.dart test/core/startup/boot_action_handler_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart
Resultat : aucun issue
```

## Validation runtime

Validation manuelle avec source IPTV reelle non executee dans cette phase. Elle
necessite une source et des credentials reels ou un environnement de recette.

Validation deterministe executee par tests avec :

- SQLite local en memoire ;
- repositories locaux reels ;
- refresh Xtream/Stalker controlables ;
- timeouts reduits ;
- lecture du `BootScreenModel` et du `TunnelStateRegistry`.

## Risques restants

### Pour Phase 4

- Les textes et libelles sont encore dans `BootScreenMapper`, pas dans une UI
  finale localisee.
- Les ecrans doivent brancher `BootScreenModel` sans refaire les decisions
  catalogue.
- Le focus TV et les surfaces d'action doivent verifier que `catalog_preparing`
  reste non interactif.

### Pour Phase 7

- La validation avec provider reel reste a faire sur un environnement controle.
- `CatalogMode.stale` existe dans le domaine mais le reader local ne produit pas
  encore de stale base sur une freshness reelle.
- Les anciens logs debug peuvent encore contenir des identifiants techniques ;
  seuls les nouveaux logs catalogue sont log-safe.
- `Future.timeout` borne l'attente utilisateur mais n'annule pas le travail
  sous-jacent du provider.

## Definition de fini Phase 3

- [x] La phase 4 peut brancher l'UI sur des etats catalogue stables.
- [x] La phase 7 peut reprendre les scenarios critiques sans redecouvrir le
      comportement.
- [x] Les incertitudes restantes sont explicites.
