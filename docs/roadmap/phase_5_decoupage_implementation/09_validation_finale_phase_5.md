# Validation finale - Phase 5 Decoupage d'implementation

## Objectif de cloture

Confirmer que la phase 5 fournit un plan d'implementation suffisamment stable pour lancer l'execution du nouveau tunnel sans re-ouvrir les arbitrages UX, UI, architecture et resilience deja pris.

## Synthese finale de la cible

La phase 5 fige une cible d'execution claire:
- la refonte est decoupee en lots executables
- les dependances et le chemin critique sont explicites
- les flags et rollbacks sont rattaches aux grandes bascules
- les migrations visibles dans le code sont identifiees
- chaque famille de lots a une `definition of done`

En pratique, le programme d'implementation retenu est:
- mesurer d'abord
- stabiliser le coeur ensuite
- basculer le routeur ensuite
- migrer les surfaces ensuite
- fermer le bloc source puis le pre-home
- nettoyer le legacy en dernier

## Recap des decisions prises

### 1. Backlog et epic map

La refonte est structuree en 8 epics:
- observabilite
- coeur de tunnel
- contrats metier
- projection routeur
- composants UI communs
- surfaces amont
- bloc source
- pre-home et cleanup

Le backlog est suffisamment detaille pour servir de base d'execution, sans encore tomber dans des stories trop fines.

### 2. Dependances et chemin critique

Le chemin critique passe par:
- telemetry
- source de verite
- contrats source
- pre-home minimal
- projection routeur
- bloc source
- nettoyage final

Decision structurante:
- le coeur `B/C/D` reste prioritaire sur les surfaces finales si un arbitrage de capacite apparait

### 3. Flags et coexistence

Les flags utiles retenus sont limites:
- `entry_journey_telemetry_v2`
- `entry_journey_state_model_v2`
- `entry_journey_routing_v2`
- `entry_journey_ui_v2`
- `entry_journey_source_hub_v2`
- `entry_journey_prehome_v2`
- `entry_journey_cleanup_v2`

Decision structurante:
- peu de flags, chacun porte un bloc coherent
- pas de double source de verite durable

### 4. Migrations visibles

La phase 5 a mappe:
- les composants a conserver, extraire ou laisser disparaitre
- les routes a garder, projeter, fusionner ou supprimer
- les branchements legacy a nettoyer avec leurs preconditions de suppression

Decision structurante:
- les suppressions legacy ne partent jamais avant la stabilisation de la surface cible equivalente

### 5. Definition of done et tests

Chaque famille de lots a maintenant:
- une `definition of done`
- des attentes minimales de test
- des criteres de revue
- un niveau de vigilance

Decision structurante:
- les lots critiques demandent des preuves renforcees

## Coherence avec les phases precedentes

La phase 5 reste coherente avec:

- phase 1:
  - aucun rework du parcours UX cible
- phase 2:
  - les composants et surfaces restent alignes avec la spec UI
- phase 3:
  - le decoupage respecte `TunnelState`, `EntryJourneyOrchestrator`, les ports et la projection routeur
- phase 4:
  - les lots critiques protegent les budgets, safe states et la separation pre-home / post-home

## Sujets deferes a l'execution

Ces sujets sont volontairement deferes a l'execution:
- decoupage plus fin en stories si l'equipe le souhaite
- choix exact des PR boundaries et du rythme de merge
- proprietaires nominatifs de chaque lot
- outillage concret de telemetry et dashboards
- arbitrages de capacite si certains lots sensibles doivent etre recoupes

## Sujets deferes a la QA

La QA devra surtout preparer:
- les scenarios par jalon
- les checks de rollback par flag
- la verification du routing sur cas cold / warm
- la verification des safe states:
  - `offline`
  - `auth_required`
  - `source_recovery_required`
  - `prehome_partial_recovery`
- la verification de `catalog_minimal_ready` vs `catalog_full_load_completed`

## Risques restants

Les risques restants les plus importants sont:
- `B4` peut encore etre trop large sans sous-decoupage
- `G1/G2` restent exposes a la complexite source
- `D2` peut reveler des loops ou des projections ambigues
- `H4` peut facilement devenir un lot fourre-tout
- la coexistence legacy peut durer trop longtemps si les jalons ne sont pas tenus

Ces risques restent acceptables car:
- ils sont identifies
- ils sont relies a des lots explicites
- ils ont deja des flags et des points de rollback

## Liste des artefacts produits

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

## Verdict final

La phase 5 est suffisamment stable pour passer a l'execution.

Cela signifie que:
- le plan d'implementation est decoupe de facon executable
- les lots critiques sont identifies
- les vagues de livraison sont ordonnees
- les flags et rollbacks sont prevus
- la migration legacy est bornee

La suite logique est:
1. lancer l'execution du backlog par jalons
2. brancher la QA et la telemetry des premiers lots
3. preparer la phase 6 de validation, QA et mise en production
