# Gate de lancement - Vague 0

## Objectif

Verifier qu'aucun lot critique du tunnel ne demarre sans cadre d'execution, de preuve et de rollback suffisant.

## Regle d'or

Un lot critique ne demarre pas si le gate vague 0 n'est pas vert.

## Scope du gate

Ce gate s'applique avant lancement des lots:
- `B4`
- `C4`
- `C5`
- `D2`
- `G1`
- `G2`
- `H2`
- `H4`

Il est recommande avant toute vague a partir de la vague 2.

## Checklist obligatoire

### A. Gouvernance

- un owner par role est explicite pour chaque epic
- les reviewers cibles sont identifies pour les lots `C1/C2`
- les lots critiques ont une classification `C/L`

### B. Traceabilite

- chaque lot critique est relie a son flag
- chaque lot critique est relie a son rollback
- chaque lot critique est relie a sa preuve attendue
- chaque lot critique est relie a sa doc de reference

### C. PR boundaries

- les regles de PR boundaries sont validees
- aucun lot critique n'est prevu dans une PR multi-bascule
- la politique de review `C1/C2` est acceptee

### D. Observabilite

- le dashboard minimal est defini
- les events critiques sont identifies
- `journey_run_id` et `reason_codes` sont prevus
- la comparaison flag `off/on` est possible

### E. Environnements

- `local`, `integration`, `staging` et `production` ont un usage clair
- les scenarios de test critiques sont rejouables dans au moins un environnement non prod
- les flags sont pilotables avant prod

### F. Verification

- la `definition of done` phase 5 sert bien de reference
- les lots `C1/C2` ont des attentes de test minimales explicites
- la verification independante est planifiee pour les lots `C1`

### G. Rollback

- les flags critiques sont disponibles
- le chemin de retour arriere est documente
- les conditions d'arret d'un rollout sont connues

## Statut recommande au demarrage

| Item | Statut attendu |
| --- | --- |
| Phases 1 a 5 validees | `OK` |
| Mega roadmap phase 6 validee | `OK` |
| Owners par role documentes | `OK` |
| Criticite et preuves minimales documentees | `OK` |
| PR boundaries documentees | `OK` |
| Dashboard minimal specifie | `OK` |
| Environnements de verification identifies | `OK` |
| Gate lots critiques relie a rollback | `OK` |

## Conditions de refus

Le gate est `NO-GO` si au moins un point suivant est vrai:
- un lot `C1` part sans rollback explicite
- un lot critique part sans flag alors qu'il doit etre reversible
- la telemetry ne permet pas de mesurer l'impact de la bascule
- les reviewers independants ne sont pas prevus pour `B4`, `D2`, `C4`, `C5`, `G1`, `G2`, `H2`
- `H4` est defini comme cleanup large sans perimetre borne

## Decision de lancement

### `GO`

Autorise:
- vague 1
- vague 2 preparation

Condition:
- toutes les checklist sont `OK`

### `GO WITH RESTRICTIONS`

Autorise:
- `A1-A3`
- `B1-B3`

Interdit:
- `B4`, `D2`, `G1/G2`, `H2`, `H4`

Condition:
- cadre partiellement pret mais gate critique incomplet

### `NO-GO`

Interdit:
- toute bascule critique

Condition:
- absence de preuve, absence de telemetry ou absence de rollback defendable

## Verdict initial sur base de la documentation actuelle

Sur base des phases 1 a 5 et des artefacts de cette vague 0:
- le programme est `GO WITH RESTRICTIONS`

Cela signifie:
- la vague 1 peut commencer
- `B1-B3`, `C1-C3`, `E1` peuvent etre prepares
- les bascules critiques restent bloquees tant que l'outillage de mesure et la verification independante ne sont pas reellement branches

## Prochaine etape

Pour passer a `GO` complet:
1. brancher effectivement le socle telemetry minimal
2. confirmer les owners nominatifs si necessaire
3. valider le dashboard sur un run reel du tunnel existant
4. confirmer la disponibilite du schema de rollback par flag
