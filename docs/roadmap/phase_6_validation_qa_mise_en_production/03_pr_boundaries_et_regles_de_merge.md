# PR boundaries et regles de merge

## Objectif

Definir des limites de PR defendables pour le programme du tunnel afin d'eviter:
- les diffs trop larges
- les bascules multiples dans une seule PR
- la perte de traceabilite
- l'absence de rollback clair

## Regle directrice

Une PR du tunnel doit pouvoir etre revue comme une hypothese unique:
- un objectif
- une zone principale
- un signal observable
- un rollback

## Regles de boundary

### Regle 1 - Une bascule critique par PR

Interdit:
- `B4 + D2` dans la meme PR
- `G1 + G2 + G3` dans la meme PR si la taille devient non defendable
- `H2 + H4` dans la meme PR

Autorise:
- petits pre-requis techniques lisibles et strictement necessaires

### Regle 2 - Ne pas melanger coeur et surfaces finales

Interdit:
- modifier `TunnelState` et migrer plusieurs pages finales dans la meme PR
- toucher simultanement orchestration, routing et cleanup legacy sauf si la PR n'active rien

### Regle 3 - Ne pas melanger creation et activation d'un flag critique

Regle:
- une PR peut preparer un comportement sous flag `off`
- une PR distincte doit porter l'activation mesurable si le risque est `C1/C2`

### Regle 4 - Cleanup tardif uniquement

Interdit:
- supprimer une route, un guard ou une page legacy avant stabilisation de la cible equivalente

### Regle 5 - Telemetry avant changement critique

Interdit:
- merger un lot critique sans signaux permettant d'observer son impact

## Structure minimale attendue dans une PR

Toute PR `C1/C2` doit contenir:
- lot et vague concernes
- objectif du changement en une phrase
- classification `C/L`
- risque principal
- flag associe
- rollback
- tests executes
- evidence observable attendue

## Template logique recommande

### Entete

- `Lot`: `B4`
- `Vague`: `3`
- `Criticite`: `C1`
- `Classe`: `L2`
- `Flag`: `entry_journey_state_model_v2`

### Sections obligatoires

- `Pourquoi`
- `Ce qui change`
- `Ce qui ne change pas`
- `Risque principal`
- `Plan de test`
- `Evidence attendue`
- `Rollback`
- `Docs impactees`

## Politique de revue

### Lots `C1`

Obligatoire:
- 2 reviewers minimum
- 1 reviewer independant
- validation explicite du rollback
- validation explicite de la preuve attendue

### Lots `C2`

Obligatoire:
- 1 reviewer principal
- 1 second avis recommande si la PR touche startup, routing ou source

### Lots `C3-C4`

Obligatoire:
- revue par pair
- verification de perimetre et de non-regression evidente

## Politique de merge

Une PR ne merge pas si:
- la pipeline n'est pas verte
- la criticite n'est pas renseignee
- le rollback n'est pas documente
- les tests attendus ne sont pas executes
- la telemetry est requise mais absente
- la PR active plusieurs bascules non separables

## Decoupage recommande des PR sur les lots les plus sensibles

### `B4`

PR recommandees:
1. preparation de la bascule, flag `off`
2. activation interne / shadow compare
3. bascule effective avec evidence

### `D2`

PR recommandees:
1. ajout projection routeur sous flag `off`
2. activation ciblee et tests navigation

### `G1/G2`

PR recommandees:
1. structure du hub source
2. branchement validation guidee
3. recoveries et messages

### `H2`

PR recommandees:
1. instrumentation `minimal/full`
2. separation effective de la charge
3. verification des budgets

## Liens obligatoires a tenir a jour

Chaque PR critique doit mettre a jour si necessaire:
- la mega roadmap phase 6 si le gate change
- le plan de migration phase 5 si l'ordre de bascule change
- la doc de rollback si la strategie evolue
- la doc telemetry si un event ou reason code change

## Verdict

Ces regles suffisent a eviter les PR opaques et a rendre les lots critiques du tunnel revuables dans une logique de haute assurance.
