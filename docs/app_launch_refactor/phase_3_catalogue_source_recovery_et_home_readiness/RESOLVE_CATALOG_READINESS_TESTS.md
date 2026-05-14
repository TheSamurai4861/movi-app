# Phase 3 - Etape 3 - Tests `ResolveCatalogReadiness`

## Objectif

Verrouiller la decision catalogue independamment du router et de l'UI.

Le resolver reste pur : il ne lit pas les sources actives, ne lance pas de
refresh, ne navigue pas et ne log pas. Les tests verifient seulement la
projection `CatalogSnapshot + CatalogRefreshOutcome -> HomeReadiness`.

## Perimetre

Inclus :

- snapshot present et exploitable ;
- snapshot absent ;
- snapshot vide ;
- snapshot indisponible ;
- cache stale exploitable ;
- refresh success ;
- refresh timeout ;
- provider error ;
- credentials invalides ;
- catalogue vide apres refresh ;
- priorite du snapshot exploitable sur une erreur de refresh.

Hors perimetre du resolver :

- source active absente ;
- source selectionnee invalide ;
- persistance du snapshot apres refresh ;
- timeout reel du refresh bloquant ;
- navigation router.

Ces cas dependent de `AppLaunchOrchestrator`, des preferences de source ou des
repositories, et sont traites dans les etapes suivantes.

## Table de couverture

```text
test | scenario | entree | resultat attendu | raison metier | fichier
maps a fresh snapshot to HomeReady | snapshot present et pleinement exploitable | CatalogMode.fresh, no refresh | HomeReady catalog_snapshot_fresh | Home peut s'ouvrir sans warning catalogue | test/core/startup/resolve_catalog_readiness_test.dart
maps a cached snapshot to HomePartial with background resync | snapshot present, exploitable, fraicheur inconnue | CatalogMode.cached, no refresh | HomePartial catalog_snapshot_cached + openHomeCached/resyncSource | Home doit s'ouvrir vite ; la sync reste non bloquante | test/core/startup/resolve_catalog_readiness_test.dart
maps a stale snapshot to HomePartial with background resync | snapshot ancien mais exploitable | CatalogMode.stale, no refresh | HomePartial catalog_snapshot_stale + openHomeCached/resyncSource | Un cache stale exploitable vaut mieux qu'une attente bloquante | test/core/startup/resolve_catalog_readiness_test.dart
opens Home from a cached snapshot even when refresh succeeded | refresh reussi puis snapshot relu exploitable | CatalogMode.cached + CatalogRefreshOutcome.succeeded | HomePartial catalog_snapshot_cached | La relecture snapshot est autoritaire apres refresh | test/core/startup/resolve_catalog_readiness_test.dart
maps a missing snapshot to catalog preparation before refresh | snapshot absent avant refresh | CatalogMode.missing, notRun | CatalogPreparationRequired catalog_snapshot_missing | Un cache absent lance une preparation, pas une recovery immediate | test/core/startup/resolve_catalog_readiness_test.dart
maps an empty snapshot before refresh to catalog empty recovery | playlists presentes mais sans item | CatalogMode.empty, notRun | SourceRecoveryRequired catalog_empty | Un catalogue local vide ne doit pas ouvrir Home partiel | test/core/startup/resolve_catalog_readiness_test.dart
maps an unavailable snapshot to retry and export logs | lecture locale impossible | CatalogMode.unavailable, notRun | SourceRecoveryRequired catalog_snapshot_unavailable | Une erreur stockage/source doit etre visible et diagnosticable | test/core/startup/resolve_catalog_readiness_test.dart
maps a refresh timeout without snapshot to source recovery | refresh borne expire sans cache exploitable | CatalogMode.missing + timedOut | SourceRecoveryRequired catalog_sync_timeout + retry/chooseSource | `La source ne repond pas` est une recovery source, pas Home partiel | test/core/startup/resolve_catalog_readiness_test.dart
maps a provider error without snapshot to source recovery | provider echoue sans cache exploitable | CatalogMode.missing + providerError | SourceRecoveryRequired catalog_provider_error + retry/chooseSource | `Impossible de charger la source` reste avant Home | test/core/startup/resolve_catalog_readiness_test.dart
maps invalid credentials to reconnect source | credentials invalides sans cache exploitable | CatalogMode.missing + credentialsInvalid | SourceRecoveryRequired catalog_credentials_invalid + reconnectSource | La bonne action est reconnecter, pas resynchroniser aveuglement | test/core/startup/resolve_catalog_readiness_test.dart
maps successful refresh without useful content to catalog empty | refresh success mais snapshot relu non utile | CatalogMode.empty + succeeded | SourceRecoveryRequired catalog_empty + resyncSource/chooseSource | Un refresh success technique ne suffit pas si aucun contenu n'est exploitable | test/core/startup/resolve_catalog_readiness_test.dart
maps explicit empty refresh outcome to catalog empty recovery | refresh indique explicitement empty | CatalogMode.missing + empty | SourceRecoveryRequired catalog_empty + resyncSource/chooseSource | Le catalogue vide a un reason code dedie | test/core/startup/resolve_catalog_readiness_test.dart
keeps an openable snapshot authoritative over refresh failure | cache exploitable malgre timeout refresh | CatalogMode.cached + timedOut | HomePartial catalog_snapshot_cached | Un cache exploitable doit eviter un nouveau blocage long | test/core/startup/resolve_catalog_readiness_test.dart
keeps a stale snapshot openable even when refresh fails | stale exploitable malgre provider error | CatalogMode.stale + providerError | HomePartial catalog_snapshot_stale | Les erreurs de sync de fond ne doivent pas bloquer Home | test/core/startup/resolve_catalog_readiness_test.dart
```

## Fixture

La fixture `_snapshot` encode l'intention metier minimale :

- `fresh`, `cached`, `stale` : `exists=true`, `hasPlaylists=true`,
  `hasItems=true`, donc Home peut s'ouvrir.
- `empty` : `exists=true`, `hasPlaylists=true`, `hasItems=false`, donc la source
  existe mais aucun contenu utile n'est disponible.
- `missing` et `unavailable` : `exists=false`, `hasPlaylists=false`,
  `hasItems=false`, donc Home ne peut pas s'ouvrir.

Cette fixture evite de tester seulement des valeurs enum sans relation avec la
forme attendue d'un snapshot local.

## Commande de verification

```text
flutter test test/core/startup/resolve_catalog_readiness_test.dart
```

## Definition de fini de l'etape 3

- [x] Les decisions catalogue importantes echouent si le resolver regresse.
- [x] Les tests encodent pourquoi Home est autorisee ou bloquee.
- [x] Aucun test ne valide seulement une valeur technique sans intention.
