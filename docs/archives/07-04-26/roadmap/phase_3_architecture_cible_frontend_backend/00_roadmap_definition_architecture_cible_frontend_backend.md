# Phase 3 - Architecture cible frontend et backend

## Objectif

Transformer les decisions UX et UI des phases 1 et 2 en architecture cible claire, testable et implementable pour le tunnel d'entree `welcome -> auth -> source -> pre-home`.

La phase 3 ne re-ouvre pas le parcours ni la cible UI. Elle fixe:
- les responsabilites des couches
- la machine d'etat du tunnel
- l'orchestrateur d'entree
- les contrats frontend / backend / infra
- les regles de composition et de dependances
- la strategie de coexistence et de rollout si la migration se fait par paliers

## Entrees de reference

La phase 3 s'appuie directement sur les artefacts valides des phases 1 et 2:
- [09_validation_finale_phase_1.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/09_validation_finale_phase_1.md)
- [03_blueprint_ux_tunnel_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/03_blueprint_ux_tunnel_cible.md)
- [04_user_flows_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/04_user_flows_tunnel_entree.md)
- [05_contrat_ux_par_ecran.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/05_contrat_ux_par_ecran.md)
- [06_decisions_fusion_suppression_inline.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/06_decisions_fusion_suppression_inline.md)
- [09_validation_finale_phase_2.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/09_validation_finale_phase_2.md)
- [04_systeme_composants_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/04_systeme_composants_tunnel.md)
- [07_spec_ui_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/07_spec_ui_tunnel.md)

## Resultat attendu

A la fin de la phase 3:
- le tunnel a un modele d'etat canonique unique
- un `entry journey orchestrator` cible est defini
- les frontieres `presentation / orchestration / domain / data` sont explicites
- les contrats backend et infra utiles au tunnel sont stabilises
- le role de `Riverpod`, `GetIt`, routeur et composition root est clarifie
- les modules a extraire, fusionner ou simplifier sont identifies avant implementation lourde

## Avancement courant

- sous-phase `3.0` : complete via [01_preparation_alignement_architecture.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/01_preparation_alignement_architecture.md)
- sous-phase `3.1` : complete via [02_modele_etat_canonique_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/02_modele_etat_canonique_tunnel.md)
- sous-phase `3.2` : complete via [03_entry_journey_orchestrator.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/03_entry_journey_orchestrator.md)
- sous-phase `3.3` : complete via [04_separation_couches_et_modules.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/04_separation_couches_et_modules.md)
- sous-phase `3.4` : complete via [05_contrats_backend_et_infra_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/05_contrats_backend_et_infra_tunnel.md)
- sous-phase `3.5` : complete via [06_composition_root_routing_et_state_management.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/06_composition_root_routing_et_state_management.md)
- sous-phase `3.6` : complete via [07_strategie_migration_feature_flags_rollout.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/07_strategie_migration_feature_flags_rollout.md)
- sous-phase `3.7` : complete via [09_validation_finale_phase_3.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/09_validation_finale_phase_3.md)

## Principes directeurs de la phase 3

- `One journey, one state model`: un seul modele d'etat canonique pour le tunnel.
- `State first, UI second`: les surfaces UI derivent d'etats explicites.
- `Orchestrator owns flow`: les decisions de sequence sortent des widgets et du routeur disperse.
- `Contracts before refactor`: les interfaces sont fixees avant l'extraction des modules.
- `Presentation stays dumb`: la UI affiche et emet des intentions, elle n'orchestre pas le tunnel.
- `Degraded states are first-class`: offline, retry, local fallback et reprise ne sont pas des exceptions.
- `Progressive migration`: l'architecture doit permettre un rollout par paliers si necessaire.

## Sous-phases proposees

### Sous-phase 3.0 - Preparation et alignement architecture

But: cadrer les decisions deja prises et les contraintes techniques avant de proposer une architecture cible.

Travaux:
- relire les validations des phases 1 et 2
- lister les surfaces UI et etats UX a servir
- inventorier les questions architecture deja deferrees
- identifier les zones actuelles de couplage:
  - routeur
  - bootstrap
  - providers
  - services
  - repositories
  - side effects
- lister les contraintes non negociables:
  - local-first
  - cloud-safe
  - mobile + TV
  - preload avant `home`

Livrables:
- liste des contraintes architecture
- liste des zones de couplage a traiter
- liste des questions techniques ouvertes

Gate:
- le perimetre architecture est verrouille
- les grands problemes a resoudre sont explicites

### Sous-phase 3.1 - Modele d'etat canonique du tunnel

But: definir la machine d'etat metier du parcours d'entree.

Travaux:
- lister les etats canoniques du tunnel
- distinguer:
  - etats stables
  - etats transitoires
  - etats de recovery
  - etats terminaux
- definir les transitions autorisees
- lister les evenements qui provoquent les transitions
- identifier les gardes et conditions critiques

Livrables:
- machine d'etat du tunnel
- table `state -> event -> next state`
- liste des reason codes principaux

Gate:
- le tunnel a un modele d'etat unique et defendable

### Sous-phase 3.2 - Orchestrateur d'entree cible

But: definir le `entry journey orchestrator` comme point central de decision du tunnel.

Travaux:
- definir le role exact de l'orchestrateur
- definir ses responsabilites et ses limites
- lister les entrees:
  - session
  - profil
  - source
  - connectivite
  - preload
- lister les sorties:
  - etat canonique
  - commandes / intentions
  - telemetry
- preciser ce qui doit rester hors orchestrateur

Livrables:
- spec de l'orchestrateur
- inputs / outputs
- liste des dependencies autorisees

Gate:
- l'orchestrateur a une responsabilite nette
- la UI et le routeur ne portent plus la logique de tunnel

### Sous-phase 3.3 - Separation des couches et modules

But: fixer les frontieres entre presentation, application, domain et data.

Travaux:
- definir la repartition cible:
  - presentation
  - application / orchestration
  - domain policies
  - data / adapters
- mapper les modules actuels vers la cible
- identifier:
  - modules a extraire
  - modules a fusionner
  - modules a simplifier
  - modules a supprimer
- clarifier les dependances autorisees entre couches

Livrables:
- schema de couches cible
- mapping `existant -> cible`
- decision log extract / merge / simplify / remove

Gate:
- les frontieres entre couches sont figees
- les dependances illegitimes sont explicites

### Sous-phase 3.4 - Contrats backend et infra du tunnel

But: redefinir les contrats utiles au tunnel avant implementation.

Travaux:
- definir les contrats de:
  - restauration de session
  - verification auth
  - chargement de profils
  - selection du profil courant
  - inventaire des sources
  - selection de source active
  - preload minimal pre-home
  - fallback local et reprise cloud
- definir les payloads, erreurs et reason codes
- distinguer:
  - `must-have before home`
  - `can-load-after-home`

Livrables:
- catalogue de contrats du tunnel
- interfaces et payloads attendus
- liste des erreurs typees

Gate:
- les contrats critiques du tunnel sont suffisamment stables pour implementation

### Sous-phase 3.5 - Composition root, routing et state management

But: clarifier le role de `Riverpod`, `GetIt`, routeur et composition root dans la cible.

Travaux:
- definir ce qui doit etre:
  - injecte
  - observe
  - derive
  - route
- clarifier la place de `Riverpod`
- clarifier la place de `GetIt`
- definir la relation entre orchestrateur et routeur
- definir le role du composition root pour le tunnel

Livrables:
- regles de composition du tunnel
- regles de routing derive de l'etat
- decision log `Riverpod / GetIt / routeur`

Gate:
- les outils de composition ont chacun un role net
- le routing n'est plus un lieu de logique metier diffuse

### Sous-phase 3.6 - Strategie de migration, feature flags et rollout

But: rendre la cible architecture livrable sans casser l'existant.

Travaux:
- definir si la migration est:
  - big bang
  - par paliers
  - mixte
- identifier les points ou feature flags sont utiles
- definir la coexistence temporaire ancien tunnel / nouveau tunnel
- definir les points de rollback
- preciser les preconditions de migration des ecrans UI

Livrables:
- strategie de migration
- plan de feature flags / rollout
- points de coexistence et de rollback

Gate:
- la cible architecture peut etre migree de facon realiste

### Sous-phase 3.7 - Validation finale de la phase 3

But: clore la phase architecture avec une cible suffisamment stable pour decoupage d'implementation.

Travaux:
- verifier la coherence avec les phases 1 et 2
- confirmer que la machine d'etat couvre le tunnel retenu
- confirmer que l'orchestrateur et les couches sont clairs
- confirmer que les contrats backend et infra sont assez stables
- lister les sujets deferes a la phase performance ou implementation

Livrables:
- synthese finale de la phase 3
- recap des decisions architecture prises
- sujets deferes
- verdict de stabilite

Gate:
- les contrats et responsabilites sont figes
- aucune ecriture UI ou integration majeure ne commence sans ces frontieres

## Sequence de travail recommandee

Ordre conseille:
1. preparation et alignement architecture
2. modele d'etat canonique
3. orchestrateur d'entree
4. separation des couches et modules
5. contrats backend et infra
6. composition root, routing et state management
7. strategie de migration et rollout
8. validation finale

## Artefacts a produire dans ce dossier

Le dossier `docs/roadmap/phase_3_architecture_cible_frontend_backend/` est prevu pour accueillir a terme:
- `00_roadmap_definition_architecture_cible_frontend_backend.md`
- `01_preparation_alignement_architecture.md`
- `02_modele_etat_canonique_tunnel.md`
- `03_entry_journey_orchestrator.md`
- `04_separation_couches_et_modules.md`
- `05_contrats_backend_et_infra_tunnel.md`
- `06_composition_root_routing_et_state_management.md`
- `07_strategie_migration_feature_flags_rollout.md`
- `08_schema_architecture_cible.md`
- `09_validation_finale_phase_3.md`

## Points de validation avec le stakeholder

Les checkpoints ou une validation produit / technique est utile sont:

1. fin de `3.0`
Pour confirmer le perimetre technique et les contraintes non negotiables.

2. fin de `3.1`
Pour valider que la machine d'etat represente bien le tunnel cible.

3. fin de `3.2`
Pour confirmer le role de l'orchestrateur avant de redistribuer les responsabilites.

4. fin de `3.4`
Pour valider les contrats critiques du tunnel.

5. fin de `3.7`
Pour acter la cible architecture finale avant decoupage d'implementation.

## Prompts a me redonner pour lancer chaque sous-phase

Tu peux copier-coller ces prompts tels quels pour demarrer chaque sous-phase.

### Lancer la sous-phase 3.0

Nous lancons la sous-phase 3.0 de preparation et alignement architecture pour le tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des contraintes architecture
- la liste des zones de couplage a traiter
- la liste des questions techniques encore ouvertes
- les ambiguities restantes a lever avant la sous-phase 3.1
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.1

Nous lancons la sous-phase 3.1 de modele d'etat canonique du tunnel.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des etats canoniques
- la table des transitions principales
- les evenements et gardes critiques
- les points de vigilance sur les etats de recovery
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.2

Nous lancons la sous-phase 3.2 de definition du `entry journey orchestrator`.
Travaille sur cette sous-phase uniquement.
Je veux:
- le role exact de l'orchestrateur
- ses inputs / outputs
- ses responsabilites et limites
- les dependances autorisees et interdites
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.3

Nous lancons la sous-phase 3.3 de separation des couches et modules.
Travaille sur cette sous-phase uniquement.
Je veux:
- le schema de couches cible
- le mapping `existant -> cible`
- les modules a extraire, fusionner, simplifier ou supprimer
- les dependances a casser
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.4

Nous lancons la sous-phase 3.4 de contrats backend et infra du tunnel.
Travaille sur cette sous-phase uniquement.
Je veux:
- les contrats critiques du tunnel
- les payloads et interfaces attendus
- les erreurs typees et reason codes principaux
- la distinction `must-have before home` vs `can-load-after-home`
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.5

Nous lancons la sous-phase 3.5 de composition root, routing et state management.
Travaille sur cette sous-phase uniquement.
Je veux:
- le role cible de `Riverpod`, `GetIt`, routeur et composition root
- les regles de composition et d'injection
- les regles de routing derive de l'etat
- les antipatterns a eviter
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.6

Nous lancons la sous-phase 3.6 de strategie de migration, feature flags et rollout.
Travaille sur cette sous-phase uniquement.
Je veux:
- la strategie de migration recommandee
- les points de feature flags utiles
- les conditions de coexistence et rollback
- les risques de migration majeurs
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

### Lancer la sous-phase 3.7

Nous lancons la sous-phase 3.7 de validation finale de la phase 3.
Travaille sur cette sous-phase uniquement.
Je veux:
- une synthese finale de la phase
- le recap des decisions architecture prises
- la liste des sujets deferes a la phase performance ou implementation
- un verdict explicite sur la stabilite de la phase 3
Mets a jour la documentation dans docs/roadmap/phase_3_architecture_cible_frontend_backend/ si necessaire.

## Prompts a me redonner pour clore chaque sous-phase

Tu peux aussi utiliser ces prompts de cloture si tu veux formaliser la sortie d'une sous-phase avant de passer a la suivante.

### Clore la sous-phase 3.0

La sous-phase 3.0 est-elle suffisamment cadree pour lancer la machine d'etat du tunnel ? Donne-moi le verdict, les points fixes et les questions restantes.

### Clore la sous-phase 3.1

Le modele d'etat canonique est-il assez stable pour definir l'orchestrateur ? Donne-moi le verdict, les choix retenus et les zones fragiles.

### Clore la sous-phase 3.2

L'orchestrateur est-il assez clair pour separer les couches et les contrats ? Donne-moi le verdict, ses responsabilites critiques et les risques restants.

### Clore la sous-phase 3.3

La separation des couches est-elle assez stable pour figer les contrats du tunnel ? Donne-moi le verdict, les couplages restants et les points de vigilance.

### Clore la sous-phase 3.4

Les contrats backend et infra sont-ils assez stables pour clarifier composition root et migration ? Donne-moi le verdict, les contrats critiques et les zones encore floues.

### Clore la sous-phase 3.5

La composition et le routing sont-ils assez clairs pour penser la migration ? Donne-moi le verdict, les regles retenues et les antipatterns encore probables.

### Clore la sous-phase 3.6

La strategie de migration est-elle assez realiste pour cloturer la phase 3 ? Donne-moi le verdict, les risques majeurs et les preconditions restantes.

## Prochaine etape recommandee

Apres validation de cette roadmap detaillee, produire d'abord:
1. `01_preparation_alignement_architecture.md`
2. `02_modele_etat_canonique_tunnel.md`
3. `03_entry_journey_orchestrator.md`

Le schema d'architecture cible detaille ne doit arriver qu'une fois le modele d'etat et l'orchestrateur stabilises.
