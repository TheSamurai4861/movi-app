# Vague 0 - Preparation operative

## Objectif

Transformer la vague 0 de la mega roadmap en cadre d'execution immediatement exploitable, sans changer encore le comportement utilisateur du tunnel.

La vague 0 sert a verrouiller:
- la gouvernance
- la criticite des lots
- les owners par epic
- les regles de PR et de merge
- les environnements de verification
- le dashboard minimal de suivi
- le gate de lancement avant toute bascule critique

## Ancrage de reference

Cette vague applique explicitement:
- [rules_nasa.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/archives/02-04-26/rules_nasa.md)
- [00_mega_roadmap_implementation_et_verification.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/00_mega_roadmap_implementation_et_verification.md)
- [07_plan_migration_consolide.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/07_plan_migration_consolide.md)
- [06_definition_of_done_et_tests_par_lot.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/06_definition_of_done_et_tests_par_lot.md)
- [09_validation_finale_phase_4.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/09_validation_finale_phase_4.md)

## Principes d'execution retenus

- `No evidence, no merge`: aucun lot critique ne part sans preuve attendue explicite.
- `No green pipeline, no release`: aucun flag critique n'est active durablement sans pipeline verte.
- `State before screens`: le coeur passe avant les surfaces finales.
- `One risky change, one boundary`: une PR critique ne doit porter qu'une seule bascule defendable.
- `Traceability first`: chaque lot doit etre relie a un besoin, une criticite, un flag, des tests et un rollback.
- `Explicit degraded mode`: tout comportement degrade attendu doit etre nomme, observe et testable.

## Sorties de la vague 0

Les sorties concretes attendues de cette vague sont:
- un backlog ordonne confirme
- un registre d'owners et de criticite
- un cadre de PR boundaries et de merge
- une cartographie des environnements de verification
- un dashboard minimal specifie
- un gate de lancement verifiable avant les vagues critiques

## Artefacts produits

- [02_registre_owners_criticite_et_preuves.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/02_registre_owners_criticite_et_preuves.md)
- [03_pr_boundaries_et_regles_de_merge.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/03_pr_boundaries_et_regles_de_merge.md)
- [04_environnements_dashboard_et_traces.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/04_environnements_dashboard_et_traces.md)
- [05_gate_lancement_vague_0.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/05_gate_lancement_vague_0.md)

## Decision log de vague 0

### 1. Gouvernance de criticite

Les lots du tunnel sont gouvernes par double classification:
- criticite du changement `C1 -> C4`
- classe logicielle du composant `L1 -> L4`

Regle retenue:
- tout lot `C1` ou `C2` sur composant `L1` ou `L2` exige:
  - risque documente
  - rollback documente
  - tests adaptes
  - verification independante

### 2. Owners par epic

Faute de noms de personnes explicitement fournis, la vague 0 nomme des owners par role:
- observabilite / telemetry
- coeur tunnel
- routing / composition
- UI tunnel
- domaine source
- QA / release

Ces owners sont suffisants pour lancer l'execution. Les noms individuels peuvent etre ajoutes sans reouvrir la roadmap.

### 3. PR boundaries

La vague 0 interdit:
- les PR fourre-tout
- les PR qui melangent coeur, routing et plusieurs surfaces finales
- les activations de plusieurs flags risquees dans une seule PR
- les suppressions legacy avant stabilisation de la cible equivalente

### 4. Observabilite minimale

Avant la vague 2, le projet doit pouvoir lire au minimum:
- latence des stages critiques
- `time_to_safe_state`
- reason codes critiques
- succes / echec de validation source
- `catalog_minimal_ready`
- `catalog_full_load_completed`
- exposition des flags

### 5. Gate de lancement

Aucune implementation critique ne doit commencer tant que:
- les owners ne sont pas explicites
- les PR boundaries ne sont pas posees
- le dashboard minimal n'est pas specifie
- les rollbacks critiques ne sont pas rattaches aux lots `B4`, `D2`, `C4`, `C5`, `G1`, `G2`, `H2`, `H4`

## Impact sur les vagues suivantes

La vague 0 rend possible:
- la vague 1 sans dette de mesure
- la vague 2 sans ambiguite de source de verite
- la vague 3 sans risque de bascule routeur non encadree
- la vague 5 sans flou sur la proprietes du bloc source
- la vague 6 sans confusion entre `catalog minimal` et `catalog full`

## Verdict

La vague 0 est consideree comme correctement preparee seulement si les quatre artefacts associes sont valides ensemble.

La suite logique est:
1. valider le gate de lancement
2. lancer `A1-A3`
3. ne pas engager `B4`, `D2`, `G1/G2` ou `H2` avant verification du cadre vague 0
