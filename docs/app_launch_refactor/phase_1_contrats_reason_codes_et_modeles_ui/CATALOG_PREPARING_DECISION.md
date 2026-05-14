# Decision preparation catalogue

## Decision

`catalogPreparing` doit devenir un etat runtime explicite et un etat UI derive.

Decision retenue :

- ajouter une phase runtime `AppLaunchPhase.catalogPreparing` ou equivalent ;
- exposer un `BootScreenModel` de type chargement catalogue quand cette phase
  est active ;
- ajouter un reason code log-safe `catalog_preparing` si la phase doit etre
  tracee dans les logs ou la telemetrie ;
- garder les reason codes de detection et de sortie existants :
  `catalog_snapshot_missing`, `catalog_empty`,
  `catalog_snapshot_unavailable`, `catalog_sync_timeout`,
  `catalog_provider_error`, `catalog_credentials_invalid`.

Raison : l'etat est aujourd'hui cache dans `preloadCompleteHome`, alors qu'il
peut durer longtemps pendant le refresh IPTV bloquant. Une simple projection UI
depuis `preloadCompleteHome` serait trop ambigue, car la meme phase couvre aussi
la lecture snapshot, le preload Home, le preload library et l'ouverture Home.

## Point exact dans l'orchestrateur

Dans `AppLaunchOrchestrator`, le bloc actuel est :

```text
step = 'preload_complete_home'
_setPhase(AppLaunchPhase.preloadCompleteHome)
_readCatalogSnapshotForLaunch(reason: 'launch_initial')
ResolveCatalogReadiness(snapshot)
if SourceRecoveryRequired:
  _ensureIptvCatalogReadyForLaunch()
  _readCatalogSnapshotForLaunch(reason: 'launch_after_blocking_refresh')
  ResolveCatalogReadiness(snapshot, refreshOutcome)
```

`catalogPreparing` commence apres la premiere resolution
`ResolveCatalogReadiness` quand le resultat est `SourceRecoveryRequired` et
avant l'appel a `_ensureIptvCatalogReadyForLaunch()`.

`catalogPreparing` se termine apres la seconde lecture snapshot et la seconde
resolution `ResolveCatalogReadiness`.

Sorties possibles :

- snapshot devenu ouvrable : retour vers l'etat d'ouverture Home ;
- snapshot toujours non ouvrable : recovery source avant Home ;
- exception critique non mappee : failure technique.

## Table de transitions

| transition | signal code | phase/runtime | reason code | ecran UI | destination |
| --- | --- | --- | --- | --- | --- |
| Entree preload Home | `step=preload_complete_home` | `AppLaunchPhase.preloadCompleteHome` | `preload_complete_home` ou reason existant de stage | `opening_home` ou chargement simple temporaire | Aucune destination immediate. |
| Lecture snapshot initiale ouvrable | `catalog_snapshot mode=fresh/cached/stale` | Reste `preloadCompleteHome` puis preload Home/library. | `catalog_snapshot_fresh`, `catalog_snapshot_cached` ou `catalog_snapshot_stale` | `opening_home` bref, pas recovery. | `home` apres preload. |
| Lecture snapshot initiale non ouvrable | `catalog_snapshot mode=missing/empty/unavailable` | Transition vers `AppLaunchPhase.catalogPreparing`. | Detection : `catalog_snapshot_missing`, `catalog_empty` ou `catalog_snapshot_unavailable`. Etat courant : `catalog_preparing`. | `catalog_preparing` avec texte bas d'ecran. | Aucune destination immediate. |
| Refresh bloquant demarre | `_ensureIptvCatalogReadyForLaunch()` | `AppLaunchPhase.catalogPreparing`. | `catalog_preparing`. | `catalog_preparing`. | Aucune destination immediate. |
| Refresh reussi puis snapshot ouvrable | `launch_after_blocking_refresh` + `CatalogMode.cached/fresh/stale` | Sortie vers `preloadCompleteHome` ou sous-etat `openingHome`. | `catalog_snapshot_cached`, `catalog_snapshot_fresh` ou `catalog_snapshot_stale`. | `opening_home` bref. | `home` apres preload. |
| Refresh reussi mais catalogue vide | `CatalogRefreshOutcome.succeeded/empty` + snapshot non ouvrable | Sortie de `catalogPreparing`. | `catalog_empty`. | Recovery source `catalog_empty`. | `welcomeSources` aujourd'hui, cible a confirmer avec action `resyncSource` / `chooseSource`. |
| Refresh timeout | `_LaunchStepException.iptvNetworkTimeout` | Sortie de `catalogPreparing`. | `catalog_sync_timeout`. | Recovery source `source_timeout`. | `welcomeSources` aujourd'hui, cible recovery/source. |
| Refresh provider error | `_LaunchStepException.iptvProviderError` | Sortie de `catalogPreparing`. | `catalog_provider_error`. | Recovery source `provider_error`. | `welcomeSources` aujourd'hui, cible recovery/source. |
| Refresh credentials invalid | Outcome cible `CatalogRefreshOutcome.credentialsInvalid` | Sortie de `catalogPreparing`. | `catalog_credentials_invalid`. | Recovery source `credentials_invalid`. | Cible action `reconnectSource`; emission runtime a verifier en etape 5. |
| Recovery source confirmee | `catalog_readiness result=recovery_required` | `AppLaunchPhase.done` via `completeSuccess`. | Reason code de recovery source. | Ecran recovery source. | `welcomeSources` actuellement. |
| Preload Home apres catalogue pret | `catalog_minimal_ready result=success` | `AppLaunchPhase.preloadCompleteHome` ou futur `openingHome`. | Reason code readiness du snapshot. | `opening_home`. | `home` apres preload Home/library. |

## Reason codes

### A conserver

- `catalog_snapshot_fresh`
- `catalog_snapshot_cached`
- `catalog_snapshot_stale`
- `catalog_snapshot_missing`
- `catalog_snapshot_unavailable`
- `catalog_empty`
- `catalog_sync_timeout`
- `catalog_provider_error`
- `catalog_credentials_invalid`

### A ajouter ou confirmer

- `catalog_preparing`

Ce code ne represente pas une erreur. Il represente une operation en cours :
preparer un catalogue local exploitable a partir d'une source deja selectionnee.

## Logs attendus

Les logs doivent rester techniques et log-safe. Ils ne doivent pas contenir de
texte utilisateur final.

| moment | log attendu | niveau | champs |
| --- | --- | --- | --- |
| Detection snapshot non ouvrable | `[Startup] action=catalog_snapshot result=success` | info | `code`, `mode`, `exists`, `hasPlaylists`, `hasItems`, `reason=launch_initial`. |
| Entree preparation | `[Startup] action=catalog_preparing result=started` | info | `code=catalog_preparing`, `triggerReason`, `catalogMode`, `runId` si disponible. |
| Refresh termine | `[Startup] action=catalog_preparing result=completed` | info | `refreshOutcome`, `refreshed`, `elapsedMs`, `catalogModeAfterRefresh`. |
| Refresh impossible | `[Startup] action=catalog_preparing result=failed` | warn | `code=catalog_sync_timeout` ou `catalog_provider_error` ou `catalog_credentials_invalid` ou `catalog_empty`. |
| Recovery source | `[Startup] action=catalog_readiness result=recovery_required` | warn | `code`, `mode`, `refreshed`, `actions`. |
| Catalogue minimal pret | `catalog_minimal_ready result=success` | telemetry | `reasonCode`, `catalogMode`, `refreshed`. |

Les champs interdits cote UI :

- reason code brut affiche comme texte ;
- message exception provider ;
- identifiants source ou credentials ;
- URL provider.

## UI attendue

`catalogPreparing` doit produire un ecran de chargement catalogue non
interactif :

- logo centre ;
- texte court en bas d'ecran, hors du flux centre ;
- aucune action principale ;
- aucun focus initial ;
- reason code conserve seulement pour logs/tests.

Le texte exact sera defini dans le mapping UI, mais il doit rester utilisateur,
court et non technique.

## Impact sur les tests

Tests a ajouter ou adapter :

| test | assertion critique |
| --- | --- |
| `boot_ui_state_mapper_test.dart` | `AppLaunchPhase.catalogPreparing` produit un `BootScreenModel` de type chargement catalogue, non interactif. |
| `app_launch_orchestrator_catalog_preparing_test.dart` ou test existant adapte | Premier run sans snapshot emet `catalog_preparing` avant refresh bloquant. |
| `resolve_catalog_readiness_test.dart` | Reste source de verite pour les sorties `SourceRecoveryRequired` et snapshots ouvrables. |
| `boot_no_generic_messages_test.dart` | `catalog_preparing` n'affiche pas le reason code brut. |

## Consequences pour la phase 2

- Mettre a jour les transitions autorisees de `AppLaunchPhase`.
- Exposer la phase via `AppLaunchState` avant le refresh bloquant.
- Revenir vers `preloadCompleteHome` ou un futur etat `openingHome` apres un
  refresh reussi.
- S'assurer que `LaunchRedirectGuard` ne redirige pas pendant
  `catalogPreparing` tant qu'aucune destination finale n'est decidee.

## Definition de fini - etape 4

- La preparation catalogue n'est plus implicite.
- Le premier run sans snapshot peut afficher un etat dedie.
- Le second run avec snapshot peut eviter cet etat bloquant.
