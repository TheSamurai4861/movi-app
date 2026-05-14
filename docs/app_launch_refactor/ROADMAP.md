# Roadmap complete - Refactor du boot

## Objectif

Cette roadmap couvre le refactor complet du boot Movi, depuis la decision
technique jusqu'a l'UI finale affichee a l'utilisateur.

Le chantier ne doit pas reconstruire le boot depuis zero. Le code contient deja
une base importante dans `lib/src/core/startup` :

- contrats de boot et reason codes ;
- orchestration `AppLaunchOrchestrator` ;
- resolution session/profil/source/catalogue ;
- mapping recovery partiel ;
- surfaces legacy comme `SplashBootstrapPage`, `WelcomeSourceLoadingPage`,
  `LaunchErrorPanel` et `LaunchRecoveryBanner`.

Le refactor doit donc consolider l'existant, combler les trous, puis remplacer
les surfaces generiques par les ecrans Figma.

## Phase 0 - Audit et gel du comportement actuel

### But

Stabiliser le point de depart avant toute modification structurante.

### Actions

- Lister les chemins de boot actuels depuis `main` jusqu'a Home.
- Identifier toutes les destinations router impliquees :
  - `launch` ;
  - `auth` ;
  - `welcomeUser` ;
  - `welcomeSources` ;
  - `welcomeSourceSelect` ;
  - `welcomeSourceLoading` ;
  - `home`.
- Cartographier les widgets legacy du boot :
  - `SplashBootstrapPage` ;
  - `WelcomeSourcePage` ;
  - `WelcomeSourceSelectPage` ;
  - `WelcomeSourceLoadingPage` ;
  - `LaunchErrorPanel` ;
  - `LaunchRecoveryBanner` ;
  - `OverlaySplash`.
- Cartographier les contrats existants :
  - `BootContracts` ;
  - `EntryDecision` ;
  - `HomeReadiness` ;
  - `CatalogMode` ;
  - `StartupRecoveryReasonCodes` ;
  - `AppLaunchState` ;
  - `AppLaunchPhase` ;
  - `AppLaunchRecovery`.
- Verifier les tests existants lies au boot, au router et au welcome flow.
- Documenter les comportements actuels a preserver :
  - ouverture Home rapide avec snapshot exploitable ;
  - redirection auth si session requise ;
  - creation/selection profil ;
  - ajout/selection source ;
  - Home partiel pour erreurs non critiques.

### Livrables

- Table `chemin actuel -> destination -> widget -> reason code si disponible`.
- Liste des doublons entre orchestrateur et widgets.
- Liste des messages generiques a supprimer.

### Definition de fini

- Les chemins existants sont connus.
- Les fichiers a modifier sont identifies.
- Les comportements a ne pas casser sont explicites.

## Phase 1 - Contrats, reason codes et modeles UI

### But

Transformer les decisions de boot en contrat stable entre orchestration,
routage et UI.

### Actions

- Conserver les contrats existants quand ils sont suffisants.
- Ajouter les etats manquants au lieu de creer un second systeme parallele.
- Introduire ou completer un modele UI dedie, par exemple `BootScreenModel`.
- Mapper chaque etat technique vers :
  - un type d'ecran ;
  - un titre utilisateur ;
  - un message ;
  - un sous-message optionnel ;
  - une action principale ;
  - une action secondaire optionnelle ;
  - une destination router ;
  - un reason code log-safe.
- Ajouter un etat explicite de preparation catalogue :
  - `catalogPreparing` ou equivalent dans `AppLaunchPhase` ;
  - reason code visible dans les logs mais jamais affiche brut.
- Clarifier `catalogSnapshotCached` et `catalogSnapshotStale` :
  - un snapshot exploitable doit permettre Home rapidement ;
  - l'UI peut afficher un bref etat `Ouverture de l'accueil` ;
  - ce cas ne doit pas etre traite comme une erreur source.
- Verifier que `catalogCredentialsInvalid` peut etre emis depuis les erreurs
  IPTV reelles.
- Distinguer clairement :
  - source recovery avant Home ;
  - Home partiel apres ouverture Home.

### Etats cibles minimaux

- `technical_startup`
- `session_check`
- `auth_required`
- `profile_check`
- `profile_required`
- `profile_selection_required`
- `source_check`
- `source_required`
- `source_selection_required`
- `catalog_preparing`
- `catalog_cached_ready`
- `catalog_snapshot_missing`
- `source_timeout`
- `provider_error`
- `credentials_invalid`
- `catalog_empty`
- `technical_failure`
- `opening_home`
- `home_ready`
- `home_sections_failed`
- `library_failed`
- `iptv_sections_empty`
- `multiple_degradations`

### Livrables

- Table `reason code -> screen model -> actions -> destination`.
- Tests unitaires du mapping.
- Decision documentee sur `cached/stale`: ouverture Home rapide ou warning.

### Definition de fini

- Aucun etat utilisateur important ne depend d'une erreur generique.
- Chaque action Figma a une intention technique stable.
- Les codes internes ne sont pas exposes dans les textes UI.

## Phase 2 - Orchestration et routage

### But

Faire de l'orchestrateur la source de verite du boot, et eviter les navigations
concurrentes depuis les widgets.

### Actions

- Verifier `LaunchRedirectGuard` et son interaction avec
  `AppLaunchOrchestrator`.
- Definir qui decide la destination finale :
  - l'orchestrateur pour les decisions boot ;
  - le router pour appliquer la destination ;
  - les pages d'action pour collecter les donnees utilisateur.
- Centraliser l'execution des actions boot :
  - `retry` ;
  - `exportLogs` ;
  - `login` ;
  - `createProfile` ;
  - `chooseProfile` ;
  - `addSource` ;
  - `chooseSource` ;
  - `reconnectSource` ;
  - `resyncSource` ;
  - `retryHomeSections` ;
  - `retryLibrary`.
- Remplacer les navigations directes dispersees quand elles representent une
  decision boot.
- Garder les pages auth existantes proprietaires du login/signup/reset sauf
  decision produit contraire.
- Garder les pages profil/source existantes proprietaires de la saisie metier,
  mais les raccorder aux actions boot.
- Prevoir un flag de rollout si necessaire :
  - nouveau renderer boot ;
  - ancien tunnel en fallback ;
  - rollback simple.

### Livrables

- Contrat `BootActionHandler` ou equivalent.
- Tests router pour chaque destination boot.
- Table `action -> handler -> route/controller`.

### Definition de fini

- Une seule couche decide les transitions boot.
- Les widgets n'embarquent plus de logique catalogue critique.
- Le bouton principal de chaque ecran produit une action testable.

## Phase 3 - Catalogue, source recovery et Home readiness

### But

Regler le probleme principal observe : un snapshot absent ne doit plus produire
une attente opaque de 10 secondes.

### Actions

- Auditer la lecture snapshot :
  - source active ;
  - snapshot present ;
  - snapshot exploitable ;
  - snapshot vide ;
  - snapshot indisponible.
- Garantir que le refresh reussi persiste un snapshot exploitable.
- Separar les chemins :
  - snapshot exploitable -> Home rapide ;
  - snapshot absent -> ecran `Preparation du catalogue` ;
  - refresh timeout -> recovery `La source ne repond pas` ;
  - provider error -> recovery `Impossible de charger la source` ;
  - credentials invalides -> recovery `Connexion a la source impossible` ;
  - catalogue vide -> recovery `Aucun contenu trouve`.
- Ajouter un timeout explicite pour le refresh bloquant.
- Prevoir une action secondaire prudente apres delai :
  - `Changer de source`.
- Verifier le second run apres refresh :
  - `catalog_snapshot_cached` doit eviter un nouveau blocage long.
- Conserver les syncs de fond sans bloquer Home si un snapshot exploitable
  existe.

### Livrables

- Tests unitaires `ResolveCatalogReadiness`.
- Tests orchestrateur pour refresh success/timeout/provider/empty.
- Logs de transition catalogue lisibles.

### Definition de fini

- Premier run sans snapshot affiche `catalog_preparing`.
- Refresh reussi ouvre Home et persiste le snapshot.
- Second run avec snapshot ouvre Home rapidement.
- Les erreurs source ne sont pas confondues avec Home partiel.

## Phase 4 - UI boot et composants

### But

Implementer les ecrans Figma en reutilisant les composants existants quand ils
sont adaptes.

### Composants a reutiliser ou adapter

- Logo :
  - reutiliser `MoviAssetIcon` ;
  - utiliser `AppAssets.iconAppLogoSvg` ;
  - ne pas implementer le rectangle Figma comme forme finale.
- Bouton :
  - partir de `MoviPrimaryButton` ;
  - ajouter une variante boot si necessaire ;
  - respecter largeur/hauteur Figma sur mobile ;
  - conserver l'etat focus TV.
- Text input :
  - partir de `AppLabeledTextField` ;
  - aligner radius, hauteur, padding et couleurs avec le composant Figma.
- Avatar profil :
  - partir de `ProfileAvatarChip` ;
  - ajouter une variante initiale + nom si necessaire.
- Splash :
  - repartir de `OverlaySplash` ;
  - conserver logo centre et texte bas ecran pour les etats simples.
- Recovery :
  - remplacer ou envelopper `LaunchErrorPanel` ;
  - remplacer ou envelopper `LaunchRecoveryBanner`.

### Ecrans a implementer

- Chargement simple avec logo centre et texte bas ecran :
  - demarrage technique ;
  - verification session ;
  - resolution profil ;
  - resolution source ;
  - ouverture Home.
- Chargement enrichi :
  - preparation catalogue ;
  - catalogue pret en cache.
- Recovery action panel :
  - erreur technique boot ;
  - source timeout ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide ;
  - profil requis ;
  - source requise ;
  - selection source requise.
- Pages d'action raccordees :
  - connexion ;
  - inscription ;
  - mot de passe oublie ;
  - creation profil ;
  - selection profil ;
  - ajout source ;
  - selection source.
- Banniere Home partiel :
  - sections Home en erreur ;
  - reprise/bibliotheque indisponible ;
  - sections IPTV vides ;
  - degradations multiples.

### Contraintes responsive et focus

- Mobile :
  - suivre les JSON `393x852` comme reference.
- Desktop :
  - largeur de contenu contrainte ;
  - eviter les formulaires trop larges.
- TV :
  - focus initial sur l'action principale ;
  - navigation haut/bas/gauche/droite explicite ;
  - texte lisible a distance ;
  - aucun bouton non atteignable au clavier.

### Livrables

- Widgets boot reutilisables.
- Renderer `BootScreenModel -> Widget`.
- Tests widget pour les ecrans critiques.
- Verification manuelle mobile, desktop et TV/focus.

### Definition de fini

- Les ecrans Figma critiques existent dans Flutter.
- Le logo utilise l'asset reel.
- Les etats simples ont bien texte bas ecran hors du flux logo centre.
- Les actions sont focusables et testables.

## Phase 5 - Nettoyage legacy et migration

### But

Supprimer les doublons et empecher l'ancien boot de continuer a afficher des
messages contradictoires.

### Nature

Implementation + refactor progressif, avec suppression ciblee du legacy quand
la couverture fonctionnelle du boot unifie est confirmee.

### Plan d'execution

#### Etape 5.1 - Cartographie legacy

- Lister les surfaces boot coexistantes :
  - `SplashBootstrapPage` ;
  - `LaunchErrorPanel` ;
  - `LaunchRecoveryBanner` ;
  - `OverlaySplash` ;
  - `WelcomeSourceLoadingPage`.
- Documenter pour chaque surface :
  - etats affiches ;
  - dependances (providers, routes, bridges) ;
  - remplaçant cible (renderer/surface unifiee ou conservation).

Sortie 5.1:

```text
docs/app_launch_refactor/phase_5_nettoyage_legacy_et_migration/CARTOGRAPHIE_LEGACY.md
```

#### Etape 5.2 - Migration renderer boot

- Brancher le renderer boot unifie comme chemin principal du tunnel.
- Conserver une strategie de repli temporaire si une route legacy est encore
  necessaire.
- Verifier qu'un meme etat boot ne peut pas afficher 2 surfaces concurrentes.

Sortie 5.2:

```text
lib/src/core/startup/presentation/widgets/boot_screen_renderer.dart
test/core/startup/boot_screen_renderer_test.dart
```

Statut 5.2:

- Renderer boot presentation-only ajoute (`BootScreenRenderer`).
- `SplashBootstrapPage` branche sur ce renderer (chemin principal).
- Strategie de repli conservee via routes legacy encore actives
  (`/welcome/sources/loading` et banners welcome/shell), traitees en 5.3/5.4.

#### Etape 5.3 - Nettoyage pages source legacy

- Reduire `WelcomeSourceLoadingPage` :
  - retirer la logique catalogue critique du widget ;
  - conserver uniquement la presentation si elle reste utile ;
  - sinon supprimer la page.
- Harmoniser `WelcomeSourcePage` et `WelcomeSourceSelectPage` avec les
  composants boot design.
- Eviter de supprimer les pages auth/profil/source encore utiles hors tunnel
  boot.

Sortie 5.3:

```text
lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart
docs/app_launch_refactor/phase_5_nettoyage_legacy_et_migration/WELCOME_SOURCE_LOADING_MIGRATION.md
```

Statut 5.3:

- `WelcomeSourceLoadingPage` reduite a une surface de transition (bridge) ;
- logique catalogue critique retiree du widget ;
- route legacy conservee temporairement pour compatibilite (a trier en 5.4).

#### Etape 5.4 - Routes et navigation

- Auditer les routes obsoletes :
  - garder les routes correspondant a une vraie page d'action ;
  - supprimer ou rediriger celles devenues purement legacy.
- Verifier que les destinations boot restent stables en mode nominal.

Sortie 5.4:

```text
docs/app_launch_refactor/phase_5_nettoyage_legacy_et_migration/ROUTES_AUDIT.md
```

Statut 5.4:

- route `/welcome/sources/loading` redirigee vers `/launch` ;
- planner `resyncSource` aligne sur `/launch` ;
- guard/router tests mis a jour et valides.

#### Etape 5.5 - Textes et messages contradictoires

- Supprimer/remplacer les messages generiques restants dans le boot :
  - `Preparation de l'accueil...` ;
  - `Impossible de preparer la page d'accueil` ;
  - `Erreur inconnue`.
- Verifier qu'aucun message legacy ne contredit l'etat rendu par le mapper.

Sortie 5.5:

```text
docs/app_launch_refactor/phase_5_nettoyage_legacy_et_migration/BOOT_TEXTS_CLEANUP.md
```

Statut 5.5:

- textes generiques supprimes/remplaces dans les surfaces boot/welcome cibles ;
- messages d'erreur contextualises (`welcome_source_select`, `welcome_user`) ;
- l10n boot fr/en ajuste (`overlayPreparingHome`, `errorPrepareHome`).

#### Etape 5.6 - Bridges, flags et dette technique

- Nettoyer les flags de migration et bridges temporaires devenus inutiles.
- Supprimer les points d'entree legacy non references.
- Laisser des TODO explicites pour ce qui est reporte en phases 6/7.

Sortie 5.6:

```text
docs/app_launch_refactor/phase_5_nettoyage_legacy_et_migration/BRIDGES_AND_FLAGS_CLEANUP.md
```

Statut 5.6:

- point d'entree legacy `WelcomeSourceLoadingPage` retire du runtime ;
- route `/welcome/sources/loading` conservee en redirection explicite vers
  `/launch` ;
- TODO phases 6/7 documentes (localisation/logs + scenarios E2E).

### Validation

- Executer les tests startup/core et router impactes.
- Ajouter des tests de non-regression navigation quand une route est supprimee
  ou redirigee.
- Verifier manuellement les parcours critiques :
  - lancement nominal vers Home ;
  - source requise ;
  - source en echec ;
  - reprise apres retry.

### Livrables

- Liste des widgets/pages legacy :
  - supprimes ;
  - remplaces ;
  - conserves (avec justification).
- Tableau des routes :
  - conservee ;
  - redirigee ;
  - supprimee.
- Suppression des messages generiques contradictoires dans le boot.
- Tests de non-regression router et startup mis a jour.
- Note de migration indiquant ce qui est reporte en phase 6 et phase 7.

### Definition de fini

- Il n'existe plus deux surfaces concurrentes pour le meme etat boot.
- La logique catalogue n'est plus dupliquee entre orchestrateur et UI.
- Le parcours utilisateur reste identique quand tout va bien.
- Toute route legacy retiree est couverte par un test ou une redirection
  explicite.
- Les surfaces legacy conservees sont justifiees et planifiees pour la suite.

## Phase 6 - Localisation, logs et observabilite

### But

Rendre le boot lisible pour l'utilisateur et diagnosticable pour le
developpeur.

### Nature

Implementation + instrumentation + documentation. Cette phase normalise les
textes utilisateur et la telemetrie sans changer la logique metier du tunnel.

### Plan d'execution

#### Etape 6.1 - Inventaire textes boot

- Lister les textes visibles dans :
  - mapper boot ;
  - widgets boot ;
  - pages welcome liees au tunnel ;
  - messages d'erreur startup.
- Identifier les strings encore codees en dur.
- Classer les textes :
  - utilisateur final ;
  - diagnostic dev ;
  - details debug uniquement.

Sortie 6.1:

```text
docs/app_launch_refactor/phase_6_localisation_logs_et_observabilite/TEXTS_INVENTORY.md
```

Statut 6.1:

- inventaire des textes boot/welcome produit ;
- classification UI vs diagnostic documentee ;
- backlog actionnable prepare pour 6.2.

#### Etape 6.2 - Localisation (l10n)

- Ajouter les cles `l10n` pour tous les textes boot manquants.
- Remplacer les strings en dur dans les surfaces boot/welcome ciblees.
- Corriger les textes issus des JSON avec encodage altere.
- Garder des messages courts, actionnables et non techniques.
- Verifier qu'aucun reason code interne n'est affiche a l'utilisateur.

Sortie 6.2:

```text
docs/app_launch_refactor/phase_6_localisation_logs_et_observabilite/BOOT_L10N_MIGRATION.md
```

Statut 6.2:

- cles l10n boot/welcome completees (FR/EN) ;
- rendu boot localise centralise via `boot_screen_localizer.dart` ;
- hardcodes critiques supprimes dans `launch_recovery_banner`,
  `welcome_source_page` et `welcome_user_page` ;
- validations analyse/tests ciblees passees.

#### Etape 6.3 - Contrat d'evenements logs

- Definir les evenements structurels :
  - `boot_state_changed` ;
  - `boot_action_triggered` ;
  - `catalog_preparation_started` ;
  - `catalog_preparation_completed` ;
  - `catalog_preparation_failed` ;
  - `boot_recovery_shown` ;
  - `home_partial_shown` ;
  - `entry_journey_completed`.
- Definir le schema minimal commun :
  - `run_id` ;
  - `phase` ;
  - `reason_code` ;
  - `duration_ms` (si dispo) ;
  - `destination` (si dispo) ;
  - `action` (si dispo).

Sortie 6.3:

```text
docs/app_launch_refactor/phase_6_localisation_logs_et_observabilite/BOOT_EVENTS_CONTRACT.md
```

Statut 6.3:

- contrat d'evenements boot formalise (table event -> source d'emission) ;
- schema commun `run_id/phase/reason_code/duration_ms/destination/action`
  applique via `boot_event_contract_logger.dart` ;
- instrumentation de base branchee sur:
  - transitions de phase (`boot_state_changed`) ;
  - actions boot (`boot_action_triggered`) ;
  - transitions catalogue (`catalog_preparation_*`) ;
  - surfaces recovery/home partial ;
  - fin de run (`entry_journey_completed`) ;
- compatibilite legacy preservee (`startup` + `entry_journey` conserves).

#### Etape 6.4 - Instrumentation runtime

- Brancher l'emission des evenements aux transitions critiques du tunnel.
- Eviter les doublons d'evenements sur une meme transition.
- Conserver la compatibilite avec les logs existants tant que la migration n'est
  pas terminee.

Sortie 6.4:

```text
docs/app_launch_refactor/phase_6_localisation_logs_et_observabilite/BOOT_RUNTIME_INSTRUMENTATION.md
```

Statut 6.4:

- helper runtime `_emitContractEvent` centralise dans l'orchestrateur ;
- dedupe par run activee via `_contractEventKey` +
  `_emittedContractEventKeys` ;
- emissions critiques validees sur:
  - transitions de phase ;
  - transitions catalogue ;
  - recoveries auth/source/technique ;
  - affichage Home partiel ;
  - completion de run ;
- compatibilite legacy maintenue (`startup` + `entry_journey` preserves).

#### Etape 6.5 - Reduction du bruit

- Reduire/filtrer les logs hors diagnostic cible :
  - `home_hero_debug` ;
  - rafales `image_pipeline` ;
  - logs de focus recherche ;
  - bruit Flutter Windows isolable.
- Garder les traces necessaires pour deboguer un run boot complet.

Sortie 6.5:

```text
docs/app_launch_refactor/phase_6_localisation_logs_et_observabilite/BOOT_NOISE_REDUCTION.md
```

Statut 6.5:

- filtrage categorie applique pour `home_hero_debug` et `image_pipeline`
  (sampling + rate-limit + min level par environnement) ;
- erreurs `image_pipeline` relevees en `warn` pour rester visibles ;
- traces focus recherche desactivees par defaut, reactivables avec
  `SEARCH_FOCUS_DEBUG=true` ;
- logs startup critiques preserves (`startup`, `entry_journey`,
  `startup_contract`).

#### Etape 6.6 - Validation et garde-fous

- Ajouter/mettre a jour tests ou snapshots de logs pour les transitions
  critiques.
- Verifier que les messages utilisateurs ne contiennent pas de details reseau
  bruts ou d'identifiants internes.
- Verifier qu'un run boot est lisible du debut a la fin avec le `run_id`.

Sortie 6.6:

```text
docs/app_launch_refactor/phase_6_localisation_logs_et_observabilite/BOOT_VALIDATION_GUARDRAILS.md
```

Statut 6.6:

- tests/snapshots de logs critiques ajoutes sur `startup_contract` ;
- coherence `run_id` verifiee sur run complet ;
- garde-fou anti-fuite ajoute sur UI boot critique (pas d'URL brute ni
  d'identifiant interne) ;
- verification non-regression reasonCode conservee.

### Validation

- Executer les tests startup/core impactes.
- Executer les tests widget des ecrans boot critiques apres remplacement des
  textes.
- Ajouter une verification de non-regression sur les reason codes exposes aux
  logs.

### Livrables

- Cles de traduction boot (`l10n`) completees.
- Table des evenements logs (nom, schema, source d'emission).
- Tests/snapshots de logs pour transitions critiques.
- Note de reduction du bruit (sources reduites et justifications).

### Definition de fini

- Un run boot peut etre lu sans details reseau bruts.
- Les reason codes sont stables.
- Aucun code interne n'est affiche a l'utilisateur.
- Les evenements critiques du tunnel sont traces avec un schema coherent.

## Phase 7 - Tests automatises et validation runtime

### But

Valider le boot complet sur les chemins critiques, pas seulement le chemin
nominal.

### Nature

Consolidation qualite (tests + runs cibles) pour valider les decisions boot et
securiser les regressions avant cloture documentaire.

### Plan d'execution

#### Etape 7.1 - Couverture unitaire contrats de decision

- Completer/valider les tests de decision :
  - `ResolveEntryDecision` (auth/profil/source/Home) ;
  - `ResolveCatalogReadiness` (fresh/cached/stale/missing/unavailable/timeout/provider/credentials/empty) ;
  - `StartupRecoveryMapper` (boot failure + recoveries source + Home partiel) ;
  - `BootScreenModel` (reason code -> ecran + action principale).

Sortie 7.1:

```text
test/core/startup/resolve_entry_decision_test.dart
test/core/startup/resolve_catalog_readiness_test.dart
test/core/startup/startup_recovery_mapper_test.dart
test/core/startup/boot_screen_mapper_test.dart
docs/app_launch_refactor/phase_7_tests_automatises_et_validation_runtime/UNIT_TEST_CONTRACT_COVERAGE.md
```

Statut 7.1:

- suites unitaires critiques executees et vertes ;
- couverture des cas de decision/recovery/mappeur validee ;
- garde-fou non-fuite `reasonCode` confirme via tests.

#### Etape 7.2 - Couverture widget des surfaces critiques

- Verifier les widgets boot:
  - chargements simples (logo, texte, pas d'action) ;
  - preparation catalogue (titre/message/sous-message) ;
  - recovery (actions et focus) ;
  - Home partial banner (message/action/comportement compact).

Sortie 7.2:

```text
test/core/startup/boot_critical_screens_widget_test.dart
test/core/startup/boot_simple_loading_screen_test.dart
test/core/startup/boot_catalog_loading_screen_test.dart
test/core/startup/boot_recovery_panel_test.dart
test/features/home/presentation/widgets/home_error_banner_test.dart
docs/app_launch_refactor/phase_7_tests_automatises_et_validation_runtime/WIDGET_SURFACES_COVERAGE.md
```

Statut 7.2:

- suites widget critiques executees et vertes ;
- focus/order/actions valides sur les surfaces recovery ;
- robustesse viewport etroit validee sur chargements ;
- garde-fous anti-fuite UI verifies (reasonCode/URL/id internes non affiches).

#### Etape 7.3 - Couverture router/integration des parcours launch

- Verifier les parcours critiques :
  - `launch -> auth` ;
  - `launch -> create profile` ;
  - `launch -> choose profile` ;
  - `launch -> add source` ;
  - `launch -> choose source` ;
  - `launch -> catalog preparing -> home` ;
  - `launch -> source recovery` ;
  - `launch -> home partial`.

Sortie 7.3:

```text
test/core/router/new_user_auth_launch_flow_test.dart
test/core/router/launch_redirect_guard_boot_alignment_test.dart
test/core/router/launch_redirect_guard_tunnel_surface_test.dart
test/core/router/launch_redirect_guard_reconnect_test.dart
docs/app_launch_refactor/phase_7_tests_automatises_et_validation_runtime/ROUTER_INTEGRATION_COVERAGE.md
```

Statut 7.3:

- suites router/integration executees et vertes ;
- parcours launch critiques verifies (auth/profil/source/home/recovery) ;
- alignement guard/tunnel confirme sur redirections de securite et readiness.

#### Etape 7.4 - Validation runtime multi-scenarios

- Executer et tracer des runs manuels cibles :
  - run sans snapshot ;
  - run avec snapshot ;
  - run source timeout ;
  - run credentials invalides ;
  - run catalogue vide ;
  - run Home partiel ;
  - run Windows (qualification desktop vs TV + focus clavier).
- Capturer les observations et preuves (logs + comportement UI).

Sortie 7.4:

```text
docs/app_launch_refactor/phase_7_tests_automatises_et_validation_runtime/RUNTIME_SCENARIOS.md
```

Statut 7.4:

- scenarios runtime critiques executes via suites startup/router/widget ;
- preuves capturees pour:
  - sans snapshot ;
  - snapshot exploitable ;
  - timeout source ;
  - credentials invalides ;
  - catalogue vide ;
  - Home partiel ;
- qualification Windows TV vs desktop gardee en verification manuelle.

#### Etape 7.5 - Synthese qualite et backlog de correction

- Consolider les resultats (unitaires, widget, router, runtime).
- Dresser la liste des ecarts restants et la priorisation de correction.
- Verifier que les transitions attendues sont visibles dans les logs.

Sortie 7.5:

```text
docs/app_launch_refactor/phase_7_tests_automatises_et_validation_runtime/TEST_RESULTS_AND_GAPS.md
```

Statut 7.5:

- synthese 7.1 -> 7.4 consolidee ;
- aucun blocage automatisation critique restant ;
- backlog restant priorise:
  - P1: qualification manuelle Windows desktop/TV + focus clavier ;
  - P2: archivage des preuves runtime manuelles ;
- transitions logs critiques confirmees dans les scenarios/tests.

### Validation

- Executer les suites startup/core impactees.
- Executer les suites widget boot critiques.
- Executer les tests router/integration launch.
- Verifier qu'un run boot complet est lisible de bout en bout dans les logs.

### Definition de fini

- Les tests couvrent les decisions critiques.
- Les runs confirment la reduction de l'attente opaque.
- Les logs confirment les transitions attendues.

## Phase 8 - Documentation finale et criteres de sortie

### But

Rendre le nouveau boot maintenable.

### Actions

- Mettre a jour `docs/app_launch_refactor/README.md`.
- Ajouter une table finale :
  - reason code ;
  - phase ;
  - ecran ;
  - action principale ;
  - action secondaire ;
  - destination ;
  - tests.
- Documenter les responsabilites :
  - orchestrateur ;
  - resolver ;
  - mapper UI ;
  - router ;
  - widgets ;
  - pages d'action.
- Documenter les decisions produit :
  - cache exploitable ;
  - Home partiel ;
  - Windows TV ou desktop ;
  - auth integre au boot ou pages auth separees.
- Archiver les resultats runtime :
  - run sans snapshot ;
  - run avec snapshot ;
  - cas recovery.

### Definition de fini globale

- Tous les etats de lancement attendus sont representes par un reason code.
- Chaque reason code a une destination ou une action claire.
- Les ecrans Figma critiques sont implementes.
- Les anciens ecrans generiques ne masquent plus les decisions boot.
- Home s'ouvre rapidement quand un snapshot exploitable existe.
- Un snapshot absent affiche une preparation source comprehensible.
- Les erreurs source restent separees de Home partiel.
- Les logs permettent de diagnostiquer le boot sans bruit excessif.
- Les tests couvrent orchestration, routage, UI et catalogue.

## Ordre d'execution recommande

1. Phase 0 - Audit et gel du comportement actuel.
2. Phase 1 - Contrats, reason codes et modeles UI.
3. Phase 3 - Catalogue, source recovery et Home readiness.
4. Phase 2 - Orchestration et routage.
5. Phase 4 - UI boot et composants.
6. Phase 5 - Nettoyage legacy et migration.
7. Phase 6 - Localisation, logs et observabilite.
8. Phase 7 - Tests automatises et validation runtime.
9. Phase 8 - Documentation finale et criteres de sortie.

La phase 3 est placee avant l'implementation UI complete car elle traite le
probleme runtime principal observe : le refresh IPTV bloquant quand le snapshot
catalogue est absent. L'UI doit ensuite se brancher sur cette decision stabilisee.
