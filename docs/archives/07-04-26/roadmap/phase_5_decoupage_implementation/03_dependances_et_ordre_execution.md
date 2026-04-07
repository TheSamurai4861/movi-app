# Sous-phase 5.2 - Dependances, ordre d'execution et chemin critique

## Objectif

Ordonner le backlog initial de la phase 5 selon les dependances reelles du tunnel, pour obtenir:
- un ordre de livraison defendable
- un chemin critique lisible
- une liste claire des lots parallelisables

Cette sous-phase ne redefinit pas les lots. Elle precise dans quel ordre ils doivent vivre.

## Principe directeur

Le nouvel ordre doit respecter une logique simple:

1. mesurer avant de basculer
2. stabiliser la source de verite avant le routeur
3. stabiliser le routeur avant les grandes surfaces
4. stabiliser le preload borne avant de nettoyer le legacy

## Dependances structurantes

Les dependances les plus fortes du programme sont:

- les lots UI dependent du coeur `TunnelState + Orchestrator + Route projection`
- le preload minimal depend des contrats source et validation source
- le nettoyage legacy depend de la stabilisation des surfaces migrees
- l'observabilite doit exister avant les grosses bascules de comportement

Consequence:
- le coeur du tunnel reste le chemin critique
- les composants UI communs sont paralleles au coeur, mais pas devant lui

## Matrice de dependances par lot

| Lot | Dependances minimales | Nature de dependance | Peut demarrer avant le coeur complet ? |
| --- | --- | --- | --- |
| `A1` | aucune | fondation mesure | oui |
| `A2` | `A1` | enrichissement telemetry | oui |
| `A3` | aucune | fondation migration | oui |
| `B1` | aucune | fondation domaine | oui |
| `B2` | `B1` | bridge de compatibilite | oui |
| `B3` | `B1`, `B2` | nouvel orchestrateur en shadow | non |
| `B4` | `B3` | bascule source de verite | non |
| `C1` | `B3` | branchement contrat session | partiellement |
| `C2` | `B3` | branchement contrat profils | partiellement |
| `C3` | `B3` | branchement contrat sources | partiellement |
| `C4` | `C3` | validation source | non |
| `C5` | `C3`, `C4` | pre-home minimal | non |
| `D1` | `B4` | derive de surface | non |
| `D2` | `D1` | projection routeur | non |
| `D3` | `D2` | simplification guards legacy | non |
| `E1` | spec UI phase 2 | briques communes | oui |
| `E2` | `E1` | composants de choix / feedback | oui |
| `E3` | `E1`, `E2` | focus TV commun | oui |
| `F1` | `A1`, `B4`, `D2`, `E1` | surface systeme | non |
| `F2` | `C1`, `E1` | surface auth | non |
| `F3` | `C2`, `E1` | creation profil | non |
| `F4` | `C2`, `E2`, `E3` | choix profil | non |
| `G1` | `C3`, `E2`, `E3` | hub source | non |
| `G2` | `G1`, `C4` | ajout + validation source | non |
| `G3` | `G2` | recovery source | non |
| `H1` | `C5`, `E1`, `E2` | surface chargement medias | non |
| `H2` | `C5`, `H1` | separation catalog minimal / full | non |
| `H3` | `B4`, `C2`, `C3` | preferences hors logique metier | non |
| `H4` | `D3`, `F1-F4`, `G1-G3`, `H1-H3` | nettoyage final | non |

## Chemin critique recommande

Le chemin critique de livraison est:

`A1 -> A2 -> B1 -> B2 -> B3 -> B4 -> C3 -> C4 -> C5 -> D1 -> D2 -> G1 -> G2 -> G3 -> H1 -> H2 -> D3 -> H3 -> H4`

Pourquoi ce chemin critique:
- il ouvre d'abord la mesure
- il pose ensuite la source de verite
- il securise ensuite le bloc source, qui est le hotspot metier et resilience
- il verrouille le pre-home borne avant le nettoyage final

## Chemins secondaires critiques

Deux chemins secondaires restent importants, sans etre le coeur du chemin critique.

### Chemin secondaire `auth / profil`

`B3 -> C1 -> C2 -> E1 -> E2 -> E3 -> F2 -> F3 -> F4`

Importance:
- il stabilise l'entree utilisateur la plus visible
- il peut avancer partiellement en parallele du bloc source

### Chemin secondaire `observabilite / migration`

`A1 -> A2 -> A3 -> D1 -> D2`

Importance:
- il garantit que les bascules de comportement restent pilotables

## Ordre recommande des vagues d'execution

## Vague 0 - Fondations de mesure et migration

Lots:
- `A1`
- `A2`
- `A3`
- `B1`
- `E1`

But:
- ne pas commencer aveugle
- poser les briques communes du domaine et de l'UI

## Vague 1 - Coeur du tunnel

Lots:
- `B2`
- `B3`
- `C1`
- `C2`
- `C3`

But:
- faire emerger le nouveau coeur sans casser le tunnel visible

## Vague 2 - Bascule de source de verite et projection routeur

Lots:
- `B4`
- `D1`
- `D2`

But:
- faire porter le parcours par l'etat cible

## Vague 3 - Composants UI et surfaces amont

Lots:
- `E2`
- `E3`
- `F1`
- `F2`
- `F3`
- `F4`

But:
- migrer l'amont du tunnel sur les nouvelles briques sans attendre le bloc source final

## Vague 4 - Bloc source et resilience source

Lots:
- `C4`
- `G1`
- `G2`
- `G3`

But:
- fermer le plus gros noeud de risque fonctionnel

## Vague 5 - Pre-home borne

Lots:
- `C5`
- `H1`
- `H2`

But:
- sortir le catalogue complet du chemin pre-home
- finaliser `Chargement medias`

## Vague 6 - Nettoyage et fermeture

Lots:
- `D3`
- `H3`
- `H4`

But:
- supprimer la duplication systemique
- nettoyer les ponts legacy

## Lots parallelisables

Les lots suivants peuvent raisonnablement avancer en parallele, si les frontieres de responsabilite sont respectees.

### Parallelisation sure

- `A1`, `A3`, `B1`, `E1`
- `C1`, `C2`, `C3` apres `B3`
- `E2` et `E3` apres `E1`
- `F2` et `F3` une fois `E1` et leurs contrats respectifs prets

### Parallelisation conditionnelle

- `F4` peut avancer en parallele de `G1`, mais seulement si les composants de galerie sont stabilises
- `H1` peut preparer sa surface avant `C5`, mais pas finaliser son comportement
- `H3` peut etre prepare en amont, mais ne doit pas etre merge comme changement metier avant `B4`

### Parallelisation non recommandee

- `B4` en parallele avec `D2`
- `G2` en parallele avec `C4`
- `H4` avant stabilisation des surfaces finales

## Points de blocage potentiels

Les blocages les plus probables sont:

### 1. `B4` - Bascule de source de verite

Risque:
- trop de consommateurs historiques du state legacy

Effet:
- ralentit `D1`, `D2`, `F1`, `H3`

### 2. `C4` - Validation source

Risque:
- hotspot reseau et logique de recovery

Effet:
- ralentit `G2`, `G3`, `C5`

### 3. `C5` - Pre-home minimal

Risque:
- confusion entre `catalog minimal` et `catalog full`

Effet:
- ralentit `H1`, `H2`, `H4`

### 4. `D2` - Route projection

Risque:
- coexistence longue avec les guards historiques

Effet:
- ralentit `F1` et le nettoyage final

## Arbitrages recommandes

- si un arbitrage doit etre fait, privilegier toujours le coeur `B/C/D` avant les surfaces finales
- ne pas lancer `H4` pour "faire du propre" tant que `H2` n'est pas stabilise
- accepter que `E1-E3` avancent tot, mais sans faire deriver la logique metier dans les composants
- garder `F1` tot dans le plan car il porte le premier safe state critique `offline`

## Definition simplifiee du chemin critique

En une phrase:
- mesurer
- fixer la source de verite
- brancher sources et preload minimal
- projeter via le routeur
- migrer les surfaces
- nettoyer le legacy

## Verdict

La sous-phase `5.2` est suffisamment stable si l'on retient ces points:
- les dependances entre lots sont maintenant explicites
- le chemin critique de livraison est lisible
- les vagues d'execution sont defendables
- les fenetres de parallelisation sont bornees

La suite logique est la sous-phase `5.3`, pour rattacher les flags, la coexistence temporaire et les points de rollback a ce plan d'execution.
