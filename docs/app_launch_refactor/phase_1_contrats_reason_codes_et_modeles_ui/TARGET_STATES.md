# Normalisation des etats cibles

## Synthese

Les etats cibles se repartissent en cinq familles :

- etats de chargement non interactifs ;
- actions requises avant Home ;
- recovery source/catalogue avant Home ;
- ouverture Home nominale ;
- degradations Home apres ouverture.

La regle structurante est la suivante : une erreur source ou catalogue qui
empeche Home d'ouvrir reste une recovery avant Home. Une erreur de section Home
ou de bibliotheque apres ouverture devient une degradation Home partielle.

## Table de normalisation

| etat cible | categorie | visible utilisateur | contrat existant | ajout requis |
| --- | --- | --- | --- | --- |
| `technical_startup` | Type d'ecran UI + phase runtime technique. | Oui, chargement simple. | `AppStartupGate`, `StartupPhase`, `OverlaySplash`. | Ajouter une projection UI boot technique si `OverlaySplash` est remplace. Ne pas fusionner avec le tunnel applicatif. |
| `session_check` | Type d'ecran UI + sous-etat de `AppLaunchPhase.auth`. | Oui, chargement simple. | `AppLaunchPhase.auth`, `SessionContractSnapshot`, `ResolveEntryDecision`. | Ajouter un etat UI derive. Pas besoin de nouveau reason code si uniquement transitoire. |
| `auth_required` | Reason code + destination router + ecran action requise. | Oui, action requise. | `EntryDecisionReasonCodes.authRequired`, `StartupRecoveryReasonCodes.authRequired`, `RequireAuth`, `BootstrapDestination.auth`. | Harmoniser la source du reason code pour le mapper UI. |
| `profile_check` | Type d'ecran UI + sous-etat de `AppLaunchPhase.profiles`. | Oui, chargement simple. | `AppLaunchPhase.profiles`, `ProfilesContractSnapshot`. | Ajouter un etat UI derive. Pas besoin de destination. |
| `profile_required` | Reason code + destination router + ecran action requise. | Oui, action requise. | `EntryDecisionReasonCodes.profileRequired`, `StartupRecoveryReasonCodes.profileRequired`, `RequireProfile`, `BootstrapDestination.welcomeUser`. | Mapper vers action `RecoveryAction.createProfile`. |
| `profile_selection_required` | Reason code + destination router + ecran action requise. | Oui, action requise. | `EntryDecisionReasonCodes.profileSelectionRequired`, `StartupRecoveryReasonCodes.profileSelectionRequired`, `RequireProfile`, `BootstrapDestination.welcomeUser`. | Distinguer dans le mapper UI creation profil vs selection profil. |
| `source_check` | Type d'ecran UI + sous-etat de `AppLaunchPhase.sources` / `localAccounts` / `sourceSelection`. | Oui, chargement simple. | `AppLaunchPhase.sources`, `AppLaunchPhase.localAccounts`, `AppLaunchPhase.sourceSelection`, `SourcesContractSnapshot`. | Ajouter un etat UI derive, probablement sans nouveau reason code. |
| `source_required` | Reason code + destination router + ecran action requise. | Oui, action requise. | `EntryDecisionReasonCodes.sourceRequired`, `StartupRecoveryReasonCodes.sourceRequired`, `RequireSource`, `BootstrapDestination.welcomeSources`. | Mapper vers action `RecoveryAction.addSource`. |
| `source_selection_required` | Reason code + destination router + ecran action requise. | Oui, action requise. | `EntryDecisionReasonCodes.sourceSelectionRequired`, `StartupRecoveryReasonCodes.sourceSelectionRequired`, `RequireSourceSelection`, `BootstrapDestination.chooseSource`. | Mapper vers action `RecoveryAction.chooseSource`. |
| `catalog_preparing` | Phase runtime ou sous-etat UI + reason code loggable. | Oui, chargement catalogue. | Refresh cache dans `AppLaunchPhase.preloadCompleteHome`, `CatalogRefreshOutcome` apres coup. | Ajouter `AppLaunchPhase.catalogPreparing` ou un sous-etat UI derive. Ajouter `catalog_preparing` si un reason code loggable est necessaire. |
| `catalog_cached_ready` | Reason code + etat nominal ouvrable. | Eventuellement, bref `opening_home`; pas une erreur. | `CatalogMode.cached`, `CatalogMode.stale`, `HomePartial`, `StartupRecoveryReasonCodes.catalogSnapshotCached`, `catalogSnapshotStale`. | Decision dediee `cached/stale` : warning non bloquant ou ouverture silencieuse. |
| `catalog_snapshot_missing` | Reason code + declencheur preparation catalogue. | Non si refresh demarre immediatement; oui seulement si recovery sans refresh possible. | `CatalogMode.missing`, `StartupRecoveryReasonCodes.catalogSnapshotMissing`, `SourceRecoveryRequired`. | Normaliser : avant refresh, declenche `catalog_preparing`; apres echec/absence persistante, recovery source. |
| `source_timeout` | Reason code + recovery source avant Home. | Oui, recovery. | `CatalogRefreshOutcome.timedOut`, `StartupRecoveryReasonCodes.catalogSyncTimeout`, `SourceRecoveryRequired`. | Mapper vers ecran recovery source avec actions `retry` et `chooseSource`. |
| `provider_error` | Reason code + recovery source avant Home. | Oui, recovery. | `CatalogRefreshOutcome.providerError`, `StartupRecoveryReasonCodes.catalogProviderError`, `SourceRecoveryRequired`. | Mapper vers ecran recovery provider avec actions `retry` et `chooseSource`. |
| `credentials_invalid` | Reason code + recovery source avant Home. | Oui, recovery. | `CatalogRefreshOutcome.credentialsInvalid`, `StartupRecoveryReasonCodes.catalogCredentialsInvalid`, `SourceRecoveryRequired`. | Verifier emission runtime Xtream/Stalker. Mapper vers action `reconnectSource`. |
| `catalog_empty` | Reason code + recovery source avant Home. | Oui, recovery. | `CatalogMode.empty`, `CatalogRefreshOutcome.empty`, `StartupRecoveryReasonCodes.catalogEmpty`, `SourceRecoveryRequired`. | Mapper vers actions `resyncSource` et `chooseSource`. |
| `technical_failure` | Reason code + ecran failure/recovery. | Oui, recovery technique. | `TechnicalBootFailure`, `StartupRecoveryMapper`, `StartupRecoveryReasonCodes.bootTechnicalFailure`, `bootConfigTimeout`, `bootDependenciesTimeout`. | Mapper vers ecran technique. Les messages diagnostics ne doivent pas etre affiches tels quels. |
| `opening_home` | Type d'ecran UI + phase runtime derivee. | Oui, chargement simple bref. | `AppLaunchPhase.preloadCompleteHome`, `HomeReady`, `AppLaunchCriteria.hasHomePreloaded`, `hasLibraryReady`. | Ajouter un etat UI derive distinct de `catalog_preparing`. Reason code optionnel si log necessaire. |
| `home_ready` | Reason code + destination router. | Non en general, le router ouvre Home. | `HomeReady`, `StartupRecoveryReasonCodes.homeReady`, `BootstrapDestination.home`, `TunnelStage.readyForHome`. | Mapper vers destination Home. Pas besoin d'ecran si navigation immediate. |
| `home_sections_failed` | Degradation Home + notice Home partiel. | Oui, apres Home. | `HomeDegradationKind.feedFailed`, `StartupRecoveryReasonCodes.homeFeedFailed`, `HomePartial`. | Mapper vers banniere/notice Home partiel, pas vers recovery source. |
| `library_failed` | Degradation Home + notice Home partiel. | Oui, apres Home. | `HomeDegradationKind.libraryPreloadFailed`, `HomeDegradationKind.libraryPreloadTimeout`, `StartupRecoveryReasonCodes.libraryPreloadFailed`, `libraryPreloadTimeout`. | Mapper vers action `retryLibrary`. |
| `iptv_sections_empty` | Degradation Home + notice Home partiel. | Oui, apres Home. | `HomeDegradationKind.iptvSectionsEmpty`, `StartupRecoveryReasonCodes.homeIptvSectionsEmpty`, `HomePartial`. | Mapper vers actions `retryHomeSections` et `resyncSource`, sans bloquer Home. |
| `multiple_degradations` | Degradation Home agregatee + notice Home partiel. | Oui, apres Home. | `ResolveHomeDegradation` retourne `StartupRecoveryReasonCodes.homePartial` si plusieurs degradations. | Mapper vers notice Home partiel agregatee avec actions dedupliquees. |

## Etats internes

Ces etats ne doivent pas etre affiches comme libelles utilisateur bruts :

- `catalog_snapshot_missing` : signal technique qui declenche soit
  `catalog_preparing`, soit une recovery si aucune preparation utile n'est
  possible.
- `home_ready` : destination ou reason code de fin, pas un ecran long.
- reason codes `boot_config_timeout`, `boot_dependencies_timeout`,
  `catalog_provider_error`, `catalog_credentials_invalid` et similaires :
  utilisables pour logs/tests, jamais comme texte UI.
- `preloadCompleteHome` : phase runtime trop large, a decomposer par projection
  UI.

## Etats visibles utilisateur

Les etats suivants doivent produire un `BootScreenModel` ou une notice Home :

- `technical_startup` ;
- `session_check` ;
- `profile_check` ;
- `source_check` ;
- `catalog_preparing` ;
- `catalog_cached_ready` si la decision `cached/stale` retient un warning ou un
  message d'ouverture ;
- `auth_required` ;
- `profile_required` ;
- `profile_selection_required` ;
- `source_required` ;
- `source_selection_required` ;
- `source_timeout` ;
- `provider_error` ;
- `credentials_invalid` ;
- `catalog_empty` ;
- `technical_failure` ;
- `opening_home` ;
- `home_sections_failed` ;
- `library_failed` ;
- `iptv_sections_empty` ;
- `multiple_degradations`.

## Separation avant Home / apres Home

| famille | etats | contrat pivot | destination |
| --- | --- | --- | --- |
| Recovery source avant Home | `catalog_snapshot_missing`, `source_timeout`, `provider_error`, `credentials_invalid`, `catalog_empty`. | `SourceRecoveryRequired`. | Reste dans le boot ou routes source/recovery. |
| Home ouvrable | `catalog_cached_ready`, `opening_home`, `home_ready`. | `HomeReady` ou `HomePartial` avec snapshot exploitable. | `BootstrapDestination.home`. |
| Home partiel apres ouverture | `home_sections_failed`, `library_failed`, `iptv_sections_empty`, `multiple_degradations`. | `HomePartial` issu de `ResolveHomeDegradation`. | Home deja ouverte avec notice/banniere. |

## Decisions pour les etapes suivantes

- `catalog_preparing` doit devenir l'etat visible principal du premier run sans
  snapshot exploitable.
- `catalog_snapshot_missing` ne doit pas etre l'ecran utilisateur final du
  refresh nominal ; il reste un signal de detection ou de recovery.
- `catalog_cached_ready` et `catalog_snapshot_stale` restent ouvrables et ne
  doivent jamais devenir des erreurs source.
- `opening_home` doit etre separe de la preparation catalogue afin d'eviter un
  splash opaque pendant le preload Home/library.
- Les etats Home partiel restent apres la navigation Home et ne doivent pas
  renvoyer vers le tunnel de recovery source.

## Definition de fini - etape 2

- Tous les etats cibles ont une categorie.
- Les etats internes et les etats UI sont separes.
- Les etats Home partiel ne sont pas melanges avec la recovery source avant
  Home.
