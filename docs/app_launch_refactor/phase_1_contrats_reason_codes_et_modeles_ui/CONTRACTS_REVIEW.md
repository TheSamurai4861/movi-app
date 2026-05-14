# Relecture cible des contrats existants

## Synthese

Les contrats de domaine existants sont reutilisables pour la phase 1. Ils
couvrent deja :

- les modes catalogue exploitables ou non ;
- les actions de recovery comme intentions techniques ;
- les decisions d'entree auth/profil/source/Home ;
- la distinction entre source recovery avant Home et Home partiel apres Home ;
- les reason codes startup/catalogue/Home.

Le refactor ne doit donc pas introduire un second systeme de decision. La bonne
direction est d'ajouter une projection UI au-dessus de ces contrats, puis
d'etendre seulement les points qui restent implicites dans le runtime actuel.

## Table de decision

| concept | decision | justification | fichier cible | test concerne |
| --- | --- | --- | --- | --- |
| `CatalogMode` | Reutilisable tel quel. | Les valeurs `fresh`, `cached`, `stale`, `missing`, `empty`, `unavailable` couvrent les etats catalogue attendus et `canOpenHome` encode deja l'invariant Home rapide pour les snapshots exploitables. | `lib/src/core/startup/domain/boot_contracts.dart` | `test/core/startup/resolve_catalog_readiness_test.dart`, futur test `boot_ui_state_mapper_test.dart`. |
| `CatalogMode.canOpenHome` | A ne pas dupliquer. | C'est la regle canonique pour savoir si Home peut s'ouvrir avec un snapshot local. Le mapping UI doit la consommer, pas recreer sa propre logique. | `lib/src/core/startup/domain/boot_contracts.dart` | `test/core/startup/resolve_catalog_readiness_test.dart`. |
| `RecoveryAction` | Reutilisable tel quel. | L'enum decrit deja des intentions techniques et non des callbacks UI. Les actions Figma doivent se mapper vers ces valeurs. | `lib/src/core/startup/domain/boot_contracts.dart` | `test/core/startup/startup_recovery_mapper_test.dart`, futur test `boot_ui_state_mapper_test.dart`. |
| `RecoveryActionRules.hasPrimaryAction` | Reutilisable tel quel. | La regle empeche `exportLogs` d'etre l'unique action utile. Elle reste pertinente pour les ecrans recovery. | `lib/src/core/startup/domain/boot_contracts.dart` | `test/core/startup/startup_recovery_mapper_test.dart`. |
| `EntryDecision` | Reutilisable, a projeter vers UI. | Les sous-types `RequireAuth`, `RequireProfile`, `RequireSource`, `RequireSourceSelection`, `OpenHome` couvrent les destinations metier. Ils ne portent pas de titre/message utilisateur, ce qui est correct. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_entry_decision_test.dart`, futur test `boot_ui_state_mapper_test.dart`. |
| `RequireProfile` | A projeter vers UI. | Le meme type couvre creation et selection profil via le reason code. Ne pas creer un nouveau contrat domaine tant que `profile_required` et `profile_selection_required` suffisent. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_entry_decision_test.dart`. |
| `RequireSource` | A projeter vers UI. | Le type couvre source absente et catalogue non pret via reason code. La phase suivante doit clarifier le mapping UI pour eviter un message source generique. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_entry_decision_test.dart`, `test/core/startup/resolve_catalog_readiness_test.dart`. |
| `RequireSourceSelection` | Reutilisable, a projeter vers UI. | La distinction selection source existe deja. Elle doit devenir un ecran/action stable dans `BootScreenModel`. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_entry_decision_test.dart`. |
| `TechnicalBootFailure` | Reutilisable pour domaine, a projeter vers UI. | Le contrat porte reason code, message diagnostic et actions. Le message ne doit pas devenir le texte utilisateur final. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/startup_recovery_mapper_test.dart`. |
| `HomeReadiness` | Reutilisable tel quel. | Le sealed class separe correctement `HomeReady`, `HomePartial` et `SourceRecoveryRequired`. Cette separation est centrale pour la phase 1. | `lib/src/core/startup/domain/boot_contracts.dart` | `test/core/startup/resolve_catalog_readiness_test.dart`, `test/core/startup/resolve_home_degradation_test.dart`. |
| `HomeReady` | Reutilisable tel quel. | Represente Home ouvrable sans action recovery. Le futur UI mapper peut l'afficher comme `opening_home` ou ne rien afficher si le router ouvre Home immediatement. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_home_degradation_test.dart`. |
| `HomePartial` | Reutilisable, a projeter vers UI. | Represente une Home ouvrable avec degradations/actions. Il ne doit pas etre confondu avec une recovery source avant Home. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_home_degradation_test.dart`. |
| `SourceRecoveryRequired` | Reutilisable, a projeter vers UI. | C'est le bon contrat pour timeout/provider/credentials/catalogue vide avant Home. Les ecrans Figma recovery doivent se brancher dessus. | `lib/src/core/startup/domain/boot_contracts.dart`, futur mapper UI | `test/core/startup/resolve_catalog_readiness_test.dart`. |
| `CatalogSnapshot` | Reutilisable tel quel. | Decrit un snapshot local deja lu, sans dependance storage/reseau. L'age nullable permet de reporter la decision freshness. | `lib/src/core/startup/domain/catalog_snapshot_contracts.dart` | `test/core/startup/catalog_snapshot_test.dart`, `test/core/startup/resolve_catalog_readiness_test.dart`. |
| `SessionContractSnapshot` | Reutilisable tel quel. | Contractualise la session lue par l'adapter. La decision auth reste dans `ResolveEntryDecision`. | `lib/src/core/startup/domain/entry_journey_contracts.dart` | `test/core/startup/resolve_entry_decision_test.dart`. |
| `ProfilesContractSnapshot` | Reutilisable tel quel. | Donne le nombre et la validite de selection. Suffisant pour `profile_required` et `profile_selection_required`. | `lib/src/core/startup/domain/entry_journey_contracts.dart` | `test/core/startup/resolve_entry_decision_test.dart`. |
| `SourcesContractSnapshot` | Reutilisable tel quel. | Couvre sources locales/distantes, selection valide et selection manuelle. Suffisant pour source requise ou selection source. | `lib/src/core/startup/domain/entry_journey_contracts.dart` | `test/core/startup/resolve_entry_decision_test.dart`. |
| `ResolveEntryDecision` | Reutilisable, a completer par projection UI. | Le resolver pur couvre auth/profil/source/Home et conserve le local-first. Le reason code `catalog_not_ready_for_entry` reste temporaire et doit etre mappe prudemment. | `lib/src/core/startup/domain/resolve_entry_decision.dart`, futur mapper UI | `test/core/startup/resolve_entry_decision_test.dart`. |
| `EntryDecisionReasonCodes` | A ne pas dupliquer, a harmoniser. | Certains codes recoupent `StartupRecoveryReasonCodes`. La phase 1 doit choisir une source de codes pour le mapping UI ou documenter le pont, pas creer de nouvelles constantes paralleles. | `lib/src/core/startup/domain/resolve_entry_decision.dart`, `lib/src/core/startup/domain/startup_recovery_mapper.dart` | `test/core/startup/resolve_entry_decision_test.dart`, futur test `boot_ui_state_mapper_test.dart`. |
| `CatalogRefreshOutcome` | Reutilisable, emission runtime a verifier. | Les outcomes attendus existent, y compris `credentialsInvalid`. Le point faible est l'emission depuis Xtream/Stalker, pas le contrat. | `lib/src/core/startup/domain/resolve_catalog_readiness.dart` | `test/core/startup/resolve_catalog_readiness_test.dart`, futur test `app_launch_orchestrator_credentials_invalid_test.dart`. |
| `ResolveCatalogReadiness` | Reutilisable, decision `cached/stale` a documenter. | Le resolver separe snapshot ouvrable et recovery source. Il traite `cached/stale` comme `HomePartial` avec resync, ce qui doit etre confirme comme warning ou simple ouverture Home. | `lib/src/core/startup/domain/resolve_catalog_readiness.dart`, futur mapper UI | `test/core/startup/resolve_catalog_readiness_test.dart`. |
| `HomeDegradationKind` | Reutilisable tel quel. | Les degradations Home connues sont listees sans melanger source/catalogue. | `lib/src/core/startup/domain/resolve_home_degradation.dart` | `test/core/startup/resolve_home_degradation_test.dart`. |
| `ResolveHomeDegradation` | Reutilisable tel quel. | Le resolver convertit les degradations Home en `HomeReady` ou `HomePartial`, avec actions combinees. | `lib/src/core/startup/domain/resolve_home_degradation.dart` | `test/core/startup/resolve_home_degradation_test.dart`. |
| `StartupRecoveryReasonCodes` | A ne pas dupliquer, a etendre seulement si necessaire. | La liste couvre deja boot technique, auth/profil/source, catalogue, Home et library. Manque possible : reason code explicite `catalog_preparing` si l'etat devient visible/loggable. | `lib/src/core/startup/domain/startup_recovery_mapper.dart` | `test/core/startup/startup_recovery_mapper_test.dart`, futur test `boot_ui_state_mapper_test.dart`. |
| `StartupRecoveryMapper` | Reutilisable pour recovery technique, a projeter vers UI. | Le mapper produit un plan log-safe/actions, mais ses `message` sont diagnostics non localises. Ne pas les afficher comme texte Figma. | `lib/src/core/startup/domain/startup_recovery_mapper.dart`, futur mapper UI | `test/core/startup/startup_recovery_mapper_test.dart`. |
| `AppLaunchStatus` | Reutilisable tel quel. | Les statuts `idle/running/success/failure` suffisent pour le cycle d'execution. | `lib/src/core/startup/app_launch_orchestrator.dart` | Tests orchestrateur existants, futur test projection UI. |
| `AppLaunchPhase` | A etendre ou projeter. | `preloadCompleteHome` concentre preparation catalogue, snapshot ready, preload Home et preload library. Il faut ajouter `catalogPreparing` ou exposer un sous-etat derive. | `lib/src/core/startup/app_launch_orchestrator.dart`, futur modele UI | Tests orchestrateur existants, futur test `boot_ui_state_mapper_test.dart`. |
| `AppLaunchRecovery` | A etendre ou remplacer par projection UI. | Le modele actuel est auth-centrique (`AuthFailureCode cause`) et ne couvre pas proprement source/catalogue/Home partial comme contrat UI. | `lib/src/core/startup/app_launch_orchestrator.dart`, futur modele UI | Tests orchestrateur existants, futur test recovery UI. |
| `AppLaunchState` | Reutilisable comme runtime, a projeter vers UI. | Porte statut, phase, destination, criteria, recovery et run id. Il ne doit pas devenir un modele d'affichage avec textes localises. | `lib/src/core/startup/app_launch_orchestrator.dart`, futur provider `BootScreenModel` | Tests orchestrateur existants, futur test projection UI. |
| `AppLaunchCriteria` | Reutilisable, a ne pas surcharger. | Les boolens sont utiles pour router/projection, mais pas assez expressifs pour distinguer les sous-etats catalogue. Ne pas y ajouter des textes ou reason codes. | `lib/src/core/startup/app_launch_criteria.dart` | Tests orchestrateur existants, `test/core/startup/canonical_tunnel_state_projector_test.dart`. |
| `TunnelState` | Reutilisable pour routage projete, pas comme modele UI final. | Il resume le tunnel pour router/flags V2, mais ses stages sont trop grossiers pour les ecrans Figma. | `lib/src/core/startup/domain/tunnel_state.dart`, `lib/src/core/startup/canonical_tunnel_state_projector.dart` | `test/core/startup/canonical_tunnel_state_projector_test.dart`. |
| `CanonicalTunnelStateProjector` | A conserver, peut consommer les nouveaux etats. | Il fait le pont `AppLaunchState -> TunnelState`. Il ne doit pas devenir le mapper Figma, mais devra rester coherent avec lui. | `lib/src/core/startup/canonical_tunnel_state_projector.dart` | `test/core/startup/canonical_tunnel_state_projector_test.dart`. |

## Contrats a conserver

- `CatalogMode` et `CatalogMode.canOpenHome`.
- `RecoveryAction`.
- `EntryDecision` et ses sous-types.
- `HomeReadiness` et ses sous-types.
- `CatalogSnapshot`.
- `SessionContractSnapshot`, `ProfilesContractSnapshot`,
  `SourcesContractSnapshot`.
- `ResolveEntryDecision`.
- `ResolveCatalogReadiness`.
- `ResolveHomeDegradation`.
- `StartupRecoveryReasonCodes`, comme source principale des reason codes
  startup/catalogue/Home.
- `AppLaunchState`, comme etat runtime.
- `AppLaunchCriteria`, comme criteres runtime/router.

## Contrats a modifier ou completer avec prudence

- `AppLaunchPhase` : ajouter `catalogPreparing` ou conserver les phases et
  exposer un sous-etat UI derive. La decision doit etre prise avant Phase 2.
- `StartupRecoveryReasonCodes` : ajouter seulement les codes manquants
  indispensables, par exemple `catalog_preparing` si l'etat est loggable.
- `AppLaunchRecovery` : ne pas l'etendre aveuglement pour tout le boot. Preferer
  un modele UI separe ou un plan recovery generique si le besoin se confirme.
- `ResolveCatalogReadiness` : ne pas changer le comportement `cached/stale`
  avant la decision dediee. Le contrat actuel ouvre Home via `HomePartial`.
- Emission `CatalogRefreshOutcome.credentialsInvalid` : verifier le runtime
  Xtream/Stalker avant d'ajouter un nouveau mapping.

## Concepts a projeter vers UI

- `EntryDecision` vers ecrans action requise.
- `HomeReadiness` vers Home ready, Home partial ou source recovery.
- `StartupRecoveryPlan` vers ecran technical failure ou recovery.
- `AppLaunchState` vers `BootScreenModel`.
- `TunnelState` seulement comme aide router, pas comme renderer Figma.

## Concepts a ne pas dupliquer

- `CatalogMode.canOpenHome`.
- `RecoveryAction`.
- `StartupRecoveryReasonCodes`.
- `EntryDecisionReasonCodes` sans decision d'harmonisation.
- `BootstrapDestination`.
- `HomeReadiness`.
- `TunnelState`.

## Points d'attention pour l'etape suivante

- La normalisation des etats cibles doit choisir quels etats sont des reason
  codes et quels etats sont seulement des types d'ecran.
- `catalog_not_ready_for_entry` est marque temporaire dans le code. Il doit etre
  remplace ou mappe explicitement avant l'UI finale.
- `cached/stale` sont deja ouvrables. Toute UI de warning doit rester non
  bloquante.
- Les messages de `StartupRecoveryPlan.message` sont diagnostics et non
  localises. Ils ne doivent pas etre repris tels quels dans `BootScreenModel`.

## Definition de fini - etape 1

- Les contrats a conserver sont identifies.
- Les contrats a modifier sont limites au strict necessaire.
- Aucun doublon de concept n'est introduit dans le plan.
