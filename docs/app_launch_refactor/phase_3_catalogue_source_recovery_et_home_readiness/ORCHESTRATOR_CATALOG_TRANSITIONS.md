# Phase 3 - Etape 7 - Transitions catalogue orchestrateur

## Objectif

Faire appliquer les decisions catalogue par `AppLaunchOrchestrator` sans
navigation concurrente ni Home partiel abusif.

## Decision runtime

`AppLaunchOrchestrator` consomme `ResolveCatalogReadiness` comme source de
decision catalogue :

- `HomeReady` ou `HomePartial` avec snapshot exploitable : continuer vers Home.
- `CatalogPreparationRequired` : rester dans `preloadCompleteHome`, afficher
  `catalog_preparing`, lancer le refresh bloquant borne, relire le snapshot.
- `SourceRecoveryRequired` : terminer vers `BootstrapDestination.welcomeSources`
  avec reason code catalogue et sans precharger Home.

Le router ne recree pas cette decision. `LaunchRedirectGuard` applique seulement
`BootstrapDestination` :

```text
welcomeSources -> /welcome/sources
chooseSource -> /welcome/source/select
home -> /home
```

## Table des transitions

```text
etat catalogue | phase orchestrateur | destination | Home autorisee | sync fond | test
snapshot fresh/cached/stale au premier read | preloadCompleteHome puis done | home | oui, sans refresh bloquant | lancee apres Home | opens home from a local catalog snapshot even if foreground refresh would fail
snapshot cached avec refresh qui timeout si lance | preloadCompleteHome puis done | home | oui, refresh non lance | lancee apres Home | opens home from a local catalog snapshot even if foreground refresh would time out
snapshot missing avant refresh | preloadCompleteHome running | aucune destination finale pendant attente | non pendant preparation | non pendant attente | exposes catalog preparing while first run waits for missing snapshot refresh
snapshot missing puis refresh success + snapshot relu cached | preloadCompleteHome puis done | home | oui apres relecture locale | lancee apres Home | opens home when blocking refresh creates the missing local snapshot
snapshot missing puis refresh timeout | preloadCompleteHome puis done | welcomeSources | non | non | routes to source recovery when no snapshot exists and refresh times out
snapshot missing puis timeout Future.timeout | preloadCompleteHome puis done | welcomeSources | non | non | routes to source recovery when blocking refresh exceeds its timeout
snapshot missing puis provider error | preloadCompleteHome puis done | welcomeSources | non | non | routes to source recovery when no snapshot exists and provider refresh fails
snapshot missing puis credentials invalides | preloadCompleteHome puis done | welcomeSources | non | non | routes to credentials recovery when Xtream refresh reports invalid credentials
snapshot missing puis Stalker provider error | preloadCompleteHome puis done | welcomeSources | non | non | routes to source recovery when Stalker refresh fails
refresh success mais catalogue toujours vide | preloadCompleteHome puis done | welcomeSources | non | non | routes to source recovery when refresh leaves catalog empty
Home feed/library degradation apres snapshot exploitable | preloadCompleteHome puis done | home | oui avec Home partial notice | lancee apres Home | opens Home partially when Home preload reports feed error / library preload times out
```

## Etat `catalog_preparing`

Le test `exposes catalog preparing while first run waits for missing snapshot
refresh` bloque volontairement le fake refresh. Pendant cette attente, il
verifie :

- `AppLaunchStatus.running` ;
- `AppLaunchPhase.preloadCompleteHome` ;
- `BootScreenModel.reasonCode == catalog_preparing` ;
- `TunnelState.stage == preloadingHome`.

Apres completion du refresh et sauvegarde d'une playlist avec item, le run finit
sur Home et le tunnel passe a `readyForHome`.

## Separation Home partiel / source recovery

Les chemins source recovery verifient :

- destination `BootstrapDestination.welcomeSources` ;
- `homeController.loadCalls == 0` ;
- `homeDegradationNoticeProvider == null`.

Les chemins Home partiel verifient l'inverse :

- destination `BootstrapDestination.home` ;
- notice Home partielle presente ;
- reason code Home (`home_feed_failed`, `home_iptv_sections_empty`,
  `library_preload_timeout`) ;
- pas de reason code catalogue source comme `catalog_empty` ou
  `catalog_provider_error`.

## TunnelStateRegistry

Le registre tunnel est mis a jour via `_updateState` a chaque changement de
`AppLaunchState`.

Couverture ajoutee :

- pendant `catalog_preparing` : `TunnelStage.preloadingHome` ;
- apres refresh success et Home : `TunnelStage.readyForHome`,
  `hasCatalogReady=true`, `hasHomePreloaded=true`.

Les recoveries source terminent sur `BootstrapDestination.welcomeSources`, ce
qui projette le tunnel vers `TunnelStage.sourceRequired`.

## Definition de fini de l'etape 7

- [x] Le premier run sans snapshot affiche `catalog_preparing`.
- [x] Le refresh reussi ouvre Home.
- [x] Les erreurs source avant Home n'ouvrent pas Home partiel.
- [x] Un snapshot exploitable autorise Home sans refresh bloquant.
