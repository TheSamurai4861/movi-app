# Cartographie de l'orchestration AppLaunch

## Synthese

`AppLaunchOrchestrator` est la source principale de decision du tunnel
applicatif apres `/launch`.

Il maintient :

- `AppLaunchState` pour l'UI/router legacy ;
- `AppLaunchStateRegistry` pour notifier `LaunchRedirectGuard` ;
- `TunnelStateRegistry` pour le routage projete V2 ;
- `AppLaunchCriteria` pour savoir si Home peut etre ouverte ;
- `AppLaunchRecovery` et `recoveryMessage` pour les etats degradables ;
- `EntryJourneyTelemetry` et logs `startup` pour diagnostiquer le parcours.

Le chemin nominal est :

```text
run()
  -> init
  -> startup
  -> auth
  -> profiles
  -> localAccounts
  -> sources si besoin remote
  -> localAccounts si hydratation remote
  -> sourceSelection
  -> preloadCompleteHome
  -> done
```

## Modeles d'etat

### AppLaunchStatus

| status | role |
| --- | --- |
| `idle` | Aucun run actif. Etat initial ou apres reset. |
| `running` | Run de lancement en cours. |
| `success` | Destination resolue. Le guard peut appliquer la navigation. |
| `failure` | Echec critique du run. Le guard renvoie vers `/bootstrap`. |

### AppLaunchPhase

| phase | role actuel |
| --- | --- |
| `init` | Demarrage du run, attribution `runId`, reset erreur/destination/criteria. |
| `startup` | Execution du bootstrap technique via `_startupRunner`. |
| `auth` | Resolution session via `AuthOrchestrator.bootstrapSession()`. |
| `profiles` | Lecture profils et selection/reparation du profil courant. |
| `sources` | Lecture sources distantes Supabase si aucune source locale. |
| `localAccounts` | Lecture sources locales, puis hydratation locale depuis Supabase si possible. |
| `sourceSelection` | Resolution source active : auto-selection, restauration ou selection manuelle requise. |
| `preloadCompleteHome` | Lecture snapshot catalogue, refresh bloquant si necessaire, preload Home, preload library. |
| `done` | Etat terminal success/failure. |

### AppLaunchCriteria

`AppLaunchCriteria` contient :

- `hasSession`
- `hasSelectedProfile`
- `hasSelectedSource`
- `hasIptvCatalogReady`
- `hasHomePreloaded`
- `hasLibraryReady`

`isHomeReady` vaut true seulement si :

```text
hasSelectedProfile
hasSelectedSource
hasIptvCatalogReady
hasHomePreloaded
hasLibraryReady
```

Observation : `hasSession` n'est pas requis par `isHomeReady`, ce qui confirme
le support du mode local-first.

## Transitions explicites

`_setPhase()` appelle `_assertValidTransition()`. Les transitions autorisees
sont :

| depuis | vers autorises |
| --- | --- |
| `init` | `startup` |
| `startup` | `auth`, `done` |
| `auth` | `profiles`, `done` |
| `profiles` | `localAccounts`, `done` |
| `localAccounts` | `sources`, `sourceSelection`, `done` |
| `sources` | `localAccounts`, `sourceSelection`, `done` |
| `sourceSelection` | `preloadCompleteHome`, `done` |
| `preloadCompleteHome` | `done` |
| `done` | aucune |

Les retours `sources -> localAccounts` sont explicites pour le cas
d'hydratation de sources remote vers stockage local.

## Table orchestration

| phase | entree | operation | sortie success | sortie failure | reason code/log | destination |
| --- | --- | --- | --- | --- | --- | --- |
| `init` | `run()` appele par `appLaunchRunnerProvider`. | Cree `runId`, met `status=running`, `phase=init`, reset erreur/destination/recovery/criteria. | `_setPhase(startup)`. | Pas de failure directe, sauf exception inattendue avant `_runInternal`. | `phase_transition phase=init step=start`, `entry_journey_started`. | Aucune. |
| `startup` | Transition `init -> startup`. | Execute `_startupRunner()`, donc le startup technique deja expose par `appStartupProvider`. | Phase `auth`. | `completeFailure()` si exception. | `entry_journey_stage_completed reasonCode=startup_ready`. | Peut terminer `done` si failure. |
| `auth` | Transition `startup -> auth`. | Execute `AuthOrchestrator.bootstrapSession()`, determine session cloud/local/degraded. | Phase `profiles` si continuation possible. | Failure critique via catch global. | `session_resolved` avec `session_authenticated`, `reauth_required`, `degraded_retryable`, `auth_required` ou `local_mode`. | Peut terminer success vers `auth` si reauth obligatoire ou auth cloud bloquante. |
| `profiles` | Transition `auth -> profiles`. | Charge les profils, compte l'inventaire, repare la selection sur le premier profil si selection invalide. | Phase `localAccounts`. | Failure critique via catch global. | `profiles_inventory_loaded`, `entry_journey_stage_completed`, reason `profile_missing` ou `profiles_loaded`. | Peut terminer success vers `welcomeUser` si aucun profil. |
| `localAccounts` | Transition depuis `profiles` ou retour depuis `sources`. | Charge comptes Xtream/Stalker locaux. Si sources remote hydratees, relit les comptes locaux. | Phase `sourceSelection` si sources locales disponibles. | Failure critique via catch global. | `sources_inventory_loaded`, reason `source_missing`, `sources_loaded` ou `sources_hydrated_from_cloud`. | Peut terminer success vers `welcomeSources` si aucune source locale exploitable. |
| `sources` | Transition depuis `localAccounts` si aucune source locale et session/repo Supabase disponibles. | Charge sources distantes Supabase, migre credentials legacy, prepare hydratation locale. | Retour `localAccounts` pour relire apres hydratation, ou `sourceSelection` si pas d'hydratation utile. | Erreur fetch remote ignoree en fallback local-only, sauf exception critique hors try local. | Debug `remote_sources_fetch_failed`, `sources fetched`. | Pas de destination directe, sauf via etape suivante. |
| `sourceSelection` | Transition depuis `localAccounts` ou `sources`. | Lit preferences source, tire preferences cloud si plusieurs sources, restaure/auto-selectionne ou demande selection manuelle. | Phase `preloadCompleteHome`. | Failure critique si exception. | `source_selection_resolved` avec `source_single_auto_selected`, `source_selection_restored` ou `source_selection_required`. | Peut terminer success vers `chooseSource` si selection manuelle requise. |
| `preloadCompleteHome` | Source selectionnee presente. | Lit snapshot catalogue, tente refresh bloquant si snapshot non exploitable, resout readiness, preload Home, preload library. | `done` success vers Home si criteria Home complets. | Recovery source si catalogue non recuperable, ou failure critique si exception non recuperee. | `catalog_snapshot`, `catalog_minimal_ready`, `catalog_readiness recovery_required`, `preload_home`, `preload_library`, `catalog_full_load_completed`, `entry_journey_stage_completed reasonCode=preload_complete`. | `home` si pret, `welcomeSources` si `SourceRecoveryRequired`. |
| `done` | `completeSuccess()` ou `completeFailure()`. | Ecrit etat terminal, destination ou failure, logs finaux. | Guard applique destination. | Guard affiche `/bootstrap` si failure. | `phase_transition phase=done`, `entry_journey_completed`, `entry_journey_failed`, `entry_journey_safe_state_reached`. | `auth`, `welcomeUser`, `welcomeSources`, `chooseSource`, `home` ou aucune si failure. |

## Transitions implicites et sous-etats

Plusieurs decisions importantes ne sont pas des `AppLaunchPhase` dediees.
Elles sont representees par `step`, `criteria`, logs ou `recoveryMessage`.

| sous-etat reel | representation actuelle | impact |
| --- | --- | --- |
| `profiles_select` | Variable locale `step`, pas de phase dediee. | La reparation du profil selectionne est invisible dans `AppLaunchPhase`. |
| `sources_fetch` | Phase `sources`, step `sources_fetch`. | OK, mais uniquement quand aucune source locale et source remote possible. |
| `local_accounts_hydrate_from_supabase` | Phase `localAccounts`, step local. | Hydratation remote/local visible seulement dans logs/telemetry. |
| Pull preferences source cloud | Phase `sourceSelection`, logs debug. | Peut influencer la source selectionnee sans phase dediee. |
| Snapshot catalogue initial | Phase `preloadCompleteHome`, log `catalog_snapshot`. | Pas de phase `catalogSnapshotCheck`. |
| Preparation catalogue / refresh bloquant | Phase `preloadCompleteHome`, `_ensureIptvCatalogReadyForLaunch()`, logs `iptv_sync_*`, `recoveryMessage` pour retries. | Point critique UX : pas de phase `catalogPreparing`. |
| Source recovery catalogue | `SourceRecoveryRequired` puis success vers `welcomeSources` avec reason override. | Recovery source n'a pas de destination dediee : retour vers page sources. |
| Home preload | Phase `preloadCompleteHome`, `_preloadHomeForLaunch`. | Pas de distinction entre preparation catalogue et preparation Home. |
| Library preload | Phase `preloadCompleteHome`, `_ensureLibraryReadyForLaunch`. | Degradation Home partiel geree par notice, pas par destination. |
| Home partiel | `HomePartial` via `_setHomeDegradationNotice`. | L'orchestrateur ouvre quand meme Home si criteria techniques sont true. |
| Retry interne | `_runWithRetry`, `recoveryMessage='Recovery: ...'`. | Visible potentiellement dans splash legacy, mais pas modele UX stable. |
| Sync IPTV/background cloud | Lancee apres success Home. | Hors phase principale, logs debug/degraded. |

## Mises a jour AppLaunchState

Tous les changements passent par `_updateState(next)`, qui :

```text
state = next
_launchRegistry.update(next)
_tunnelStateRegistry.update(_projectTunnelState(next))
```

Points de mise a jour identifies :

| point | effet |
| --- | --- |
| `build()` | Initialise `AppLaunchState` et `TunnelState`. |
| `run()` | Passe en `running/init`, reset erreur/destination/recovery/criteria, cree `runId`. |
| `reset()` | Revient a `AppLaunchState()` et annule references ongoing/background. |
| `setResolvedDestination()` | Force une destination resolue ; bloque Home si `criteria.isHomeReady` false. |
| `completeManualSourceLoadingToHome()` | Chemin manuel source loading -> preload Home/library -> destination Home. |
| `updateCriteria()` local | Recalcule criteria depuis `AppLaunchMeta`. |
| `setRecovery()` local | Met a jour `AppLaunchRecovery`. |
| `completeSuccess()` | Passe en `success/done`, pose destination. |
| `completeFailure()` | Passe en `failure`, pose `AppLaunchFailure`, efface destination. |
| `_setPhase()` | Change seulement la phase et logge l'entree de stage. |
| `_setRecoveryMessage()` | Met a jour un message temporaire de retry/preparation. |

## TunnelStateRegistry

`TunnelStateRegistry` est mis a jour a chaque `_updateState`.

Projection utilisee :

- `CanonicalTunnelStateProjector` si `enableEntryJourneyStateModelV2 == true` ;
- `LegacyTunnelStateBridge` sinon.

En mode legacy :

- `AppLaunchPhase.init/startup` -> `TunnelStage.preparingSystem` ;
- `auth` -> `authRequired` ;
- `profiles` -> `profileRequired` ;
- `sources/localAccounts/sourceSelection` -> `sourceRequired` ;
- `preloadCompleteHome` -> `preloadingHome` ;
- success destination Home + criteria ready -> `readyForHome`.

En mode canonique :

- failure -> `preparingSystem` reason `launch_failure` ;
- running/idle -> `preparingSystem` ;
- destination auth/recovery reauth -> `authRequired` ;
- profil manquant -> `profileRequired` ;
- source manquante -> `sourceRequired` ;
- Home ready -> `readyForHome` ;
- sinon -> `preloadingHome`.

## Logs et telemetry principaux

| signal | origine | role |
| --- | --- | --- |
| `[Startup] action=phase_transition` | `_logPhase()` | Trace chaque entree de phase et l'etat terminal. |
| `entry_journey_started` | `run()` | Debut de run avec `runId`. |
| `entry_journey_stage_entered` | `_setPhase()` | Entree dans une phase. |
| `entry_journey_stage_completed` | `_runInternal()` | Fin logique d'une phase. |
| `session_resolved` | phase auth | Resultat session. |
| `profiles_inventory_loaded` | phase profiles | Nombre de profils. |
| `sources_inventory_loaded` | local/remote sources | Nombre sources locales/remote. |
| `source_selection_resolved` | phase sourceSelection | Auto/restauration/selection manuelle. |
| `[Startup] action=catalog_snapshot` | lecture snapshot | Mode snapshot et presence items. |
| `[Startup] action=iptv_sync_*` | refresh IPTV | Decision refresh, skip, run, done, failed. |
| `catalog_minimal_ready` | phase preloadCompleteHome | Catalogue exploitable ou recovery required. |
| `[Startup] action=preload_home` | preload Home | ready/partial/recovery. |
| `[Startup] action=preload_library` | preload library | ready/partial/recovery/skipped. |
| `catalog_full_load_completed` | apres Home/library | Home/library preloads termines. |
| `entry_journey_completed` | `completeSuccess()` | Fin success. |
| `entry_journey_failed` | `completeFailure()` | Fin failure. |
| `[Startup] action=evaluate_home_criteria` | checks Home | Diagnostic criteria Home. |

## Chemins success

| condition | sortie |
| --- | --- |
| Auth cloud exige reauth | success `done`, destination `auth`. |
| Aucun profil | success `done`, destination `welcomeUser`. |
| Aucun compte source local exploitable | success `done`, destination `welcomeSources`. |
| Plusieurs sources sans selection valide | success `done`, destination `chooseSource`. |
| Catalogue source non recuperable | success `done`, destination `welcomeSources`, reason override du recovery catalogue. |
| Home criteria complets | success `done`, destination `home`. |
| Chargement manuel source reussi | `setResolvedDestination(home)` apres preload Home/library. |

## Chemins failure

`completeFailure()` capture les exceptions non recuperees et produit :

- `AppLaunchStatus.failure` ;
- `AppLaunchFailure(step, failure, original, userId)` ;
- `destination=null` ;
- log `[Startup] action=launch_step result=failure code=app_launch_step_failed` ;
- telemetry `entry_journey_failed` ;
- `AppLaunchResult(destination: auth, failure: launchFailure)` pour compat.

Principales erreurs codees :

| error code | cas observe |
| --- | --- |
| `invalidTransition` | Transition phase invalide ou Home sans source selectionnee. |
| `iptvEmptyData` | Refresh IPTV termine sans catalogue exploitable. |
| `iptvNetworkTimeout` | Timeout refresh catalogue IPTV. |
| `iptvProviderError` | Erreur fournisseur/route/annulation/retry exhausted. |
| `homePreloadInvalidState` | Home preload incomplet ou timeout. |
| `libraryPreloadTimeout` | Enum present, mais la library timeout est aujourd'hui convertie en `HomePartial`, pas failure. |

## Etats sans phase dediee a prevoir

Pour le refactor boot/Figma, les etats suivants devraient probablement sortir
de `preloadCompleteHome` ou de simples logs :

- `catalogSnapshotChecking`
- `catalogPreparing`
- `catalogRefreshing`
- `catalogRecoveryRequired`
- `homePreloading`
- `libraryPreloading`
- `homePartial`
- `sourceCredentialsInvalid`

Observation : `sourceCredentialsInvalid` existe dans les reason codes de
recovery, mais n'apparait pas comme `AppLaunchErrorCode`; il faudra verifier
dans la phase catalogue/source si une erreur IPTV reelle peut produire ce cas.
