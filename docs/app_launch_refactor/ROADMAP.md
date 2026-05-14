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

### Actions

- Remplacer progressivement `SplashBootstrapPage` par le renderer boot unifie.
- Reduire `WelcomeSourceLoadingPage` :
  - retirer la logique catalogue critique du widget ;
  - conserver seulement la surface UI si elle reste necessaire ;
  - ou supprimer la page si le nouveau boot la couvre completement.
- Harmoniser `WelcomeSourcePage` avec les composants boot/design.
- Harmoniser `WelcomeSourceSelectPage` avec les composants boot/design.
- Remplacer les textes generiques :
  - `Preparation de l'accueil...` ;
  - `Impossible de preparer la page d'accueil` ;
  - `Erreur inconnue` dans les surfaces boot.
- Verifier les routes obsoletes :
  - garder celles qui representent une vraie page d'action ;
  - supprimer ou rediriger celles qui ne sont plus des destinations boot.
- Nettoyer les flags ou bridges devenus inutiles apres rollout.
- Eviter de supprimer les pages auth/profil/source qui restent necessaires
  hors boot.

### Livrables

- Liste des widgets legacy supprimes, remplaces ou conserves.
- Suppression des messages generiques dans le boot.
- Tests de non-regression router.

### Definition de fini

- Il n'existe plus deux surfaces concurrentes pour le meme etat boot.
- La logique catalogue n'est plus dupliquee entre orchestrateur et UI.
- Le parcours utilisateur reste identique quand tout va bien.

## Phase 6 - Localisation, logs et observabilite

### But

Rendre le boot lisible pour l'utilisateur et diagnosticable pour le
developpeur.

### Localisation

- Ajouter les cles `l10n` pour tous les textes boot.
- Eviter les strings codees en dur dans les nouveaux widgets.
- Corriger les textes issus des JSON dont l'encodage est altere.
- Garder les messages courts et non techniques.

### Logs

- Ajouter des evenements structurels :
  - `boot_state_changed` ;
  - `boot_action_triggered` ;
  - `catalog_preparation_started` ;
  - `catalog_preparation_completed` ;
  - `catalog_preparation_failed` ;
  - `boot_recovery_shown` ;
  - `home_partial_shown` ;
  - `entry_journey_completed`.
- Chaque evenement doit inclure :
  - run id ;
  - phase ;
  - reason code ;
  - duree si disponible ;
  - destination si disponible ;
  - action si disponible.
- Reduire les logs bruyants hors diagnostic cible :
  - `home_hero_debug` ;
  - rafales `image_pipeline` ;
  - logs recherche focus ;
  - bruit Flutter Windows si isolable.

### Livrables

- Cles de traduction boot.
- Table des evenements logs.
- Tests ou snapshots de logs pour les transitions critiques.

### Definition de fini

- Un run boot peut etre lu sans details reseau bruts.
- Les reason codes sont stables.
- Aucun code interne n'est affiche a l'utilisateur.

## Phase 7 - Tests automatises et validation runtime

### But

Valider le boot complet sur les chemins critiques, pas seulement le chemin
nominal.

### Tests unitaires

- `ResolveEntryDecision` :
  - auth requise ;
  - profil requis ;
  - selection profil requise ;
  - source requise ;
  - selection source requise ;
  - entree Home.
- `ResolveCatalogReadiness` :
  - fresh ;
  - cached ;
  - stale ;
  - missing ;
  - unavailable ;
  - timeout ;
  - provider error ;
  - credentials invalides ;
  - empty.
- `StartupRecoveryMapper` :
  - boot technical failure ;
  - source timeout ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide ;
  - Home partiel.
- `BootScreenModel` :
  - chaque reason code attendu mappe un ecran ;
  - chaque ecran actionnable a une action principale.

### Tests widget

- Chargements simples :
  - logo centre ;
  - texte bas ecran ;
  - pas d'action.
- Preparation catalogue :
  - titre ;
  - message ;
  - sous-message ;
  - action secondaire si activee.
- Recovery :
  - titre utilisateur ;
  - message court ;
  - action principale focusable ;
  - action secondaire si attendue.
- Home partial banner :
  - message ;
  - action ;
  - comportement mobile compact.

### Tests router/integration

- `launch -> auth`.
- `launch -> create profile`.
- `launch -> choose profile`.
- `launch -> add source`.
- `launch -> choose source`.
- `launch -> catalog preparing -> home`.
- `launch -> source recovery`.
- `launch -> home partial`.

### Validation runtime

- Run sans snapshot :
  - `catalog_preparing` visible ;
  - refresh bloquant mesure ;
  - Home ouverte apres succes.
- Run avec snapshot :
  - Home rapide ;
  - pas de refresh bloquant.
- Run source timeout :
  - ecran `La source ne repond pas` ;
  - `Reessayer` fonctionne ;
  - `Choisir une autre source` fonctionne si disponible.
- Run credentials invalides :
  - ecran `Connexion a la source impossible` ;
  - action `Reconnecter la source`.
- Run catalogue vide :
  - ecran `Aucun contenu trouve` ;
  - actions `Resynchroniser` et `Choisir une autre source`.
- Run Home partiel :
  - Home accessible ;
  - banniere compacte ;
  - action de recharge limitee a la section concernee.
- Run Windows :
  - confirmer si Windows est TV ou desktop ;
  - documenter le choix ;
  - tester focus clavier.

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
