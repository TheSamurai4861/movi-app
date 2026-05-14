# Cartographie des contrats boot

## Synthese

Les contrats de boot sont deja bien avances et doivent etre reutilises. Ils
sont majoritairement purs, sans dependance Flutter/Riverpod/GetIt, ce qui est
coherent avec les bonnes pratiques du projet.

Le refactor ne doit donc pas creer un second modele parallele. Il doit plutot :

- conserver `CatalogMode`, `EntryDecision`, `HomeReadiness`,
  `RecoveryAction` et les resolvers purs ;
- etendre `AppLaunchPhase` ou introduire un modele UI derive pour exposer les
  etats Figma manquants ;
- clarifier le traitement de `cached/stale` ;
- raccorder les reason codes existants a des textes/actions UI stables ;
- eviter de dupliquer `BootstrapDestination`, `TunnelState` et
  `EntryDecision`.

## Table des concepts

| concept | fichier | role | valeurs actuelles | equivalent Figma | manque identifie |
| --- | --- | --- | --- | --- | --- |
| `CatalogMode` | `boot_contracts.dart` | Decrit si le catalogue local permet d'ouvrir Home. | `fresh`, `cached`, `stale`, `missing`, `empty`, `unavailable`. | `catalog_cached_ready`, `catalog_preparing`, `catalog_empty`, source recovery. | `cached/stale` sont openables mais `ResolveCatalogReadiness` les transforme en `HomePartial`; a clarifier avec la spec. |
| `RecoveryAction` | `boot_contracts.dart` | Enum d'intentions d'action, sans execution UI. | `retry`, `exportLogs`, `login`, `createProfile`, `chooseProfile`, `addSource`, `chooseSource`, `reconnectSource`, `resyncSource`, `openHomeCached`, `retryHomeSections`, `retryLibrary`. | Tous les boutons Figma principaux/secondaires. | Pas encore de handler central documente `action -> route/controller`. |
| `EntryDecision` | `boot_contracts.dart` | Decision pure de destination d'entree. | `OpenHome`, `RequireAuth`, `RequireProfile`, `RequireSource`, `RequireSourceSelection`, `TechnicalBootFailure`. | Auth, profil, source, Home, erreur technique. | Ne distingue pas create vs choose profile dans le type, seulement via donnees profils ailleurs. `RequireSource` couvre plusieurs cas source/catalogue. |
| `HomeReadiness` | `boot_contracts.dart` | Etat de Home une fois le catalogue exploitable. | `HomeReady`, `HomePartial`, `SourceRecoveryRequired`. | Home normal, Home partial banner, source recovery. | Tres reutilisable. Il manque surtout un mapping UI dedie vers banner/recovery panel. |
| `StartupRecoveryReasonCodes` | `startup_recovery_mapper.dart` | Liste de reason codes stables startup/catalogue/Home. | Boot timeout/failure, auth/profile/source, catalog snapshots, catalog sync/provider/credentials/empty, Home/library. | Variants boot/recovery/Home partial de la spec. | Pas de reason code dedie `catalog_preparing` ou `opening_home`. Credentials invalid existe mais emission reelle reste a verifier. |
| `StartupRecoveryPlan` | `startup_recovery_mapper.dart` | Plan actionnable reason code + actions + message diagnostic. | `reasonCode`, `actions`, `message`. | Recovery action panel. | Message non-localise et diagnostic, pas un modele UI final. |
| `StartupRecoveryMapper` | `startup_recovery_mapper.dart` | Convertit erreurs techniques/launch/Home en plans recovery. | `mapBootFailure`, `mapLaunchFailure`, `mapHomeFailure`. | Recovery boot/source/Home partial. | `mapLaunchFailure` depend de codes normalises `iptvnetworktimeout`, etc. Couverture credentials invalid a verifier cote emission. |
| `EntryDecisionReasonCodes` | `resolve_entry_decision.dart` | Reason codes pour decisions d'entree. | `auth_required`, `profile_required`, `profile_selection_required`, `source_required`, `source_selection_required`, `entry_ready`, `catalog_not_ready_for_entry`. | Etats auth/profil/source/opening Home. | `catalog_not_ready_for_entry` est note comme temporaire et trop generique pour l'UX catalogue. |
| `EntryDecisionInput` | `resolve_entry_decision.dart` | Input pur pour resoudre la destination. | Session/profiles/sources/resolved ids/catalog mode. | Contrat orchestrateur -> decision. | Pas un modele UI. Ne porte pas les listes de profils/sources pour rendu. |
| `ResolveEntryDecision` | `resolve_entry_decision.dart` | Resolver pur session/profil/source/catalogue vers `EntryDecision`. | Stoppe sur auth/profil/source/catalog non openable, sinon `OpenHome`. | State machine entree. | Si catalog non openable, renvoie `RequireSource(catalog_not_ready_for_entry)`, pas un etat `catalogPreparing`/recovery precis. |
| `CatalogRefreshOutcome` | `resolve_catalog_readiness.dart` | Resultat abstrait d'un refresh bloquant. | `notRun`, `succeeded`, `timedOut`, `providerError`, `credentialsInvalid`, `empty`. | Preparation catalogue et erreurs source. | Bon contrat, mais `AppLaunchErrorCode` ne contient pas `credentialsInvalid`. |
| `CatalogReadinessInput` | `resolve_catalog_readiness.dart` | Snapshot + outcome refresh pour decider readiness. | `snapshot`, `refreshOutcome`. | Source preparation panel/recovery. | Ne porte pas etat en cours `refreshing`, seulement resultat. |
| `ResolveCatalogReadiness` | `resolve_catalog_readiness.dart` | Resolver pur snapshot/refresh vers `HomeReadiness`. | Openable -> `HomeReady`/`HomePartial`; non openable -> `SourceRecoveryRequired`. | Cache ready, timeout, provider error, credentials invalid, catalog empty. | `succeeded` + snapshot non openable devient `catalog_empty`, correct. `cached/stale` en `HomePartial` a revoir. |
| `CatalogSnapshot` | `catalog_snapshot_contracts.dart` | Snapshot local pour une source resolue. | `sourceId`, `exists`, `hasPlaylists`, `hasItems`, `mode`, `age`, `canOpenHome`. | Verification catalogue/cache. | Ne porte pas nom/type de source pour UI. `sourceId` ne doit pas etre affiche. |
| `HomeDegradationKind` | `resolve_home_degradation.dart` | Types de degradation Home non bloquants. | `feedFailed`, `iptvSectionsEmpty`, `libraryPreloadTimeout`, `libraryPreloadFailed`. | Home partial banner variants. | La spec parle de reprise/bibliotheque indisponible; `libraryPreload*` couvre probablement mais le wording UI reste a mapper. |
| `HomeDegradation` / `HomeDegradationInput` | `resolve_home_degradation.dart` | Input pur de degradation Home. | `catalogMode`, liste degradations. | Home partiel. | Ne porte pas detail de sections echouees. Suffisant pour premier chantier. |
| `ResolveHomeDegradation` | `resolve_home_degradation.dart` | Convertit degradations en `HomeReady` ou `HomePartial`. | Combine reason codes et actions. | Home partial banner. | Bon contrat, manque mapping UI et action execution. |
| `StartupPhase` | `startup_contracts.dart` | Phases du bootstrap technique pre-MyApp. | `init`, `loadFlavor`, `registerConfig`, `initDependencies`, `exposeAppState`, `loggingReady`, `iptvSyncSetup`, `done`. | Demarrage technique / erreur technique boot. | Niveau L1 distinct du tunnel applicatif. Ne pas confondre avec `AppLaunchPhase`. |
| `StartupFailureCode` | `startup_contracts.dart` | Erreurs techniques pre-MyApp. | `unknown`, `flavorLoadFailed`, `configInvalid`, `configTimeout`, `dependenciesInitFailed`, `dependenciesInitTimeout`, `appStateExposureFailed`, `loggingInitFailed`, `iptvSyncSetupFailed`. | `technical_failure`. | Mapper vers textes UI finaux sans exposer details. |
| `StartupResult` | `startup_contracts.dart` | Resultat bootstrap technique. | `ready`, `safeMode`, `failure?`, `durationMs`, `reasonCode`. | Startup loading/safe mode/technical failure. | Safe mode n'est pas explicitement dans la spec Figma boot. |
| `SessionContractSnapshot` | `entry_journey_contracts.dart` | Snapshot session pur. | `unknown`, `authenticated`, `unauthenticated`, `userId`, `reasonCode`. | Verification session / auth required. | OK. Ne porte pas UI. |
| `ProfilesContractSnapshot` | `entry_journey_contracts.dart` | Snapshot profils pur. | `count`, `hasValidSelection`, `selectedProfileId`, `reasonCode`. | Resolution profil / create profile / choose profile. | Distingue create vs choose via `count`, pas par type dedie. |
| `SourcesContractSnapshot` | `entry_journey_contracts.dart` | Snapshot sources pur. | `localCount`, `remoteCount`, `hasValidSelection`, `requiresManualSelection`, `selectedSourceId`, `reasonCode`. | Resolution source / add source / choose source. | Pas de liste de sources ni labels pour UI. |
| `TunnelState` | `tunnel_state.dart` | Etat projete pour routing/surface V2. | Stages `preparingSystem`, `authRequired`, `profileRequired`, `sourceRequired`, `preloadingHome`, `readyForHome`; loading/execution mode; criteria booleens. | Surfaces boot haut niveau. | Plus grossier que Figma : pas de `catalogPreparing`, `sourceTimeout`, `catalogEmpty`, `homePartial` dedies. |
| `AppLaunchStatus` | `app_launch_orchestrator.dart` | Statut runtime de l'orchestrateur. | `idle`, `running`, `success`, `failure`. | Loading/success/failure. | Trop generique pour UI. |
| `AppLaunchPhase` | `app_launch_orchestrator.dart` | Phase runtime legacy du tunnel. | `init`, `startup`, `auth`, `profiles`, `sources`, `localAccounts`, `sourceSelection`, `preloadCompleteHome`, `done`. | Boot status variants. | `preloadCompleteHome` regroupe trop d'etats UX. Manque catalog/source/home sous-phases. |
| `AppLaunchRecoveryKind` | `app_launch_orchestrator.dart` | Type de recovery auth actuel. | `reauthRequired`, `degradedRetryable`. | Auth recovery/degraded continuation. | Trop limite pour source/catalogue/Home recovery. Ne pas l'etendre sans verifier usage auth. |
| `AppLaunchRecovery` | `app_launch_orchestrator.dart` | Recovery attache a `AppLaunchState`. | `kind`, `cause`, `reasonCode`, `message`. | Recovery banner/panel. | Couple a `AuthFailureCode`; pas adapte comme contrat recovery general source/catalogue. |
| `AppLaunchState` | `app_launch_orchestrator.dart` | Etat observable par UI/router. | `status`, `phase`, `error`, dates, `destination`, `criteria`, `recovery`, `recoveryMessage`, `runId`. | Source du futur `BootScreenModel`. | Pas de champ UI stable. `recoveryMessage` contient du texte ponctuel non structure. |
| `AppLaunchCriteria` | `app_launch_criteria.dart` | Criteres d'ouverture Home. | session, profile, source, catalog, Home preload, library. | Gate Home / opening Home. | Pas de details sur quelle section Home est partielle. |

## Correspondances entre contrats

### Entree applicative

```text
SessionContractSnapshot
ProfilesContractSnapshot
SourcesContractSnapshot
CatalogMode
  -> EntryDecisionInput
  -> ResolveEntryDecision
  -> EntryDecision
  -> BootstrapDestination
  -> route via LaunchRedirectGuard
```

### Catalogue et source recovery

```text
CatalogSnapshot
CatalogRefreshOutcome
  -> CatalogReadinessInput
  -> ResolveCatalogReadiness
  -> HomeReady | HomePartial | SourceRecoveryRequired
```

### Home partiel

```text
HomeDegradationKind
HomeDegradationInput
  -> ResolveHomeDegradation
  -> HomeReady | HomePartial
```

### Startup technique

```text
StartupPhase
StartupFailureCode
StartupFailure
StartupResult
  -> AppStartupGate
  -> OverlaySplash | LaunchErrorPanel | AppUpdateBlockedScreen
```

### Router/surface projetee

```text
AppLaunchState
  -> LegacyTunnelStateBridge | CanonicalTunnelStateProjector
  -> TunnelState
  -> TunnelSurface
  -> route
```

## Doublons ou recouvrements de sens

| doublon potentiel | observation | recommandation |
| --- | --- | --- |
| `EntryDecision` vs `BootstrapDestination` | `EntryDecision` explique pourquoi, `BootstrapDestination` indique ou aller. | Ne pas dupliquer. Garder `EntryDecision` comme decision domaine et `BootstrapDestination` comme compat router. |
| `AppLaunchPhase` vs `TunnelStage` | `AppLaunchPhase` est runtime legacy detaille, `TunnelStage` est surface projetee plus grossiere. | Ne pas ajouter une troisieme state machine sans mapping clair. |
| `StartupFailureCode.reasonCode` vs `StartupRecoveryReasonCodes.boot*` | Deux familles de reason codes techniques startup. | Conserver, mais mapper vers un reason code UI unique pour `technical_failure`. |
| `AppLaunchRecovery` vs `StartupRecoveryPlan` | `AppLaunchRecovery` est auth-centrique, `StartupRecoveryPlan` est plus general. | Ne pas reutiliser `AppLaunchRecovery` comme recovery source/catalogue sans refactor. |
| `CatalogMode.cached/stale` vs `HomePartial` | Le resolver actuel traite cached/stale comme partiel avec actions `openHomeCached/resyncSource`. | Clarifier produit : cache exploitable doit ouvrir Home rapidement sans banner bloquante. |
| `SourceRecoveryRequired` vs `RequireSource` | `RequireSource` est destination/action source generale; `SourceRecoveryRequired` explique une cause catalogue/source. | Garder les deux, mais le mapping UI doit preserver le reason code source recovery. |

## Trous par rapport a la spec Figma

| besoin Figma | couverture actuelle | manque |
| --- | --- | --- |
| `technical_startup` | `StartupPhase`, `AppStartupGate`, `AppLaunchPhase.startup`. | Deux niveaux startup a distinguer dans l'UI. |
| `session_check` | `AppLaunchPhase.auth`, `SessionContractSnapshot`. | Pas de modele UI dedie. |
| `profile_check` | `AppLaunchPhase.profiles`, `ProfilesContractSnapshot`. | Pas de distinction UI create/choose dans `EntryDecision`, mais possible via count. |
| `source_check` | `AppLaunchPhase.localAccounts/sourceSelection`, `SourcesContractSnapshot`. | Phase source dispersee entre local, remote et selection. |
| `catalog_preparing` | Refresh dans `preloadCompleteHome`, `CatalogRefreshOutcome` seulement apres coup. | Manque etat en cours stable. |
| `opening_home` | `preloadCompleteHome` + criteria. | Manque etat UI dedie distinct du catalogue. |
| `source_timeout` | `catalogSyncTimeout`, `iptvNetworkTimeout`. | Couvert en reason code, mapping UI a creer. |
| `provider_error` | `catalogProviderError`, `iptvProviderError`. | Couvert en reason code, mapping UI a creer. |
| `credentials_invalid` | `catalogCredentialsInvalid`, `CatalogRefreshOutcome.credentialsInvalid`. | Contrat existe, emission depuis refresh IPTV a verifier. |
| `catalog_empty` | `catalogEmpty`, `CatalogMode.empty`. | Couvert. |
| `technical_failure` | `StartupFailureCode`, `bootTechnicalFailure`, `AppLaunchStatus.failure`. | Plusieurs sources a unifier pour UI. |
| `home_sections_failed` | `HomeDegradationKind.feedFailed`. | Couvert. |
| `library_failed` / reprise indisponible | `libraryPreloadTimeout`, `libraryPreloadFailed`. | Wording UI a clarifier. |
| `iptv_sections_empty` | `HomeDegradationKind.iptvSectionsEmpty`. | Couvert. |
| `multiple_degradations` | `ResolveHomeDegradation` retourne `homePartial` si plusieurs reason codes. | Couvert, mapping UI a creer. |

## Concepts reutilisables

- `CatalogMode`
- `RecoveryAction`
- `EntryDecision`
- `HomeReadiness`
- `SourceRecoveryRequired`
- `StartupRecoveryReasonCodes`
- `StartupRecoveryPlan`
- `ResolveEntryDecision`
- `ResolveCatalogReadiness`
- `ResolveHomeDegradation`
- `CatalogSnapshot`
- `SessionContractSnapshot`
- `ProfilesContractSnapshot`
- `SourcesContractSnapshot`
- `AppLaunchCriteria`

## Concepts a etendre ou adapter

- `AppLaunchPhase` : ajouter des sous-etats ou introduire un `BootScreenModel`
  derive pour catalog/home/recovery sans casser l'orchestrateur.
- `AppLaunchState` : peut rester source technique, mais l'UI a besoin d'un
  modele derive stable.
- `AppLaunchRecovery` : auth-centrique, ne pas l'utiliser tel quel pour tous
  les recoveries source/catalogue.
- `ResolveCatalogReadiness` : clarifier le traitement de `cached/stale`.
- Mapping `AppLaunchErrorCode -> CatalogRefreshOutcome` : ajouter/verifier
  credentials invalid.

## Concepts a ne pas dupliquer

- Ne pas creer un second enum de reason codes concurrent a
  `StartupRecoveryReasonCodes`.
- Ne pas creer une nouvelle destination parallele a `BootstrapDestination` sans
  strategie de migration.
- Ne pas creer une nouvelle state machine router qui ignore `TunnelState`.
- Ne pas encoder les actions UI en strings alors que `RecoveryAction` existe.
