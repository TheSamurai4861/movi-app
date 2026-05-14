# Phase 3 - Etape 1 - Chemin catalogue actuel

## Objectif

Verifier l'etat exact de la lecture snapshot, des refreshs IPTV et de la
decision Home avant modification.

Ce document est factuel : il decrit le comportement observe dans le code au
moment de l'audit. Les decisions cibles correspondent a la roadmap Phase 3 et
seront confirmees ou corrigees dans les etapes suivantes.

## Hypotheses

- Le chemin critique audite est le lancement local gere par
  `AppLaunchOrchestrator`.
- `CatalogSnapshotReader` est la source de verite locale pour savoir si le
  catalogue selectionne est exploitable avant refresh.
- Les refreshs `RefreshXtreamCatalog` et `RefreshStalkerCatalog` persistent le
  catalogue via leurs repositories respectifs ; cette persistance n'est pas
  encore verifiee en detail dans cette etape.
- Le remplacement UI complet n'est pas traite ici. La phase `preloadCompleteHome`
  est deja projetee en `catalog_preparing` par `BootScreenMapper`.

## Fichiers relus

```text
lib/src/core/startup/catalog_snapshot_reader.dart
lib/src/core/startup/domain/boot_contracts.dart
lib/src/core/startup/domain/catalog_snapshot_contracts.dart
lib/src/core/startup/domain/resolve_catalog_readiness.dart
lib/src/core/startup/domain/startup_recovery_mapper.dart
lib/src/core/startup/app_launch_orchestrator.dart
lib/src/core/startup/presentation/boot_screen_mapper.dart
lib/src/features/iptv/application/usecases/refresh_xtream_catalog.dart
lib/src/features/iptv/application/usecases/refresh_stalker_catalog.dart
test/core/startup/catalog_snapshot_test.dart
test/core/startup/resolve_catalog_readiness_test.dart
test/core/startup/app_launch_orchestrator_local_mode_test.dart
```

## Synthese du flux actuel

1. L'orchestrateur atteint `AppLaunchPhase.preloadCompleteHome`.
2. Il lit le snapshot local de la source selectionnee avec
   `CatalogSnapshotReader.readForSource`.
3. Il passe ce snapshot a `ResolveCatalogReadiness`.
4. Si le snapshot est exploitable (`fresh`, `cached`, `stale`), Home peut etre
   prechargee sans refresh bloquant.
5. Si le resolver retourne `CatalogPreparationRequired`, l'orchestrateur tente
   un refresh bloquant via `_ensureIptvCatalogReadyForLaunch`.
6. Le refresh bloquant utilise 3 tentatives, avec timeout de 20 secondes par
   tentative.
7. Apres le refresh, l'orchestrateur relit le snapshot local puis rappelle
   `ResolveCatalogReadiness` avec le `CatalogRefreshOutcome`.
8. Si le snapshot relu est devenu exploitable, l'orchestrateur precharge Home,
   marque le catalogue pret et ouvre `BootstrapDestination.home`.
9. Si la readiness reste `SourceRecoveryRequired`, l'orchestrateur termine avec
   `BootstrapDestination.welcomeSources` et un reason code catalogue.
10. Les syncs IPTV/cloud de fond ne sont lancees qu'apres le succes vers Home.

## Table des conditions

```text
condition | detection actuelle | decision actuelle | decision cible | fichier | risque
source active absente | _ensureIptvCatalogReady lit activeIptvSourceIds vide | retourne catalogReady=false/refreshed=false, puis le refresh de lancement peut finir en catalog_empty si ce chemin est atteint | source/source selection doit etre resolue avant catalogue ; ne pas afficher Home partiel | app_launch_orchestrator.dart | Risque faible dans le chemin nominal car la selection source est resolue avant preload, mais le cas reste melange avec empty dans _ensureIptvCatalogReady.
source selectionnee vide | controle explicite de selectedSourceId avant lecture snapshot | lance _LaunchStepException invalidTransition | erreur technique de transition, pas recovery catalogue | app_launch_orchestrator.dart | Risque faible ; ce cas indique une incoherence orchestrateur/source.
source localement connue | _ensureIptvCatalogReady compare activeIds avec comptes Xtream/Stalker locaux | log active_sources_missing si un id actif n'est pas connu, mais continue | source inconnue devrait rester un probleme source explicite si elle bloque le catalogue | app_launch_orchestrator.dart | Risque moyen : les ids actifs inconnus ne provoquent pas directement une recovery dediee.
snapshot present avec playlists et items | CatalogSnapshotReader trouve des playlists puis hasAnyPlaylistItems=true | CatalogMode.cached, canOpenHome=true | Home rapide ; sync de fond possible sans blocage | catalog_snapshot_reader.dart, resolve_catalog_readiness.dart | Risque faible ; couvert par tests reader/resolver.
snapshot present mais age connu stale | Le contrat supporte CatalogMode.stale et age nullable | Le reader actuel ne produit pas stale ; les tests construisent stale directement | Home rapide avec warning/sync de fond si la freshness devient disponible | catalog_snapshot_contracts.dart, resolve_catalog_readiness.dart | Risque moyen : stale existe dans le domaine mais pas dans le reader local actuel.
snapshot present sans item | CatalogSnapshotReader trouve playlists mais hasAnyPlaylistItems=false | CatalogMode.empty, SourceRecoveryRequired catalog_empty avant refresh si non refreshe ; apres refresh success sans contenu reste catalog_empty | recovery `Aucun contenu trouve` | catalog_snapshot_reader.dart, resolve_catalog_readiness.dart | Risque faible cote resolver ; risque a verifier cote refresh selon persistance et contenu reel.
snapshot absent | CatalogSnapshotReader trouve playlists vide | CatalogMode.missing, CatalogPreparationRequired catalog_snapshot_missing ; l'orchestrateur lance un refresh bloquant | afficher `catalog_preparing`, puis Home si refresh success, recovery si echec | catalog_snapshot_reader.dart, resolve_catalog_readiness.dart, app_launch_orchestrator.dart | Risque principal observe : l'etat UI depend de preloadCompleteHome et le timeout total peut atteindre 3 x 20 s.
snapshot indisponible | CatalogSnapshotReader catch toute exception de lecture locale | CatalogMode.unavailable, SourceRecoveryRequired catalog_snapshot_unavailable ; l'orchestrateur tente quand meme un refresh bloquant car toute SourceRecoveryRequired declenche refresh | recovery lecture locale ou retry explicite ; ne pas masquer une erreur stockage comme provider | catalog_snapshot_reader.dart, app_launch_orchestrator.dart | Risque moyen : l'indisponibilite locale peut etre convertie apres refresh en provider/empty selon le resultat relu.
refresh non necessaire | _ensureIptvCatalogReady voit playlists presentes et hasAnyPlaylistItems=true | retourne catalogReady=true/refreshed=false et skip refresh | Home rapide ; aucune attente bloquante | app_launch_orchestrator.dart | Risque faible ; mais ce chemin n'est appele qu'apres SourceRecoveryRequired dans le lancement, donc normalement pas pour snapshot deja cached.
refresh necessaire | playlists manquantes ou items manquants sur activeIds | _ensureIptvCatalogReady lance refresh pour chaque source active connue | refresh uniquement quand snapshot non exploitable ; decision bornee et visible | app_launch_orchestrator.dart | Risque moyen : le refresh porte sur activeIds, pas seulement la source selectionnee.
refresh Xtream reussi | RefreshXtreamCatalog retourne Ok(snapshot) | refreshed=true, log refresh_xtream success ; readiness finale depend de la relecture locale | persister snapshot exploitable et relire cached au second run | refresh_xtream_catalog.dart, app_launch_orchestrator.dart | Risque restant : cette etape n'a pas verifie la persistance repository en profondeur.
refresh Stalker reussi | RefreshStalkerCatalog retourne Ok(snapshot) | refreshed=true meme si le fold err ne throw pas ; erreurs Stalker sont seulement debugPrint dans ce bloc | meme garantie que Xtream, avec erreur provider si Err | refresh_stalker_catalog.dart, app_launch_orchestrator.dart | Risque eleve : le Err Stalker ne semble pas mappe en _LaunchStepException et refreshed passe a true apres le fold.
refresh timeout | timeout Dart de 20 s par tentative ou Failure reseau mappe iptvNetworkTimeout | CatalogRefreshOutcome.timedOut, reason catalog_sync_timeout, destination welcomeSources | recovery `La source ne repond pas` avec retry/changer source | app_launch_orchestrator.dart, resolve_catalog_readiness.dart | Risque moyen : 3 tentatives x 20 s peuvent depasser l'objectif d'attente courte.
provider error | UnknownFailure, CancelledFailure ou route failure non reseau mappe iptvProviderError | CatalogRefreshOutcome.providerError, reason catalog_provider_error, destination welcomeSources | recovery `Impossible de charger la source` | app_launch_orchestrator.dart, resolve_catalog_readiness.dart | Risque faible pour Xtream ; risque Stalker car Err non throw.
credentials invalides | CatalogRefreshOutcome.credentialsInvalid existe dans le resolver | aucun mapping observe depuis AppLaunchErrorCode ou _mapIptvFailureToLaunchStep | recovery `Connexion a la source impossible` | resolve_catalog_readiness.dart, app_launch_orchestrator.dart | Risque eleve : le contrat existe mais le chemin orchestrateur ne semble pas l'emettre actuellement.
catalogue vide apres refresh | _ensureIptvCatalogReady relit hasAnyPlaylistItems sur activeIds apres refresh | retourne catalogReady=false ; _ensureIptvCatalogReadyForLaunch throw iptvEmptyData ; reason catalog_empty | recovery `Aucun contenu trouve` | app_launch_orchestrator.dart, resolve_catalog_readiness.dart | Risque faible ; couvert par test orchestrateur.
Home preload apres catalogue exploitable | readiness n'est pas SourceRecoveryRequired, puis _preloadHomeForLaunch | Home preload, library preload, destination home | ouvrir Home sans bloquer sur sync de fond | app_launch_orchestrator.dart | Risque faible pour cached ; les degradations Home restent separees.
Home partiel | ResolveHomeDegradation traite les erreurs apres Home reachable | HomePartial et homeDegradationNoticeProvider, pas source recovery | rester reserve aux degradations apres ouverture Home | resolve_home_degradation.dart, app_launch_orchestrator_local_mode_test.dart | Risque faible ; des tests verifient que catalog_empty/provider ne fuitent pas dans Home partiel.
logs snapshot | _readCatalogSnapshotForLaunch log action=catalog_snapshot result=success avec mode/exists/hasPlaylists/hasItems | logs lisibles mais nom generique result=success meme pour missing/empty/unavailable | logs de transition catalogue plus explicites | app_launch_orchestrator.dart | Risque moyen : diagnostic possible, mais les noms d'evenements ne distinguent pas toutes les transitions ciblees.
logs readiness | catalog_minimal_ready success ou recovery_required dans telemetry ; log startup catalog_readiness en recovery | les logs contiennent reasonCode/actions/mode/refreshed | logs `catalog_preparation_started/completed/failed` en phase 6 ou etape 9 | app_launch_orchestrator.dart | Risque faible pour recovery ; preparation start/completion reste implicite.
```

## Points deja alignes avec la Phase 3

- `CatalogMode.canOpenHome` separe clairement `fresh/cached/stale` de
  `missing/empty/unavailable`.
- `CatalogSnapshotReader` ne declenche ni refresh ni navigation.
- `ResolveCatalogReadiness` est pur et couvre deja :
  - snapshot exploitable ;
  - snapshot missing comme preparation catalogue ;
  - snapshot unavailable ;
  - refresh timeout ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide.
- L'orchestrateur relit le snapshot apres refresh avant de decider Home ou
  recovery.
- Les tests existants couvrent le reader, le resolver, et plusieurs chemins
  orchestrateur : success apres refresh, timeout, provider error, empty.
- Les erreurs source avant Home sont testees comme non confondues avec
  `homeDegradationNoticeProvider`.

## Ecarts et risques pour les etapes suivantes

- `CatalogMode.stale` existe dans le contrat mais n'est pas produit par
  `CatalogSnapshotReader`.
- Le timeout bloquant est explicite, mais il est actuellement de 20 secondes par
  tentative avec 3 tentatives.
- `CatalogRefreshOutcome.credentialsInvalid` existe dans le resolver, mais aucun
  mapping observe ne le produit depuis les failures de refresh.
- Le refresh Stalker semble traiter `Err` par debugPrint sans throw, puis marque
  `refreshed=true`.
- `_ensureIptvCatalogReady` rafraichit les `activeIds`, pas uniquement la source
  selectionnee pour le lancement.
- `snapshot unavailable` declenche le meme chemin de refresh bloquant que
  `snapshot missing`, ce qui peut masquer une erreur de lecture locale.
- Les logs actuels permettent de diagnostiquer, mais les transitions
  `catalog_preparation_started/completed/failed` ne sont pas explicites.

## Definition de fini de l'etape 1

- [x] Le chemin actuel `snapshot absent -> refresh -> Home` est documente.
- [x] Les cas deja distinguables par le code sont identifies.
- [x] Les cas melanges ou implicites sont listes avant implementation.
