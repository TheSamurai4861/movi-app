# Phase 5 - Decoupage d'implementation

## Objectif

Transformer les decisions des phases 1, 2, 3 et 4 en lots d'implementation suffisamment petits, ordonnes et rollbackables pour livrer le nouveau tunnel sans casser le produit.

La phase 5 ne redefinit pas:
- le parcours UX cible
- la spec UI cible
- l'architecture cible
- les budgets et safe states

Elle fixe:
- le backlog de lots executables
- les dependances entre lots
- la strategie de coexistence ancien / nouveau tunnel
- le plan de migration progressif
- les criteres de done par lot

## Entrees de reference

La phase 5 s'appuie directement sur les artefacts valides des phases 1, 2, 3 et 4:
- [09_validation_finale_phase_1.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/09_validation_finale_phase_1.md)
- [09_validation_finale_phase_2.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/09_validation_finale_phase_2.md)
- [09_validation_finale_phase_3.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/09_validation_finale_phase_3.md)
- [09_validation_finale_phase_4.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/09_validation_finale_phase_4.md)
- [08_checklist_implementation_ui_ux.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/08_checklist_implementation_ui_ux.md)
- [07_strategie_migration_feature_flags_rollout.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/07_strategie_migration_feature_flags_rollout.md)
- [07_optimisations_obligatoires_avant_release.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/07_optimisations_obligatoires_avant_release.md)

## Resultat attendu

A la fin de la phase 5:
- la refonte est decoupee en lots independants autant que possible
- l'ordre d'execution des lots est defendable
- chaque lot a un perimetre, un flag, un rollback et une definition of done
- la coexistence temporaire ancien / nouveau tunnel est bornee
- les migrations de routes, composants et branchements legacy sont planifiees

## Avancement courant

- sous-phase `5.0` : complete via [01_preparation_alignement_decoupage.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/01_preparation_alignement_decoupage.md)
- sous-phase `5.1` : complete via [02_epic_map_et_backlog_lots.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/02_epic_map_et_backlog_lots.md)
- sous-phase `5.2` : complete via [03_dependances_et_ordre_execution.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/03_dependances_et_ordre_execution.md)
- sous-phase `5.3` : complete via [04_feature_flags_et_coexistence.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/04_feature_flags_et_coexistence.md)
- sous-phase `5.4` : complete via [05_migration_composants_routes_branchements.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/05_migration_composants_routes_branchements.md)
- sous-phase `5.5` : complete via [06_definition_of_done_et_tests_par_lot.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/06_definition_of_done_et_tests_par_lot.md)
- sous-phase `5.6` : complete via [07_plan_migration_consolide.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/07_plan_migration_consolide.md)
- sous-phase `5.7` : complete via [09_validation_finale_phase_5.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/09_validation_finale_phase_5.md)

## Principes directeurs de la phase 5

- `Small enough to review`: aucun lot ne doit devenir un mini-programme.
- `Flags before fear`: les parties risquees doivent etre livrables derriere feature flag.
- `State before screens`: l'etat et l'orchestrateur passent avant les ecrans finaux.
- `Measure before replace`: les briques d'observabilite arrivent avant les grosses bascules UI.
- `Coexist temporarily, not forever`: la coexistence legacy est un outil de migration, pas une architecture cible.
- `Rollbackable by design`: chaque lot doit pouvoir etre coupe ou reverti sans remettre tout le tunnel en cause.

## Sous-phases proposees

### Sous-phase 5.0 - Preparation et alignement du decoupage

But: cadrer les contraintes de livraison avant de decouper les lots.

Travaux:
- relire les validations des phases 1 a 4
- rappeler les decisions non negociables pour l'implementation
- lister les contraintes de migration:
  - feature flags
  - coexistence legacy
  - couverture telemetry
  - rollback
- identifier les zones a tres fort couplage qui imposent un ordre de lots

Livrables:
- contraintes de decoupage
- liste des zones a fort risque de migration
- liste des hypotheses de livraison

Gate:
- le cadre de decoupage est verrouille avant de creer le backlog

### Sous-phase 5.1 - Epic map et backlog des lots

But: transformer la refonte en epics et lots executables.

Travaux:
- decouper la refonte en epics techniques et UX
- definir les lots candidats sous chaque epic
- borner le perimetre de chaque lot:
  - objectif
  - entree
  - sortie
  - impact
- verifier que chaque lot reste revuable

Livrables:
- epic map de la refonte
- backlog des lots
- description courte de chaque lot

Gate:
- aucun lot n'est encore trop gros ou ambigu

### Sous-phase 5.2 - Dependances, ordre d'execution et chemin critique

But: ordonner les lots selon les dependances reelles.

Travaux:
- cartographier les dependances entre lots
- identifier le chemin critique
- verifier l'ordre recommande:
  - instrumentation
  - etat + orchestrateur
  - contrats
  - composants communs
  - ecrans
  - preload final
  - nettoyage legacy
- signaler les lots parallelisables

Livrables:
- matrice des dependances
- ordre recommande des lots
- chemin critique de livraison

Gate:
- l'ordre d'execution est defendable et explicite

### Sous-phase 5.3 - Feature flags, coexistence et strategie de bascule

But: definir comment livrer la refonte par paliers sans casser le tunnel existant.

Travaux:
- definir les flags utiles par lot
- definir les zones de coexistence temporaire ancien / nouveau tunnel
- definir les regles de bascule progressive
- definir les points de rollback
- limiter la duree de vie de chaque coexistence

Livrables:
- plan de feature flags
- plan de coexistence et de bascule
- points de rollback par lot critique

Gate:
- chaque lot risque a une strategie de bascule et de rollback

### Sous-phase 5.4 - Migration des composants, routes et branchements

But: preciser les migrations techniques visibles dans le code.

Travaux:
- identifier les composants a migrer, extraire ou supprimer
- identifier les routes a projeter, remplacer ou supprimer
- identifier les branchements legacy:
  - guards
  - providers
  - services
  - pages `welcome/*`
- definir pour chaque migration:
  - coexistence temporaire ou remplacement direct
  - precondition
  - critere de suppression legacy

Livrables:
- plan de migration des composants
- plan de migration des routes
- liste des branchements legacy a nettoyer

Gate:
- les migrations visibles ont un plan concret et borne

### Sous-phase 5.5 - Definition of done, tests et criteres de revue par lot

But: rendre chaque lot testable, revuable et fermable.

Travaux:
- definir la `definition of done` par lot
- definir les tests minimum par lot:
  - unit
  - widget
  - integration
  - telemetry
- definir les criteres de revue:
  - taille
  - rollback
  - telemetry
  - documentation
- lier chaque lot aux budgets ou safe states concernes

Livrables:
- definition of done par lot
- criteres de revue
- attentes de test par lot

Gate:
- chaque lot est concretement verifiable

### Sous-phase 5.6 - Plan de migration consolide

But: assembler backlog, dependances, flags et migrations dans un plan unique de livraison.

Travaux:
- consolider l'ordre des lots
- rattacher les flags et les migrations a chaque lot
- definir les jalons intermediaires
- definir les sorties d'etape partielles possibles
- verifier la coherence avec les phases 3 et 4

Livrables:
- plan de migration consolide
- jalons de livraison
- backlog ordonne final

Gate:
- le plan global peut etre execute sans redecoupage majeur

### Sous-phase 5.7 - Validation finale de la phase 5

But: clore le decoupage d'implementation avec une cible executable par l'equipe.

Travaux:
- verifier que tous les lots sont assez petits pour revue, test et rollback
- verifier la coherence avec les phases 1 a 4
- confirmer l'ordre de livraison
- confirmer la strategie de coexistence et de nettoyage final
- lister les points deferes a l'execution ou a la QA

Livrables:
- synthese finale de la phase 5
- recap des lots et dependances retenus
- sujets deferes
- verdict de stabilite

Gate:
- chaque lot est assez petit pour etre revu, teste et rollbacke

## Sequence de travail recommandee

Ordre conseille:
1. preparation et alignement
2. epic map et backlog
3. dependances et ordre d'execution
4. feature flags et coexistence
5. migration composants / routes / branchements
6. definition of done et tests par lot
7. plan de migration consolide
8. validation finale

## Liste des artefacts attendus dans le dossier

- [00_roadmap_definition_decoupage_implementation.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/00_roadmap_definition_decoupage_implementation.md)
- [01_preparation_alignement_decoupage.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/01_preparation_alignement_decoupage.md)
- [02_epic_map_et_backlog_lots.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/02_epic_map_et_backlog_lots.md)
- [03_dependances_et_ordre_execution.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/03_dependances_et_ordre_execution.md)
- [04_feature_flags_et_coexistence.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/04_feature_flags_et_coexistence.md)
- [05_migration_composants_routes_branchements.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/05_migration_composants_routes_branchements.md)
- [06_definition_of_done_et_tests_par_lot.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/06_definition_of_done_et_tests_par_lot.md)
- [07_plan_migration_consolide.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/07_plan_migration_consolide.md)
- [08_schema_decoupage_implementation.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/08_schema_decoupage_implementation.md)
- [09_validation_finale_phase_5.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/09_validation_finale_phase_5.md)

## Checkpoints de validation recommandes

- checkpoint 1: validation du cadre et des contraintes de decoupage
- checkpoint 2: validation du backlog de lots
- checkpoint 3: validation du chemin critique et des dependances
- checkpoint 4: validation des flags et de la coexistence legacy
- checkpoint 5: validation finale de la phase

## Prompts a me redonner pour lancer chaque sous-phase

Tu peux copier-coller ces prompts tels quels pour demarrer chaque sous-phase.

### Lancer la sous-phase 5.0

Nous lancons la sous-phase 5.0 de preparation et alignement du decoupage d'implementation du tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des contraintes de livraison et de migration
- la liste des zones a fort couplage ou fort risque
- la liste des hypotheses de rollout
- les ambiguities restantes a lever avant la sous-phase 5.1
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.1

Nous lancons la sous-phase 5.1 d'epic map et backlog des lots.
Travaille sur cette sous-phase uniquement.
Je veux:
- l'epic map de la refonte
- le backlog initial des lots
- le perimetre court de chaque lot
- les lots qui paraissent encore trop gros
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.2

Nous lancons la sous-phase 5.2 de dependances, ordre d'execution et chemin critique.
Travaille sur cette sous-phase uniquement.
Je veux:
- la matrice des dependances entre lots
- l'ordre recommande des lots
- le chemin critique
- les lots parallelisables
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.3

Nous lancons la sous-phase 5.3 de feature flags, coexistence et strategie de bascule.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des flags utiles
- le plan de coexistence ancien / nouveau tunnel
- les points de rollback
- les zones ou la coexistence doit rester la plus courte possible
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.4

Nous lancons la sous-phase 5.4 de migration des composants, routes et branchements.
Travaille sur cette sous-phase uniquement.
Je veux:
- le plan de migration des composants
- le plan de migration des routes
- la liste des branchements legacy a nettoyer
- les preconditions de suppression legacy
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.5

Nous lancons la sous-phase 5.5 de definition of done, tests et criteres de revue par lot.
Travaille sur cette sous-phase uniquement.
Je veux:
- la definition of done par lot
- les attentes de test par lot
- les criteres de revue
- les zones qui restent fragiles
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.6

Nous lancons la sous-phase 5.6 de plan de migration consolide.
Travaille sur cette sous-phase uniquement.
Je veux:
- le backlog ordonne final
- les jalons de livraison
- le plan consolide de migration
- les points qui imposent encore un arbitrage
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

### Lancer la sous-phase 5.7

Nous lancons la sous-phase 5.7 de validation finale de la phase 5.
Travaille sur cette sous-phase uniquement.
Je veux:
- la synthese finale du decoupage d'implementation
- le recap des lots, dependances et flags retenus
- les sujets deferes a l'execution ou a la QA
- le verdict explicite de stabilite de la phase
Mets a jour la documentation dans docs/roadmap/phase_5_decoupage_implementation/ si necessaire.

## Prompts de cloture de sous-phase

Tu peux aussi me redonner ces prompts a la fin de chaque sous-phase si tu veux un point de sortie formel.

### Fin de la sous-phase 5.0

Cloture la sous-phase 5.0.
Je veux:
- un verdict clair sur les contraintes verrouillees
- les questions restantes avant 5.1
- la recommandation de prochaine etape

### Fin de la sous-phase 5.1

Cloture la sous-phase 5.1.
Je veux:
- le recap des epics et lots retenus
- les lots encore trop gros
- la recommandation de prochaine etape

### Fin de la sous-phase 5.2

Cloture la sous-phase 5.2.
Je veux:
- le recap des dependances et du chemin critique
- les points de blocage potentiels
- la recommandation de prochaine etape

### Fin de la sous-phase 5.3

Cloture la sous-phase 5.3.
Je veux:
- le recap des flags et de la coexistence
- les points de rollback critiques
- la recommandation de prochaine etape

### Fin de la sous-phase 5.4

Cloture la sous-phase 5.4.
Je veux:
- le recap des migrations de composants, routes et branchements
- la liste des suppressions legacy conditionnelles
- la recommandation de prochaine etape

### Fin de la sous-phase 5.5

Cloture la sous-phase 5.5.
Je veux:
- le recap des definitions of done et attentes de test
- les zones encore fragiles
- la recommandation de prochaine etape

### Fin de la sous-phase 5.6

Cloture la sous-phase 5.6.
Je veux:
- le recap du plan de migration consolide
- les arbitrages restants
- la recommandation de prochaine etape

### Fin de la sous-phase 5.7

Cloture la phase 5.
Je veux:
- le verdict final de stabilite
- les risques restants
- la recommandation de suite
