# Sous-phase 4.1 - Budgets de performance du tunnel

## Objectif

Definir des budgets de temps defendables pour chaque etape critique du tunnel, ainsi que les seuils `nominal / slow / blocked`.

Cette sous-phase fixe:
- des budgets de release initiale
- des seuils de degradation observables
- des budgets agreges par scenario

Elle ne fixe pas encore:
- les timeouts exacts de chaque contrat
- les retries et backoffs
- les politiques de fallback

Ces points seront traites en `4.2`.

## Principe de budget retenu

Les budgets retenus ici sont:
- des **budgets cibles de release**
- pas des performances ideales de laboratoire
- mais pas non plus des seuils laxistes

Chaque etape critique recoit trois seuils:

- `nominal`
  - le temps cible a tenir la plupart du temps
- `slow`
  - le seuil a partir duquel l'etape doit etre consideree comme lente et potentiellement signalee
- `blocked`
  - le seuil a partir duquel l'attente normale n'est plus acceptable sans recovery explicite

## Regles de lecture

- `nominal` doit couvrir le retour utilisateur sain
- `slow` doit declencher un signal telemetry et, selon l'etape, une evolution visuelle
- `blocked` doit conduire a un comportement explicite en `4.2` et `4.5`

## Budgets par etape canonique

## 1. `preparing_system`

Role:
- bootstrap systeme
- premiere evaluation reseau
- premiere resolution auth/context

Budget retenu:

| Etape | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `preparing_system` | `<= 1200 ms` | `> 1200 ms` et `<= 2500 ms` | `> 2500 ms` |

Interpretation:
- en dessous de `1.2 s`, le splash reste bref et credible
- entre `1.2 s` et `2.5 s`, l'etape reste acceptable mais doit etre tracee comme lente
- au-dela de `2.5 s`, le tunnel ne peut plus rester dans une simple attente silencieuse

## 2. Resolution session / auth

Role:
- restore ou refresh session
- decision vers nominal ou `auth_required`

Budget retenu:

| Sous-etape | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `session_resolve` | `<= 800 ms` | `> 800 ms` et `<= 1800 ms` | `> 1800 ms` |
| `auth_surface_ready` | `<= 400 ms` apres decision | `> 400 ms` et `<= 900 ms` | `> 900 ms` |

Interpretation:
- la decision "session valide ou non" doit etre rapide
- si l'auth est requise, la surface doit apparaitre presque immediatement apres la decision

## 3. Resolution profils

Role:
- charger l'inventaire profils
- resoudre ou imposer le choix du profil

Budget retenu:

| Sous-etape | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `profiles_inventory` | `<= 500 ms` | `> 500 ms` et `<= 1200 ms` | `> 1200 ms` |
| `selected_profile_resolve` | `<= 150 ms` | `> 150 ms` et `<= 400 ms` | `> 400 ms` |

Interpretation:
- l'inventaire profils doit rester tres leger
- la resolution du profil selectionne ne doit presque jamais etre perceptible

## 4. Resolution sources

Role:
- charger l'inventaire sources
- resoudre la source active
- verifier qu'elle est exploitable

Budget retenu:

| Sous-etape | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `sources_inventory` | `<= 700 ms` | `> 700 ms` et `<= 1500 ms` | `> 1500 ms` |
| `selected_source_resolve` | `<= 150 ms` | `> 150 ms` et `<= 400 ms` | `> 400 ms` |
| `source_validation` | `<= 1200 ms` | `> 1200 ms` et `<= 3000 ms` | `> 3000 ms` |

Interpretation:
- l'inventaire doit rester contenu
- la validation peut etre plus couteuse, mais ne doit pas geler le tunnel indefiniment
- `source_validation` est un des hotspots majeurs de la phase 4

## 5. `preloading_home`

Role:
- attendre le minimum requis avant d'autoriser `home`

Decision retenue:
- budgete comme etape globale
- avec sous-budgets guides pour `catalog`, `library` et `home preload`

Hypothese produit clarifiee:
- un chargement **complet** de catalogue peut legitimement prendre `10-15 s`
- les budgets ci-dessous ne s'appliquent donc **pas** au catalogue exhaustif
- ils s'appliquent au **minimum exploitable pre-home**
  - snapshot minimal
  - index minimal
  - premiers blocs exploitables
  - metadata strictement requise pour tenir la promesse de `home prete`

Budget retenu:

| Sous-etape | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `catalog_ready` | `<= 1800 ms` | `> 1800 ms` et `<= 4000 ms` | `> 4000 ms` |
| `library_ready` | `<= 900 ms` | `> 900 ms` et `<= 2000 ms` | `> 2000 ms` |
| `home_preloaded` | `<= 700 ms` | `> 700 ms` et `<= 1500 ms` | `> 1500 ms` |
| `preloading_home` global | `<= 2500 ms` | `> 2500 ms` et `<= 5000 ms` | `> 5000 ms` |

Interpretation:
- `preloading_home` reste l'etape la plus chere du tunnel nominal
- au-dela de `2.5 s`, l'utilisateur doit etre considere en attente lente
- au-dela de `5 s`, le tunnel doit sortir d'une attente implicite simple
- le **catalogue complet** peut continuer apres `home` sans remettre en cause ce budget

## 6. Transition vers `ready_for_home`

Role:
- sortie du tunnel et premiere arrivee exploitable sur `home`

Budget retenu:

| Etape | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `ready_for_home -> first_home_paint_useful` | `<= 600 ms` | `> 600 ms` et `<= 1200 ms` | `> 1200 ms` |

Interpretation:
- une fois `ready_for_home` atteint, la bascule visuelle vers `home` doit etre tres rapide

## Budgets agreges par scenario

## 1. Warm start - retour utilisateur sain

Definition:
- session valide
- profil deja resolu
- source valide deja resolue
- preload minimal a effectuer

Budget retenu:

| Scenario | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `warm_start_healthy_return` | `<= 3500 ms` | `> 3500 ms` et `<= 6000 ms` | `> 6000 ms` |

## 2. Cold start - utilisateur deja valide

Definition:
- app froide
- session resolvable
- profil et source deja connus
- preload minimal requis

Budget retenu:

| Scenario | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `cold_start_known_user` | `<= 5000 ms` | `> 5000 ms` et `<= 8000 ms` | `> 8000 ms` |

## 3. Premier parcours

Definition:
- pas de session ou premiere connexion
- creation/selection du profil
- ajout/selection de source
- preload minimal avant `home`

Decision:
- on ne budgete pas le temps de saisie utilisateur dans le temps systeme
- on budgete seulement les etapes systeme entre actions utilisateur

Budget retenu:

| Scenario | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `first_time_guided_system_time` | `<= 6500 ms` cumule hors saisie | `> 6500 ms` et `<= 10000 ms` | `> 10000 ms` |

## 4. Retour utilisateur avec recovery source

Definition:
- session valide
- profil resolu
- source absente ou invalide
- passage par `source_required`

Budget retenu:

| Scenario | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `return_user_source_recovery_system_time` | `<= 5000 ms` hors choix utilisateur | `> 5000 ms` et `<= 8000 ms` | `> 8000 ms` |

## 5. Entree en safe state degrade

Definition:
- reseau indisponible, timeout, cloud lent ou fallback local

Decision:
- en degrade, on budgete d'abord le **temps avant safe state explicite**

Budget retenu:

| Scenario | Nominal | Slow | Blocked |
| --- | --- | --- | --- |
| `time_to_safe_state` | `<= 2500 ms` | `> 2500 ms` et `<= 4500 ms` | `> 4500 ms` |

## Regles budgetaires par categorie

## Regle 1 - Les etapes de resolution pure doivent rester sub-secondes ou proches

Doivent tendre vers `< 1 s` en nominal:
- `session_resolve`
- `profiles_inventory`
- `selected_profile_resolve`
- `selected_source_resolve`

## Regle 2 - Les etapes reseau lourdes ont un plafond plus haut mais borne

Peuvent depasser `1 s`, mais doivent etre bornees:
- `source_validation`
- `catalog_ready`
- `preloading_home`

## Regle 3 - L'utilisateur ne doit pas rester plus de 2.5 s dans une attente systeme silencieuse

Au-dela:
- l'etape doit etre taggee `slow`
- la telemetry doit le refleter
- un comportement de recovery ou d'explication devient legitime selon l'etape

## Regle 4 - Au-dela de 5 s sur une etape critique, on quitte le simple "loading normal"

Au-dela:
- la phase 4 considerera le cas comme `blocked` ou `degraded strong`
- la suite exacte sera fixee en `4.2` et `4.5`

## Arbitrages retenus

## Arbitrage 1 - Budgets de release, pas budgets "moonshot"

Decision:
- les chiffres poses ici visent une release initiale defendable
- ils pourront etre durcis plus tard, mais doivent etre tenables

## Arbitrage 2 - `preloading_home` a un budget global plus des sous-budgets guides

Decision:
- on garde un budget global pour le tunnel
- mais on isole `catalog`, `library` et `home preload` pour localiser les lenteurs
- `catalog_ready` signifie ici `catalogue minimal exploitable`
- le chargement complet du catalogue sort du budget pre-home et devra etre traite en `4.3`

## Arbitrage 3 - Le budget degrade principal est "temps avant safe state"

Decision:
- en degrade, le premier KPI n'est pas "temps jusqu'a issue finale"
- c'est "temps jusqu'a etat de repli explicite"

## Arbitrage 4 - TV et mobile partagent la meme doctrine, pas forcement le meme reel

Decision:
- les budgets cibles sont communs
- la mesure devra ensuite verifier si TV demande des ajustements de seuil

## Points encore ouverts apres 4.1

Ces points ne remettent pas en cause les budgets, mais seront precises en `4.2` et `4.4`.

1. Quel timeout exact declenche `blocked` vs `degraded` par contrat.
2. Quel nombre de retries est autorise par contrat critique.
3. Quel message ou signal visuel apparait exactement au seuil `slow`.
4. Quels evenements telemetry doivent porter `nominal`, `slow` et `blocked`.

## Decision log

1. Chaque etape critique du tunnel a maintenant un budget cible.
2. `preloading_home` est budgete comme hotspot principal.
3. Les resolutions profil/source selectionnees doivent rester quasi invisibles en nominal.
4. Le premier KPI degrade du tunnel est le temps avant safe state explicite.
5. Les budgets poses ici servent de cible de release, pas de plafond theoretique.

## Verdict de sortie de la sous-phase 4.1

Verdict:
- la sous-phase `4.1` est suffisamment stable pour lancer `4.2`

Pourquoi:
- chaque etape critique a un budget defendable
- les seuils `nominal / slow / blocked` sont poses
- les scenarios agreges principaux sont couverts
- les arbitrages structurants de budget sont explicites

## Prochaine etape recommandee

La suite logique est:
1. traduire ces budgets en timeouts et retries concrets
2. definir les politiques de preload borne et fallback
3. fixer les conditions de passage vers `degraded` et `blocked`
